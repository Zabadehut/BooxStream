# Architecture finale BooxStream

## Vue d'ensemble

```
Internet
   ↓
Cloudflare Tunnel (a40eeeac-5f83-4d51-9da2-67a0c9e0e975)
   ↓
VM Gateway (gère le tunnel unique)
   ├─ Traefik → localhost:80
   ├─ Authentik → via Traefik
   ├─ Homepage → via Traefik
   ├─ Affine → via Traefik (ou direct selon config)
   └─ BooxStream → 192.168.1.202:3001 (VM Linux séparée)
```

## Configuration

### VM Gateway

**Fichier** : `/opt/cloudflare/config.yml`

```yaml
tunnel: a40eeeac-5f83-4d51-9da2-67a0c9e0e975
credentials-file: /etc/cloudflared/cred.json

ingress:
  - hostname: kevinvdb.dev
    service: http://traefik:80
  - hostname: auth.kevinvdb.dev
    service: http://traefik:80
  - hostname: home.kevinvdb.dev
    service: http://traefik:80
  - hostname: affine.kevinvdb.dev
    service: http://traefik:80
  - hostname: traefik.kevinvdb.dev
    service: http://traefik:80
  - hostname: booxstream.kevinvdb.dev
    service: http://192.168.1.202:3001
  - service: http_status:404
```

**Service** : `cloudflared` actif sur le gateway uniquement

### VM Linux (BooxStream) - 192.168.1.202

**Service** : `booxstream-web` actif sur port 3001

**Cloudflared** : DÉSACTIVÉ (ne doit pas être actif)

**Configuration** : La config dans `~/.cloudflared/config.yml` n'est plus utilisée car cloudflared est désactivé.

### Application Affine

**Tunnel** : Utilise le même tunnel via le gateway (probablement via Traefik)

## Points importants

✅ **Un seul tunnel Cloudflare** : `a40eeeac-5f83-4d51-9da2-67a0c9e0e975`  
✅ **Un seul processus cloudflared actif** : Sur le VM Gateway uniquement  
✅ **Toutes les routes gérées au même endroit** : Dans `/opt/cloudflare/config.yml` du gateway  
✅ **Services isolés** : Chaque service peut être sur une VM différente  

## Vérification

### Sur le VM Gateway

```bash
# Vérifier que cloudflared est actif
sudo systemctl status cloudflared

# Vérifier la configuration
cat /opt/cloudflare/config.yml | grep booxstream

# Tester l'accès au service BooxStream
curl http://192.168.1.202:3001/api/hosts

# Redémarrer si nécessaire
sudo systemctl restart cloudflared
```

### Sur la VM Linux (BooxStream)

```bash
# Vérifier que cloudflared est INACTIF
sudo systemctl status cloudflared
# Doit être "inactive (dead)"

# Vérifier que le service BooxStream est actif
sudo systemctl status booxstream-web

# Tester localement
curl http://localhost:3001/api/hosts
```

### Depuis Internet

```bash
# Tester BooxStream
curl https://booxstream.kevinvdb.dev/api/hosts

# Tester les autres services
curl https://kevinvdb.dev
curl https://affine.kevinvdb.dev
curl https://auth.kevinvdb.dev
```

## Avantages de cette architecture

✅ **Centralisation** : Un seul point de configuration  
✅ **Pas de conflit** : Un seul processus cloudflared  
✅ **Cohérence** : Toutes les routes au même endroit  
✅ **Isolation** : Services sur différentes VMs  
✅ **Maintenance simplifiée** : Modifications centralisées  

## Troubleshooting

### Si BooxStream retourne 404

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

5. **Redémarrer cloudflared sur le gateway** :
   ```bash
   sudo systemctl restart cloudflared
   sudo journalctl -u cloudflared -n 50 -f
   ```

### Si les autres services ne fonctionnent plus

1. **Vérifier que cloudflared est actif sur le gateway**
2. **Vérifier les logs** : `sudo journalctl -u cloudflared -n 50`
3. **Vérifier la configuration** : `cat /opt/cloudflare/config.yml`

