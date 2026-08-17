# Fiche de configuration — TP2 : Connecter Jenkins à AWS

## Contexte / incident rencontré

Le compte AWS du laboratoire est un compte restreint (type AWS Academy) : l'utilisateur `jenkins-lab-al`
n'a **aucun droit IAM en self-service** (`iam:CreateUser`, `iam:GetUser`, etc. tous refusés — `AccessDenied`).
Il n'a pas été possible de créer un nouvel utilisateur IAM dédié et strictement scopé pour Jenkins.

**Décision** : réutilisation du profil `jenkins-lab-al` existant (déjà scopé par la plateforme du labo)
pour le job Jenkins, ses permissions réelles ayant été vérifiées avant usage (voir ci-dessous).

## Permissions vérifiées pour `jenkins-lab-al`

| Action | Résultat |
|---|---|
| `sts:GetCallerIdentity` | ✅ Autorisé |
| `ec2:DescribeInstances` | ✅ Autorisé |
| `s3:ListAllMyBuckets` | ❌ Refusé (`AccessDenied`) |
| `iam:GetUser` / `iam:CreateUser` | ❌ Refusé (`AccessDenied`) |

→ Le second contrôle du job utilise donc `ec2 describe-instances` (S3 non accessible avec ces droits),
conformément à la consigne du cahier ("selon les droits accordés").

## Credential Jenkins

| Élément | Valeur |
|---|---|
| Type | Username with password (plugin `credentials`) |
| ID | `aws-jenkins-lab` |
| Username | Access Key ID de `jenkins-lab-al` |
| Password | Secret Access Key de `jenkins-lab-al` |
| Portée | Global |
| Stocké en clair dans un fichier/Jenkinsfile ? | Non — uniquement dans le Credentials Manager Jenkins |

## Job créé

| Élément | Valeur |
|---|---|
| Nom | `aws-identity-check` |
| Type | Pipeline (déclaratif) |
| Credential utilisé | `aws-jenkins-lab` via `withCredentials` |
| Commandes exécutées | `aws sts get-caller-identity`, `aws ec2 describe-instances --output table` |

## Résultat du build #1

```
=== Date du build : Mon Aug 17 11:13:00 UTC 2026 ===
=== Identite AWS utilisee ===
{
    "UserId": "AIDAZBZP7DWOPMPR4TG3J",
    "Account": "622333992348",
    "Arn": "arn:aws:iam::622333992348:user/jenkins-lab-al"
}
=== Inventaire EC2 (lecture seule) ===
-------------------------
|   DescribeInstances   |
+-----------------------+
|  i-00ac063e3d22bdbc0  |
|  ... (9 instances)    |
+-----------------------+
Build 1 termine avec le statut : SUCCESS
```

## Critères de réussite (section 3.3 du cahier)

- [x] La sortie révèle une identité AWS dédiée au laboratoire (`jenkins-lab-al`, pas de credentials personnels).
- [x] Les commandes non autorisées sont refusées par IAM (`s3:ListAllMyBuckets` → `AccessDenied`, vérifié en amont).
- [x] Aucune clé d'accès en clair n'apparaît dans la console Jenkins (`Masking supported pattern matches of $AWS_SECRET_ACCESS_KEY` dans les logs).
- [x] Le build conserve une trace lisible de la date, du job et du résultat (voir sortie ci-dessus).

## Livrables restants à joindre manuellement

- [ ] Capture d'écran du job `aws-identity-check` dans Jenkins (page du build #1, statut SUCCESS)
- [ ] Capture d'écran de la page Credentials (`Manage Jenkins > Credentials`) montrant `aws-jenkins-lab` sans révéler le secret
