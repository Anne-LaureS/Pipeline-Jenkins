#!/usr/bin/env bash
#
# update-ip.sh <NOUVELLE_IP>
# Met à jour l'IP publique de web01 (contrôleur Jenkins / cible web_lab, réutilisée
# depuis TP1 en TP4/TP5/TP7) dans tous les fichiers concernés, en une seule commande.
# Utile après un stop/start de l'instance EC2 (pas d'Elastic IP sur ce labo).

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <NOUVELLE_IP>" >&2
  exit 1
fi

NEW_IP="$1"

if ! [[ "$NEW_IP" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
  echo "IP invalide : ${NEW_IP}" >&2
  exit 1
fi

sed -i -E "s/^CONTROLLER_IP=\"[0-9.]+\"/CONTROLLER_IP=\"${NEW_IP}\"/" TP_4/deploy-jenkins-agent-ec2.sh
sed -i -E "s/ansible_host=[0-9.]+/ansible_host=${NEW_IP}/" TP_5/inventory.ini
sed -i -E "s/ansible_host=[0-9.]+/ansible_host=${NEW_IP}/" TP_7/inventory/hosts.ini

echo "==> IP mise à jour vers ${NEW_IP} dans :"
echo "    - TP_4/deploy-jenkins-agent-ec2.sh"
echo "    - TP_5/inventory.ini"
echo "    - TP_7/inventory/hosts.ini"
echo ""
echo "⚠️  Pense aussi à mettre à jour manuellement la règle de Security Group de l'agent"
echo "    (SSH entrant depuis l'IP du contrôleur) — cette règle AWS n'est pas gérée par ce script."
