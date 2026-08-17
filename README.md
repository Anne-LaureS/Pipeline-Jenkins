TP 1 — Déployer un serveur Jenkins sur AWS (via VS Code)
1. Prérequis en local (une seule fois)
Installer AWS CLI v2 si pas déjà fait :
macOS : brew install awscli
Windows : installeur MSI officiel
Linux : voir https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
Vérifier : aws --version
Configurer tes credentials IAM (celles de l'utilisateur jenkins-lab-al créé dans la console AWS) :
bash
   aws configure --profile jenkins-lab
Renseigne :

AWS Access Key ID : (celle de ton user IAM — PAS celle qu'on a déjà générée et que tu dois supprimer, régénères-en une nouvelle proprement)
AWS Secret Access Key
Default region name : eu-west-3
Default output format : json
Ces identifiants restent stockés uniquement en local sur ta machine (~/.aws/credentials), jamais partagés.

Ouvrir ce dossier dans VS Code avec les 3 fichiers :
deploy-jenkins-ec2.sh (script principal de provisioning)
jenkins-userdata.sh (script d'installation de Jenkins, exécuté automatiquement sur l'instance)
ce README
2. Lancer le déploiement
Dans le terminal intégré de VS Code :

bash
chmod +x deploy-jenkins-ec2.sh
./deploy-jenkins-ec2.sh
Le script :

vérifie tes credentials AWS ;
détecte ton IP publique pour restreindre les accès réseau ;
récupère automatiquement la dernière AMI Ubuntu 24.04 LTS officielle ;
crée une paire de clés SSH (al-jenkins-key.pem, à garder précieusement, permissions 400) ;
crée un security group al-jenkins-sg ouvrant uniquement le port 22 (SSH) et 8080 (Jenkins) depuis ton IP ;
lance l'instance EC2 al-jenkins-tp avec le script jenkins-userdata.sh en user-data (installation automatique de Java 21 + Jenkins au premier boot) ;
affiche l'IP publique de l'instance à la fin.
3. Vérifications attendues (cf. cahier de TP)
Patiente ~2-3 minutes après le lancement (le temps que cloud-init installe Jenkins), puis connecte-toi en SSH :

bash
ssh -i al-jenkins-key.pem ubuntu@<IP_PUBLIQUE>
Une fois connecté :

bash
sudo systemctl status jenkins --no-pager
sudo journalctl -u jenkins --since "10 minutes ago" --no-pager
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
Si l'install cloud-init n'est pas terminée, tu peux suivre sa progression avec :

bash
sudo cat /var/log/cloud-init-output.log
Puis ouvre dans ton navigateur : http://<IP_PUBLIQUE>:8080

Utilise le mot de passe d'initialisation récupéré ci-dessus.
Installe les plugins suggérés.
Crée un compte administrateur nominatif (pas de compte générique/partagé).
4. Livrables à préparer
Capture d'écran de sudo systemctl status jenkins
Capture d'écran de l'écran d'accueil Jenkins (après setup wizard)
Fiche de configuration (voir modèle séparé) indiquant :
URL : http://<IP_PUBLIQUE>:8080
Nom de l'administrateur créé
Liste des plugins essentiels installés (les "suggested plugins" par défaut)
5. Nettoyage en fin de TP (IMPORTANT — compte AWS partagé avec toute la classe)
Une fois le TP validé, termine l'instance pour ne pas consommer le budget/quota partagé :

bash
aws --profile jenkins-lab --region eu-west-3 ec2 terminate-instances --instance-ids <INSTANCE_ID>
(L'ID de l'instance est affiché à la fin du script deploy-jenkins-ec2.sh, ou visible dans la console EC2.)

Tu peux aussi, si plus besoin :

bash
aws --profile jenkins-lab --region eu-west-3 ec2 delete-security-group --group-name al-jenkins-sg
aws --profile jenkins-lab --region eu-west-3 ec2 delete-key-pair --key-name al-jenkins-key
(attends que l'instance soit bien terminée avant de supprimer le security group, sinon ça échoue car encore attaché.)