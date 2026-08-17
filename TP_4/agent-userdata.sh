#!/usr/bin/env bash
#
# agent-userdata.sh
# Exécuté par cloud-init au premier démarrage de l'agent Jenkins EC2.
# Installer les dépendances (Java, Git, AWS CLI v2, Python, Ansible) et crée
# un compte d'exécution dédié "jenkins-agent" pour la connexion SSH depuis le contrôleur.

set -euxo pipefail

apt-get update -y

# 1. Dépendances de base
apt-get install -y openjdk-21-jre-headless git python3 python3-pip ansible unzip curl

# 2. AWS CLI v2
cd /tmp
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
unzip -q -o awscliv2.zip
./aws/install

# 3. Compte d'exécution dédié pour l'agent Jenkins (pas "ubuntu")
useradd -m -s /bin/bash jenkins-agent
mkdir -p /home/jenkins-agent/.ssh
chmod 700 /home/jenkins-agent/.ssh

# La clé publique du contrôleur est injectée séparément après création (voir deploy script)

mkdir -p /home/jenkins-agent/agent-work
chown -R jenkins-agent:jenkins-agent /home/jenkins-agent

echo "=== Versions installées ==="
java -version
git --version
aws --version
python3 --version
ansible --version

echo "=== Agent prêt ==="
