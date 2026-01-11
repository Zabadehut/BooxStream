# Configuration du domaine BooxStream

Guide pour configurer le domaine `booxstream.kevinvdb.dev` dans Cloudflare et Authentik.

## Prérequis

- Domaine configuré dans Cloudflare
- Serveur avec IP publique accessible
- Authentik installé et configuré
- Reverse proxy (nginx, Traefik, ou Caddy) sur le serveur

## 1. Configuration DNS dans Cloudflare

### Option A : Enregistrement CNAME (recommandé avec Authentik)

Si vous avez créé un CNAME (comme vous l'avez fait), voici comment vérifier et configurer :

1. Connectez-vous à votre compte Cloudflare
2. Sélectionnez le domaine `kevinvdb.dev`
3. Allez dans **DNS** → **Records**
4. Vérifiez votre enregistrement CNAME

**Configuration CNAME typique :**
- **Type** : `CNAME`
- **Name** : `booxstream`
- **Target** : `auth.kevinvdb.dev` (ou votre domaine Authentik)
- **Proxy status** : 
  - ✅ **Proxied** (orange cloud) - Recommandé pour SSL automatique via Cloudflare
  - ⚪ **DNS only** (gris) - Si vous gérez SSL vous-même

**Note** : Un CNAME pointe vers un autre nom de domaine. Assurez-vous que le domaine cible (ex: `auth.kevinvdb.dev`) résout correctement vers votre serveur.

### Option B : Enregistrement A (alternative)

Si vous préférez utiliser un enregistrement A directement :

**Configuration :**
- **Type** : `A`
- **Name** : `booxstream`
- **IPv4 address** : `VOTRE_IP_PUBLIQUE`
- **Proxy status** : 
  - ✅ **Proxied** (orange cloud) - Si vous utilisez Cloudflare SSL/TLS
  - ⚪ **DNS only** (gris) - Si vous gérez SSL vous-même avec Authentik

### Étape 2 : Vérifier la propagation DNS

```bash
# Vérifier que le DNS résout correctement
nslookup booxstream.kevinvdb.dev
# ou
dig booxstream.kevinvdb.dev

# Si vous utilisez un CNAME, vérifiez qu'il pointe vers le bon domaine
dig booxstream.kevinvdb.dev +short
# Devrait retourner le domaine cible (ex: auth.kevinvdb.dev)

# Vérifier la chaîne complète de résolution
dig booxstream.kevinvdb.dev +trace
```

## 2. Configuration SSL/TLS dans Cloudflare

### Option A : SSL/TLS complet (recommandé avec Authentik)

1. Allez dans **SSL/TLS** → **Overview**
2. Sélectionnez **Full (strict)** ou **Full**
   - **Full (strict)** : SSL de bout en bout avec certificat valide sur le serveur
   - **Full** : SSL de bout en bout, accepte les certificats auto-signés

3. Allez dans **SSL/TLS** → **Edge Certificates**
   - Activez **Always Use HTTPS**
   - Activez **Automatic HTTPS Rewrites**

### Option B : SSL/TLS flexible (si pas de certificat sur le serveur)

1. Sélectionnez **Flexible**
   - Cloudflare chiffre la connexion entre le client et Cloudflare
   - La connexion entre Cloudflare et votre serveur n'est pas chiffrée

## 3. Configuration du Reverse Proxy (nginx)

Créez un fichier de configuration nginx pour BooxStream :

```bash
sudo nano /etc/nginx/sites-available/booxstream.kevinvdb.dev
```

**Configuration nginx :**

```nginx
# Redirection HTTP vers HTTPS
server {
    listen 80;
    server_name booxstream.kevinvdb.dev;
    return 301 https://$server_name$request_uri;
}

# Configuration HTTPS principale
server {
    listen 443 ssl http2;
    server_name booxstream.kevinvdb.dev;

    # Certificats SSL (générés par Certbot ou Authentik)
    ssl_certificate /etc/letsencrypt/live/booxstream.kevinvdb.dev/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/booxstream.kevinvdb.dev/privkey.pem;
    
    # Ou si vous utilisez les certificats d'Authentik :
    # ssl_certificate /etc/authentik/certs/cert.pem;
    # ssl_certificate_key /etc/authentik/certs/key.pem;

    # Configuration SSL moderne
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Headers de sécurité
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;

    # Proxy vers Authentik (pour l'authentification)
    location / {
        proxy_pass http://localhost:9000;  # Port d'Authentik
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # Proxy direct vers BooxStream (si pas d'auth requise)
    # OU configuré via Authentik comme application proxy
    location /api/ {
        proxy_pass http://localhost:3001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # WebSocket pour les viewers (port 3001)
    location /ws/ {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # WebSocket pour Android (port 8080) - Note: Le serveur BooxStream écoute directement sur le port 8080
    # Si vous utilisez Authentik, vous devrez peut-être configurer un port différent ou bypasser l'auth
    # Option 1: Exposer directement le port 8080 (sans proxy)
    # Option 2: Configurer un sous-domaine séparé (ex: ws-booxstream.kevinvdb.dev)
    # Option 3: Utiliser un chemin spécifique avec bypass d'auth dans Authentik
}
```

**Activer la configuration :**

```bash
# Créer le lien symbolique
sudo ln -s /etc/nginx/sites-available/booxstream.kevinvdb.dev /etc/nginx/sites-enabled/

# Tester la configuration
sudo nginx -t

# Recharger nginx
sudo systemctl reload nginx
```

## 4. Configuration dans Authentik

### Étape 1 : Créer une application Proxy Provider

1. Connectez-vous à Authentik (généralement `https://auth.kevinvdb.dev` ou votre domaine Authentik)
2. Allez dans **Applications** → **Providers**
3. Cliquez sur **Create** → **Proxy Provider**

**Configuration :**
- **Name** : `BooxStream`
- **Internal host** : `http://localhost:3001` (ou l'IP interne de votre serveur BooxStream)
- **External host** : `https://booxstream.kevinvdb.dev`
- **Mode** : `Forward auth (single application)`
- **Skip path regex** : `/api/.*|/ws/.*|/android-ws/.*` (pour bypasser l'auth sur les WebSockets si nécessaire)

### Étape 2 : Créer l'application

1. Allez dans **Applications** → **Applications**
2. Cliquez sur **Create**

**Configuration :**
- **Name** : `BooxStream`
- **Slug** : `booxstream`
- **Provider** : Sélectionnez le provider créé à l'étape 1
- **Launch URL** : `https://booxstream.kevinvdb.dev`

### Étape 3 : Créer une politique d'accès (optionnel)

1. Allez dans **Policies** → **Policies**
2. Créez une politique si vous voulez restreindre l'accès
3. Assigne la politique à l'application BooxStream

### Étape 4 : Configurer les utilisateurs/groupes

1. Assignez des utilisateurs ou groupes à l'application BooxStream
2. Les utilisateurs pourront se connecter via Authentik pour accéder à BooxStream

## 5. Configuration alternative : Authentik en mode Proxy

Si vous préférez que Authentik gère complètement le proxy :

### Configuration nginx pour Authentik

```nginx
server {
    listen 443 ssl http2;
    server_name booxstream.kevinvdb.dev;

    ssl_certificate /etc/letsencrypt/live/booxstream.kevinvdb.dev/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/booxstream.kevinvdb.dev/privkey.pem;

    location / {
        proxy_pass http://localhost:9000;  # Authentik
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

Puis configurez dans Authentik :
- **Internal host** : `http://localhost:3001`
- **External host** : `https://booxstream.kevinvdb.dev`

## 6. Mise à jour de l'application Android

Une fois le domaine configuré, mettez à jour l'URL dans l'application Android :

1. Ouvrez l'application BooxStream sur la tablette
2. Modifiez l'URL de l'API pour utiliser `https://booxstream.kevinvdb.dev`
3. Redémarrez l'application

## 7. Vérification

### Tester le DNS
```bash
nslookup booxstream.kevinvdb.dev
```

### Tester HTTPS
```bash
curl -I https://booxstream.kevinvdb.dev
```

### Tester l'authentification
1. Ouvrez `https://booxstream.kevinvdb.dev` dans un navigateur
2. Vous devriez être redirigé vers Authentik pour vous connecter
3. Après connexion, vous devriez voir l'interface BooxStream

### Tester les WebSockets
```bash
# Depuis le serveur
wscat -c wss://booxstream.kevinvdb.dev/ws/
```

## 8. Configuration du firewall

Assurez-vous que les ports sont ouverts :

```bash
# Sur le serveur
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --permanent --add-port=3001/tcp  # BooxStream web
sudo firewall-cmd --permanent --add-port=8080/tcp  # BooxStream Android WebSocket
sudo firewall-cmd --reload
```

## Notes importantes

1. **WebSockets et Authentik** : Les WebSockets peuvent nécessiter une configuration spéciale. Vous devrez peut-être bypasser l'authentification pour les WebSockets ou configurer Authentik pour les gérer correctement.

2. **Certificats SSL** : 
   - Utilisez Let's Encrypt avec Certbot pour des certificats gratuits
   - Ou utilisez les certificats générés par Authentik
   - Ou laissez Cloudflare gérer SSL en mode Flexible

3. **IP publique** : Assurez-vous que votre serveur est accessible depuis Internet si vous utilisez Cloudflare en mode Proxied.

4. **Ports** : 
   - Port 3001 : Interface web + WebSocket viewers (via HTTP)
   - Port 8080 : WebSocket Android (connexion directe, peut nécessiter une configuration spéciale avec Authentik)
   
   **Note importante** : Le port 8080 est utilisé directement par le serveur BooxStream pour les connexions Android. Si vous utilisez Authentik, vous devrez soit :
   - Exposer le port 8080 directement (sans proxy Authentik)
   - Configurer Authentik pour bypasser l'authentification sur ce port
   - Modifier le code pour utiliser un chemin WebSocket sur le port 3001

## Dépannage

### Le domaine ne résout pas
- Vérifiez la propagation DNS : `dig booxstream.kevinvdb.dev`
- Vérifiez que l'enregistrement A est correct dans Cloudflare

### Erreur SSL
- Vérifiez que les certificats sont valides
- Vérifiez la configuration SSL dans Cloudflare
- Vérifiez que nginx utilise les bons certificats

### Authentik ne redirige pas correctement
- Vérifiez la configuration du Proxy Provider dans Authentik
- Vérifiez les logs d'Authentik : `sudo journalctl -u authentik -f`
- Vérifiez la configuration nginx

### WebSockets ne fonctionnent pas
- Vérifiez que les headers `Upgrade` et `Connection` sont correctement configurés
- Vérifiez que Authentik ne bloque pas les WebSockets
- Testez directement avec `wscat` ou un client WebSocket

