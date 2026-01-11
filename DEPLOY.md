# Guide de déploiement BooxStream

## 📋 État actuel

✅ **Local (Windows)** : Tous les fichiers sont créés et prêts
❌ **Serveur (192.168.1.202)** : Rien n'a encore été déployé
❌ **GitHub** : Code pas encore poussé

## 🚀 Premier déploiement

### Étape 1 : Préparer le serveur (à faire une seule fois)

Connectez-vous en SSH sur le serveur :
```bash
ssh kvdb@192.168.1.202
```

Puis exécutez :
```bash
# Installer Node.js 20
sudo dnf module reset nodejs
sudo dnf module enable nodejs:20
sudo dnf install nodejs npm git -y

# Créer le répertoire de déploiement
sudo mkdir -p /opt/booxstream
sudo chown kvdb:kvdb /opt/booxstream

# Configurer le firewall
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload

# Cloner le projet (après le premier push GitHub)
git clone https://github.com/Zabadehut/BooxStream.git /opt/booxstream
cd /opt/booxstream/server
npm install

# Configurer le service systemd
sudo cp /opt/booxstream/server/booxstream.service /etc/systemd/system/
sudo nano /etc/systemd/system/booxstream.service
# Modifier : User=kvdb et WorkingDirectory=/opt/booxstream/server

# Activer et démarrer
sudo systemctl daemon-reload
sudo systemctl enable booxstream
sudo systemctl start booxstream
```

### Étape 2 : Pousser vers GitHub

Depuis Windows, dans le dossier du projet :
```powershell
# Vérifier que tout est prêt
git status

# Ajouter tous les fichiers
git add .

# Créer le commit
git commit -m "Initial commit: BooxStream avec scripts de déploiement"

# Pousser vers GitHub
git push -u origin main
```

### Étape 3 : Déployer sur le serveur

**Option A : Automatique (recommandé)**
```powershell
.\deploy.ps1
```

**Option B : Manuel**
```powershell
# Seulement GitHub
.\deploy.ps1 -GitOnly

# Seulement serveur (après avoir cloné sur le serveur)
.\deploy.ps1 -ServerOnly
```

## 📁 Structure des scripts

```
BooxStream/
├── deploy.ps1              ← Script principal (Windows)
├── restore.ps1             ← Restauration (Windows)
├── backup.ps1               ← Sauvegarde (Windows)
├── deploy-config.json       ← Configuration (local, pas sur Git)
├── server/
│   ├── deploy-server.sh     ← Déploiement serveur (Linux)
│   └── restore-server.sh    ← Restauration serveur (Linux)
```

## 🔄 Workflow quotidien

1. **Modifier le code** dans Cursor
2. **Déployer** : `.\deploy.ps1`
   - Commit automatique si changements
   - Push vers GitHub
   - Déploiement sur serveur via SSH

## ⚠️ Notes importantes

- `deploy-config.json` est dans `.gitignore` (contient vos infos sensibles)
- Les scripts `.sh` sont pour le serveur Linux
- Les scripts `.ps1` sont pour Windows
- Le premier déploiement nécessite de cloner manuellement sur le serveur

