# Mise à jour configuration Cloudflare Tunnel (Docker)

## Si cloudflared est dans Docker sur le Gateway

### 1. Modifier la configuration

La configuration est généralement montée dans le conteneur Docker.

**Option A : Fichier monté depuis l'hôte**

```bash
# Éditer le fichier sur l'hôte
nano /opt/cloudflare/config.yml
```

Ajoutez la route BooxStream :

```yaml
ingress:
  # ... vos routes existantes ...
  - hostname: booxstream.kevinvdb.dev
    service: http://192.168.1.202:3001
  - service: http_status:404
```

**Option B : Volume Docker**

Si la config est dans un volume Docker, vous pouvez :

```bash
# Trouver le conteneur
docker ps --filter "name=cloudflared"

# Entrer dans le conteneur
docker exec -it <container_name> sh

# Éditer la config (généralement dans /etc/cloudflared/config.yml)
vi /etc/cloudflared/config.yml
```

### 2. Redémarrer cloudflared

**Si docker-compose :**

```bash
cd /opt/cloudflare
docker-compose restart cloudflared
# ou
docker compose restart cloudflared
```

**Si conteneur Docker simple :**

```bash
docker restart <container_name>
```

**OU utiliser le script automatique :**

```bash
chmod +x RESTART-CLOUDFLARE-DOCKER.sh
./RESTART-CLOUDFLARE-DOCKER.sh
```

### 3. Vérifier les logs

```bash
# Logs Docker
docker logs <container_name> -f

# Ou si docker-compose
docker-compose logs -f cloudflared
```

### 4. Tester

```bash
curl https://booxstream.kevinvdb.dev/api/hosts
```

## Structure typique avec Docker

```
/opt/cloudflare/
├── config.yml              # Configuration Cloudflare Tunnel
├── docker-compose.yml      # Configuration Docker Compose
└── cred.json               # Credentials (monté en volume)
```

**docker-compose.yml typique :**

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
      - ./cred.json:/etc/cloudflared/cred.json:ro
```

## Commandes utiles

```bash
# Voir les conteneurs cloudflared
docker ps --filter "name=cloudflared"

# Voir les logs en temps réel
docker logs -f <container_name>

# Redémarrer
docker restart <container_name>

# Vérifier la config montée
docker exec <container_name> cat /etc/cloudflared/config.yml
```

