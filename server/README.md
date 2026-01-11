# Serveur BooxStream - Rocky Linux 9

Serveur Node.js qui fait office de relais WebSocket entre l'application Android et les clients web pour BooxStream.

## Installation

### 1. Installer Node.js 20

```bash
sudo dnf module reset nodejs
sudo dnf module enable nodejs:20
sudo dnf install nodejs npm -y
```

### 2. Installer les dépendances

```bash
cd server
npm install
```

### 3. Configurer le firewall

```bash
sudo firewall-cmd --permanent --add-port=3000/tcp  # Interface web
sudo firewall-cmd --permanent --add-port=8080/tcp  # Android WebSocket
sudo firewall-cmd --reload
```

### 4. Démarrer le serveur

#### Mode développement
```bash
node server.js
```

#### Mode production (systemd)
```bash
# Éditer le fichier de service avec votre utilisateur et chemin
sudo nano /etc/systemd/system/booxstream.service

# Activer et démarrer
sudo systemctl daemon-reload
sudo systemctl enable booxstream
sudo systemctl start booxstream
sudo systemctl status booxstream
```

## Ports

- **8080** : WebSocket pour l'application Android
- **3000** : HTTP + WebSocket pour l'interface web

## Accès

- Interface web : `http://IP_SERVEUR:3000`
- WebSocket Android : `ws://IP_SERVEUR:8080`

## Logs

En mode systemd :
```bash
sudo journalctl -u booxstream -f
```

