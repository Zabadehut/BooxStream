# Fix Tunnel Credentials - gateway-tunnel

## Problème
Le fichier credentials pour le tunnel `gateway-tunnel` (ID: `491bddf7-fbfa-4f8e-8e1f-417dccee4c17`) n'existe pas sur le serveur.

## Solutions

### Solution 1 : Vérifier les fichiers existants

```bash
# Lister tous les fichiers credentials
ls -la ~/.cloudflared/*.json

# Lister les tunnels disponibles
cloudflared tunnel list
```

### Solution 2 : Si le tunnel existe mais pas le fichier credentials

Le fichier credentials doit être présent pour que le tunnel fonctionne. Il y a plusieurs possibilités :

#### Option A : Le fichier est ailleurs

Si vous avez configuré le tunnel depuis un autre serveur ou machine, vous devez copier le fichier credentials :

```bash
# Depuis la machine où le tunnel a été créé
scp ~/.cloudflared/491bddf7-fbfa-4f8e-8e1f-417dccee4c17.json kvdb@192.168.1.202:~/.cloudflared/
```

#### Option B : Ré-authentifier avec le tunnel spécifique

Si le tunnel `gateway-tunnel` existe dans votre compte Cloudflare mais que le fichier credentials n'est pas sur ce serveur :

```bash
# 1. S'authentifier (si pas déjà fait)
cloudflared tunnel login

# 2. Vérifier que le tunnel est listé
cloudflared tunnel list

# 3. Si le tunnel apparaît dans la liste mais pas le fichier, il faut peut-être
#    utiliser cloudflared tunnel run avec le nom du tunnel
cloudflared tunnel run gateway-tunnel
```

**Note** : Si vous utilisez Cloudflare Zero Trust Dashboard, les credentials peuvent être gérés différemment.

### Solution 3 : Utiliser le tunnel existant avec credentials

Si vous avez un autre tunnel avec des credentials valides, vous pouvez :

1. **Utiliser l'ancien tunnel** (si il fonctionne) :
   ```bash
   # Garder la configuration actuelle avec a40eeeac-5f83-4d51-9da2-67a0c9e0e975
   # Mais vérifier qu'il route correctement vers localhost:3001
   ```

2. **Ou créer une nouvelle route DNS** pour le tunnel existant :
   ```bash
   # Si vous avez un tunnel qui fonctionne déjà
   cloudflared tunnel route dns <tunnel-name> booxstream.kevinvdb.dev
   ```

### Solution 4 : Vérifier dans Cloudflare Dashboard

1. Allez dans **Zero Trust** → **Networks** → **Tunnels**
2. Cliquez sur le tunnel `gateway-tunnel`
3. Vérifiez la configuration et les credentials
4. Si nécessaire, téléchargez ou régénérez les credentials

## Configuration recommandée

Une fois que vous avez le bon fichier credentials, mettez à jour la configuration :

```bash
cat > ~/.cloudflared/config.yml << 'EOF'
tunnel: 491bddf7-fbfa-4f8e-8e1f-417dccee4c17
credentials-file: /home/kvdb/.cloudflared/491bddf7-fbfa-4f8e-8e1f-417dccee4c17.json

ingress:
  - hostname: booxstream.kevinvdb.dev
    service: http://localhost:3001
  
  - service: http_status:404
EOF

# Redémarrer le service
sudo systemctl restart cloudflared
sudo systemctl status cloudflared
```

## Vérification

```bash
# Vérifier que le service fonctionne
sudo systemctl status cloudflared

# Voir les logs
sudo journalctl -u cloudflared -f

# Tester l'accès
curl https://booxstream.kevinvdb.dev/api/hosts
```

## Alternative : Utiliser le tunnel existant

Si obtenir les credentials pour `gateway-tunnel` est compliqué, vous pouvez continuer à utiliser le tunnel `a40eeeac-5f83-4d51-9da2-67a0c9e0e975` mais vérifier qu'il route correctement :

```bash
# Vérifier que le tunnel fonctionne
sudo systemctl status cloudflared

# Vérifier les logs pour voir s'il y a des erreurs
sudo journalctl -u cloudflared -n 100

# Vérifier que le serveur local répond
curl http://localhost:3001/api/hosts
```

