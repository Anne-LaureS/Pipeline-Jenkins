#!/usr/bin/env bash
#
# provision-app-ec2.sh
# Projet de groupe TP7 - provisionne (ou réutilise) l'instance EC2 dédiée à
# l'application GLPI + MySQL. Idempotent : relançable sans dupliquer la ressource.

set -euo pipefail

REGION="eu-west-3"
PREFIX="al"
INSTANCE_NAME="${PREFIX}-glpi-app"
KEY_NAME="${PREFIX}-jenkins-agent-key"
SG_NAME="${PREFIX}-glpi-app-sg"
INSTANCE_TYPE="t3.small"
CONTROLLER_IP="${CONTROLLER_IP:?Variable CONTROLLER_IP requise}"
# IP de la personne qui doit accéder à l'appli (port 8080) dans son navigateur —
# ne PAS auto-détecter ici : ce script tourne sur l'agent Jenkins, dont l'IP n'a
# aucun rapport avec celle de l'opérateur humain.
OPERATOR_IP="${OPERATOR_IP:?Variable OPERATOR_IP requise (IP publique operateur, sans /32)}"

# Sur l'agent Jenkins, les identifiants arrivent via AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY
# (withCredentials), pas via un profil nommé — donc pas de --profile ici.
AWS="aws --region ${REGION}"

echo "==> Vérification des credentials AWS"
$AWS sts get-caller-identity

echo "==> IP opérateur fournie : ${OPERATOR_IP}/32"

echo "==> Recherche de la dernière AMI Ubuntu 24.04 LTS"
AMI_ID=$($AWS ec2 describe-images \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*" \
            "Name=state,Values=available" \
  --query "sort_by(Images, &CreationDate)[-1].ImageId" \
  --output text)
echo "    AMI trouvée : ${AMI_ID}"

echo "==> Création (ou réutilisation) du security group : ${SG_NAME}"
SG_ID=$($AWS ec2 describe-security-groups \
  --filters "Name=group-name,Values=${SG_NAME}" \
  --query "SecurityGroups[0].GroupId" --output text 2>/dev/null || echo "None")

if [ "${SG_ID}" == "None" ] || [ -z "${SG_ID}" ]; then
  VPC_ID=$($AWS ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text)
  SG_ID=$($AWS ec2 create-security-group \
    --group-name "${SG_NAME}" \
    --description "Projet groupe TP7 - app GLPI - acces restreint" \
    --vpc-id "${VPC_ID}" \
    --query "GroupId" --output text)
  echo "    Security group créé : ${SG_ID}"

  # SSH depuis le contrôleur (Ansible) uniquement, HTTP GLPI depuis mon IP uniquement
  $AWS ec2 authorize-security-group-ingress \
    --group-id "${SG_ID}" --protocol tcp --port 22 --cidr "${CONTROLLER_IP}/32" >/dev/null
  $AWS ec2 authorize-security-group-ingress \
    --group-id "${SG_ID}" --protocol tcp --port 8080 --cidr "${OPERATOR_IP}/32" >/dev/null
  echo "    Règles ajoutées : SSH(22) depuis ${CONTROLLER_IP}/32, HTTP(8080) depuis ${OPERATOR_IP}/32"
else
  echo "    Security group ${SG_NAME} déjà existant (${SG_ID})."
fi

echo "==> Lancement (ou réutilisation) de l'instance : ${INSTANCE_NAME}"
EXISTING=$($AWS ec2 describe-instances \
  --filters "Name=tag:Name,Values=${INSTANCE_NAME}" "Name=instance-state-name,Values=pending,running" \
  --query "Reservations[].Instances[].InstanceId" --output text)

if [ -n "${EXISTING}" ]; then
  echo "    Une instance ${INSTANCE_NAME} tourne déjà (${EXISTING})."
  INSTANCE_ID="${EXISTING}"
else
  INSTANCE_ID=$($AWS ec2 run-instances \
    --image-id "${AMI_ID}" \
    --instance-type "${INSTANCE_TYPE}" \
    --key-name "${KEY_NAME}" \
    --security-group-ids "${SG_ID}" \
    --user-data "file://$(dirname "$0")/user-data-app.sh" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${INSTANCE_NAME}},{Key=Owner,Value=${PREFIX}},{Key=Project,Value=TP7-projet-groupe},{Key=Course,Value=TP-Jenkins-AWS}]" \
    --query "Instances[0].InstanceId" --output text)
  echo "    Instance lancée : ${INSTANCE_ID}"
fi

echo "==> Attente 'running'..."
$AWS ec2 wait instance-running --instance-ids "${INSTANCE_ID}"

PUBLIC_IP=$($AWS ec2 describe-instances \
  --instance-ids "${INSTANCE_ID}" \
  --query "Reservations[0].Instances[0].PublicIpAddress" --output text)

mkdir -p "$(dirname "$0")/inventory"
cat > "$(dirname "$0")/inventory/hosts.ini" <<EOF
[glpi_app]
app01 ansible_host=${PUBLIC_IP} ansible_user=automation
EOF

echo ""
echo "=================================================="
echo " Instance app GLPI prête !"
echo "   Instance ID : ${INSTANCE_ID}"
echo "   IP publique : ${PUBLIC_IP}"
echo "   Inventaire écrit : inventory/hosts.ini"
echo "=================================================="
