# Configuration BooxStream via Gateway (comme Affine)

## Architecture

BooxStream suit la même architecture qu'Affine :
- **Service** : BooxStream tourne sur la VM Linux (`192.168.1.202:3001`)
- **Tunnel** : Géré par le tunnel principal sur le Gateway
- **Route** : `booxstream.kevinvdb.dev` → `http://192.168.1.202:3001`

## Comparaison avec Affine

| Service | Tunnel ID | Config | Service Location |
|---------|-----------|--------|------------------|
| **Affine** | `10c995f5-985d-4ce3-91f5-ca90b1bd1341` | `/etc/cloudflared/config.yml` | `affine_server:3010` |
| **BooxStream** | `a40eeeac-5f83-4d51-9da2-67a0c9e0e975` | `/opt/cloudflare/config.yml` (gateway) | `192.168.1.202:3001` |

## Configuration sur le Gateway

### 1. Modifier `/opt/cloudflare/config.yml`

Ajoutez la route BooxStream dans la section `ingress` :

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
  
  # Affine (exemple)
  - hostname: affine.kevinvdb.dev
    service: http://affine_server:3010
  
  # ⭐ BooxStream (à ajouter)
  - hostname: booxstream.kevinvdb.dev
    service: http://192.168.1.202:3001
  
  # Catch-all (DOIT être en dernier)
  - service: http_status:404
```

### 2. Redémarrer cloudflared sur le Gateway

```bash
sudo systemctl restart cloudflared
sudo systemctl status cloudflared
```

## Configuration sur la VM Linux

### 1. Désactiver cloudflared

```bash
# Copier le script
scp DISABLE-CLOUDFLARE-VM.sh kvdb@192.168.1.202:/tmp/

# Sur la VM Linux
chmod +x /tmp/DISABLE-CLOUDFLARE-VM.sh
/tmp/DISABLE-CLOUDFLARE-VM.sh
```

Ou manuellement :

```bash
sudo systemctl stop cloudflared
sudo systemctl disable cloudflared
```

### 2. Vérifier que le service BooxStream fonctionne

```bash
# Vérifier le statut
sudo systemctl status booxstream-web

# Tester localement
curl http://localhost:3001/api/hosts

# Tester depuis le réseau local
curl http://192.168.1.202:3001/api/hosts
```

## Vérification finale

### Depuis n'importe où :

```bash
# Test BooxStream
curl https://booxstream.kevinvdb.dev/api/hosts

# Test autres services (doivent toujours fonctionner)
curl https://kevinvdb.dev
curl https://traefik.kevinvdb.dev
curl https://auth.kevinvdb.dev
curl https://affine.kevinvdb.dev
```

## Avantages de cette configuration

✅ **Centralisation** : Toutes les routes gérées au même endroit  
✅ **Pas de conflit** : Un seul processus cloudflared actif  
✅ **Cohérence** : Même architecture qu'Affine  
✅ **Simplicité** : Modifications centralisées sur le gateway  
✅ **Isolation** : Le service reste sur sa VM dédiée  

## Troubleshooting

### Si vous obtenez toujours un 404 :

1. **Vérifier que cloudflared est désactivé sur la VM Linux** :
   ```bash
   sudo systemctl status cloudflared
   # Doit être "inactive (dead)"
   ```

2. **Vérifier que la route est dans la config du gateway** :
   ```bash
   cat /opt/cloudflare/config.yml | grep booxstream
   ```

3. **Vérifier que cloudflared est actif sur le gateway** :
   ```bash
   sudo systemctl status cloudflared
   # Doit être "active (running)"
   ```

4. **Vérifier que le gateway peut accéder à la VM Linux** :
   ```bash
   # Depuis le gateway
   curl http://192.168.1.202:3001/api/hosts
   ```

5. **Vérifier les logs cloudflared sur le gateway** :
   ```bash
   sudo journalctl -u cloudflared -n 50 -f
   ```

## Notes importantes

- ⚠️ **Le catch-all (`http_status:404`) doit TOUJOURS être en dernier**
- ⚠️ **L'ordre des routes est important** : Cloudflare teste dans l'ordre
- ⚠️ **Assurez-vous que le service BooxStream est actif** avant de tester
- ⚠️ **Un seul cloudflared doit être actif** pour le tunnel `a40eeeac-5f83-4d51-9da2-67a0c9e0e975`

