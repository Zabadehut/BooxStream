# Guide de démarrage du service BooxStream sur Rocky Linux 9

## 1. Première installation

### Sur le serveur (192.168.1.202)

Connectez-vous en SSH :
```bash
ssh kvdb@192.168.1.202
```

### Installer Node.js 20 (si pas déjà fait)

```bash
sudo dnf module reset nodejs
sudo dnf module enable nodejs:20
sudo dnf install nodejs npm git -y
```

### Cloner et installer le projet

```bash
# Cloner le projet
sudo mkdir -p /opt/booxstream
sudo chown kvdb:kvdb /opt/booxstream
cd /opt
git clone https://github.com/Zabadehut/BooxStream.git booxstream
cd booxstream

# Installer les dépendances du site web
cd web
npm install

# Créer le fichier .env
cat > .env << 'EOF'
PORT=3001
JWT_SECRET=$(openssl rand -hex 32)
DB_PATH=/opt/booxstream/web/booxstream.db
DOMAIN=booxstream.kevinvdb.dev
EOF

# Générer un secret JWT
JWT_SECRET=$(openssl rand -hex 32)
sed -i "s|JWT_SECRET=.*|JWT_SECRET=$JWT_SECRET|" .env
```

## 2. Configurer le firewall

```bash
sudo firewall-cmd --permanent --add-port=3001/tcp  # Interface web + WebSocket viewers
sudo firewall-cmd --permanent --add-port=8080/tcp  # WebSocket Android
sudo firewall-cmd --reload
```

## 3. Démarrer le service

### Option A : Test manuel (pour vérifier)

```bash
cd /opt/booxstream/web
node server.js
```

Vous devriez voir :
```
╔════════════════════════════════════════╗
║   BooxStream Web Server démarré!      ║
╠════════════════════════════════════════╣
║ 🌐 API Web: http://localhost:3001      ║
║ 📱 Android WebSocket: port 8080        ║
║ 👁️  Viewer WebSocket: port 3001        ║
╚════════════════════════════════════════╝
```

### Option B : Service systemd (recommandé)

```bash
# Copier le fichier de service
sudo cp /opt/booxstream/web/booxstream-web.service /etc/systemd/system/

# Recharger systemd
sudo systemctl daemon-reload

# Activer le service (démarrage automatique au boot)
sudo systemctl enable booxstream-web

# Démarrer le service
sudo systemctl start booxstream-web

# Vérifier le statut
sudo systemctl status booxstream-web
```

## 4. Commandes utiles

### Voir les logs
```bash
sudo journalctl -u booxstream-web -f
```

### Redémarrer le service
```bash
sudo systemctl restart booxstream-web
```

### Arrêter le service
```bash
sudo systemctl stop booxstream-web
```

### Vérifier que le service écoute
```bash
sudo netstat -tlnp | grep -E '3001|8080'
# ou
sudo ss -tlnp | grep -E '3001|8080'
```

## 5. Vérification

### Test local sur le serveur
```bash
curl http://localhost:3001
```

### Test depuis Windows
Ouvrez dans un navigateur : `http://192.168.1.202:3001`

Vous devriez voir l'interface de gestion des hôtes.

## 6. Mise à jour après un git pull

```bash
cd /opt/booxstream
git pull
cd web
npm install
sudo systemctl restart booxstream-web
```

## Dépannage

### Le service ne démarre pas
```bash
# Vérifier les logs
sudo journalctl -u booxstream-web -n 50

# Vérifier que Node.js est installé
node --version

# Vérifier les permissions
ls -la /opt/booxstream/web
```

### Port déjà utilisé
```bash
# Voir quel processus utilise le port
sudo lsof -i :3001
sudo lsof -i :8080

# Tuer le processus si nécessaire
sudo kill -9 <PID>
```

### Base de données
La base SQLite est créée automatiquement dans `/opt/booxstream/web/booxstream.db`

Pour la réinitialiser :
```bash
cd /opt/booxstream/web
rm booxstream.db
# Redémarrer le service, la base sera recréée
sudo systemctl restart booxstream-web
```

