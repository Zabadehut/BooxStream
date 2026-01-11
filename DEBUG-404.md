# Debug erreur 404 - Cloudflare Tunnel

## Symptôme
```
GET https://booxstream.kevinvdb.dev/ net::ERR_HTTP_RESPONSE_CODE_FAILURE 404
```

Le tunnel Cloudflare répond mais retourne 404, ce qui signifie que le tunnel ne route pas correctement vers le serveur local.

## Vérifications à faire sur le serveur

### 1. Vérifier que le serveur local fonctionne

```bash
# Tester le serveur local
curl http://localhost:3001/api/hosts

# Vérifier le service
sudo systemctl status booxstream-web

# Voir les logs
sudo journalctl -u booxstream-web -n 50
```

**Résultat attendu** : Le serveur doit retourner `[]` ou une liste JSON d'hôtes.

### 2. Vérifier que cloudflared est actif

```bash
sudo systemctl status cloudflared
```

**Résultat attendu** : `active (running)`

Si ce n'est pas le cas :
```bash
sudo systemctl restart cloudflared
sudo systemctl status cloudflared
```

### 3. Vérifier les logs du tunnel

```bash
sudo journalctl -u cloudflared -n 100 --no-pager
```

**Rechercher** :
- Erreurs de connexion à `localhost:3001`
- Messages indiquant que le tunnel est connecté
- Messages d'erreur spécifiques comme "connection refused" ou "no route to host"

### 4. Vérifier la configuration du tunnel

```bash
cat ~/.cloudflared/config.yml
```

**Configuration attendue** :
```yaml
tunnel: a40eeeac-5f83-4d51-9da2-67a0c9e0e975
credentials-file: /home/kvdb/.cloudflared/a40eeeac-5f83-4d51-9da2-67a0c9e0e975.json

ingress:
  - hostname: booxstream.kevinvdb.dev
    service: http://localhost:3001
  
  - service: http_status:404
```

### 5. Vérifier que le fichier credentials existe

```bash
ls -la ~/.cloudflared/a40eeeac-5f83-4d51-9da2-67a0c9e0e975.json
cat ~/.cloudflared/a40eeeac-5f83-4d51-9da2-67a0c9e0e975.json
```

### 6. Tester le tunnel manuellement

```bash
# Arrêter le service
sudo systemctl stop cloudflared

# Tester manuellement (en tant que kvdb)
su - kvdb
cloudflared tunnel --config ~/.cloudflared/config.yml run
```

Cela affichera les erreurs en temps réel.

## Solutions courantes

### Problème 1 : Le serveur local ne répond pas

```bash
# Vérifier que le port 3001 écoute
sudo ss -tlnp | grep 3001

# Redémarrer le service
sudo systemctl restart booxstream-web
sudo systemctl status booxstream-web
```

### Problème 2 : Le tunnel ne peut pas se connecter au serveur local

Vérifiez que le service cloudflared s'exécute avec le bon utilisateur (`kvdb`) et peut accéder à `localhost:3001`.

### Problème 3 : Configuration incorrecte

Vérifiez que `service: http://localhost:3001` est correct dans `config.yml`.

### Problème 4 : Le tunnel n'est pas connecté à Cloudflare

Vérifiez dans les logs si le tunnel est bien connecté. Vous devriez voir des messages comme :
```
INF +--------------------------------------------------------------------------------------------+
INF |  Your quick Tunnel has been created! Visit it at: https://booxstream.kevinvdb.dev         |
INF +--------------------------------------------------------------------------------------------+
```

## Commande de test complète

```bash
# 1. Vérifier le serveur local
curl http://localhost:3001/api/hosts

# 2. Vérifier cloudflared
sudo systemctl status cloudflared

# 3. Voir les logs
sudo journalctl -u cloudflared -n 100 --no-pager

# 4. Tester depuis l'extérieur
curl https://booxstream.kevinvdb.dev/api/hosts
```

