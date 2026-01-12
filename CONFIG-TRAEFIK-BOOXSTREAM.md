# Configuration Traefik pour BooxStream

## Vue d'ensemble

BooxStream doit passer par Traefik comme les autres services (Affine, Auth, etc.).

```
booxstream.kevinvdb.dev → Cloudflare Tunnel → traefik:80 → 192.168.1.202:3001
```

## Configuration Traefik

### Option 1 : Via fichier de configuration dynamique (recommandé)

Créez `/opt/traefik/dynamic/booxstream.yml` sur le gateway :

```yaml
http:
  routers:
    booxstream:
      rule: "Host(`booxstream.kevinvdb.dev`)"
      service: booxstream
      entryPoints:
        - websecure
      tls:
        certResolver: letsencrypt
      # Middleware Authentik si nécessaire (voir plus bas)
      # middlewares:
      #   - authentik-booxstream

  services:
    booxstream:
      loadBalancer:
        servers:
          - url: "http://192.168.1.202:3001"
```

### Option 2 : Via docker-compose (si Traefik est en Docker)

Dans votre `docker-compose.yml` Traefik, ajoutez les labels :

```yaml
services:
  traefik:
    # ... votre config existante ...
    labels:
      # ... autres labels ...
      
      # Route BooxStream
      - "traefik.http.routers.booxstream.rule=Host(`booxstream.kevinvdb.dev`)"
      - "traefik.http.routers.booxstream.entrypoints=websecure"
      - "traefik.http.routers.booxstream.tls.certresolver=letsencrypt"
      - "traefik.http.services.booxstream.loadbalancer.server.url=http://192.168.1.202:3001"
```

### Option 3 : Via traefik.yml (configuration statique)

Dans votre `traefik.yml` principal :

```yaml
http:
  routers:
    booxstream:
      rule: "Host(`booxstream.kevinvdb.dev`)"
      service: booxstream
      entryPoints:
        - websecure
      tls:
        certResolver: letsencrypt

  services:
    booxstream:
      loadBalancer:
        servers:
          - url: "http://192.168.1.202:3001"
```

## Configuration Authentik (optionnel)

Si vous voulez protéger BooxStream avec Authentik :

### 1. Créer l'application dans Authentik

1. Allez dans Authentik Dashboard → Applications → Providers
2. Créez un nouveau Provider (Proxy Provider)
3. Créez une Application liée à ce Provider
4. Notez le `Client ID` et `Client Secret`

### 2. Configurer le middleware dans Traefik

Dans `/opt/traefik/dynamic/booxstream.yml` :

```yaml
http:
  middlewares:
    authentik-booxstream:
      forwardAuth:
        address: "http://authentik:9000/outpost.goauthentik.io/forward/auth/nginx/"
        trustForwardHeader: true
        authResponseHeaders:
          - "X-authentik-username"
          - "X-authentik-groups"
          - "X-authentik-email"
        authRequestHeaders:
          - "X-Forwarded-Proto"
          - "X-Forwarded-Host"

  routers:
    booxstream:
      rule: "Host(`booxstream.kevinvdb.dev`)"
      service: booxstream
      entryPoints:
        - websecure
      tls:
        certResolver: letsencrypt
      middlewares:
        - authentik-booxstream  # ← Ajouter ici

  services:
    booxstream:
      loadBalancer:
        servers:
          - url: "http://192.168.1.202:3001"
```

### 3. Configurer Authentik Outpost

Assurez-vous que l'Outpost Authentik est configuré pour écouter sur le réseau Docker (si Traefik est en Docker) ou sur localhost.

## Vérification

### 1. Vérifier la configuration Traefik

```bash
# Vérifier que Traefik charge la config
docker logs traefik | grep booxstream
# ou
journalctl -u traefik | grep booxstream
```

### 2. Tester depuis le gateway

```bash
# Test direct vers Traefik
curl -H "Host: booxstream.kevinvdb.dev" http://localhost:80

# Test direct vers BooxStream
curl http://192.168.1.202:3001/api/hosts
```

### 3. Tester via Cloudflare Tunnel

```bash
curl https://booxstream.kevinvdb.dev/api/hosts
```

## Configuration Cloudflare Tunnel (sur gateway ET VM Linux)

Les deux doivent avoir la MÊME config dans `/opt/cloudflare/config.yml` (gateway) et `~/.cloudflared/config.yml` (VM Linux) :

```yaml
tunnel: a40eeeac-5f83-4d51-9da2-67a0c9e0e975
credentials-file: /path/to/credentials.json

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
    service: http://traefik:80  # ← Via Traefik comme les autres
  - service: http_status:404
```

## Résumé

1. ✅ Config Cloudflare Tunnel synchronisée (gateway + VM Linux)
2. ✅ Config Traefik pour router vers 192.168.1.202:3001
3. ✅ (Optionnel) Config Authentik pour protection
4. ✅ Redémarrer cloudflared sur gateway et VM Linux
5. ✅ Redémarrer Traefik pour charger la nouvelle config

## Troubleshooting

### Si BooxStream retourne 404

1. Vérifier que Traefik charge la config : `docker logs traefik`
2. Vérifier que le gateway peut accéder à 192.168.1.202:3001
3. Vérifier que cloudflared est actif sur les deux serveurs
4. Vérifier que les configs cloudflared sont identiques

### Si Authentik ne fonctionne pas

1. Vérifier que l'Outpost Authentik est actif
2. Vérifier que le middleware est correctement configuré
3. Vérifier les logs Traefik pour les erreurs d'authentification

