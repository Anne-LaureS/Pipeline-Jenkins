# Fiche de configuration — TP5 : Imposer une configuration avec Ansible

## Architecture retenue

| Rôle | Machine |
|---|---|
| Nœud de contrôle Ansible | Agent EC2 du TP4 (`aws-lab-agent`, 35.180.87.8) — déjà équipé d'Ansible |
| Cible `web_lab` | Contrôleur Jenkins du TP1 (13.36.171.149) — réutilisé plutôt que de créer une 3e instance |
| Compte de connexion | `automation` (créé spécifiquement sur le contrôleur, clé SSH dédiée, sudo NOPASSWD) |

## Incident rencontré et diagnostic

Lors du premier test manuel du playbook, l'instance contrôleur (t3.micro, 1 Go de RAM, **sans swap
configuré**) a cessé de répondre (SSH timeout dès l'échange de bannière) pendant qu'une tâche
`ansible apt` était en cours. Diagnostic :

- Les status checks AWS (`SystemStatus`/`InstanceStatus`) restaient `ok` → la VM elle-même n'était pas
  en panne, seul l'OS était en détresse (probable saturation mémoire, aggravée par l'absence de swap qui
  aurait permis une dégradation progressive plutôt qu'un blocage brutal).
- **Correction** : redémarrage de l'instance via `aws ec2 reboot-instances`. Après reboot, Jenkins et SSH
  répondaient de nouveau normalement, aucun processus résiduel.
- **Amélioration possible (non appliquée, hors périmètre du TP)** : ajouter un fichier swap sur les
  instances t3.micro du labo pour éviter ce type de blocage.

## Partie A — Inventaire et connectivité

```ini
[web_lab]
web01 ansible_host=13.36.171.149 ansible_user=automation
```

```
$ ansible -i inventory.ini web_lab -m ping
web01 | SUCCESS => { "changed": false, "ping": "pong" }
```

## Partie B — Playbook (idempotent)

`playbook.yml` installe `curl`, crée `/etc/training/` et y dépose un fichier de preuve.

**Preuve d'idempotence** — deux exécutions réelles consécutives :

| Exécution | Résultat |
|---|---|
| 1ère (`ansible-playbook playbook.yml`) | `changed=2` (création réelle) |
| 2ème (même commande, sans modification entre-temps) | `changed=0` (rien à faire, conforme) |

## Partie C — Exécution via Jenkins

Job `tp5-ansible-web-lab` (Pipeline SCM, `TP_5/Jenkinsfile`), exécuté sur l'agent `aws-lab` :

1. **Lint** — `ansible-lint playbook.yml` → 0 échec, archivé (`ansible-lint-output.txt`)
2. **Vérification (`--check --diff`)** — dry-run archivé (`ansible-check-output.txt`)
3. **Approbation manuelle** — déclenchée uniquement si `ENVIRONMENT != dev` (`input` step)
4. **Exécution réelle** — via credential SSH Jenkins (`ssh-ansible-web-lab`), jamais de clé en clair,
   archivée (`ansible-apply-output.txt`)
5. **Inventaire archivé** (`TP_5/inventory.ini`) à chaque build

### Test #1 — `ENVIRONMENT=dev`

Approbation **non déclenchée** (stage skip) :
```
Stage "Approbation manuelle (environnement sensible)" skipped due to when conditional
...
Build 1 (environnement dev) terminé avec le statut : SUCCESS
```

### Test #2 — `ENVIRONMENT=prod`

Approbation **déclenchée**, build mis en pause :
```
[Pipeline] { (Approbation manuelle (environnement sensible))
[Pipeline] input
Confirmer l'exécution réelle du playbook sur l'environnement 'prod' ?
Exécuter or Abort
```
Après validation manuelle :
```
Build 2 (environnement prod) terminé avec le statut : SUCCESS
```

## Critères de réussite

- [x] Playbook idempotent (`changed=0` au second passage réel).
- [x] `ansible-lint` exécuté et archivé.
- [x] `ansible-playbook --check --diff` exécuté et archivé avant toute action réelle.
- [x] Approbation manuelle déclenchée pour les environnements sensibles (`test`, `prod`), pas pour `dev`.
- [x] Fichier d'inventaire archivé à chaque build.
- [x] Aucune clé SSH en clair dans les logs Jenkins (credential masqué, transmis via fichier temporaire).

## Livrables restants à joindre manuellement

- [ ] Capture d'écran du build #2 en pause sur l'étape d'approbation (bouton "Exécuter"/"Abort")
- [ ] Capture d'écran des artefacts archivés du job (lint + check + apply + inventaire)
