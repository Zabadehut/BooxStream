# Application de la configuration booxstream.yml

## Problème

Les logs Traefik montrent :
```
level=error msg="the service \"booxstream-backend@file\" does not exist"
```

Le fichier `/opt/traefik/config/booxstream.yml` sur le gateway ne contient pas la section `services` ou a un problème de format YAML.

## Solution rapide

### Sur le GATEWAY (192.168.1.200)

#### Option 1 : Utiliser le script automatique

```bash
# Copiez le script depuis votre PC
scp FIX-BOOXSTREAM-YML.sh kvdb@192.168.1.200:/tmp/

# Sur le gateway
ssh kvdb@192.168.1.200
bash /tmp/FIX-BOOXSTREAM-YML.sh
```

#### Option 2 : Copier le fichier directement

Depuis votre PC Windows :

```powershell
scp booxstream.yml kvdb@192.168.1.200:/tmp/booxstream.yml
```

Puis sur le gateway :

```bash
sudo cp /tmp/booxstream.yml /opt/traefik/config/booxstream.yml
sudo chown root:root /opt/traefik/config/booxstream.yml
sudo chmod 644 /opt/traefik/config/booxstream.yml
```

#### Option 3 : Créer manuellement

Sur le gateway :

```bash
sudo nano /opt/traefik/config/booxstream.yml
```

Collez ce contenu **EXACT** :

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

  services:
    booxstream-backend:
      loadBalancer:
        servers:
          - url: "http://192.168.1.202:3001"
```

**⚠️ IMPORTANT :** 
- L'indentation doit être exactement comme ci-dessus (2 espaces)
- La section `services` doit être au même niveau que `routers` (sous `http:`)
- Pas de tabulations, seulement des espaces

### Redémarrer Traefik

```bash
# Si Traefik est en Docker
docker restart traefik

# OU si Traefik est en systemd
sudo systemctl restart traefik
```

### Vérifier

```bash
# Vérifier les logs
docker logs traefik 2>&1 | grep -i "booxstream-backend\|error" | tail -20

# Tester l'API
curl -X POST https://booxstream.kevinvdb.dev/api/hosts/register \
  -H "Content-Type: application/json" \
  -d '{"uuid":"test","name":"Test"}'
```

Les erreurs "service does not exist" devraient disparaître.

