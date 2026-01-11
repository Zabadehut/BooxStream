# Configuration Cloudflare Tunnel pour BooxStream

Guide pour exposer le service BooxStream Web Server via Cloudflare Tunnel (cloudflared).

## Prérequis

- Compte Cloudflare avec domaine configuré
- Accès SSH au serveur Rocky Linux
- Domaine `booxstream.kevinvdb.dev` configuré dans Cloudflare

## Option 1 : Installation directe de cloudflared (recommandé)

### 1. Installer cloudflared sur le serveur

```bash
ssh kvdb@192.168.1.202

# Télécharger cloudflared
cd /tmp
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
sudo mv cloudflared-linux-amd64 /usr/local/bin/cloudflared
sudo chmod +x /usr/local/bin/cloudflared

# Vérifier l'installation
cloudflared --version
```

### 2. Authentifier cloudflared

```bash
cloudflared tunnel login
```

Cela ouvrira votre navigateur pour vous connecter à Cloudflare et autoriser le tunnel.

### 3. Créer un tunnel

```bash
cloudflared tunnel create booxstream
```

Notez le **Tunnel ID** qui sera affiché.

### 4. Créer la configuration du tunnel

```bash
mkdir -p ~/.cloudflared
nano ~/.cloudflared/config.yml
```

**Configuration pour BooxStream :**

```yaml
tunnel: <TUNNEL_ID>  # Remplacez par votre Tunnel ID
credentials-file: /home/kvdb/.cloudflared/<TUNNEL_ID>.json

ingress:
  # WebSocket Android (port 8080)
  - hostname: ws-booxstream.kevinvdb.dev
    service: tcp://localhost:8080
    originRequest:
      noHappyEyeballs: true
      tcpKeepAlive: 30s
      keepAliveConnections: 10
      keepAliveTimeout: 90s
  
  # Interface web + WebSocket viewers (port 3001)
  - hostname: booxstream.kevinvdb.dev
    service: http://localhost:3001
    originRequest:
      httpHostHeader: booxstream.kevinvdb.dev
      noHappyEyeballs: true
      keepAliveConnections: 10
      keepAliveTimeout: 90s
      connectTimeout: 30s
  
  # Catch-all (doit être en dernier)
  - service: http_status:404
```

### 5. Créer les enregistrements DNS dans Cloudflare

**Via l'interface Cloudflare :**

1. Allez dans votre domaine `kevinvdb.dev`
2. **DNS** → **Records**
3. Créez deux enregistrements CNAME :

**Enregistrement 1 :**
- **Type** : `CNAME`
- **Name** : `booxstream`
- **Target** : `<TUNNEL_ID>.cfargotunnel.com` (remplacez par votre Tunnel ID)
- **Proxy** : ✅ Proxied (orange cloud)

**Enregistrement 2 :**
- **Type** : `CNAME`
- **Name** : `ws-booxstream`
- **Target** : `<TUNNEL_ID>.cfargotunnel.com`
- **Proxy** : ⚪ DNS only (gris) - Important pour WebSocket TCP

**OU via la ligne de commande :**

```bash
cloudflared tunnel route dns booxstream booxstream.kevinvdb.dev
cloudflared tunnel route dns ws-booxstream ws-booxstream.kevinvdb.dev
```

### 6. Créer le service systemd

```bash
sudo nano /etc/systemd/system/cloudflared.service
```

**Contenu :**

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
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

**Activer et démarrer :**

```bash
sudo systemctl daemon-reload
sudo systemctl enable cloudflared
sudo systemctl start cloudflared
sudo systemctl status cloudflared
```

## Option 2 : Via Docker (alternative)

### 1. Créer le fichier de configuration

```bash
mkdir -p ~/cloudflared
nano ~/cloudflared/config.yml
```

Utilisez la même configuration que ci-dessus.

### 2. Lancer avec Docker

```bash
docker run -d \
  --name cloudflared \
  --restart unless-stopped \
  -v ~/cloudflared/config.yml:/etc/cloudflared/config.yml:ro \
  -v ~/.cloudflared:/home/nonroot/.cloudflared:ro \
  cloudflare/cloudflared:latest tunnel --config /etc/cloudflared/config.yml run
```

### 3. Ou utiliser docker-compose

Créez `~/cloudflared/docker-compose.yml` :

