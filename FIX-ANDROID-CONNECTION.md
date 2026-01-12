# Résolution du problème de connexion Android

## Problème

L'application Android ne peut pas se connecter car :
- Les appels API (`POST /api/hosts/register`) passent par Traefik + Authentik
- Authentik bloque les requêtes non authentifiées
- L'app Android ne peut pas s'authentifier via Authentik (pas de navigateur)

## Solution : Route publique pour l'API

Créer une route Traefik **publique** (sans Authentik) pour les endpoints API, et garder Authentik pour l'interface web.

### Option 1 : Route publique pour `/api/*` (recommandé)

**Fichier** : `/opt/traefik/config/booxstream-api-public.yml`

```yaml
http:
  routers:
    # Route publique pour l'API mobile (sans Authentik)
    booxstream-api:
      rule: "Host(`booxstream.kevinvdb.dev`) && PathPrefix(`/api/`)"
      entrypoints:
        - web
      service: booxstream-backend
      priority: 10  # Priorité plus haute que la route principale

    # Route principale avec Authentik (interface web)
    booxstream:
      rule: "Host(`booxstream.kevinvdb.dev`)"
      entrypoints:
        - web
      middlewares:
        - authentik-forward-auth
      service: booxstream-backend
      priority: 1  # Priorité plus basse

  services:
    booxstream-backend:
      loadBalancer:
        servers:
          - url: "http://192.168.1.202:3001"
```

**Avantages** :
- ✅ L'API mobile fonctionne sans authentification
- ✅ L'interface web reste protégée par Authentik
- ✅ Une seule configuration Traefik

### Option 2 : Fusionner avec booxstream.yml existant

**Modifier** `/opt/traefik/config/booxstream.yml` :

```yaml
http:
  routers:
    # Route publique pour l'API (priorité haute)
    booxstream-api:
      rule: "Host(`booxstream.kevinvdb.dev`) && PathPrefix(`/api/`)"
      entrypoints:
        - web
      service: booxstream-backend
      priority: 10

    # Route principale avec Authentik (priorité basse)
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

## Configuration sur le Gateway

### Étape 1 : Créer ou modifier le fichier Traefik

```bash
# Sur le gateway (192.168.1.200)
sudo nano /opt/traefik/config/booxstream.yml
```

Copiez la configuration ci-dessus.

### Étape 2 : Redémarrer Traefik

```bash
docker-compose restart traefik
# OU
docker restart traefik
```

### Étape 3 : Vérifier

```bash
# Test API (doit fonctionner sans authentification)
curl -X POST https://booxstream.kevinvdb.dev/api/hosts/register \
  -H "Content-Type: application/json" \
  -d '{"uuid":"test-uuid","name":"Test"}'

# Test interface web (doit rediriger vers Authentik)
curl -I https://booxstream.kevinvdb.dev/
# Doit retourner 302 (redirection Authentik)
```

## WebSocket pour Android

Le WebSocket Android doit aussi être accessible. Deux options :

### Option A : Route publique pour `/android-ws`

Ajoutez dans Traefik :

```yaml
http:
  routers:
    # WebSocket Android (sans Authentik)
    booxstream-ws-android:
      rule: "Host(`booxstream.kevinvdb.dev`) && Path(`/android-ws`)"
      entrypoints:
        - web
      service: booxstream-backend
      priority: 10
```

### Option B : Utiliser le port 8080 directement (actuel)

L'app Android utilise déjà le port 8080 directement si c'est une IP locale, ou `/android-ws` pour un domaine.

**Vérifiez** que le serveur écoute bien sur le port 8080 ET que Traefik peut router vers ce port.

## Vérification dans l'app Android

L'app Android devrait maintenant pouvoir :
1. ✅ Appeler `POST https://booxstream.kevinvdb.dev/api/hosts/register`
2. ✅ Se connecter au WebSocket `wss://booxstream.kevinvdb.dev/android-ws`

## Sécurité

⚠️ **L'API `/api/*` est maintenant publique** (sans Authentik)

Pour sécuriser :
- ✅ L'API utilise déjà des tokens JWT internes
- ✅ Seul `/api/hosts/register` est vraiment public (nécessaire pour l'enregistrement)
- ✅ Les autres endpoints (`/api/hosts/update-ip`) nécessitent déjà un token JWT
- ✅ L'interface web reste protégée par Authentik

## Résumé

1. ✅ Créer route publique `/api/*` dans Traefik
2. ✅ Garder Authentik pour l'interface web (`/`)
3. ✅ Redémarrer Traefik
4. ✅ Tester depuis l'app Android

L'app Android devrait maintenant fonctionner !

