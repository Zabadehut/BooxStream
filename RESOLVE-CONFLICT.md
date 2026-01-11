# Résolution du conflit Cloudflare Tunnel

## Problème identifié

Vous avez **deux serveurs** qui utilisent le **même tunnel Cloudflare** (`a40eeeac-5f83-4d51-9da2-67a0c9e0e975`) :

1. **Gateway** : Gère Traefik, Authentik, Homepage, et tous les autres services
2. **VM Linux (192.168.1.202)** : Gère uniquement BooxStream

Quand la VM Linux démarre `cloudflared` avec seulement la route `booxstream.kevinvdb.dev`, elle **écrase** la configuration complète du tunnel qui devrait contenir toutes les routes.

## Solution : Centraliser la configuration sur le Gateway

### Étape 1 : Désactiver cloudflared sur la VM Linux

Sur la VM Linux (`192.168.1.202`), exécutez :

```bash
# Arrêter le service
sudo systemctl stop cloudflared

# Désactiver le service (pour qu'il ne redémarre pas au boot)
sudo systemctl disable cloudflared

# Vérifier
sudo systemctl status cloudflared
```

**OU** utilisez le script automatique :

```bash
chmod +x RESOLVE-TUNNEL-CONFLICT.sh
./RESOLVE-TUNNEL-CONFLICT.sh
```

### Étape 2 : Ajouter la route BooxStream dans la config du Gateway

Sur votre **serveur Gateway**, modifiez `/opt/cloudflare/config.yml` :

```yaml
tunnel: a40eeeac-5f83-4d51-9da2-67a0c9e0e975
credentials-file: /etc/cloudflared/a40eeeac-5f83-4d51-9da2-67a0c9e0e975.json

ingress:
  # Vos routes existantes (traefik, auth, homepage, etc.)
  - hostname: traefik.kevinvdb.dev
    service: http://localhost:8080
  
  - hostname: auth.kevinvdb.dev
    service: http://localhost:9000
  
  - hostname: homepage.kevinvdb.dev
    service: http://localhost:3000
  
  # ⭐ AJOUTER CETTE ROUTE POUR BOOXSTREAM ⭐
  - hostname: booxstream.kevinvdb.dev
    service: http://192.168.1.202:3001
  
  # Catch-all (doit être en dernier)
  - service: http_status:404
```

### Étape 3 : Redémarrer cloudflared sur le Gateway

```bash
sudo systemctl restart cloudflared
sudo systemctl status cloudflared
```

### Étape 4 : Vérifier que tout fonctionne

```bash
# Vérifier le domaine principal
curl https://kevinvdb.dev

# Vérifier BooxStream
curl https://booxstream.kevinvdb.dev/api/hosts

# Vérifier les autres services
curl https://traefik.kevinvdb.dev
curl https://auth.kevinvdb.dev
curl https://homepage.kevinvdb.dev
```

## Architecture finale

```
Internet
   ↓
Cloudflare Tunnel (gateway-tunnel)
   ↓
Gateway (192.168.1.XXX)
   ├─ Traefik → localhost:8080
   ├─ Authentik → localhost:9000
   ├─ Homepage → localhost:3000
   └─ BooxStream → 192.168.1.202:3001 (VM Linux)
```

## Avantages de cette solution

✅ **Un seul point de configuration** : Toutes les routes sont gérées au même endroit  
✅ **Pas de conflit** : Un seul processus cloudflared actif  
✅ **Plus simple à maintenir** : Modifications centralisées  
✅ **Isolation** : Le service BooxStream reste sur sa VM dédiée  

## Alternative : Tunnel séparé (non recommandé)

Si vous préférez avoir un tunnel séparé pour BooxStream :

1. Créer un nouveau tunnel dans Cloudflare Dashboard
2. Configurer uniquement la route `booxstream.kevinvdb.dev` sur ce nouveau tunnel
3. Garder les deux tunnels actifs (un sur le gateway, un sur la VM Linux)

**Mais** cela complique la gestion et nécessite deux tunnels au lieu d'un.

## Notes importantes

- ⚠️ **Le catch-all (`http_status:404`) doit TOUJOURS être en dernier** dans la liste ingress
- ⚠️ **L'ordre des routes est important** : Cloudflare teste dans l'ordre jusqu'à trouver une correspondance
- ⚠️ **Assurez-vous que le service BooxStream est actif** sur la VM Linux avant de tester

