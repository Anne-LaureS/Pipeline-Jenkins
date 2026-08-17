#!/usr/bin/env bash
#
# deploy-jenkins-ec2.sh
# TP Jenkins sur AWS — provisionne une instance EC2 Ubuntu 24.04 et installe Jenkins.
#
# Prérequis :
#   1. Rendre le script exécutable : chmod +x deploy-jenkins-ec2.sh
#   2. Lancer : ./deploy-jenkins-ec2.sh
#
# Le script est idempotent-friendly : il réutilise la clé et le security group
 
set -euo pipefail
 
# ---------- Paramètres à adapter ----------
PROFILE="jenkins-lab"          # profil AWS CLI configuré via `aws configure --profile jenkins-lab`
REGION="eu-west-3"             # Paris
PREFIX="al"                    # mes initiales
INSTANCE_NAME="${PREFIX}-jenkins-tp"
KEY_NAME="${PREFIX}-jenkins-key"
SG_NAME="${PREFIX}-jenkins-sg"
INSTANCE_TYPE="t3.micro"
# -------------------------------------------
 
AWS="aws --profile ${PROFILE} --region ${REGION}"
 
echo "==> Vérification des credentials AWS (profil: ${PROFILE})"
$AWS sts get-caller-identity
 
echo "==> Récupération de ton IP publique (pour restreindre les accès SSH/8080)"
MY_IP="$(curl -s https://checkip.amazonaws.com)/32"
echo "    IP détectée : ${MY_IP}"
 
echo "==> Recherche de la dernière AMI Ubuntu 24.04 LTS (Canonical, owner 099720109477)"
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
  echo "    S'assurer d'avoir le fichier ${KEY_NAME}.pem correspondant en local."
else
  $AWS ec2 create-key-pair \
    --key-name "${KEY_NAME}" \
    --query "KeyMaterial" \
    --output text > "${KEY_NAME}.pem"
  chmod 400 "${KEY_NAME}.pem"
  echo "    Clé créée et sauvegardée dans ./${KEY_NAME}.pem (permissions 400)"
fi
 
echo "==> Création (ou réutilisation) du security group : ${SG_NAME}"
SG_ID=$($AWS ec2 describe-security-groups \
  --filters "Name=group-name,Values=${SG_NAME}" \
  --query "SecurityGroups[0].GroupId" --output text 2>/dev/null || echo "None")
 
if [ "${SG_ID}" == "None" ] || [ -z "${SG_ID}" ]; then
  VPC_ID=$($AWS ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text)
  SG_ID=$($AWS ec2 create-security-group \
    --group-name "${SG_NAME}" \
    --description "TP Jenkins - SSH+8080 restreint a mon IP" \
    --vpc-id "${VPC_ID}" \
    --query "GroupId" --output text)
  echo "    Security group créé : ${SG_ID}"
 
  $AWS ec2 authorize-security-group-ingress \
    --group-id "${SG_ID}" \
    --protocol tcp --port 22 --cidr "${MY_IP}" >/dev/null
  $AWS ec2 authorize-security-group-ingress \
    --group-id "${SG_ID}" \
    --protocol tcp --port 8080 --cidr "${MY_IP}" >/dev/null
  echo "    Règles ajoutées : SSH(22) et Jenkins(8080) ouverts uniquement depuis ${MY_IP}"
else
  echo "    Security group ${SG_NAME} déjà existant (${SG_ID}) — réutilisation."
fi
 
echo "==> Tag & lancement de l'instance : ${INSTANCE_NAME}"
EXISTING=$($AWS ec2 describe-instances \
  --filters "Name=tag:Name,Values=${INSTANCE_NAME}" "Name=instance-state-name,Values=pending,running" \
  --query "Reservations[].Instances[].InstanceId" --output text)
 
if [ -n "${EXISTING}" ]; then
  echo "    Une instance ${INSTANCE_NAME} tourne déjà (${EXISTING}) — Ne pas relancer."
  INSTANCE_ID="${EXISTING}"
else
  INSTANCE_ID=$($AWS ec2 run-instances \
    --image-id "${AMI_ID}" \
    --instance-type "${INSTANCE_TYPE}" \
    --key-name "${KEY_NAME}" \
    --security-group-ids "${SG_ID}" \
    --user-data file://jenkins-userdata.sh \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${INSTANCE_NAME}},{Key=Owner,Value=${PREFIX}},{Key=Project,Value=TP-Jenkins}]" \
    --query "Instances[0].InstanceId" --output text)
  echo "    Instance lancée : ${INSTANCE_ID}"
fi
 
echo "==> Attente que l'instance soit 'running'..."
$AWS ec2 wait instance-running --instance-ids "${INSTANCE_ID}"
 
PUBLIC_IP=$($AWS ec2 describe-instances \
  --instance-ids "${INSTANCE_ID}" \
  --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
 
echo ""
echo "=================================================="
echo " Instance prête !"
echo "   Instance ID : ${INSTANCE_ID}"
echo "   IP publique : ${PUBLIC_IP}"
echo ""
echo " Jenkins s'installe automatiquement via le script user-data (cloud-init)."
echo " Patienter 2-3 minutes puis :"
echo ""
echo "   Se connecter en SSH :"
echo "     ssh -i ${KEY_NAME}.pem ubuntu@${PUBLIC_IP}"
echo ""
echo "   Vérifier le service Jenkins (une fois connecté en SSH) :"
echo "     sudo systemctl status jenkins --no-pager"
echo "     sudo journalctl -u jenkins --since \"10 minutes ago\" --no-pager"
echo "     sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
echo ""
echo "   Interface web Jenkins :"
echo "     http://${PUBLIC_IP}:8080"
echo "=================================================="
 