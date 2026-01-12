# Application de la configuration Traefik pour BooxStream

## Problème actuel

Les logs Traefik montrent que la configuration actuelle applique Authentik à **toutes** les requêtes :

```json
"booxstream": {
  "rule": "Host(`booxstream.kevinvdb.dev`)",
  "middlewares": ["authentik-forward-auth"],  // ← Bloque tout !
  "service": "booxstream-backend"
}
```

**Résultat** : L'app Android ne peut pas appeler `/api/hosts/register` car Authentik bloque.

## Solution : Ajouter une route publique pour `/api/*`

### Étape 1 : Sur le GATEWAY (192.168.1.200)

Modifiez `/opt/traefik/config/booxstream.yml` :

```yaml
http:
  routers:
    # Route publique pour l'API mobile (SANS Authentik)
    booxstream-api:
      rule: "Host(`booxstream.kevinvdb.dev`) && PathPrefix(`/api/`)"
      entrypoints:
        - web
      service: booxstream-backend
      priority: 10  # Priorité haute = évaluée en premier

    # Route principale avec Authentik (interface web)
    booxstream:
      rule: "Host(`booxstream.kevinvdb.dev`)"
      entrypoints:
        - web
      middlewares:
        - authentik-forward-auth
      service: booxstream-backend
      priority: 1  # Priorité basse = évaluée après

  services:
    booxstream-backend:
      loadBalancer:
        servers:
          - url: "http://192.168.1.202:3001"
```

### Étape 2 : Redémarrer Traefik

```bash
# Sur le gateway
docker-compose restart traefik
# OU
docker restart traefik
```

### Étape 3 : Vérifier la nouvelle configuration

Les logs Traefik devraient maintenant montrer :

```json
"booxstream-api": {
  "rule": "Host(`booxstream.kevinvdb.dev`) && PathPrefix(`/api/`)",
  "service": "booxstream-backend",
  "priority": 10
},
"booxstream": {
  "rule": "Host(`booxstream.kevinvdb.dev`)",
  "middlewares": ["authentik-forward-auth"],
  "service": "booxstream-backend",
  "priority": 1
}
```

### Étape 4 : Tester

```bash
# Test API (doit fonctionner sans auth)
curl -X POST https://booxstream.kevinvdb.dev/api/hosts/register \
  -H "Content-Type: application/json" \
  -d '{"uuid":"test-uuid","name":"Test"}'

# Doit retourner 200 avec un token JWT

# Test interface web (doit rediriger vers Authentik)
curl -I https://booxstream.kevinvdb.dev/
# Doit retourner 302 (redirection Authentik)
```

## Ordre d'évaluation Traefik

Traefik évalue les routes par **priorité** (plus haut = évalué en premier) :

1. **Priorité 10** : `booxstream-api` avec `PathPrefix(/api/)`
   - ✅ Match `/api/hosts/register` → Route vers backend SANS Authentik
   - ✅ Match `/api/hosts` → Route vers backend SANS Authentik

2. **Priorité 1** : `booxstream` avec `Host(booxstream.kevinvdb.dev)`
   - ✅ Match `/` → Route vers backend AVEC Authentik
   - ✅ Match `/index.html` → Route vers backend AVEC Authentik

## Résultat attendu

- ✅ **API mobile** (`/api/*`) : Accessible sans authentification
- ✅ **Interface web** (`/`) : Protégée par Authentik
- ✅ **WebSocket** (`/android-ws`) : Doit aussi être public (voir ci-dessous)

## WebSocket Android

Si le WebSocket utilise `/android-ws`, ajoutez aussi :

```yaml
http:
  routers:
    # WebSocket Android (sans Authentik)
    booxstream-ws:
      rule: "Host(`booxstream.kevinvdb.dev`) && Path(`/android-ws`)"
      entrypoints:
        - web
      service: booxstream-backend
      priority: 10
```

Ou utilisez le port 8080 directement (comme actuellement dans le code Android).

## Vérification finale

Après redémarrage de Traefik, vérifiez les logs :

```bash
docker logs traefik | grep booxstream
```

Vous devriez voir les deux routes chargées.

