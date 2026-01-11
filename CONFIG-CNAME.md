# Configuration avec CNAME - BooxStream

Guide rapide pour configurer BooxStream avec un CNAME pointant vers Authentik.

## Configuration DNS (Cloudflare)

Vous avez créé un CNAME :
- **Name** : `booxstream`
- **Target** : `auth.kevinvdb.dev` (ou votre domaine Authentik)
- **Proxy** : ✅ Proxied (recommandé)

## Vérification DNS

```bash
# Vérifier la résolution
dig booxstream.kevinvdb.dev +short
# Devrait retourner : auth.kevinvdb.dev (ou l'IP si DNS only)

# Vérifier la chaîne complète
dig booxstream.kevinvdb.dev +trace
```

## Configuration Authentik

### 1. Créer un Proxy Provider

Dans Authentik Admin :

1. **Applications** → **Providers** → **Create** → **Proxy Provider**

**Configuration :**
- **Name** : `BooxStream`
- **Internal host** : `http://localhost:3001` (ou `http://192.168.1.202:3001` si sur un autre serveur)
- **External host** : `https://booxstream.kevinvdb.dev`
- **Mode** : `Forward auth (single application)`
- **Skip path regex** : `/api/.*|/ws/.*` (optionnel, pour bypasser l'auth sur certaines routes)

### 2. Créer l'application

1. **Applications** → **Applications** → **Create**

**Configuration :**
- **Name** : `BooxStream`
- **Slug** : `booxstream`
- **Provider** : Sélectionnez le provider créé ci-dessus
- **Launch URL** : `https://booxstream.kevinvdb.dev`

### 3. Assigner des utilisateurs

1. **Applications** → **Applications** → Cliquez sur `BooxStream`
2. Onglet **User assignments** → **Assign users** ou **Assign groups**

## Configuration nginx (si nécessaire)

Si Authentik n'est pas directement accessible ou si vous avez besoin d'un reverse proxy supplémentaire :

```nginx
server {
    listen 443 ssl http2;
    server_name booxstream.kevinvdb.dev;

    # Certificats SSL (Let's Encrypt ou Cloudflare)
    ssl_certificate /etc/letsencrypt/live/booxstream.kevinvdb.dev/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/booxstream.kevinvdb.dev/privkey.pem;

    # Proxy vers Authentik
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
}
```

## Configuration SSL/TLS dans Cloudflare

1. **SSL/TLS** → **Overview**
2. Sélectionnez **Full (strict)** ou **Full**
   - **Full (strict)** : Nécessite un certificat valide sur le serveur
   - **Full** : Accepte les certificats auto-signés

3. **SSL/TLS** → **Edge Certificates**
   - Activez **Always Use HTTPS**
   - Activez **Automatic HTTPS Rewrites**

## Points importants avec CNAME

### Avantages
- ✅ Gestion centralisée via Authentik
- ✅ SSL automatique via Cloudflare (si Proxied)
- ✅ Authentification unifiée
- ✅ Facile à modifier (changer le target)

### Considérations
- ⚠️ Le domaine cible (ex: `auth.kevinvdb.dev`) doit résoudre correctement
- ⚠️ Les WebSockets peuvent nécessiter une configuration spéciale
- ⚠️ Le port 8080 (WebSocket Android) peut nécessiter un accès direct

## Configuration du port 8080 (WebSocket Android)

Le serveur BooxStream écoute sur le port 8080 pour les connexions Android. Avec un CNAME pointant vers Authentik, vous avez plusieurs options :

### Option 1 : Exposer directement le port 8080

Dans Cloudflare, créez un autre enregistrement :
- **Type** : `A` ou `CNAME`
- **Name** : `ws-booxstream` (ou un autre sous-domaine)
- **Target** : Votre IP publique ou domaine
- **Proxy** : ⚪ DNS only (pas de proxy pour WebSocket)

Puis dans l'app Android, utilisez : `wss://ws-booxstream.kevinvdb.dev:8080`

### Option 2 : Configurer Authentik pour gérer le port 8080

Configurez Authentik pour proxifier aussi le port 8080, ou utilisez un chemin spécifique.

### Option 3 : Modifier le code pour utiliser le même port

Modifiez `web/server.js` pour que les WebSockets Android utilisent aussi le port 3001 avec un chemin différent (ex: `/android-ws`).

## Vérification

### 1. Vérifier le DNS
```bash
dig booxstream.kevinvdb.dev
```

### 2. Tester HTTPS
```bash
curl -I https://booxstream.kevinvdb.dev
```

### 3. Tester l'authentification
1. Ouvrez `https://booxstream.kevinvdb.dev` dans un navigateur
2. Vous devriez être redirigé vers Authentik
3. Après connexion, vous devriez voir BooxStream

### 4. Vérifier les logs

**Authentik :**
```bash
sudo journalctl -u authentik -f
```

**BooxStream :**
```bash
# Si service systemd
sudo journalctl -u booxstream-web -f

# Si exécution manuelle
# Vérifiez les logs dans la console
```

## Dépannage

### Le CNAME ne résout pas
- Vérifiez que le domaine cible existe et résout correctement
- Vérifiez la propagation DNS : `dig booxstream.kevinvdb.dev +trace`

### Erreur SSL
- Vérifiez la configuration SSL dans Cloudflare
- Vérifiez que les certificats sont valides sur le serveur
- En mode "Full (strict)", le serveur doit avoir un certificat valide

### Authentik ne redirige pas vers BooxStream
- Vérifiez la configuration du Proxy Provider dans Authentik
- Vérifiez que l'application est assignée aux utilisateurs
- Vérifiez les logs d'Authentik

### WebSockets ne fonctionnent pas
- Les WebSockets peuvent nécessiter une configuration spéciale avec Authentik
- Considérez exposer le port 8080 directement ou utiliser un sous-domaine séparé

