# Sécurité - Fichiers sensibles

## ⚠️ Fichiers à NE JAMAIS commiter sur GitHub

### Configuration
- `deploy-config.json` - Contient l'IP du serveur et l'utilisateur SSH
- `*.env` - Contient les secrets JWT et autres credentials
- `web/.env` - Configuration du serveur web avec JWT_SECRET

### Clés et certificats
- `*.keystore` - Clés de signature Android
- `*.key`, `*.pem` - Clés privées
- `id_rsa*` - Clés SSH privées

### Base de données
- `*.db`, `*.sqlite` - Bases de données avec données utilisateurs
- `*.db-journal` - Journaux de base de données

### Secrets
- Tous les fichiers contenant des mots de passe, tokens, ou secrets

## ✅ Fichiers de référence (OK à commiter)

- `deploy-config.example.json` - Exemple de configuration
- `web/env.example` - Exemple de fichier .env
- `*.env.example` - Tous les fichiers d'exemple

## Vérification

Pour vérifier qu'aucun fichier sensible n'est dans le repo :

```powershell
# Vérifier les fichiers sensibles déjà commités
git log --all --full-history --oneline -- "deploy-config.json"
git log --all --full-history --oneline -- "*.env"

# Vérifier les fichiers ignorés
git check-ignore deploy-config.json
```

## Si un fichier sensible a été commité

**URGENT** : Si un fichier sensible a été commité, il faut :

1. Le retirer de l'historique Git
2. Régénérer tous les secrets exposés
3. Mettre à jour le .gitignore

```bash
# Retirer un fichier de l'historique Git
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch deploy-config.json" \
  --prune-empty --tag-name-filter cat -- --all

# Forcer le push (ATTENTION: cela réécrit l'historique)
git push origin --force --all
```

## Bonnes pratiques

1. ✅ Toujours utiliser des fichiers `.example` pour la configuration
2. ✅ Vérifier `git status` avant chaque commit
3. ✅ Ne jamais commiter de fichiers `.env` ou `deploy-config.json`
4. ✅ Utiliser des variables d'environnement pour les secrets
5. ✅ Régénérer les secrets si exposés accidentellement

