# Explication du routage : Affine vs BooxStream

## Différence actuelle

### Affine
```yaml
- hostname: affine.kevinvdb.dev
  service: http://traefik:80
```
→ **Passe par Traefik** qui fait le reverse proxy vers le service Affine

### BooxStream (actuel)
```yaml
- hostname: booxstream.kevinvdb.dev
  service: http://192.168.1.202:3001
```
→ **Routage direct** vers la VM Linux, sans passer par Traefik

## Pourquoi cette différence ?

### Option 1 : Routage direct (actuel pour BooxStream)

**Avantages** :
- ✅ Plus simple : pas besoin de configurer Traefik
- ✅ Accès direct au service
- ✅ Moins de latence (un saut en moins)

**Inconvénients** :
- ❌ Pas d'authentification Authentik
- ❌ Pas de gestion SSL centralisée via Traefik
- ❌ Incohérent avec les autres services
- ❌ Pas de middlewares Traefik (rate limiting, etc.)

### Option 2 : Passer par Traefik (comme Affine)

**Avantages** :
- ✅ Cohérent avec les autres services
- ✅ Authentification Authentik possible
- ✅ SSL centralisé via Traefik
- ✅ Middlewares Traefik disponibles
- ✅ Gestion centralisée

**Inconvénients** :
- ❌ Nécessite configuration Traefik
- ❌ Un saut supplémentaire (légèrement plus de latence)

## Configuration recommandée : Passer par Traefik

Pour être cohérent avec Affine et les autres services, BooxStream devrait aussi passer par Traefik.

### Étape 1 : Modifier la config Cloudflare

Dans `/opt/cloudflare/config.yml` sur le gateway :

```yaml
ingress:
  # ... autres routes ...
  - hostname: booxstream.kevinvdb.dev
    service: http://traefik:80  # ← Comme Affine
  - service: http_status:404
```

### Étape 2 : Configurer Traefik

Dans votre configuration Traefik (docker-compose ou traefik.yml), ajoutez :

#### Option A : Via labels Docker (si Traefik est en Docker)

```yaml
services:
  booxstream:
    image: your-image  # ou service externe
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.booxstream.rule=Host(`booxstream.kevinvdb.dev`)"
      - "traefik.http.routers.booxstream.entrypoints=websecure"
      - "traefik.http.routers.booxstream.tls.certresolver=letsencrypt"
      - "traefik.http.services.booxstream.loadbalancer.server.url=http://192.168.1.202:3001"
```

#### Option B : Via fichier de configuration Traefik

Dans `traefik.yml` ou votre config Traefik :

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
      # Middleware pour Authentik si nécessaire
      # middlewares:
      #   - authentik-auth

  services:
    booxstream:
      loadBalancer:
        servers:
          - url: "http://192.168.1.202:3001"
```

#### Option C : Via configuration dynamique (fichier YAML)

Créez `/opt/traefik/dynamic/booxstream.yml` :

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

Puis dans votre `traefik.yml` principal :

```yaml
providers:
  file:
    filename: /opt/traefik/dynamic/booxstream.yml
    watch: true
```

### Étape 3 : Ajouter Authentik (optionnel)

Si vous voulez protéger BooxStream avec Authentik :

1. **Dans Authentik** : Créez une application pour BooxStream
2. **Dans Traefik** : Ajoutez le middleware Authentik :

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

  routers:
    booxstream:
      rule: "Host(`booxstream.kevinvdb.dev`)"
      service: booxstream
      middlewares:
        - authentik-booxstream  # ← Ajouter ici
```

## Comparaison finale

| Aspect | Routage direct | Via Traefik |
|--------|----------------|-------------|
| **Simplicité** | ✅ Plus simple | ❌ Plus complexe |
| **Cohérence** | ❌ Incohérent | ✅ Cohérent |
| **Authentik** | ❌ Non | ✅ Oui |
| **SSL** | Via Cloudflare | Via Traefik + Cloudflare |
| **Middlewares** | ❌ Non | ✅ Oui |
| **Latence** | ✅ Moins | Légèrement plus |

## Recommandation

**Pour la cohérence** : Utilisez Traefik comme pour Affine.

**Pour la simplicité** : Gardez le routage direct si vous n'avez pas besoin d'Authentik.

## Configuration actuelle (routage direct)

Si vous gardez le routage direct, votre config actuelle est correcte :

```yaml
- hostname: booxstream.kevinvdb.dev
  service: http://192.168.1.202:3001
```

Cela fonctionne, mais c'est moins cohérent avec les autres services.

