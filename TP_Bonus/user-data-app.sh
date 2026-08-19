#!/bin/bash
# user-data-app.sh
# Initialise la nouvelle instance EC2 (app GLPI) : crée l'utilisateur "automation"
# avec la même clé publique que web_lab (TP5), pour que le credential Jenkins
# ssh-ansible-web-lab existant fonctionne aussi sur cette machine.

set -euo pipefail

useradd -m -s /bin/bash automation
mkdir -p /home/automation/.ssh
cat > /home/automation/.ssh/authorized_keys <<'EOF'
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFAjtVHk2im8z5CT0UcODnDQOQsiYwizt7DBrLUAYgVC ansible-control-to-web_lab-tp5
EOF
chmod 700 /home/automation/.ssh
chmod 600 /home/automation/.ssh/authorized_keys
chown -R automation:automation /home/automation/.ssh

echo "automation ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/automation
chmod 440 /etc/sudoers.d/automation
