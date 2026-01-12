# Architecture BooxStream - Configuration Actuelle

## Vue d'ensemble

BooxStream est une application de streaming d'écran Android vers un navigateur web, avec authentification Authentik et routage via Cloudflare Tunnel + Traefik.

```
Internet
   ↓
Cloudflare (DNS + Tunnel)
   ↓
Gateway (192.168.1.200)
   ↓
[Cloudflare Tunnel gateway-tunnel]
   ↓
Traefik (Docker) - Port 80
   ↓
   ├─ booxstream.kevinvdb.dev → VM BooxStream (192.168.1.202:3001)
   ├─ affine.kevinvdb.dev → VM Affine (192.168.1.201:3010)
   ├─ auth.kevinvdb.dev → Authentik
   └─ home.kevinvdb.dev → Homepage
```

## Composants

### 1. VM BooxStream (192.168.1.202)

**Services** :
- Node.js Web Server (port 3001)
  - API REST : `/api/*`
  - Interface web : `/`
  - WebSocket Android : `/android-ws`
  - WebSocket Viewers : connexion par défaut
- WebSocket direct port 8080 (pour accès IP local)

**Fichiers** :
- `/opt/booxstream/web/` : Code serveur Node.js
- `/etc/systemd/system/booxstream-web.service` : Service systemd
- `/opt/booxstream/web/.env` : Variables d'environnement (JWT_SECRET, DB_PATH, DOMAIN)

**Base de données** :
- SQLite : `/opt/booxstream/web/booxstream.db`
- Tables : `hosts`, `sessions`, `auth_tokens`

### 2. Gateway (192.168.1.200)

**Services** :
- Cloudflare Tunnel `gateway-tunnel` (ID: `a40eeeac-5f83-4d51-9da2-67a0c9e0e975`)
- Traefik (Docker)
- Authentik (Docker)
- Homepage (Docker)

**Configuration Cloudflare Tunnel** :
```yaml
# /opt/cloudflare/config.yml
tunnel: a40eeeac-5f83-4d51-9da2-67a0c9e0e975
credentials-file: /opt/cloudflare/a40eeeac-5f83-4d51-9da2-67a0c9e0e975.json

ingress:
  - hostname: kevinvdb.dev
    service: http://traefik:80
  - hostname: auth.kevinvdb.dev
    service: http://traefik:80
  - hostname: home.kevinvdb.dev
    service: http://traefik:80
  - hostname: affine.kevinvdb.dev
    service: http://traefik:80
  - hostname: traefik.kevinvdb.dev
    service: http://traefik:80
  - hostname: booxstream.kevinvdb.dev
    service: http://traefik:80
  - service: http_status:404
```

**Configuration Traefik** :
```yaml
# /opt/traefik/config/booxstream.yml
http:
  routers:
    # API publique (sans Authentik) - Priorité 10
    booxstream-api:
      rule: "Host(`booxstream.kevinvdb.dev`) && PathPrefix(`/api/`)"
      entrypoints: [web]
      service: booxstream-backend
      priority: 10

    # WebSocket Android public (sans Authentik) - Priorité 10
    booxstream-ws:
      rule: "Host(`booxstream.kevinvdb.dev`) && Path(`/android-ws`)"
      entrypoints: [web]
      service: booxstream-backend
      priority: 10

    # Interface web avec Authentik - Priorité 1
    booxstream:
      rule: "Host(`booxstream.kevinvdb.dev`)"
      entrypoints: [web]
      middlewares: [authentik-forward-auth]
      service: booxstream-backend
      priority: 1

  services:
    booxstream-backend:
      loadBalancer:
        servers:
          - url: "http://192.168.1.202:3001"
```

### 3. Application Android

**Fonctionnement** :
1. **Enregistrement** : L'app appelle `https://booxstream.kevinvdb.dev/api/hosts/register`
   - Envoie : `{uuid, public_ip, name}`
   - Reçoit : `{token, host: {...}}`
   - Sauvegarde le token JWT dans SharedPreferences

2. **Streaming** :
   - Détecte l'URL API (domaine ou IP)
   - Construit l'URL WebSocket :
     - Domaine : `wss://booxstream.kevinvdb.dev/android-ws`
     - IP : `ws://192.168.1.202:8080`
   - Se connecte au WebSocket
   - Envoie : `{"type": "auth", "token": "..."}`
   - Reçoit : `{"type": "authenticated", "uuid": "..."}`
   - Commence à streamer les frames

**Code** :
- `android-app/app/src/main/java/com/example/booxstreamer/`
  - `MainActivity.kt` : UI et enregistrement
  - `ScreenCaptureService.kt` : Capture et streaming
  - `ApiClient.kt` : Communication API REST
  - `DeviceManager.kt` : Stockage UUID et token

## Flux d'authentification

### Android App → Serveur

