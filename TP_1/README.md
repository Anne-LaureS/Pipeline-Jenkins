# 🚀 TP 1 — Déployer un serveur Jenkins sur AWS via VS Code

<p align="center">

![AWS](https://img.shields.io/badge/AWS-EC2-232F3E?style=for-the-badge&logo=amazonwebservices&logoColor=white)
![Jenkins](https://img.shields.io/badge/Jenkins-CI%2FCD-D24939?style=for-the-badge&logo=jenkins&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![Java](https://img.shields.io/badge/Java-21-ED8B00?style=for-the-badge&logo=openjdk&logoColor=white)
![AWS CLI](https://img.shields.io/badge/AWS%20CLI-v2-232F3E?style=for-the-badge&logo=amazonwebservices&logoColor=white)
![VS Code](https://img.shields.io/badge/VS%20Code-Development-007ACC?style=for-the-badge&logo=visualstudiocode&logoColor=white)

</p>

---

## 📋 Présentation

Ce TP a pour objectif de **déployer automatiquement un serveur Jenkins sur une instance Amazon EC2**, en utilisant **AWS CLI**, **VS Code**, **Bash** et un script d'initialisation `cloud-init`.

L'ensemble du provisioning est automatisé afin de reproduire de manière fiable le déploiement d'un environnement Jenkins sur AWS.

### 🎯 Objectifs du TP

- Déployer une instance **EC2** sur AWS
- Automatiser le provisioning avec un script Bash
- Installer automatiquement **Jenkins**
- Installer **Java 21**
- Configurer un **Security Group** restrictif
- Générer et utiliser une clé SSH
- Utiliser `cloud-init` pour automatiser l'installation au premier démarrage
- Administrer l'instance via SSH
- Vérifier le bon fonctionnement du service Jenkins
- Accéder à Jenkins via son interface Web
- Nettoyer les ressources AWS après le TP

---

## 🏗️ Architecture

```text
                         ┌──────────────────┐
                         │    Poste local   │
                         │                  │
                         │      VS Code     │
                         │     AWS CLI v2   │
                         └────────┬─────────┘
                                  │
                                  │ AWS CLI
                                  ▼
                         ┌──────────────────┐
                         │       AWS        │
                         │                  │
                         │    eu-west-3     │
                         └────────┬─────────┘
                                  │
                                  ▼
                         ┌──────────────────┐
                         │      EC2         │
                         │                  │
                         │  Ubuntu 24.04    │
                         │                  │
                         │  Java 21         │
                         │  Jenkins         │
                         └────────┬─────────┘
                                  │
                    ┌─────────────┴─────────────┐
                    │                           │
                 SSH : 22                  Jenkins : 8080
                    │                           │
                    ▼                           ▼
              Administration              Interface Web
````

---

## 🛠️ Technologies utilisées

| Technologie          | Utilisation                              |
| -------------------- | ---------------------------------------- |
| **AWS EC2**          | Hébergement du serveur Jenkins           |
| **AWS CLI v2**       | Administration et provisioning AWS       |
| **Ubuntu 24.04 LTS** | Système d'exploitation de l'instance     |
| **Jenkins**          | Serveur d'intégration continue           |
| **Java 21**          | Environnement d'exécution de Jenkins     |
| **Bash**             | Automatisation du provisioning           |
| **cloud-init**       | Initialisation automatique de l'instance |
| **SSH**              | Administration distante                  |
| **VS Code**          | Environnement de développement           |

---

## 📂 Structure du repository

```text
.
├── deploy-jenkins-ec2.sh
├── jenkins-userdata.sh
└── README.md
```

### 📄 Description des fichiers

| Fichier                 | Rôle                                         |
| ----------------------- | -------------------------------------------- |
| `deploy-jenkins-ec2.sh` | Script principal de provisioning AWS         |
| `jenkins-userdata.sh`   | Script d'installation automatique de Jenkins |
| `README.md`             | Documentation du TP                          |

---

## ⚙️ Prérequis

### 💻 Environnement local

AWS CLI v2 doit être installé sur la machine locale.

### macOS

```bash
brew install awscli
```

### Windows

Installer **AWS CLI v2** à l'aide de l'installeur MSI officiel.

### Linux

Consulter la documentation officielle AWS :

[https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

### 🔎 Vérification

```bash
aws --version
```

---

## 🔐 Configuration des credentials AWS

Les credentials IAM utilisés pour le TP doivent être configurés dans un **profil AWS dédié**.

```bash
aws configure --profile jenkins-lab
```

Renseigner :

```text
AWS Access Key ID: <ACCESS_KEY_ID>
AWS Secret Access Key: <SECRET_ACCESS_KEY>
Default region name: eu-west-3
Default output format: json
```

### ⚠️ Sécurité

Les credentials doivent rester **uniquement sur la machine locale**.

Ils sont stockés dans :

```text
~/.aws/credentials
```

Ils ne doivent **jamais** être :

* Commités dans Git
* Ajoutés au repository
* Partagés
* Intégrés directement dans un script
* Publiés sur GitHub

> En cas de compromission d'une clé d'accès, celle-ci doit être immédiatement révoquée.

---

## 📁 Ouverture du projet dans VS Code

Ouvrir le dossier contenant les trois fichiers :

```text
deploy-jenkins-ec2.sh
jenkins-userdata.sh
README.md
```

Depuis le terminal intégré de VS Code :

```bash
cd <CHEMIN_DU_PROJET>
```

---

## 🚀 Déploiement

Rendre le script exécutable :

```bash
chmod +x deploy-jenkins-ec2.sh
```

Puis lancer le provisioning :

```bash
./deploy-jenkins-ec2.sh
```

---

## 🔄 Fonctionnement du script

Le script `deploy-jenkins-ec2.sh` automatise les opérations suivantes :

### 1. 🔐 Vérification des credentials AWS

Le script vérifie que le profil AWS utilisé est correctement configuré.

### 2. 🌐 Détection de l'adresse IP publique

L'adresse IP publique de la machine locale est récupérée afin de limiter les accès réseau à cette adresse.

### 3. 🖥️ Récupération de l'AMI

Le script récupère automatiquement la dernière **AMI officielle Ubuntu 24.04 LTS** compatible avec le déploiement.

### 4. 🔑 Création de la paire de clés SSH

Une paire de clés est créée :

```text
al-jenkins-key.pem
```

La clé privée doit être conservée de manière sécurisée et ses permissions doivent être limitées :

```bash
chmod 400 al-jenkins-key.pem
```

### 5. 🛡️ Création du Security Group

Le Security Group :

```text
al-jenkins-sg
```

autorise uniquement :

| Port   | Service | Source             |
| ------ | ------- | ------------------ |
| `22`   | SSH     | IP publique locale |
| `8080` | Jenkins | IP publique locale |

L'objectif est de limiter l'exposition réseau de l'instance.

### 6. ☁️ Création de l'instance EC2

Une instance EC2 est créée avec le nom :

```text
al-jenkins-tp
```

Le script `jenkins-userdata.sh` est transmis en **User Data** afin d'automatiser l'installation au premier démarrage.

### 7. ⚙️ Installation automatique

Lors du premier démarrage, `cloud-init` exécute le script d'installation et configure :

```text
Ubuntu 24.04 LTS
      │
      ├── Java 21
      │
      └── Jenkins
```

### 8. 📡 Affichage de l'adresse IP

À la fin du provisioning, l'adresse IP publique de l'instance EC2 est affichée.

---

## 🔎 Vérifications

Après le lancement de l'instance, patienter environ **2 à 3 minutes** afin de laisser `cloud-init` terminer l'installation.

### 🔑 Connexion SSH

```bash
ssh -i al-jenkins-key.pem ubuntu@<IP_PUBLIQUE>
```

---

### 🟢 Vérification du service Jenkins

Une fois connecté à l'instance :

```bash
sudo systemctl status jenkins --no-pager
```

Le service doit apparaître comme :

```text
Active: active (running)
```

---

### 📜 Consultation des logs Jenkins

```bash
sudo journalctl -u jenkins --since "10 minutes ago" --no-pager
```

---

### 🔑 Récupération du mot de passe initial Jenkins

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Conserver temporairement ce mot de passe afin de terminer la configuration initiale.

---

### ☁️ Vérification de cloud-init

Si l'installation n'est pas encore terminée :

```bash
sudo cat /var/log/cloud-init-output.log
```

Ce fichier permet de suivre les différentes étapes exécutées lors de l'initialisation de l'instance.

---

## 🌐 Accès à Jenkins

Une fois Jenkins installé et démarré, ouvrir :

```text
http://<IP_PUBLIQUE>:8080
```

Utiliser le mot de passe récupéré avec :

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Puis :

1. Déverrouiller Jenkins
2. Installer les plugins suggérés
3. Créer un compte administrateur nominatif
4. Finaliser le **Setup Wizard**

### 🔐 Bonne pratique

Ne pas utiliser de compte administrateur générique ou partagé.

Chaque administrateur doit disposer de son propre compte nominatif afin de garantir :

* La traçabilité
* L'imputabilité
* La gestion des droits
* L'audit des actions

---

## 📸 Livrables

Les éléments suivants doivent être préparés :

### 1. 🟢 État du service Jenkins

Capture d'écran de :

```bash
sudo systemctl status jenkins
```

### 2. 🖥️ Interface Jenkins

Capture d'écran de l'écran d'accueil Jenkins après le **Setup Wizard**.

### 3. 📄 Fiche de configuration

La fiche doit notamment contenir :

```text
URL :
http://<IP_PUBLIQUE>:8080

Administrateur :
<Nom du compte administrateur>

Plugins essentiels :
- Liste des plugins installés
```

---

## 🧹 Nettoyage des ressources AWS

> ## ⚠️ IMPORTANT
>
> Le compte AWS utilisé étant **partagé avec l'ensemble de la classe**, les ressources doivent être supprimées à la fin du TP afin d'éviter une consommation inutile du budget ou des quotas.

### 🛑 Terminer l'instance EC2

```bash
aws --profile jenkins-lab --region eu-west-3 ec2 terminate-instances \
  --instance-ids <INSTANCE_ID>
```

L'`INSTANCE_ID` est affiché à la fin du script `deploy-jenkins-ec2.sh` ou disponible dans la console AWS EC2.

---

### 🗑️ Supprimer le Security Group

Une fois l'instance complètement terminée :

```bash
aws --profile jenkins-lab --region eu-west-3 ec2 delete-security-group \
  --group-name al-jenkins-sg
```

### 🗝️ Supprimer la Key Pair AWS

```bash
aws --profile jenkins-lab --region eu-west-3 ec2 delete-key-pair \
  --key-name al-jenkins-key
```

> ⚠️ Attendre que l'instance soit bien dans l'état **`terminated`** avant de supprimer le Security Group. Celui-ci peut encore être attaché à l'instance pendant sa phase d'arrêt.

---

## 🔐 Bonnes pratiques de sécurité

Ce TP met en œuvre plusieurs principes de sécurité :

* 🔒 Restriction des accès SSH par adresse IP
* 🔒 Restriction de l'accès Jenkins par adresse IP
* 🔑 Utilisation d'un profil AWS dédié
* 🔑 Protection de la clé privée SSH
* 🚫 Absence de credentials dans le code source
* 👤 Utilisation de comptes Jenkins nominatifs
* 🧹 Suppression des ressources AWS après utilisation
* 📋 Traçabilité des opérations d'administration

---

## 📌 Résultat attendu

À l'issue du TP, l'environnement doit permettre d'obtenir :

```text
                    AWS
                     │
                     ▼
              ┌─────────────┐
              │     EC2     │
              │             │
              │ Ubuntu 24.04│
              │             │
              │   Java 21   │
              │             │
              │   Jenkins   │
              └──────┬──────┘
                     │
              ┌──────┴──────┐
              │             │
            SSH :22     Jenkins :8080
              │             │
              ▼             ▼
           Terminal     Interface Web
```

---

## 📊 Statut du TP

![Statut](https://img.shields.io/badge/Statut-Terminé-success?style=for-the-badge)

**TP 1 — Déploiement d'un serveur Jenkins sur AWS**

> Déploiement automatisé d'une instance EC2 Ubuntu 24.04 LTS avec installation de Java 21 et Jenkins via `cloud-init`, sécurisation des accès réseau et validation du fonctionnement du serveur Jenkins.

```
```
