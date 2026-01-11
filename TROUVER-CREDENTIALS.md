# Comment trouver AccountTag et TunnelSecret

## ⚠️ Ces valeurs ne sont PAS dans la liste DNS

Les valeurs `AccountTag` et `TunnelSecret` sont des secrets qui ne sont **pas** affichés dans la liste DNS que vous avez montrée.

## Où les trouver dans Cloudflare Dashboard

### Méthode 1 : Depuis la page du tunnel

1. Allez dans **Zero Trust** → **Networks** → **Tunnels**
2. **Cliquez sur le tunnel `gateway-tunnel`** (pas juste voir la liste)
3. Dans la page de détails du tunnel, cherchez :
   - Section **"Credentials"** ou **"Configuration"**
   - Un bouton **"Download credentials"** ou **"View credentials"**
   - Ou un onglet **"Credentials"**

4. Vous devriez voir ou pouvoir télécharger un fichier JSON avec :
   - `AccountTag`
   - `TunnelSecret`
   - `TunnelID`
   - `Endpoint`

### Méthode 2 : Utiliser votre autre tunnel comme référence

Si vous avez déjà un tunnel qui fonctionne (comme celui sur votre serveur zabbix), vous pouvez :

1. **AccountTag** : C'est le **même pour tous vos tunnels** (c'est l'ID de votre compte Cloudflare)
   - Vous pouvez utiliser le même AccountTag que celui de votre autre tunnel
   - Exemple : Si votre autre tunnel a `AccountTag: "5156716ae56617783d9b69e9f5738ede"`, utilisez le même

2. **TunnelSecret** : C'est **unique pour chaque tunnel**
   - Vous **devez** obtenir celui spécifique pour `gateway-tunnel` depuis Cloudflare Dashboard
   - Il sera différent de celui de votre autre tunnel

### Méthode 3 : Régénérer les credentials

Si vous ne trouvez pas les credentials :

1. Dans la page du tunnel `gateway-tunnel`
2. Cherchez un bouton **"Regenerate credentials"** ou **"Reset credentials"**
3. Cela créera de nouvelles credentials que vous pourrez télécharger

## Format du fichier à créer

Une fois que vous avez les valeurs :

```bash
# Sur le serveur, en tant que kvdb
su - kvdb
mkdir -p ~/.cloudflared
cat > ~/.cloudflared/a40eeeac-5f83-4d51-9da2-67a0c9e0e975.json
```

Collez cette ligne (remplacez les valeurs) :
```json
{"AccountTag":"VOTRE_ACCOUNT_TAG","TunnelSecret":"VOTRE_TUNNEL_SECRET","TunnelID":"a40eeeac-5f83-4d51-9da2-67a0c9e0e975","Endpoint":""}
```

Puis `Ctrl+D`, puis :
```bash
chmod 600 ~/.cloudflared/a40eeeac-5f83-4d51-9da2-67a0c9e0e975.json
```

## Astuce

Si vous avez accès à votre autre serveur (zabbix) où le tunnel fonctionne, vous pouvez :

1. Voir le fichier credentials de l'autre tunnel :
   ```bash
   # Sur l'autre serveur
   cat /home/zabadehut/.cloudflared/2ff8a96d-3bbf-4415-9ca3-bc0a17533afe.json
   ```

2. Utiliser le **même AccountTag** pour le nouveau tunnel

3. Obtenir le **TunnelSecret spécifique** pour `gateway-tunnel` depuis Cloudflare Dashboard

