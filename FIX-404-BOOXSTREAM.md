# Résolution du problème 404 pour BooxStream

## Diagnostic

- ✅ Affine fonctionne (302 avec redirection Authentik)
- ❌ BooxStream retourne 404

**Conclusion** : La route cloudflared fonctionne, mais Traefik n'est pas configuré pour BooxStream.

## Solution : Configurer Traefik pour BooxStream

### Étape 1 : Vérifier la config cloudflared

Sur le gateway, vérifiez que la route existe :

```bash
cat /opt/cloudflare/config.yml | grep booxstream
```

Doit afficher :
```yaml
- hostname: booxstream.kevinvdb.dev
  service: http://traefik:80
```

### Étape 2 : Créer la config Traefik pour BooxStream

Sur le gateway, créez `/opt/traefik/dynamic/booxstream.yml` :

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
      # Middleware Authentik (comme pour Affine)
      middlewares:
        - authentik-booxstream

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

  services:
    booxstream:
      loadBalancer:
        servers:
          - url: "http://192.168.1.202:3001"
```

### Étape 3 : Vérifier que Traefik charge les fichiers dynamiques

Dans votre config Traefik principale (`traefik.yml` ou `docker-compose.yml`), assurez-vous que :

```yaml
providers:
  file:
    directory: /opt/traefik/dynamic
    watch: true
```

OU si Traefik est en Docker :

```yaml
volumes:
  - /opt/traefik/dynamic:/dynamic:ro
```

### Étape 4 : Redémarrer Traefik

```bash
# Si Traefik est en Docker
docker-compose restart traefik
# OU
docker restart traefik

# Si Traefik est un service systemd
sudo systemctl restart traefik
```

### Étape 5 : Vérifier que ça fonctionne

```bash
# Test depuis le gateway vers Traefik
curl -H "Host: booxstream.kevinvdb.dev" http://localhost:80

# Test direct vers BooxStream
curl http://192.168.1.202:3001/api/hosts

# Test via Cloudflare Tunnel
curl -I https://booxstream.kevinvdb.dev/
# Doit retourner 302 (redirection Authentik) comme Affine
```

## Vérification des logs

Si ça ne fonctionne toujours pas :

```bash
# Logs Traefik
docker logs traefik | grep booxstream
# OU
journalctl -u traefik | grep booxstream

# Vérifier que Traefik charge le fichier
docker exec traefik ls -la /dynamic/
# OU
ls -la /opt/traefik/dynamic/
```

## Configuration Authentik (déjà fait)

Si vous avez déjà créé le Provider et l'Application dans Authentik, le middleware devrait fonctionner.

Vérifiez dans Authentik :
- ✅ Provider `booxstream-proxy` créé
- ✅ Application `BooxStream` créée
- ✅ Application liée au Provider

## Résumé

1. ✅ Route dans cloudflared : `booxstream.kevinvdb.dev → traefik:80`
2. ⏳ **Config Traefik** : Créer `/opt/traefik/dynamic/booxstream.yml`
3. ⏳ **Redémarrer Traefik** : Pour charger la nouvelle config
4. ✅ Authentik : Provider et Application déjà créés

Une fois Traefik configuré, BooxStream devrait fonctionner comme Affine (302 avec redirection Authentik).

