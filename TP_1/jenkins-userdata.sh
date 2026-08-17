#!/usr/bin/env bash
#
# jenkins-userdata.sh
# Exécuté automatiquement par cloud-init au premier démarrage de l'instance EC2.
# Installer Java 21 et Jenkins (dépôt LTS officiel) sur Ubuntu 24.04.
# Logs visibles ensuite avec : sudo cat /var/log/cloud-init-output.log
 
set -euxo pipefail
 
# 1. Mise à jour du système
apt-get update -y
apt-get upgrade -y
 
# 2. Vérification hostname / version / DNS (traçabilité, cf. étape 1 du TP)
hostnamectl
lsb_release -a || cat /etc/os-release
resolvectl status || true
 
# 3. Installation de Java 21 (requis par Jenkins pour les installs Linux récentes)
apt-get install -y fontconfig openjdk-21-jre
 
# 4. Ajout du dépôt Jenkins LTS officiel
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key \
  | tee /etc/apt/keyrings/jenkins-keyring.asc > /dev/null
 
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
  "https://pkg.jenkins.io/debian-stable binary/" \
  | tee /etc/apt/sources.list.d/jenkins.list > /dev/null
 
apt-get update -y
 
# 5. Installation de Jenkins
apt-get install -y jenkins
 
# 6. Activation et démarrage du service
systemctl enable --now jenkins
 
# 7. Petite pause + vérification du statut dans les logs cloud-init
sleep 15
systemctl status jenkins --no-pager || true
 
echo "=== Jenkins install terminée ==="
echo "Mot de passe initial admin :"
cat /var/lib/jenkins/secrets/initialAdminPassword || echo "(pas encore généré, patienter quelques secondes)"
 