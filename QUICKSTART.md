# Guide de démarrage rapide - BooxStream

## 🚀 Démarrage rapide

### 1. Configuration initiale

#### Sur Windows (développement)
```powershell
# Copier le fichier de configuration
Copy-Item deploy-config.example.json deploy-config.json

# Éditer deploy-config.json avec vos paramètres
notepad deploy-config.json
```

#### Sur le serveur Rocky Linux (192.168.1.202)
```bash
# Installer Node.js 20
sudo dnf module reset nodejs
sudo dnf module enable nodejs:20
sudo dnf install nodejs npm -y

# Cloner le projet
sudo mkdir -p /opt/booxstream
sudo chown $USER:$USER /opt/booxstream
git clone https://github.com/Zabadehut/BooxStream.git /opt/booxstream

# Installer les dépendances
cd /opt/booxstream/server
npm install

# Configurer le firewall
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload

# Configurer le service systemd
sudo cp /opt/booxstream/server/booxstream.service /etc/systemd/system/
sudo nano /etc/systemd/system/booxstream.service
# Modifier User et WorkingDirectory

# Démarrer le service
sudo systemctl daemon-reload
sudo systemctl enable booxstream
sudo systemctl start booxstream
sudo systemctl status booxstream
```

### 2. Déploiement depuis Windows

```powershell
# Déployer vers GitHub et le serveur
.\deploy.ps1

# Ou seulement vers GitHub
.\deploy.ps1 -GitOnly

# Ou seulement vers le serveur
.\deploy.ps1 -ServerOnly
```

### 3. Utilisation

1. **Sur la tablette Boox** :
   - Installer l'APK
   - Ouvrir l'application
   - Entrer : `ws://192.168.1.202:8080`
   - Cliquer sur "Démarrer le streaming"

2. **Dans un navigateur** :
   - Ouvrir : `http://192.168.1.202:3000`
   - Visualiser le flux en temps réel

## 🔄 Workflow de développement

### Modifier le code
1. Faire vos modifications dans Cursor
2. Tester localement si possible
3. Déployer : `.\deploy.ps1`

### Restaurer depuis GitHub
```powershell
.\restore.ps1 -From git
```

### Créer une sauvegarde
```powershell
.\backup.ps1
```

## 🛠️ Commandes utiles

### Sur le serveur
```bash
# Voir les logs
sudo journalctl -u booxstream -f

# Redémarrer le service
sudo systemctl restart booxstream

# Vérifier le statut
sudo systemctl status booxstream

# Mettre à jour manuellement
cd /opt/booxstream
git pull
./server/deploy-server.sh
```

### Sur Windows
```powershell
# Vérifier le statut Git
git status

# Voir les commits
git log --oneline

# Vérifier la connexion SSH au serveur
ssh votre_utilisateur@192.168.1.202
```

## ⚠️ Dépannage

### Le serveur ne démarre pas
- Vérifier les logs : `sudo journalctl -u booxstream -n 50`
- Vérifier que Node.js est installé : `node --version`
- Vérifier les permissions : `ls -la /opt/booxstream`

### Le déploiement échoue
- Vérifier la connexion SSH : `ssh votre_utilisateur@192.168.1.202`
- Vérifier que Git est installé sur le serveur
- Vérifier les permissions sudo

### L'app Android ne se connecte pas
- Vérifier que le serveur est démarré
- Vérifier le firewall : `sudo firewall-cmd --list-ports`
- Vérifier l'IP dans l'app : doit être `192.168.1.202`

