# Vérification d'absence de conflit avec autres services

## Configuration actuelle BooxStream

La configuration Cloudflare Tunnel sur votre VM Linux (`192.168.1.202`) ne concerne **QUE** :

```yaml
tunnel: a40eeeac-5f83-4d51-9da2-67a0c9e0e975
credentials-file: /home/kvdb/.cloudflared/a40eeeac-5f83-4d51-9da2-67a0c9e0e975.json

ingress:
  - hostname: booxstream.kevinvdb.dev
    service: http://localhost:3001
  
  - service: http_status:404
```

## Pourquoi il n'y a PAS de conflit

### 1. Hostname spécifique
- La configuration route **uniquement** `booxstream.kevinvdb.dev`
- Les autres services (Traefik, Authentik, Homepage) utilisent probablement d'autres hostnames :
  - `traefik.kevinvdb.dev`
  - `auth.kevinvdb.dev` ou `authentik.kevinvdb.dev`
  - `homepage.kevinvdb.dev` ou `home.kevinvdb.dev`
  - `gateway.kevinvdb.dev` ou autres

### 2. Tunnel partagé mais routes séparées
- Vous utilisez le tunnel `gateway-tunnel` qui est partagé
- Mais chaque route est définie par son **hostname**
- Chaque hostname pointe vers un service différent

### 3. Vérification de la configuration complète

Pour voir TOUTES les routes configurées dans votre tunnel `gateway-tunnel`, vous pouvez :

**Option 1 : Depuis Cloudflare Dashboard**
1. Zero Trust → Networks → Tunnels → `gateway-tunnel`
2. Section "Public Hostnames" ou "Routes"
3. Vous verrez toutes les routes configurées

**Option 2 : Depuis le serveur où le tunnel principal est configuré**
```bash
# Si vous avez accès au serveur gateway
cat ~/.cloudflared/config.yml
# ou
cat /path/to/cloudflared/config.yml
```

## Configuration recommandée pour éviter les conflits

Si vous avez plusieurs services sur différents serveurs, vous pouvez :

### Option A : Un tunnel par serveur (recommandé pour isolation)

**Serveur Gateway** :
```yaml
ingress:
  - hostname: traefik.kevinvdb.dev
    service: http://localhost:8080
  - hostname: auth.kevinvdb.dev
    service: http://localhost:9000
  - hostname: homepage.kevinvdb.dev
    service: http://localhost:3000
  - service: http_status:404
```

**VM Linux (BooxStream)** :
```yaml
ingress:
  - hostname: booxstream.kevinvdb.dev
    service: http://localhost:3001
  - service: http_status:404
```

### Option B : Un tunnel partagé avec toutes les routes (actuel)

Si vous utilisez le même tunnel `gateway-tunnel` pour tous les services, la configuration complète devrait ressembler à :

```yaml
tunnel: a40eeeac-5f83-4d51-9da2-67a0c9e0e975
credentials-file: /home/kvdb/.cloudflared/a40eeeac-5f83-4d51-9da2-67a0c9e0e975.json

ingress:
  # Traefik (sur gateway)
  - hostname: traefik.kevinvdb.dev
    service: http://GATEWAY_IP:8080
  
  # Authentik (sur gateway)
  - hostname: auth.kevinvdb.dev
    service: http://GATEWAY_IP:9000
  
  # Homepage (sur gateway)
  - hostname: homepage.kevinvdb.dev
    service: http://GATEWAY_IP:3000
  
  # BooxStream (sur VM Linux)
  - hostname: booxstream.kevinvdb.dev
    service: http://192.168.1.202:3001
  
  # Catch-all (doit être en dernier)
  - service: http_status:404
```

**⚠️ IMPORTANT** : Si vous utilisez cette approche, la configuration doit être **identique sur tous les serveurs** qui exécutent cloudflared avec le même tunnel.

## Vérification sur le serveur

Pour voir la configuration actuelle sur votre VM Linux :

```bash
cat ~/.cloudflared/config.yml
```

Pour voir la configuration sur votre gateway (si elle existe) :

```bash
# Sur le serveur gateway
cat ~/.cloudflared/config.yml
# ou
cat /opt/cloudflared/config.yml
# ou selon où se trouve votre config
```

## Conclusion

**Votre configuration actuelle ne devrait PAS créer de conflit** car :
1. Elle route uniquement `booxstream.kevinvdb.dev`
2. Les autres services utilisent d'autres hostnames
3. Chaque hostname pointe vers un service différent

**Pour être sûr**, vérifiez :
1. La configuration complète du tunnel dans Cloudflare Dashboard
2. Les autres fichiers `config.yml` sur vos autres serveurs
3. Que chaque hostname pointe vers le bon service