```
1. Android App
   ↓ POST /api/hosts/register
   ↓ {uuid, public_ip, name}
2. Serveur (booxstream)
   ↓ Génère JWT avec {uuid, type: "host"}
   ↓ Sauvegarde dans DB
   ↓ Retourne token
3. Android App
   ↓ Sauvegarde token
   ↓ Connexion WebSocket
   ↓ {"type": "auth", "token": "..."}
4. Serveur
   ↓ Vérifie JWT
   ↓ {"type": "authenticated", "uuid": "..."}
5. Android App
   ↓ Commence streaming
   ↓ {"type": "frame", "data": "base64..."}
```

### Viewer Web → Serveur

```
1. Viewer
   ↓ Clique sur "Voir"
   ↓ POST /api/sessions/create
   ↓ {host_uuid: "..."}
2. Serveur
   ↓ Génère JWT avec {host_uuid, type: "viewer"}
   ↓ Crée session dans DB
   ↓ Retourne viewer_token
3. Viewer
   ↓ Connexion WebSocket
   ↓ {"type": "auth", "token": "..."}
4. Serveur
   ↓ Vérifie JWT
   ↓ Ajoute au Set de viewers pour ce host
   ↓ {"type": "authenticated", "host_uuid": "..."}
5. Serveur (relais)
   ↓ Reçoit frames de Android
   ↓ Broadcast aux viewers de ce host
```

## Sécurité

### Routes publiques (sans Authentik)
- `/api/*` : API REST pour l'app Android
- `/android-ws` : WebSocket Android

### Routes protégées (avec Authentik)
- `/` : Interface web

### Tokens JWT
- **Host token** : Valide 30 jours, type `"host"`
- **Viewer token** : Valide 24h, type `"viewer"`
- Secret : Variable `JWT_SECRET` dans `.env`

## Déploiement

### Serveur Web (VM BooxStream)

```bash
# Depuis votre PC Windows
git add .
git commit -m "Message"
git push
.\deploy-simple.ps1 -ServerOnly
```

Le script :
1. Push vers GitHub
2. SSH vers 192.168.1.202
3. Pull les changements
4. Installe les dépendances npm
5. Crée `.env` si nécessaire
6. Redémarre le service systemd

### Application Android

```powershell
cd android-app
.\build-and-install.ps1
```

Le script :
1. Détecte Android Studio JDK
2. Compile l'APK
3. Installe sur la tablette connectée

### Configuration Traefik (Gateway)

```bash
# Sur le gateway
scp booxstream.yml kvdb@192.168.1.200:/opt/traefik/config/
ssh kvdb@192.168.1.200
docker restart traefik
```

## Diagnostic

### Logs serveur

```bash
ssh kvdb@192.168.1.202
sudo journalctl -u booxstream-web -n 50 -f
```

### Logs Android

```powershell
cd android-app
.\check-logs.ps1
```

### Test WebSocket

```bash
# Depuis le serveur
npm install -g wscat
wscat -c wss://booxstream.kevinvdb.dev/android-ws
# Envoyer : {"type":"auth","token":"VOTRE_TOKEN"}
```

### Vérifier Traefik

```bash
# Sur le gateway
docker logs traefik | grep booxstream
curl https://booxstream.kevinvdb.dev/api/hosts
```

## Ports utilisés

| Service | Port | Protocole | Accessible depuis |
|---------|------|-----------|-------------------|
| Node.js Web | 3001 | HTTP/WS | Réseau local |
| WebSocket Direct | 8080 | WS | Réseau local |
| Traefik | 80 | HTTP | Docker network |
| Cloudflare Tunnel | - | HTTPS/WSS | Internet |

## URLs

- **Interface web** : https://booxstream.kevinvdb.dev (protégé par Authentik)
- **API** : https://booxstream.kevinvdb.dev/api/* (public)
- **WebSocket Android** : wss://booxstream.kevinvdb.dev/android-ws (public)
- **WebSocket Viewers** : wss://booxstream.kevinvdb.dev (public, mais nécessite token de session)

## Fichiers de configuration importants

### Sur la VM BooxStream (192.168.1.202)
- `/opt/booxstream/web/.env`
- `/opt/booxstream/web/booxstream.db`
- `/etc/systemd/system/booxstream-web.service`

### Sur le Gateway (192.168.1.200)
- `/opt/cloudflare/config.yml`
- `/opt/cloudflare/a40eeeac-5f83-4d51-9da2-67a0c9e0e975.json`
- `/opt/traefik/config/booxstream.yml`

### Sur le PC de développement
- `web/server.js` : Code serveur Node.js
- `booxstream.yml` : Template config Traefik
- `deploy-simple.ps1` : Script de déploiement
- `android-app/` : Code application Android

## Notes importantes

1. **Cloudflare Tunnel** : Un seul tunnel sur le gateway, pas sur la VM BooxStream
2. **Traefik** : Toutes les routes passent par Traefik, qui fait le proxy vers les services
3. **Authentik** : Protège uniquement l'interface web, pas l'API ni le WebSocket Android
4. **WebSocket** : L'upgrade HTTP vers WebSocket est géré manuellement par `server.on('upgrade', ...)`
5. **JWT_SECRET** : Doit être le même entre les déploiements (stocké dans `.env`)

