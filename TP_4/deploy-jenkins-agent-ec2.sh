#!/usr/bin/env bash
#
# deploy-jenkins-agent-ec2.sh
# TP4 - provisionne une instance EC2 dédiée à servir d'agent Jenkins (label aws-lab).

set -euo pipefail

PROFILE="jenkins-lab"
REGION="eu-west-3"
PREFIX="al"
INSTANCE_NAME="${PREFIX}-jenkins-agent-tp4"
KEY_NAME="${PREFIX}-jenkins-agent-key"
SG_NAME="${PREFIX}-jenkins-agent-sg"
INSTANCE_TYPE="t3.micro"
CONTROLLER_IP="13.36.171.149"

AWS="aws --profile ${PROFILE} --region ${REGION}"

echo "==> Vérification des credentials AWS"
$AWS sts get-caller-identity

echo "==> Récupération de ton IP publique"
MY_IP="$(curl -s https://checkip.amazonaws.com)/32"
echo "    IP détectée : ${MY_IP}"

echo "==> Recherche de la dernière AMI Ubuntu 24.04 LTS"
AMI_ID=$($AWS ec2 describe-images \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*" \
            "Name=state,Values=available" \
  --query "sort_by(Images, &CreationDate)[-1].ImageId" \
  --output text)
echo "    AMI trouvée : ${AMI_ID}"

echo "==> Création (ou réutilisation) de la paire de clés SSH : ${KEY_NAME}"
if $AWS ec2 describe-key-pairs --key-names "${KEY_NAME}" >/dev/null 2>&1; then
  echo "    La clé ${KEY_NAME} existe déjà côté AWS."
else
  $AWS ec2 create-key-pair \
    --key-name "${KEY_NAME}" \
    --query "KeyMaterial" \
    --output text > "${KEY_NAME}.pem"
  chmod 400 "${KEY_NAME}.pem"
  echo "    Clé créée : ./${KEY_NAME}.pem"
fi

echo "==> Création (ou réutilisation) du security group : ${SG_NAME}"
SG_ID=$($AWS ec2 describe-security-groups \
  --filters "Name=group-name,Values=${SG_NAME}" \
  --query "SecurityGroups[0].GroupId" --output text 2>/dev/null || echo "None")

if [ "${SG_ID}" == "None" ] || [ -z "${SG_ID}" ]; then
  VPC_ID=$($AWS ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text)
  SG_ID=$($AWS ec2 create-security-group \
    --group-name "${SG_NAME}" \
    --description "TP4 - agent Jenkins - SSH restreint" \
    --vpc-id "${VPC_ID}" \
    --query "GroupId" --output text)
  echo "    Security group créé : ${SG_ID}"

  # SSH depuis mon IP (setup/debug) et depuis le contrôleur Jenkins (connexion agent)
  $AWS ec2 authorize-security-group-ingress \
    --group-id "${SG_ID}" --protocol tcp --port 22 --cidr "${MY_IP}" >/dev/null
  $AWS ec2 authorize-security-group-ingress \
    --group-id "${SG_ID}" --protocol tcp --port 22 --cidr "${CONTROLLER_IP}/32" >/dev/null
  echo "    Règles ajoutées : SSH(22) depuis ${MY_IP} et depuis le contrôleur ${CONTROLLER_IP}/32"
else
  echo "    Security group ${SG_NAME} déjà existant (${SG_ID})."
fi

echo "==> Lancement de l'instance : ${INSTANCE_NAME}"
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
    --user-data file://agent-userdata.sh \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${INSTANCE_NAME}},{Key=Owner,Value=${PREFIX}},{Key=Project,Value=TP-Jenkins-Agent}]" \
    --query "Instances[0].InstanceId" --output text)
  echo "    Instance lancée : ${INSTANCE_ID}"
fi

echo "==> Attente 'running'..."
$AWS ec2 wait instance-running --instance-ids "${INSTANCE_ID}"

PUBLIC_IP=$($AWS ec2 describe-instances \
  --instance-ids "${INSTANCE_ID}" \
  --query "Reservations[0].Instances[0].PublicIpAddress" --output text)

echo ""
echo "=================================================="
echo " Agent prêt !"
echo "   Instance ID : ${INSTANCE_ID}"
echo "   IP publique : ${PUBLIC_IP}"
echo "   ssh -i ${KEY_NAME}.pem ubuntu@${PUBLIC_IP}"
echo "=================================================="
