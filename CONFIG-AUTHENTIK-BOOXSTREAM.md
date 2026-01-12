# Configuration Authentik pour BooxStream

## Vue d'ensemble

BooxStream doit être configuré dans Authentik pour apparaître dans la homepage et être protégé par authentification.

## Étape 1 : Créer le Provider (Proxy Provider)

### Dans Authentik Dashboard

1. **Allez dans** : Applications → Providers
2. **Cliquez sur** : "Create" → "Proxy Provider"

### Configuration du Provider

**Informations de base** :
- **Name** : `booxstream-proxy`
- **Authorization flow** : Sélectionnez votre flow d'autorisation (généralement le flow par défaut)
- **Forward auth (single application)** : ✅ Activé (si vous voulez une seule app)
- **External host** : `https://booxstream.kevinvdb.dev`
- **Internal host** : `http://192.168.1.202:3001` (ou `http://traefik:80` si via Traefik)

**Mode** :
- **Forward auth (single application)** : ✅ (recommandé pour une app simple)
  - Une seule application sera liée à ce provider
  
OU

- **Forward auth (domain)** : ✅ (si vous voulez protéger plusieurs sous-domaines)
  - Plusieurs applications peuvent utiliser ce provider

**Mode de fonctionnement** :
- **Forward auth (single application)** : Le provider gère une seule application
- **Forward auth (domain)** : Le provider peut gérer plusieurs applications sur le même domaine

### Exemple de configuration

```
Name: booxstream-proxy
Authorization flow: default-provider-authorization-implicit-consent
Forward auth (single application): ✅ Activé
External host: https://booxstream.kevinvdb.dev
Internal host: http://192.168.1.202:3001
```

**OU si via Traefik** :

```
Name: booxstream-proxy
Authorization flow: default-provider-authorization-implicit-consent
Forward auth (single application): ✅ Activé
External host: https://booxstream.kevinvdb.dev
Internal host: http://traefik:80
```

3. **Cliquez sur** : "Create"

## Étape 2 : Créer l'Application

### Dans Authentik Dashboard

1. **Allez dans** : Applications → Applications
2. **Cliquez sur** : "Create"

### Configuration de l'Application

**Informations de base** :
- **Name** : `BooxStream`
- **Slug** : `booxstream` (sera utilisé dans l'URL)
- **Provider** : Sélectionnez `booxstream-proxy` (créé à l'étape 1)
- **Launch URL** : `https://booxstream.kevinvdb.dev`

**Métadonnées** (pour la homepage) :
- **Icon** : URL d'une icône ou upload d'une image
  - Exemple : `https://example.com/booxstream-icon.png`
  - Ou utilisez une icône par défaut
- **Description** : `Streaming d'écran depuis tablette Android Boox`
- **Publisher** : Votre nom/organisation

**Permissions** :
- **Policy engine mode** : 
  - `any` : N'importe quelle politique peut autoriser
  - `all` : Toutes les politiques doivent autoriser (plus strict)

**Exemple de configuration complète** :

```
Name: BooxStream
Slug: booxstream
Provider: booxstream-proxy
Launch URL: https://booxstream.kevinvdb.dev

Icon: (upload ou URL)
Description: Streaming d'écran depuis tablette Android Boox
Publisher: Votre Nom

Policy engine mode: any
```

3. **Cliquez sur** : "Create"

## Étape 3 : Configurer les politiques d'accès (optionnel)

### Créer une politique

1. **Allez dans** : Policies → Policies
2. **Créez une politique** pour autoriser l'accès à BooxStream

**Exemple** :
- **Name** : `booxstream-access`
- **Type** : `Group membership` ou `User`
- **Group/User** : Sélectionnez les groupes ou utilisateurs autorisés

### Lier la politique à l'application

1. **Allez dans** : Applications → Applications → BooxStream
2. **Onglet** : "Policies"
3. **Ajoutez** la politique créée

## Étape 4 : Configurer la Homepage

### Vérifier que l'application apparaît

1. **Allez dans** : Applications → Applications → BooxStream
2. **Vérifiez** que les métadonnées sont complètes :
   - ✅ Icon
   - ✅ Description
   - ✅ Publisher

### Configuration Homepage (si vous utilisez une homepage personnalisée)

Si vous utilisez une homepage comme `homepage.kevinvdb.dev`, l'application devrait apparaître automatiquement si :
- ✅ L'application est créée dans Authentik
- ✅ L'utilisateur a accès à l'application (via les politiques)
- ✅ La homepage est configurée pour récupérer les applications depuis Authentik

### Configuration dans le fichier homepage (si nécessaire)

Si vous utilisez un fichier de configuration pour la homepage, ajoutez :

```yaml
services:
  - BooxStream:
      href: https://booxstream.kevinvdb.dev
      icon: booxstream.png  # ou URL
      description: Streaming d'écran depuis tablette Android Boox
```

## Étape 5 : Configuration Traefik (si nécessaire)

Si BooxStream passe par Traefik, configurez le middleware Authentik dans Traefik :

### Dans `/opt/traefik/dynamic/booxstream.yml` :

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
        - authentik-booxstream  # ← Middleware Authentik

  services:
    booxstream:
      loadBalancer:
        servers:
          - url: "http://192.168.1.202:3001"
```

## Vérification

### 1. Vérifier dans Authentik

- ✅ Provider créé : Applications → Providers → `booxstream-proxy`
- ✅ Application créée : Applications → Applications → `BooxStream`
- ✅ Métadonnées complètes (icon, description)

### 2. Vérifier dans Homepage

- ✅ L'application apparaît dans la liste
- ✅ L'icône s'affiche correctement
- ✅ Le lien fonctionne

### 3. Tester l'accès

1. **Accédez à** : `https://booxstream.kevinvdb.dev`
2. **Vous devriez être redirigé** vers Authentik pour vous connecter
3. **Après connexion**, vous êtes redirigé vers BooxStream

## Résumé des étapes

1. ✅ **Créer Provider** : `booxstream-proxy` dans Authentik
   - External host: `https://booxstream.kevinvdb.dev`
   - Internal host: `http://192.168.1.202:3001` (ou via Traefik)

2. ✅ **Créer Application** : `BooxStream` dans Authentik
   - Provider: `booxstream-proxy`
   - Launch URL: `https://booxstream.kevinvdb.dev`
   - Métadonnées: Icon, Description, Publisher

3. ✅ **Configurer politiques** (optionnel)
   - Qui peut accéder à BooxStream

4. ✅ **Vérifier Homepage**
   - L'application apparaît automatiquement

5. ✅ **Configurer Traefik** (si nécessaire)
   - Middleware Authentik pour protéger la route

## Troubleshooting

### L'application n'apparaît pas dans la homepage

- Vérifiez que les métadonnées sont complètes (icon, description)
- Vérifiez que l'utilisateur a accès via les politiques
- Vérifiez que la homepage récupère bien les applications depuis Authentik

### Erreur 401/403 lors de l'accès

- Vérifiez que le Provider est correctement configuré
- Vérifiez que l'Internal host est accessible depuis Authentik
- Vérifiez les logs Authentik : `docker logs authentik` ou `journalctl -u authentik`

### Redirection infinie

- Vérifiez que l'External host correspond exactement à l'URL utilisée
- Vérifiez que le middleware Traefik est correctement configuré
- Vérifiez que l'Outpost Authentik est actif

