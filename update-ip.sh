#!/usr/bin/env bash
#
# update-ip.sh <NOUVELLE_IP>
# Met à jour l'IP publique de web01 (contrôleur Jenkins / cible web_lab, réutilisée
# depuis TP1 en TP4/TP5/TP7) dans tous les fichiers concernés, et met à jour en direct
# la règle SSH du Security Group de l'agent Jenkins pour pointer vers cette nouvelle IP.
# Utile après un stop/start de l'instance EC2 (pas d'Elastic IP sur ce labo).

set -euo pipefail

PROFILE="jenkins-lab"
REGION="eu-west-3"
AGENT_SG_ID="sg-09af4db2d3ef9daaf"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <NOUVELLE_IP>" >&2
  exit 1
fi

NEW_IP="$1"

if ! [[ "$NEW_IP" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
  echo "IP invalide : ${NEW_IP}" >&2
  exit 1
fi

OLD_IP=$(grep -oE "ansible_host=[0-9.]+" TP_7/inventory/hosts.ini | cut -d= -f2)

sed -i -E "s/^CONTROLLER_IP=\"[0-9.]+\"/CONTROLLER_IP=\"${NEW_IP}\"/" TP_4/deploy-jenkins-agent-ec2.sh
sed -i -E "s/ansible_host=[0-9.]+/ansible_host=${NEW_IP}/" TP_5/inventory.ini
sed -i -E "s/ansible_host=[0-9.]+/ansible_host=${NEW_IP}/" TP_7/inventory/hosts.ini
sed -i -E "s/CONTROLLER_IP = '[0-9.]+'/CONTROLLER_IP = '${NEW_IP}'/" TP_7/projet-groupe/jobs/Jenkinsfile-provision
sed -i -E "s/\`al-jenkins-tp\` \([0-9.]+\)/\`al-jenkins-tp\` (${NEW_IP})/" README.md

echo "==> IP mise à jour vers ${NEW_IP} dans :"
echo "    - TP_4/deploy-jenkins-agent-ec2.sh"
echo "    - TP_5/inventory.ini"
echo "    - TP_7/inventory/hosts.ini"
echo "    - TP_7/projet-groupe/jobs/Jenkinsfile-provision"
echo "    - README.md"

AWS="aws --profile ${PROFILE} --region ${REGION}"

if [[ -n "$OLD_IP" && "$OLD_IP" != "$NEW_IP" ]]; then
  echo "==> Retrait de la règle SSH pour l'ancienne IP (${OLD_IP}) sur ${AGENT_SG_ID}"
  $AWS ec2 revoke-security-group-ingress \
    --group-id "${AGENT_SG_ID}" --protocol tcp --port 22 --cidr "${OLD_IP}/32" \
    || echo "    (règle absente, rien à retirer)"
fi

echo "==> Ajout de la règle SSH pour la nouvelle IP (${NEW_IP}) sur ${AGENT_SG_ID}"
$AWS ec2 authorize-security-group-ingress \
  --group-id "${AGENT_SG_ID}" --protocol tcp --port 22 --cidr "${NEW_IP}/32" \
  || echo "    (règle déjà présente)"

APP_SG_ID=$($AWS ec2 describe-security-groups \
  --filters "Name=group-name,Values=al-glpi-app-sg" \
  --query "SecurityGroups[0].GroupId" --output text 2>/dev/null || echo "None")

if [[ "$APP_SG_ID" != "None" && -n "$APP_SG_ID" ]]; then
  echo "==> Mise à jour de la règle SSH (contrôleur) sur le SG de l'app GLPI (${APP_SG_ID})"
  if [[ -n "$OLD_IP" && "$OLD_IP" != "$NEW_IP" ]]; then
    $AWS ec2 revoke-security-group-ingress \
      --group-id "${APP_SG_ID}" --protocol tcp --port 22 --cidr "${OLD_IP}/32" \
      || echo "    (règle absente, rien à retirer)"
  fi
  $AWS ec2 authorize-security-group-ingress \
    --group-id "${APP_SG_ID}" --protocol tcp --port 22 --cidr "${NEW_IP}/32" \
    || echo "    (règle déjà présente)"
fi

echo ""
echo "==> Commit et push des fichiers mis à jour (nécessaire : les jobs Jenkins lisent le repo via checkout SCM)"
git add TP_4/deploy-jenkins-agent-ec2.sh TP_5/inventory.ini TP_7/inventory/hosts.ini TP_7/projet-groupe/jobs/Jenkinsfile-provision README.md
if git diff --cached --quiet; then
  echo "    (rien à committer, fichiers déjà à jour)"
else
  git commit -m "Mise à jour IP web_lab (${OLD_IP} -> ${NEW_IP})"
  git push origin main
fi

echo ""
echo "==> Terminé : fichiers + Security Group de l'agent (${AGENT_SG_ID}) à jour, poussé sur GitHub."
