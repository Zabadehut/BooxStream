# Comment obtenir les credentials Cloudflare Tunnel

## ⚠️ Les credentials ne sont PAS dans les "Informations de base"

Les valeurs `AccountTag` et `TunnelSecret` sont dans une section séparée appelée **"Credentials"**.

## Où les trouver dans Cloudflare Dashboard

### Sur la page du tunnel `gateway-tunnel` :

1. **Cherchez un onglet "Credentials"** en haut de la page
2. **Ou une section "Credentials"** dans le menu latéral
3. **Ou un bouton "Download credentials" / "View credentials"**
4. **Ou dans "Configuration" → "Credentials"**

### Si vous ne trouvez pas la section Credentials :

1. **Régénérer les credentials** :
   - Cherchez un bouton **"Regenerate credentials"** ou **"Reset credentials"**
   - Cela créera de nouvelles credentials que vous pourrez télécharger

2. **Ou utiliser cloudflared CLI** :
   ```bash
   # Sur le serveur, en tant que kvdb
   cloudflared tunnel token gateway-tunnel
   ```
   Cela peut générer un token si vous avez les permissions.

## Le tunnel fonctionne déjà !

Le tunnel est **"Sain"** depuis 15 heures, ce qui signifie qu'il y a **déjà un connecteur qui fonctionne** quelque part (probablement sur un autre serveur).

Pour ajouter un **nouveau connecteur** sur votre serveur Rocky Linux, vous avez besoin des credentials.

## Solution alternative : Utiliser le même connecteur

Si le tunnel fonctionne déjà avec un connecteur, vous pourriez :

1. **Arrêter le connecteur existant** (si vous savez où il est)
2. **Démarrer le nouveau connecteur** sur votre serveur Rocky Linux

Mais pour cela, vous avez toujours besoin des credentials.

## Format du fichier credentials

Une fois que vous avez les valeurs, créez le fichier :

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

Si vous avez accès au serveur où le tunnel fonctionne actuellement, vous pouvez copier le fichier credentials depuis là :

```bash
# Sur l'autre serveur où le tunnel fonctionne
cat ~/.cloudflared/a40eeeac-5f83-4d51-9da2-67a0c9e0e975.json

# Copiez le contenu et créez le même fichier sur le nouveau serveur
```

