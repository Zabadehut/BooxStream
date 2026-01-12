# Diagnostic erreur token d'authentification Android

## Flux d'authentification

1. **App Android** → `POST /api/hosts/register` → Reçoit token JWT
2. **App Android** → WebSocket → Envoie `{"type": "auth", "token": "..."}`
3. **Serveur** → Vérifie token JWT → `decoded.type === 'host'`

## Problèmes possibles

### 1. L'enregistrement échoue (pas de token)

**Symptôme** : L'app dit "Token d'authentification manquant"

**Vérification** :
```bash
# Sur le serveur BooxStream (192.168.1.202)
sudo journalctl -u booxstream-web -n 50 | grep register
```

**Solution** : Vérifier que `/api/hosts/register` fonctionne sans Authentik.

### 2. Le token n'est pas valide

**Symptôme** : "Authentification échouée" dans les logs WebSocket

**Vérification** :
```bash
# Sur le serveur BooxStream
sudo journalctl -u booxstream-web -n 50 | grep "authentification\|token\|JWT"
```

**Causes possibles** :
- `JWT_SECRET` différent entre les appels
- Token expiré (mais valide 30 jours)
- Token malformé

### 3. Le WebSocket ne peut pas se connecter

**Symptôme** : Erreur de connexion WebSocket

**Vérification** :
- L'app Android utilise `wss://booxstream.kevinvdb.dev/android-ws`
- Traefik doit router `/android-ws` vers le backend
- Le WebSocket doit être accessible sans Authentik

**Solution** : Ajouter une route publique pour `/android-ws` dans Traefik.

### 4. Le WebSocket passe par Authentik

**Symptôme** : WebSocket se connecte mais Authentik bloque

**Solution** : Créer une route publique pour `/android-ws` dans Traefik.

## Solution : Route publique pour WebSocket Android

### Dans Traefik (`/opt/traefik/config/booxstream.yml`)

```yaml
http:
  routers:
    # Route publique pour l'API mobile (SANS Authentik)
    booxstream-api:
      rule: "Host(`booxstream.kevinvdb.dev`) && PathPrefix(`/api/`)"
      entrypoints:
        - web
      service: booxstream-backend
      priority: 10

    # Route publique pour WebSocket Android (SANS Authentik)
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

## Vérification étape par étape

### Étape 1 : Vérifier l'enregistrement

```bash
# Depuis n'importe où
curl -X POST https://booxstream.kevinvdb.dev/api/hosts/register \
  -H "Content-Type: application/json" \
  -d '{"uuid":"test-uuid-123","name":"Test Device"}'

# Doit retourner :
# {"success":true,"token":"eyJhbGc...","host":{...}}
```

### Étape 2 : Vérifier le WebSocket

```bash
# Test WebSocket (nécessite wscat ou autre outil)
wscat -c wss://booxstream.kevinvdb.dev/android-ws

# Ensuite envoyer :
# {"type":"auth","token":"VOTRE_TOKEN_ICI"}
```

### Étape 3 : Vérifier les logs serveur

```bash
# Sur la VM BooxStream (192.168.1.202)
sudo journalctl -u booxstream-web -f

# Vous devriez voir :
# 📱 Connexion Android WebSocket (HTTP)
# ✅ Hôte authentifié: uuid-xxx
```

## Configuration Traefik complète

Le fichier `/opt/traefik/config/booxstream.yml` doit contenir :

```yaml
http:
  routers:
    # API publique (priorité 10)
    booxstream-api:
      rule: "Host(`booxstream.kevinvdb.dev`) && PathPrefix(`/api/`)"
      entrypoints: ["web"]
      service: booxstream-backend
      priority: 10

    # WebSocket Android public (priorité 10)
    booxstream-ws:
      rule: "Host(`booxstream.kevinvdb.dev`) && Path(`/android-ws`)"
      entrypoints: ["web"]
      service: booxstream-backend
      priority: 10

    # Interface web avec Authentik (priorité 1)
    booxstream:
      rule: "Host(`booxstream.kevinvdb.dev`)"
      entrypoints: ["web"]
      middlewares: ["authentik-forward-auth"]
      service: booxstream-backend
      priority: 1

  services:
    booxstream-backend:
      loadBalancer:
        servers:
          - url: "http://192.168.1.202:3001"
```

## Test complet

1. **Enregistrement** :
   ```bash
   curl -X POST https://booxstream.kevinvdb.dev/api/hosts/register \
     -H "Content-Type: application/json" \
     -d '{"uuid":"test","name":"Test"}'
   ```

2. **WebSocket** : Utiliser le token obtenu dans l'app Android

3. **Vérifier les logs** : Les logs doivent montrer l'authentification réussie

