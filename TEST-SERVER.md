# Test du serveur BooxStream

## 1. Tester le serveur en local (depuis le serveur)

```bash
# Tester l'API HTTP
curl http://localhost:3001/api/hosts

# Tester l'interface web
curl http://localhost:3001/

# Vérifier que le serveur écoute sur les ports
sudo ss -tlnp | grep -E '3001|8080'
```

**Résultat attendu** :
- Port 3001 : Écoute (HTTP + WebSocket viewers)
- Port 8080 : Écoute (WebSocket Android)
- API répond avec `[]` ou une liste JSON

## 2. Tester depuis votre machine Windows

```powershell
# Depuis votre PC Windows
curl http://192.168.1.202:3001/api/hosts

# Ou ouvrir dans le navigateur
# http://192.168.1.202:3001/
```

## 3. Problème avec le domaine

### ❌ Erreur : `Could not resolve host: booxstreamkevinvdb.dev`

**Cause** :
1. Nom de domaine incorrect : il manque un **point**
   - ❌ `booxstreamkevinvdb.dev` (sans point)
   - ✅ `booxstream.kevinvdb.dev` (avec point)

2. Cloudflare Tunnel n'est pas encore configuré
   - Le DNS pointe vers Cloudflare, pas directement vers votre serveur
   - Le tunnel doit être actif pour que le domaine fonctionne

### ✅ Solution : Configurer Cloudflare Tunnel

```bash
# Sur le serveur
cd /opt/booxstream
chmod +x SETUP-CLOUDFLARE-TUNNEL.sh
./SETUP-CLOUDFLARE-TUNNEL.sh
```

Le script va :
1. Installer `cloudflared`
2. Vous authentifier (ouvrira votre navigateur)
3. Créer le tunnel
4. Configurer le DNS automatiquement
5. Démarrer le service

## 4. Après configuration Cloudflare Tunnel

### Tester depuis l'extérieur (depuis votre PC Windows)

```powershell
# Le domaine devrait maintenant fonctionner
curl https://booxstream.kevinvdb.dev/api/hosts

# Ou ouvrir dans le navigateur
# https://booxstream.kevinvdb.dev/
```

### Vérifier les logs du tunnel

```bash
# Sur le serveur
sudo journalctl -u cloudflared -f
```

Vous devriez voir des connexions entrantes.

## 5. Ordre des étapes

1. ✅ **Serveur fonctionne en local** (`http://localhost:3001`)
2. ✅ **Serveur accessible depuis votre réseau** (`http://192.168.1.202:3001`)
3. ⏳ **Configurer Cloudflare Tunnel** (`SETUP-CLOUDFLARE-TUNNEL.sh`)
4. ⏳ **Tester le domaine** (`https://booxstream.kevinvdb.dev`)
5. ⏳ **Configurer l'app Android** avec `https://booxstream.kevinvdb.dev`

