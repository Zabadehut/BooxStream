# Guide de déploiement BooxStream

## Scripts disponibles

### 🚀 `deploy-prod.ps1` (RECOMMANDÉ)

**Script complet de déploiement en production avec tests**

```powershell
.\deploy-prod.ps1
```

**Ce script fait :**
1. ✅ Push vers GitHub (si changements)
2. ✅ Déploiement sur le serveur (git pull + npm install)
3. ✅ Redémarrage du service
4. ✅ Tests de vérification (service, ports, HTTP)

**Options :**
- `-SkipGit` : Ignore le push GitHub
- `-SkipTest` : Ignore les tests finaux

**Exemple :**
```powershell
# Déploiement complet
.\deploy-prod.ps1

# Déploiement sans push GitHub
.\deploy-prod.ps1 -SkipGit

# Déploiement sans tests
.\deploy-prod.ps1 -SkipTest
```

### 📦 `deploy-simple.ps1`

**Script simplifié de déploiement**

```powershell
.\deploy-simple.ps1 -ServerOnly
```

**Ce script fait :**
- Push GitHub (optionnel)
- Déploiement sur le serveur

**Options :**
- `-GitOnly` : Push GitHub seulement
- `-ServerOnly` : Déploiement serveur seulement

## Workflow recommandé

### 1. Développement local
```powershell
# Faire vos modifications
# ...

# Tester localement
# ...
```

### 2. Déploiement en production
```powershell
# Déployer tout (GitHub + Serveur + Tests)
.\deploy-prod.ps1
```

Le script va :
- Détecter les changements
- Vous demander un message de commit
- Pousser sur GitHub
- Déployer sur le serveur
- Redémarrer le service
- Tester que tout fonctionne

### 3. Vérification

```powershell
# Voir les logs
.\logs.ps1 -Follow

# Voir le statut
ssh kvdb@192.168.1.202 "sudo systemctl status booxstream-web"
```

## Structure du déploiement

```
Windows (Dev)
    ↓
deploy-prod.ps1
    ↓
GitHub (git push)
    ↓
Serveur Rocky Linux (git pull)
    ↓
npm install
    ↓
systemctl restart
    ↓
Tests automatiques
```

## Fichiers déployés

Le script déploie **TOUS** les fichiers du projet :
- ✅ Code source (`web/`, `server/`, `android-app/`)
- ✅ Scripts de déploiement
- ✅ Configuration systemd
- ✅ Documentation

## Configuration

Le script utilise `deploy-config.json` :
```json
{
  "server": {
    "host": "192.168.1.202",
    "user": "kvdb",
    "deployPath": "/opt/booxstream"
  },
  "git": {
    "remote": "origin",
    "branch": "main"
  }
}
```

## Dépannage

### Le script échoue sur "git pull"
- Vérifier la connexion SSH
- Vérifier que le dépôt existe sur le serveur
- Vérifier les permissions

### Le service ne redémarre pas
- Vérifier que le service est configuré : `sudo systemctl status booxstream-web`
- Vérifier les logs : `sudo journalctl -u booxstream-web -n 50`

### Les tests échouent
- Vérifier que le service est démarré
- Vérifier que les ports sont ouverts (firewall)
- Vérifier que Node.js est installé

## Commandes utiles

```powershell
# Déploiement complet
.\deploy-prod.ps1

# Voir les logs en temps réel
.\logs.ps1 -Follow

# Voir le statut du service
ssh kvdb@192.168.1.202 "sudo systemctl status booxstream-web"

# Redémarrer manuellement
ssh kvdb@192.168.1.202 "sudo systemctl restart booxstream-web"
```

