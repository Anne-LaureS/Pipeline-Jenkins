# 🚀 Pipeline Jenkins — CI/CD & DevSecOps

<p align="center">

![Jenkins](https://img.shields.io/badge/Jenkins-CI%2FCD-D24939?style=for-the-badge&logo=jenkins&logoColor=white)
![Git](https://img.shields.io/badge/Git-F05032?style=for-the-badge&logo=git&logoColor=white)
![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=for-the-badge&logo=ansible&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazonwebservices&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-844FBA?style=for-the-badge&logo=terraform&logoColor=white)
![DevSecOps](https://img.shields.io/badge/DevSecOps-4B0082?style=for-the-badge)

</p>

---

## 📋 Présentation

Ce projet a pour objectif de mettre en place un **pipeline CI/CD automatisé avec Jenkins**, intégré à GitHub et progressivement enrichi de contrôles de sécurité selon une approche **DevSecOps**.

Le pipeline permet d'automatiser les différentes étapes du cycle de développement :

```text
Développeur
     │
     ▼
  GitHub
     │
  Webhook
     │
     ▼
  Jenkins
     │
     ├──► Checkout
     │
     ├──► Build
     │
     ├──► Tests
     │
     ├──► Analyse de qualité
     │
     ├──► Contrôles de sécurité
     │
     ├──► Quality Gate
     │
     └──► Déploiement
````

---

## 🎯 Objectifs

* Automatiser le cycle CI/CD
* Mettre en place un pipeline Jenkins reproductible
* Intégrer GitHub au processus d'intégration continue
* Automatiser les tests
* Intégrer progressivement des contrôles de sécurité
* Détecter les vulnérabilités le plus tôt possible
* Mettre en œuvre une démarche **DevSecOps**
* Sécuriser la gestion des secrets et des credentials
* Assurer la traçabilité des builds et des déploiements

---

## 🛠️ Technologies

| Technologie   | Utilisation                                  |
| ------------- | -------------------------------------------- |
| **Jenkins**   | Orchestration du pipeline CI/CD              |
| **GitHub**    | Gestion du code source                       |
| **Git**       | Gestion de versions                          |
| **AWS**       | Infrastructure et services Cloud             |
| **Terraform** | Infrastructure as Code                       |
| **Ansible**   | Automatisation, configuration et déploiement |
| **Docker**    | Conteneurisation                             |
| **SonarQube** | Analyse de qualité et de sécurité du code    |
| **Trivy**     | Analyse des vulnérabilités                   |
| **OWASP**     | Contrôles de sécurité applicative            |

> Les outils seront intégrés progressivement au fur et à mesure de l'évolution du pipeline.

---

## 🏗️ Architecture

```text
                         ┌───────────────┐
                         │  Développeur  │
                         └───────┬───────┘
                                 │
                              Git Push
                                 │
                                 ▼
                         ┌───────────────┐
                         │    GitHub     │
                         └───────┬───────┘
                                 │
                              Webhook
                                 │
                                 ▼
                         ┌───────────────┐
                         │    Jenkins    │
                         └───────┬───────┘
                                 │
              ┌──────────────────┼──────────────────┐
              │                  │                  │
              ▼                  ▼                  ▼
           Build &            Security          Quality
            Tests              Scans              Gate
              │                  │                  │
              └──────────────────┼──────────────────┘
                                 │
                                 ▼
                         ┌───────────────┐
                         │   Terraform   │
                         │      IaC      │
                         └───────┬───────┘
                                 │
                         Provisionnement
                                 │
                                 ▼
                    ┌────────────────────────┐
                    │          AWS           │
                    │                        │
                    │  Infrastructure Cloud  │
                    └───────────┬────────────┘
                                │
                                ▼
                         ┌───────────────┐
                         │    Ansible    │
                         │               │
                         │ Configuration │
                         │   Hardening   │
                         └───────┬───────┘
                                 │
                                 ▼
                         ┌───────────────┐
                         │  Application  │
                         └───────────────┘
```

---

## 🔄 Pipeline CI/CD

### 1. 📥 Checkout

Récupération du code source depuis le repository GitHub.

### 2. 🔨 Build

Compilation et/ou construction de l'application et de ses dépendances.

### 3. 🧪 Tests

Exécution automatique des tests :

* Tests unitaires
* Tests d'intégration
* Tests fonctionnels selon les besoins

### 4. 🔍 Analyse de qualité

Analyse automatique du code afin d'identifier :

* Bugs
* Code smells
* Vulnérabilités
* Problèmes de qualité

### 5. 🛡️ Sécurité

Intégration progressive de contrôles de sécurité :

* SAST
* SCA
* Scan des secrets
* Scan des dépendances
* Scan des images Docker
* Scan de l'Infrastructure as Code

### 6. 🚦 Quality Gate

Le pipeline vérifie que les seuils de qualité et de sécurité définis sont respectés.

```text
             Quality Gate
                  │
          ┌───────┴───────┐
          │               │
        PASS             FAIL
          │               │
          ▼               ▼
     Déploiement      Arrêt du pipeline
```

### 7. 🚀 Déploiement

Lorsque l'ensemble des contrôles est validé, le déploiement peut être déclenché automatiquement vers l'environnement cible.

---

## 🔐 DevSecOps

La sécurité est intégrée directement dans le pipeline afin de détecter les problèmes le plus tôt possible.

```text
                    DEVSECOPS
                        │
       ┌────────────────┼────────────────┐
       │                │                │
       ▼                ▼                ▼
     CODE             BUILD          DEPLOY
       │                │                │
       ▼                ▼                ▼
     SAST          Scan Image        IaC Scan
       │                │                │
       └────────────────┼────────────────┘
                        │
                        ▼
                 Security Gate
                        │
                 ┌──────┴──────┐
                 ▼             ▼
               PASS           FAIL
                 │             │
                 ▼             ▼
             Déploiement      STOP
```

---

## 📂 Structure du repository

```text
.
├── Jenkinsfile
├── README.md
├── src/
├── tests/
├── docker/
├── terraform/
├── ansible/
│   ├── inventory/
│   ├── playbooks/
│   ├── roles/
│   └── group_vars/
└── scripts/
```

La structure pourra évoluer en fonction des besoins du projet.

---

## 🔑 Gestion des credentials

Les informations sensibles ne doivent **jamais être stockées directement dans le code du pipeline**.

Les credentials seront gérés via le gestionnaire de credentials de Jenkins.

Exemples :

```text
GitHub Token
Docker Registry
Clés SSH
Cloud Credentials
API Tokens
SonarQube Token
```

L'objectif est de garantir :

* La confidentialité des secrets
* La séparation des responsabilités
* La traçabilité
* La réduction du risque d'exposition

---

## 🔗 Intégration GitHub / Jenkins

Le repository GitHub sera connecté à Jenkins à l'aide d'un **Webhook**.

```text
        Git Push
           │
           ▼
       ┌────────┐
       │ GitHub │
       └────┬───┘
            │
         Webhook
            │
            ▼
       ┌─────────┐
       │ Jenkins │
       └────┬────┘
            │
            ▼
        Pipeline
```

Chaque modification poussée sur la branche configurée pourra ainsi déclencher automatiquement le pipeline.

---

## 📊 États du pipeline

| Étape                | État                |
| -------------------- | ------------------- |
| Checkout             | 🟡 En développement |
| Build                | 🟡 En développement |
| Tests                | 🟡 En développement |
| Analyse de code      | 🟡 En développement |
| SAST                 | 🟡 En développement |
| Scan des dépendances | 🟡 En développement |
| Scan des conteneurs  | 🟡 En développement |
| Quality Gate         | 🟡 En développement |
| Déploiement          | 🟡 En développement |

---

## 🗺️ Roadmap

* [ ] Création du Jenkinsfile
* [ ] Connexion GitHub → Jenkins
* [ ] Configuration du Webhook
* [ ] Checkout automatique
* [ ] Build automatique
* [ ] Tests automatisés
* [ ] Intégration SonarQube
* [ ] SAST
* [ ] SCA
* [ ] Détection des secrets
* [ ] Scan Trivy
* [ ] Build Docker
* [ ] Scan de l'image Docker
* [ ] Validation Terraform
* [ ] Scan de sécurité IaC
* [ ] Intégration Ansible
* [ ] Création des playbooks Ansible
* [ ] Gestion de la configuration
* [ ] Automatisation du déploiement
* [ ] Quality Gate
* [ ] Déploiement automatisé
* [ ] Notifications
* [ ] Monitoring du pipeline

---

## 📚 Documentation

La documentation du projet sera enrichie progressivement avec :

* Architecture du pipeline
* Configuration Jenkins
* Configuration GitHub
* Gestion des credentials
* Contrôles de sécurité
* Procédure de déploiement
* Gestion des erreurs
* Troubleshooting
* Résultats des scans
* Évolutions et améliorations

---

## 📌 Statut du projet

![Statut](https://img.shields.io/badge/Projet-En%20développement-orange?style=for-the-badge)

Le pipeline est actuellement en phase de construction et sera enrichi progressivement avec les différentes étapes CI/CD et les contrôles de sécurité.

---

<p align="center">

**Jenkins • GitHub • AWS • Terraform • Ansible • Docker • DevSecOps**

</p>
```
