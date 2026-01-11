# Vérification du déploiement

## Ce que `deploy-simple.ps1` transfère

Le script `deploy-simple.ps1` fonctionne en 2 étapes :

### 1. Push vers GitHub (si pas `-ServerOnly`)
- Commite tous les changements locaux
- Push vers GitHub sur la branche configurée

### 2. Sur le serveur
- `git fetch origin` : Récupère les dernières modifications
- `git reset --hard origin/$BRANCH` : **Remplace tout** par la version GitHub
- `git clean -fd` : Supprime les fichiers non trackés

**Important** : Seuls les fichiers **commités et poussés vers GitHub** sont transférés sur le serveur.

## Fichiers importants à vérifier

### ✅ Fichiers déjà dans Git (seront transférés)
- `web/server.js` - Serveur web avec modifications WebSocket
- `web/booxstream-web.service` - Service systemd
- `web/package.json` - Dépendances Node.js
- `android-app/app/src/main/java/com/example/booxstreamer/*.kt` - Code Android
- `android-app/build.gradle` - Configuration Gradle
- `android-app/gradle/wrapper/*` - Wrapper Gradle

### ⚠️ Fichiers NON dans Git (ne seront PAS transférés)
- `SETUP-CLOUDFLARE-TUNNEL.sh` - Script d'installation Cloudflare Tunnel
- `web/FIX-DOMAIN.md` - Guide de dépannage domaine
- `CHECK-SERVER-LOGS.md` - Guide vérification logs
- `CHECK-SERVICE.md` - Guide vérification service
- `CLOUDFLARE-TUNNEL.md` - Guide Cloudflare Tunnel
- `CONFIG-DOMAIN.md` - Guide configuration domaine
- `android-app/build-and-install.ps1` - Script PowerShell
- `android-app/adb-helper.ps1` - Script ADB helper
- Et autres fichiers de documentation/scripts

## Solution : Commiter les fichiers manquants

Pour que tous les fichiers soient transférés, vous devez les ajouter à Git :

```powershell
# Ajouter les fichiers importants
git add SETUP-CLOUDFLARE-TUNNEL.sh
git add web/FIX-DOMAIN.md
git add CHECK-SERVER-LOGS.md
git add CHECK-SERVICE.md
git add CLOUDFLARE-TUNNEL*.md
git add CONFIG-*.md
git add android-app/*.ps1
git add android-app/*.md

# Commiter
git commit -m "Ajout scripts et documentation pour Cloudflare Tunnel et debogage"

# Pousser
git push origin main
```

## Vérification après déploiement

Sur le serveur, vérifiez que les fichiers sont présents :

```bash
ssh kvdb@192.168.1.202
cd /opt/booxstream

# Vérifier les fichiers importants
ls -la SETUP-CLOUDFLARE-TUNNEL.sh
ls -la web/server.js
ls -la web/booxstream-web.service

# Vérifier la version du code
git log -1 --oneline
```

## Fichiers qui ne doivent PAS être dans Git

Ces fichiers sont dans `.gitignore` et ne seront jamais transférés :
- `deploy-config.json` - Configuration sensible
- `*.env` - Variables d'environnement
- `*.db` - Bases de données
- `node_modules/` - Dépendances Node.js
- `android-app/build/` - Builds Android

C'est normal et souhaitable pour la sécurité.

