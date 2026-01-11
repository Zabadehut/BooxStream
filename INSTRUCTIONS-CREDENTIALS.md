# Instructions pour obtenir les credentials

## Je n'ai pas vos valeurs AccountTag et TunnelSecret

Ces valeurs sont spécifiques à votre compte Cloudflare et doivent être obtenues depuis le Dashboard.

## Comment obtenir les valeurs

### Méthode 1 : Depuis Cloudflare Zero Trust Dashboard

1. Allez sur https://one.dash.cloudflare.com/
2. **Zero Trust** → **Networks** → **Tunnels**
3. Cliquez sur le tunnel **gateway-tunnel**
4. Dans la section **"Credentials"** ou **"Configuration"**, vous devriez voir :
   - **AccountTag** : une chaîne hexadécimale (ex: `5156716ae56617783d9b69e9f5738ede`)
   - **TunnelSecret** : une chaîne base64 (ex: `/Mb9hhTBSBgy2hJA3stM7m51e87PyVRgZEh7ntp0tiY=`)

### Méthode 2 : Si vous avez déjà un tunnel qui fonctionne

Si vous avez un autre tunnel qui fonctionne (comme celui sur votre serveur zabbix), vous pouvez :

1. **AccountTag** : C'est le même pour tous vos tunnels (c'est l'ID de votre compte Cloudflare)
   - Vous pouvez utiliser le même AccountTag que celui de votre autre tunnel

2. **TunnelSecret** : C'est unique pour chaque tunnel
   - Vous devez obtenir celui spécifique pour `gateway-tunnel` depuis Cloudflare Dashboard

### Méthode 3 : Utiliser cloudflared CLI

Si vous avez les permissions, essayez :

```bash
# Sur le serveur, en tant que kvdb
cloudflared tunnel info gateway-tunnel
```

Cela peut afficher certaines informations, mais pas nécessairement le TunnelSecret complet.

## Format du fichier

Une fois que vous avez les valeurs, créez le fichier :

```bash
cat > ~/.cloudflared/a40eeeac-5f83-4d51-9da2-67a0c9e0e975.json
{"AccountTag":"VOTRE_ACCOUNT_TAG","TunnelSecret":"VOTRE_TUNNEL_SECRET","TunnelID":"a40eeeac-5f83-4d51-9da2-67a0c9e0e975","Endpoint":""}
```

Remplacez :
- `VOTRE_ACCOUNT_TAG` par la valeur depuis Cloudflare
- `VOTRE_TUNNEL_SECRET` par la valeur depuis Cloudflare

## Exemple avec votre autre tunnel

D'après votre exemple précédent, votre AccountTag pourrait être similaire à celui de votre autre tunnel. Mais le TunnelSecret sera différent.

Si vous pouvez me donner les valeurs depuis Cloudflare Dashboard, je peux créer le fichier complet pour vous.

