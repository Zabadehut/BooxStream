# Correction erreur service Traefik manquant

## Erreur

```
level=error msg="the service \"booxstream-backend@file\" does not exist"
```

## Cause

Le fichier `/opt/traefik/config/booxstream.yml` sur le gateway ne contient probablement pas la section `services`.

## Solution

### Sur le GATEWAY (192.168.1.200)

Vérifiez le contenu du fichier :

```bash
cat /opt/traefik/config/booxstream.yml
```

Le fichier **DOIT** contenir :

```yaml
http:
  routers:
    # Route publique pour l'API mobile (sans Authentik)
    booxstream-api:
      rule: "Host(`booxstream.kevinvdb.dev`) && PathPrefix(`/api/`)"
      entrypoints:
        - web
      service: booxstream-backend
      priority: 10

    # Route publique pour WebSocket Android (sans Authentik)
    booxstream-ws:
      rule: "Host(`booxstream.kevinvdb.dev`) && Path(`/android-ws`)"
      entrypoints:
        - web
      service: booxstream-backend
      priority: 10

    # Route principale avec Authentik (interface web)
    booxstream:
      rule: "Host(`booxstream.kevinvdb.dev`)"
      entrypoints:
        - web
      middlewares:
        - authentik-forward-auth
      service: booxstream-backend
      priority: 1

  # ⭐ CETTE SECTION EST OBLIGATOIRE ⭐
  services:
    booxstream-backend:
      loadBalancer:
        servers:
          - url: "http://192.168.1.202:3001"
```

### Si la section services manque

Ajoutez-la à la fin du fichier :

```bash
# Sur le gateway
sudo nano /opt/traefik/config/booxstream.yml
```

Ajoutez à la fin :

```yaml
  services:
    booxstream-backend:
      loadBalancer:
        servers:
          - url: "http://192.168.1.202:3001"
```

### Redémarrer Traefik

```bash
docker-compose restart traefik
# OU
docker restart traefik
```

### Vérifier

Les logs ne devraient plus montrer d'erreur :

```bash
docker logs traefik | grep booxstream-backend
```

Vous devriez voir les routes chargées sans erreur.

## Vérification complète

```bash
# Vérifier que le service existe maintenant
docker logs traefik 2>&1 | grep -i "booxstream-backend\|error" | tail -10

# Tester l'API
curl -X POST https://booxstream.kevinvdb.dev/api/hosts/register \
  -H "Content-Type: application/json" \
  -d '{"uuid":"test","name":"Test"}'
```