```yaml
version: '3.8'

services:
  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared
    restart: unless-stopped
    command: tunnel --config /etc/cloudflared/config.yml run
    volumes:
      - ./config.yml:/etc/cloudflared/config.yml:ro
      - ~/.cloudflared:/home/nonroot/.cloudflared:ro
```

Puis :

```bash
cd ~/cloudflared
docker-compose up -d
```

## Configuration importante pour WebSockets

### Problème avec WebSocket TCP (port 8080)

Cloudflare Tunnel supporte les WebSockets HTTP/HTTPS mais **pas les WebSockets TCP bruts** sur le port 8080.

**Solutions :**

#### Solution A : Utiliser un sous-domaine avec DNS only

Pour le port 8080 (WebSocket Android), utilisez un sous-domaine avec **DNS only** (pas de proxy) :

```yaml
ingress:
  - hostname: ws-booxstream.kevinvdb.dev
    service: tcp://localhost:8080
```

Et dans Cloudflare DNS :
- **Proxy** : ⚪ DNS only (gris)

Cela expose directement le port 8080 sans passer par le proxy Cloudflare.

#### Solution B : Modifier le code pour utiliser HTTP WebSocket

Modifiez `web/server.js` pour que les WebSockets Android utilisent aussi le port 3001 avec un chemin spécifique (ex: `/android-ws`).

## Vérification

### 1. Vérifier que le tunnel fonctionne

```bash
sudo journalctl -u cloudflared -f
# ou si Docker
docker logs cloudflared -f
```

Vous devriez voir :
```
INF +--------------------------------------------------------------------------------------------+
INF |  Your quick Tunnel has been created! Visit it at: https://booxstream.kevinvdb.dev         |
INF +--------------------------------------------------------------------------------------------+
```

### 2. Tester l'accès

```bash
# Depuis votre machine locale
curl https://booxstream.kevinvdb.dev/api/hosts

# Devrait retourner [] ou une liste d'hôtes
```

### 3. Vérifier les logs du tunnel

```bash
sudo journalctl -u cloudflared -n 50 --no-pager
```

## Mise à jour de l'application Android

Une fois le tunnel configuré, mettez à jour l'URL dans l'application Android :

1. Ouvrez l'application BooxStream
2. Modifiez l'URL de l'API pour utiliser : `https://booxstream.kevinvdb.dev`
3. Pour le WebSocket Android, utilisez : `wss://ws-booxstream.kevinvdb.dev:8080` (si DNS only)
   OU modifiez le code pour utiliser le même domaine avec un chemin

## Configuration SSL/TLS dans Cloudflare

1. **SSL/TLS** → **Overview**
2. Sélectionnez **Full (strict)** ou **Full**
3. **SSL/TLS** → **Edge Certificates**
   - Activez **Always Use HTTPS**
   - Activez **Automatic HTTPS Rewrites**

## Dépannage

### Le tunnel ne démarre pas

```bash
# Vérifier les logs
sudo journalctl -u cloudflared -n 100 --no-pager

# Tester manuellement
cloudflared tunnel --config ~/.cloudflared/config.yml run
```

### Erreur "credentials file not found"

Vérifiez que le fichier de credentials existe :
```bash
ls -la ~/.cloudflared/
```

### Le domaine ne résout pas

```bash
# Vérifier la résolution DNS
dig booxstream.kevinvdb.dev
nslookup booxstream.kevinvdb.dev
```

### WebSockets ne fonctionnent pas

- Vérifiez que le sous-domaine WebSocket utilise **DNS only** (pas de proxy)
- Vérifiez que le port 8080 est accessible depuis Internet
- Considérez utiliser HTTP WebSocket sur le port 3001 au lieu de TCP

## Avantages de Cloudflare Tunnel

- ✅ Pas besoin d'ouvrir des ports sur le firewall
- ✅ SSL/TLS automatique via Cloudflare
- ✅ Protection DDoS intégrée
- ✅ Pas besoin d'IP publique statique
- ✅ Fonctionne derrière NAT/firewall

## Notes importantes

1. **WebSocket TCP** : Le port 8080 pour WebSocket TCP nécessite un sous-domaine avec DNS only
2. **Performance** : Les WebSockets passent par Cloudflare, ce qui peut ajouter de la latence
3. **Coûts** : Cloudflare Tunnel est gratuit pour un usage raisonnable

