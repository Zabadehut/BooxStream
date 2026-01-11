# Résolution du problème de domaine - BooxStream

Si le serveur fonctionne sur `http://192.168.1.202:3001/` mais pas sur `https://booxstream.kevinvdb.dev`, voici les étapes de dépannage.

## 1. Vérifier la résolution DNS

```bash
# Depuis votre machine locale
nslookup booxstream.kevinvdb.dev

# Depuis le serveur
dig booxstream.kevinvdb.dev +short
```

**Résultat attendu** : L'IP de votre serveur (ex: `192.168.1.202` ou votre IP publique)

Si le DNS ne résout pas correctement :
- Vérifiez la configuration dans Cloudflare
- Attendez la propagation DNS (peut prendre jusqu'à 48h, généralement quelques minutes)

## 2. Vérifier que le serveur écoute sur toutes les interfaces

Le serveur Node.js doit écouter sur `0.0.0.0` (toutes les interfaces) et non seulement sur `localhost` ou `127.0.0.1`.

Vérifiez dans `web/server.js` ligne 354 :
```javascript
server.listen(PORT, '0.0.0.0', () => {
    // ...
});
```

Si c'est `server.listen(PORT, ...)` sans spécifier l'adresse, Node.js écoute par défaut sur toutes les interfaces, ce qui est correct.

## 3. Configurer le reverse proxy (nginx/Authentik)

Le serveur écoute sur le port 3001, mais pour accéder via le domaine HTTPS, vous devez configurer un reverse proxy.

### Option A : Via Authentik (si vous utilisez un CNAME)

1. **Dans Authentik** :
   - Créez un **Proxy Provider** avec :
     - **Internal host** : `http://localhost:3001` (ou `http://192.168.1.202:3001`)
     - **External host** : `https://booxstream.kevinvdb.dev`
   - Créez une **Application** liée à ce provider

2. **Vérifiez que nginx/Authentik écoute sur le port 443** :
   ```bash
   sudo netstat -tlnp | grep :443
   # ou
   sudo ss -tlnp | grep :443
   ```

### Option B : Via nginx directement

Créez `/etc/nginx/sites-available/booxstream.kevinvdb.dev` :

```nginx
# Redirection HTTP vers HTTPS
server {
    listen 80;
    server_name booxstream.kevinvdb.dev;
    return 301 https://$server_name$request_uri;
}

# Configuration HTTPS
server {
    listen 443 ssl http2;
    server_name booxstream.kevinvdb.dev;

    # Certificats SSL (Let's Encrypt)
    ssl_certificate /etc/letsencrypt/live/booxstream.kevinvdb.dev/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/booxstream.kevinvdb.dev/privkey.pem;

    # Configuration SSL
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Proxy vers BooxStream
    location / {
        proxy_pass http://localhost:3001;
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
        
        # Timeouts pour WebSocket
        proxy_read_timeout 86400;
        proxy_send_timeout 86400;
    }
}
```

Activez et testez :
```bash
sudo ln -s /etc/nginx/sites-available/booxstream.kevinvdb.dev /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## 4. Vérifier le firewall

Assurez-vous que les ports sont ouverts :

```bash
# Vérifier les ports ouverts
sudo firewall-cmd --list-ports

# Ouvrir les ports si nécessaire
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --permanent --add-port=3001/tcp
sudo firewall-cmd --reload
```

## 5. Vérifier les certificats SSL

Si vous utilisez HTTPS, vous devez avoir des certificats valides :

```bash
# Générer avec Let's Encrypt (si nginx direct)
sudo certbot --nginx -d booxstream.kevinvdb.dev

# Vérifier les certificats
sudo certbot certificates
```

## 6. Tester la connexion

### Depuis votre machine locale :

```bash
# Test DNS
nslookup booxstream.kevinvdb.dev

# Test HTTP (devrait rediriger vers HTTPS)
curl -I http://booxstream.kevinvdb.dev

# Test HTTPS
curl -I https://booxstream.kevinvdb.dev

# Test avec navigateur
# Ouvrez https://booxstream.kevinvdb.dev dans votre navigateur
```

### Depuis le serveur :

```bash
# Test local
curl http://localhost:3001

# Test via le domaine (si DNS résout localement)
curl https://booxstream.kevinvdb.dev
```

## 7. Vérifier les logs

### Logs nginx :
```bash
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log
```

### Logs BooxStream :
```bash
# Si service systemd
sudo journalctl -u booxstream-web -f

# Si exécution manuelle
# Vérifiez la console où le serveur tourne
```

### Logs Authentik (si utilisé) :
```bash
sudo journalctl -u authentik -f
```

## Problèmes courants

### Le DNS résout mais le site ne charge pas
- ✅ Vérifiez que nginx/Authentik écoute sur le port 443
- ✅ Vérifiez que le reverse proxy est configuré correctement
- ✅ Vérifiez les certificats SSL

### Erreur "Connection refused"
- ✅ Vérifiez que le serveur BooxStream tourne : `curl http://localhost:3001`
- ✅ Vérifiez que le firewall autorise les connexions
- ✅ Vérifiez que le reverse proxy pointe vers le bon port

### Erreur SSL
- ✅ Vérifiez que les certificats sont valides et non expirés
- ✅ Vérifiez la configuration SSL dans Cloudflare (Full ou Full strict)
- ✅ Régénérez les certificats si nécessaire : `sudo certbot renew`

### Le site charge mais les WebSockets ne fonctionnent pas
- ✅ Vérifiez que les headers `Upgrade` et `Connection` sont configurés dans nginx
- ✅ Vérifiez les timeouts WebSocket dans nginx
- ✅ Vérifiez que le port 8080 (WebSocket Android) est accessible si nécessaire

## Configuration rapide nginx (copier-coller)

```bash
# Sur le serveur
sudo nano /etc/nginx/sites-available/booxstream.kevinvdb.dev
```

Collez la configuration nginx ci-dessus, puis :

```bash
sudo ln -s /etc/nginx/sites-available/booxstream.kevinvdb.dev /etc/nginx/sites-enabled/
sudo certbot --nginx -d booxstream.kevinvdb.dev
sudo nginx -t
sudo systemctl reload nginx
```

## Vérification finale

Une fois tout configuré, vous devriez pouvoir :
1. ✅ Accéder à `https://booxstream.kevinvdb.dev` depuis n'importe où
2. ✅ Voir l'interface BooxStream
3. ✅ Les WebSockets fonctionnent pour les viewers
4. ✅ L'app Android peut se connecter (port 8080 ou via le domaine)

