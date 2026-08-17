# 🚀 Pipeline Jenkins — TP Amazon AWS : CI/CD et automatisation avec Ansible et Jenkins

<p align="center">

![Jenkins](https://img.shields.io/badge/Jenkins-CI%2FCD-D24939?style=for-the-badge&logo=jenkins&logoColor=white)
![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=for-the-badge&logo=ansible&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazonwebservices&logoColor=white)
![Git](https://img.shields.io/badge/Git-F05032?style=for-the-badge&logo=git&logoColor=white)

</p>

📘 Dépôt du cahier de travaux pratiques **Amazon AWS — CI/CD et automatisation avec Ansible et Jenkins**
(Mastère Cybersécurité, 4ème année). Chaque dossier `TP_n/` correspond à un TP du cahier et contient son
code, sa fiche de configuration (preuves d'exécution + captures) et, pour le TP7, un rapport de synthèse.

## 🖥️ Infrastructure du labo

| Rôle | Instance | Détails |
|---|---|---|
| 🎛️ Contrôleur Jenkins | `al-jenkins-tp` (13.36.171.149) | Provisionné au TP1, sert aussi de cible Ansible `web_lab` (TP5/TP7) |
| 🤖 Agent Jenkins | `al-jenkins-agent-tp4` (label `aws-lab`) | Provisionné au TP4 — Git, Java, AWS CLI, Python, Ansible |

☁️ Les deux tournent sur le compte AWS de labo partagé (type Academy), région `eu-west-3`.

## 📋 Sommaire des TP

| TP | Contenu | Fiche |
|---|---|---|
| 1️⃣ [TP1](TP_1/) | Déploiement du serveur Jenkins sur EC2 (script + user-data) | [fiche-configuration-TP1.md](TP_1/fiche-configuration-TP1.md) |
| 2️⃣ [TP2](TP_2/) | Connexion Jenkins ↔ AWS, credential dédié, job `aws-identity-check` | [fiche-configuration-TP2.md](TP_2/fiche-configuration-TP2.md) |
| 3️⃣ [TP3](TP_3/) | Jenkinsfile déclaratif paramétré (job de base → paramétré → 4 stages) | [fiche-configuration-TP3.md](TP_3/fiche-configuration-TP3.md) |
| 4️⃣ [TP4](TP_4/) | Agent Jenkins dédié (`aws-lab`), job amont/aval | [fiche-configuration-TP4.md](TP_4/fiche-configuration-TP4.md) |
| 5️⃣ [TP5](TP_5/) | Playbook Ansible idempotent, lint + check/diff + approbation manuelle | [fiche-configuration-TP5.md](TP_5/fiche-configuration-TP5.md) |
| 6️⃣ [TP6](TP_6/) | AWS CLI et gestion réseau (Security Group taggé, règle restreinte) | [fiche-configuration-TP6.md](TP_6/fiche-configuration-TP6.md) |
| 7️⃣ [TP7](TP_7/) | Projet global : catalogue de 3 jobs (inventaire/déploiement/nettoyage) | [rapport-TP7.md](TP_7/docs/rapport-TP7.md) |

## 🔐 Principes appliqués sur l'ensemble du dépôt

- 🚫 **Aucun secret commité** : clés SSH (`*.pem`, clés dédiées) systématiquement exclues via `.gitignore`,
  credentials AWS/SSH stockés uniquement dans le Credentials Manager Jenkins.
- 👤 **Comptes dédiés par usage** : `jenkins-agent` (agent, TP4), `automation` (Ansible → `web_lab`, TP5/TP7) —
  jamais le compte admin `ubuntu`.
- 📜 **Traçabilité** : chaque job Jenkins archive ses sorties (logs, JSON, résultats Ansible) comme artefacts.
- ⚠️ **Limitation connue** : le compte AWS de labo interdit la gestion IAM en self-service — documenté et
  traité au TP2, repris au TP7 (mesure compensatoire : séparation des responsabilités au niveau Jenkins).

## 🧹 Nettoyage

Les ressources AWS éphémères créées pendant les TP (Security Groups de test notamment) sont supprimées
en fin de chaque pipeline concerné. Seules les deux instances EC2 listées ci-dessus restent actives, pour
la durée du cours.
