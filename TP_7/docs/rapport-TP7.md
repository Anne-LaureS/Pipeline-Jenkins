# Rapport de mise en œuvre — TP7 : Projet global Jenkins et Ansible

## 🏗️ 1. Architecture

```
Développeur (Anne-Laure)
        │
        ▼
   GitHub (Pipeline-Jenkins)
        │
        ▼
Jenkins (contrôleur, TP1) ── job Jenkins ──► Agent aws-lab (TP4)
        │                                          │
        │                                          ├─ AWS CLI (jenkins-lab-al)
        │                                          └─ Ansible (clé automation)
        ▼                                          │
  3 jobs du catalogue :                             ▼
  - tp7-inventaire      (lecture seule)      Cible web_lab (contrôleur TP1,
  - tp7-deploiement      (création + config)  réutilisé — cf. TP5)
  - tp7-nettoyage        (suppression)
```

Le dépôt est structuré comme demandé par le cahier (8.3) :

```
TP_7/
├── jobs/
│   ├── Jenkinsfile-inventaire
│   ├── Jenkinsfile-deploiement
│   └── Jenkinsfile-nettoyage
├── playbooks/
│   └── site.yml
├── inventory/
│   └── hosts.ini
└── docs/
    └── rapport-TP7.md
```

## 📚 2. Le catalogue de jobs

| Job | Rôle | Paramètres | Ressources touchées |
|---|---|---|---|
| `tp7-inventaire` | Liste les ressources AWS (identité, instances EC2, Security Groups du cours) | aucun | Lecture seule |
| `tp7-deploiement` | Lint + `--check --diff` + approbation conditionnelle + création d'un Security Group taggé + configuration Ansible réelle + enregistrement d'un artefact de rollback | `ENVIRONMENT`, `CHANGE_REFERENCE` | Crée 1 Security Group, applique le playbook sur `web_lab` |
| `tp7-nettoyage` | Supprime une ressource créée par `tp7-deploiement`, à partir de son ID | `SG_ID`, `CHANGE_REFERENCE` | Supprime 1 Security Group |

## 🔐 3. Sécurité

- **Rôles IAM dédiés par fonction — limitation rencontrée et traitement** : le compte AWS de labo (fourni
  par le formateur, pas AWS Academy) interdit toute gestion IAM en self-service (`iam:CreateUser`, `iam:CreateRole` refusés —
  incident déjà rencontré et documenté au TP2). Il n'a donc pas été possible de créer une identité AWS
  distincte par job. **Mesure compensatoire** : séparation de la responsabilité au niveau Jenkins plutôt
  qu'IAM — chaque job ne demande que le credential dont il a besoin (`aws-jenkins-lab` pour les appels AWS
  CLI, `ssh-ansible-web-lab` pour Ansible), aucun job ne mélange les deux inutilement, et les permissions
  réelles de `jenkins-lab-al` ont été vérifiées avant usage (lecture seule + gestion de Security Groups,
  pas de droits IAM).
- **Secrets** : aucune clé ni credential en clair dans le code ou les logs (masquage Jenkins vérifié sur
  chaque job, `withCredentials` systématique).
- **Réseau** : toute règle entrante créée est restreinte à une IP `/32` précise, jamais `0.0.0.0/0`
  (repris de la logique validée au TP6).
- **Tags obligatoires** appliqués à chaque ressource créée : `Owner`, `Course`, `Environment`,
  `ExpiryDate`, `ChangeReference`.
- **Constat de sécurité additionnel** : `tp7-inventaire` révèle que le compte de labo est partagé par
  toute la classe et que `jenkins-lab-al` peut lister les instances EC2 de tous les autres étudiants
  (`ec2:DescribeInstances` non scoping par tag/owner). C'est une limite de la plateforme de labo, pas de
  notre configuration, mais à signaler : dans un contexte réel, une politique IAM scoperait les
  `Describe*` par tag `Owner`.

## ⚙️ 4. Automatisation

- **Playbook idempotent** (`playbooks/site.yml`) : validé par double exécution réelle consécutive
  (`changed=1` puis `changed=0`, cf. TP5) et testé en mode `--check --diff` avant toute exécution réelle
  dans `tp7-deploiement`.
- **Contrôles intégrés** : `ansible-lint` (0 échec), validation des paramètres obligatoires
  (`CHANGE_REFERENCE`), approbation manuelle conditionnelle (`ENVIRONMENT != dev`), validation de format
  sur `SG_ID` dans le job de nettoyage (regex `sg-[0-9a-f]+`).
- **Logs et archivage** : chaque job archive ses sorties en artefacts Jenkins (lint, check/diff, apply,
  inventaires JSON, preuve avant suppression).
- **Stratégie de retour arrière (rollback)** : `tp7-deploiement` enregistre systématiquement un artefact
  `deployed-resources.json` contenant l'ID de la ressource créée et la commande de suppression exacte à
  utiliser. `tp7-nettoyage` consomme cet ID en paramètre — l'opérateur retrouve la commande de rollback
  directement dans l'historique des builds, sans avoir à deviner quoi que ce soit.

## ✅ 5. Preuves d'exécution (résumé)

| Test | Résultat |
|---|---|
| `tp7-inventaire` | SUCCESS — identité, 19 instances EC2 recensées, 0 SG taggé Course (nettoyage précédent effectif) |
| `tp7-deploiement` (paramètres invalides) | FAILURE attendue — `CHANGE_REFERENCE` obligatoire |
| `tp7-deploiement` (`dev`) | SUCCESS — pas d'approbation requise, SG créé+taggé, playbook appliqué |
| `tp7-deploiement` (`prod`) | SUCCESS — approbation manuelle déclenchée et validée avant action réelle |
| `tp7-nettoyage` (`SG_ID` invalide) | FAILURE attendue — garde-fou de format |
| `tp7-nettoyage` (ID valide, x2) | SUCCESS — ressources supprimées, aucune ressource orpheline restante |

**Incident rencontré et corrigé** : la première exécution de `tp7-deploiement` a échoué sur les étapes
Ansible (`playbook not found`) — chemins relatifs erronés dans le Jenkinsfile (oubli du préfixe `TP_7/`
après le checkout SCM du dépôt complet). Corrigé en un commit, ressource orpheline nettoyée manuellement,
puis build rejoué avec succès.

## ✨ 6. Qualité

- Nommage cohérent avec les TP précédents (`tp7-*`, mêmes conventions de tags, mêmes credentials réutilisés).
- Un Jenkinsfile par job (lisibilité), plutôt qu'un unique pipeline monolithique.
- Playbook et inventaire versionnés et réutilisables indépendamment des jobs.