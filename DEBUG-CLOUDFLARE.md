# Debug Cloudflare Tunnel - Erreur 404

## Symptôme
```
curl https://booxstream.kevinvdb.dev/api/hosts
HTTP/2 404
server: cloudflare
```

Le tunnel Cloudflare répond mais retourne 404, ce qui signifie que le tunnel ne route pas correctement vers le serveur local.

## Vérifications à faire sur le serveur

### 1. Vérifier que le serveur local fonctionne

```bash
curl http://localhost:3001/api/hosts
```

**Résultat attendu** : `[]` ou une liste JSON d'hôtes

Si ça ne fonctionne pas, vérifier le service :
```bash
sudo systemctl status booxstream-web
sudo journalctl -u booxstream-web -n 50
```

### 2. Vérifier que cloudflared est actif

```bash
sudo systemctl status cloudflared
```

**Résultat attendu** : `active (running)`

### 3. Vérifier la configuration du tunnel

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

### 4. Vérifier les logs du tunnel

```bash
sudo journalctl -u cloudflared -f
```

**Rechercher** :
- Erreurs de connexion à `localhost:3001`
- Messages indiquant que le tunnel est connecté
- Messages d'erreur spécifiques

### 5. Vérifier que le fichier credentials existe

```bash
ls -la ~/.cloudflared/*.json
```

**Résultat attendu** : Un fichier avec le Tunnel ID dans le nom

### 6. Tester le tunnel manuellement

```bash
# Arrêter le service
sudo systemctl stop cloudflared

# Tester manuellement
cloudflared tunnel --config ~/.cloudflared/config.yml run
```

Cela affichera les erreurs en temps réel.

## Solutions courantes

### Problème 1 : Le service cloudflared n'est pas démarré

```bash
sudo systemctl start cloudflared
sudo systemctl enable cloudflared
sudo systemctl status cloudflared
```

### Problème 2 : Configuration incorrecte

Vérifier que `service: http://localhost:3001` est correct et que le serveur écoute bien sur ce port :

```bash
sudo ss -tlnp | grep 3001
```

### Problème 3 : Fichier credentials manquant

Si le fichier `.json` n'existe pas, il faut ré-authentifier :

```bash
cloudflared tunnel login
```

Puis vérifier que le fichier existe :
```bash
ls -la ~/.cloudflared/a40eeeac-5f83-4d51-9da2-67a0c9e0e975.json
```

### Problème 4 : Le tunnel n'est pas connecté

Vérifier dans les logs si le tunnel est bien connecté à Cloudflare. Vous devriez voir des messages comme :
```
INF +--------------------------------------------------------------------------------------------+
INF |  Your quick Tunnel has been created! Visit it at: https://booxstream.kevinvdb.dev         |
INF +--------------------------------------------------------------------------------------------+
```

### Problème 5 : Port 3001 non accessible

Vérifier que le service booxstream-web écoute bien sur le port 3001 :

```bash
sudo netstat -tlnp | grep 3001
# ou
sudo ss -tlnp | grep 3001
```

## Commande de test complète

```bash
# 1. Vérifier le serveur local
curl http://localhost:3001/api/hosts

# 2. Vérifier cloudflared
sudo systemctl status cloudflared

# 3. Vérifier la config
cat ~/.cloudflared/config.yml

# 4. Voir les logs
sudo journalctl -u cloudflared -n 100 --no-pager

# 5. Redémarrer si nécessaire
sudo systemctl restart cloudflared
sudo systemctl status cloudflared
```

