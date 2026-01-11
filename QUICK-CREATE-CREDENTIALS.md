# Création rapide du fichier credentials

## Le fichier n'existe pas encore

Vous devez créer le fichier `/home/kvdb/.cloudflared/a40eeeac-5f83-4d51-9da2-67a0c9e0e975.json`

## Méthode rapide

### 1. Sur le serveur, exécutez :

```bash
cat > ~/.cloudflared/a40eeeac-5f83-4d51-9da2-67a0c9e0e975.json
```

### 2. Collez cette ligne (UNE SEULE LIGNE) :

```json
{"AccountTag":"VOTRE_ACCOUNT_TAG","TunnelSecret":"VOTRE_TUNNEL_SECRET","TunnelID":"a40eeeac-5f83-4d51-9da2-67a0c9e0e975","Endpoint":""}
```

**Remplacez** :
- `VOTRE_ACCOUNT_TAG` par la valeur depuis Cloudflare Dashboard
- `VOTRE_TUNNEL_SECRET` par la valeur depuis Cloudflare Dashboard

### 3. Appuyez sur `Ctrl+D` pour terminer

### 4. Corriger les permissions :

```bash
chmod 600 ~/.cloudflared/a40eeeac-5f83-4d51-9da2-67a0c9e0e975.json
```

### 5. Vérifier :

```bash
ls -la ~/.cloudflared/a40eeeac-5f83-4d51-9da2-67a0c9e0e975.json
cat ~/.cloudflared/a40eeeac-5f83-4d51-9da2-67a0c9e0e975.json
```

### 6. Redémarrer le service :

```bash
sudo systemctl restart cloudflared
sudo systemctl status cloudflared
```

## Où obtenir les valeurs ?

1. Allez dans **Cloudflare Zero Trust Dashboard**
   - https://one.dash.cloudflare.com/
   
2. **Networks** → **Tunnels** → **gateway-tunnel**

3. Section **"Credentials"** ou **"Configuration"**

4. Vous devriez voir :
   - `AccountTag` : une chaîne hexadécimale (ex: `5156716ae56617783d9b69e9f5738ede`)
   - `TunnelSecret` : une chaîne base64 (ex: `/Mb9hhTBSBgy2hJA3stM7m51e87PyVRgZEh7ntp0tiY=`)

5. Copiez ces deux valeurs et remplacez-les dans la ligne JSON ci-dessus

## Exemple complet

Si vous avez :
- AccountTag: `5156716ae56617783d9b69e9f5738ede`
- TunnelSecret: `/Mb9hhTBSBgy2hJA3stM7m51e87PyVRgZEh7ntp0tiY=`

La ligne complète sera :
```json
{"AccountTag":"5156716ae56617783d9b69e9f5738ede","TunnelSecret":"/Mb9hhTBSBgy2hJA3stM7m51e87PyVRgZEh7ntp0tiY=","TunnelID":"a40eeeac-5f83-4d51-9da2-67a0c9e0e975","Endpoint":""}
```

## Alternative : Utiliser vi

Si `cat` ne fonctionne pas, utilisez `vi` :

```bash
vi ~/.cloudflared/a40eeeac-5f83-4d51-9da2-67a0c9e0e975.json
```

- Appuyez sur `i` pour entrer en mode insertion
- Collez la ligne JSON complète
- Appuyez sur `Esc`
- Tapez `:wq` et appuyez sur `Enter` pour sauvegarder

