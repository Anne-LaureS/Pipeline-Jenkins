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

echo "==> Récupération de l'IP de l'agent Jenkins (c'est lui qui exécutera ansible-playbook, pas le contrôleur)"
AGENT_IP=$($AWS ec2 describe-instances \
  --filters "Name=tag:Name,Values=al-jenkins-agent-tp4" "Name=instance-state-name,Values=running" \
  --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
if [ -z "${AGENT_IP}" ] || [ "${AGENT_IP}" == "None" ]; then
  echo "Impossible de trouver l'agent al-jenkins-agent-tp4 en cours d'execution." >&2
  exit 1
fi
echo "    IP agent : ${AGENT_IP}"

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
else
  echo "    Security group ${SG_NAME} déjà existant (${SG_ID})."
fi

# Réconciliation des règles à CHAQUE run (pas seulement à la création) : l'IP de
# l'agent Jenkins et celle de l'opérateur changent à chaque redémarrage de leurs
# instances respectives (pas d'Elastic IP sur ce labo). On retire tout ce qui
# n'est pas l'IP courante sur ces 2 ports, puis on autorise l'IP courante.
for RULE in "22:$AGENT_IP" "8080:$OPERATOR_IP"; do
  PORT="${RULE%%:*}"
  IP="${RULE##*:}"
  OLD_CIDRS=$($AWS ec2 describe-security-groups --group-ids "${SG_ID}" \
    --query "SecurityGroups[0].IpPermissions[?FromPort==\`${PORT}\`].IpRanges[].CidrIp" --output text)
  for OLD_CIDR in ${OLD_CIDRS}; do
    if [ "${OLD_CIDR}" != "${IP}/32" ]; then
      echo "    Retrait de l'ancienne règle port ${PORT} : ${OLD_CIDR}"
      $AWS ec2 revoke-security-group-ingress \
        --group-id "${SG_ID}" --protocol tcp --port "${PORT}" --cidr "${OLD_CIDR}" >/dev/null
    fi
  done
  $AWS ec2 authorize-security-group-ingress \
    --group-id "${SG_ID}" --protocol tcp --port "${PORT}" --cidr "${IP}/32" >/dev/null 2>&1 \
    || true
  echo "    Règle port ${PORT} à jour : ${IP}/32"
done

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
