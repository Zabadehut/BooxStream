# Déploiement manuel sur le serveur 192.168.1.202

Si le script automatique ne fonctionne pas, voici les commandes à exécuter manuellement sur le serveur.

## Commandes à exécuter sur le serveur

Connectez-vous en SSH :
```bash
ssh kvdb@192.168.1.202
```

Puis exécutez :

```bash
# Créer le répertoire si nécessaire
sudo mkdir -p /opt/booxstream
sudo chown kvdb:kvdb /opt/booxstream

# Cloner ou mettre à jour le projet
if [ -d "/opt/booxstream" ] && [ -d "/opt/booxstream/.git" ]; then
    cd /opt/booxstream
    git fetch origin
    git reset --hard origin/main
    git clean -fd
else
    cd /opt
    git clone https://github.com/Zabadehut/BooxStream.git
    cd BooxStream
fi

# Installer les dépendances du site web
cd /opt/booxstream/web
npm install

# Installer les dépendances du serveur (legacy)
cd /opt/booxstream/server
npm install

# Créer le fichier .env pour le site web
cd /opt/booxstream/web
cat > .env << 'EOF'
PORT=3001
JWT_SECRET=changez-cette-cle-secrete-en-production
DB_PATH=/opt/booxstream/web/booxstream.db
DOMAIN=booxstream.kevinvdb.dev
EOF

echo "Deploiement termine!"
```

## Démarrer le site web

```bash
cd /opt/booxstream/web
node server.js
```

Ou en arrière-plan :
```bash
cd /opt/booxstream/web
nohup node server.js > /tmp/booxstream-web.log 2>&1 &
```

## Configurer comme service systemd

Créer `/etc/systemd/system/booxstream-web.service` :

```ini
[Unit]
Description=BooxStream Web Server
After=network.target

[Service]
Type=simple
User=kvdb
WorkingDirectory=/opt/booxstream/web
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
```

Puis :
```bash
sudo systemctl daemon-reload
sudo systemctl enable booxstream-web
sudo systemctl start booxstream-web
sudo systemctl status booxstream-web
```

