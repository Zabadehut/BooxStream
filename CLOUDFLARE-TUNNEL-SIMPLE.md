# Configuration Cloudflare Tunnel - Guide Simplifié

Guide rapide pour exposer BooxStream via Cloudflare Tunnel.

## Installation rapide

### 1. Installer cloudflared

```bash
ssh kvdb@192.168.1.202

# Télécharger et installer
cd /tmp
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
sudo mv cloudflared-linux-amd64 /usr/local/bin/cloudflared
sudo chmod +x /usr/local/bin/cloudflared
```

### 2. Authentifier

```bash
cloudflared tunnel login
```

### 3. Créer le tunnel

```bash
cloudflared tunnel create booxstream
```

Notez le **Tunnel ID** affiché.

### 4. Configuration minimale

```bash
mkdir -p ~/.cloudflared
nano ~/.cloudflared/config.yml
```

**Configuration simple (un seul domaine) :**

```yaml
tunnel: <VOTRE_TUNNEL_ID>
credentials-file: /home/kvdb/.cloudflared/<TUNNEL_ID>.json

ingress:
  # Tout passer par le port 3001 (HTTP + WebSocket HTTP)
  - hostname: booxstream.kevinvdb.dev
    service: http://localhost:3001
  
  # Catch-all
  - service: http_status:404
```

### 5. Configurer le DNS

```bash
cloudflared tunnel route dns booxstream booxstream.kevinvdb.dev
```

### 6. Créer le service systemd

```bash
sudo nano /etc/systemd/system/cloudflared.service
```

```ini
[Unit]
Description=Cloudflare Tunnel
After=network.target

[Service]
Type=simple
User=kvdb
ExecStart=/usr/local/bin/cloudflared tunnel --config /home/kvdb/.cloudflared/config.yml run
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable cloudflared
sudo systemctl start cloudflared
sudo systemctl status cloudflared
```

## Modification nécessaire : Utiliser HTTP WebSocket pour Android

**Problème** : Le port 8080 utilise WebSocket TCP brut, incompatible avec Cloudflare Tunnel.

**Solution** : Modifier le code pour utiliser HTTP WebSocket sur le port 3001 avec un chemin spécifique.

### Option A : Modifier le serveur (recommandé)

Modifiez `web/server.js` pour ajouter un chemin WebSocket Android sur le port 3001 :

```javascript
// Au lieu de créer un serveur séparé sur le port 8080,
// ajoutez un chemin spécifique pour Android
const wssAndroid = new WebSocket.Server({ 
    server: server,
    path: '/android-ws'
});
```

Puis modifiez l'app Android pour utiliser `wss://booxstream.kevinvdb.dev/android-ws` au lieu de `ws://...:8080`.

### Option B : Exposer le port 8080 directement (si IP publique disponible)

Si votre serveur a une IP publique accessible, vous pouvez :
1. Exposer le port 8080 directement (sans Cloudflare Tunnel)
2. Utiliser un sous-domaine avec DNS only dans Cloudflare
3. Configurer le firewall pour autoriser le port 8080

## Vérification

```bash
# Logs du tunnel
sudo journalctl -u cloudflared -f

# Tester l'accès
curl https://booxstream.kevinvdb.dev/api/hosts
```

## Avantages

- ✅ SSL/TLS automatique
- ✅ Pas besoin d'ouvrir des ports
- ✅ Protection DDoS
- ✅ Fonctionne derrière NAT

## Note importante

Pour que cela fonctionne complètement, il faudra modifier le code pour que les WebSockets Android utilisent HTTP WebSocket au lieu de TCP brut.

