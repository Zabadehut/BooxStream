# Comparaison des architectures : Gateway centralisé vs Tunnels séparés

## Architecture actuelle d'Affine

Affine a son **propre tunnel Cloudflare** sur le serveur où il tourne :

```
Serveur Affine:
  - Tunnel ID: 10c995f5-985d-4ce3-91f5-ca90b1bd1341
  - Config: /etc/cloudflared/config.yml
  - Route: affine.kevinvdb.dev → http://affine_server:3010
  - cloudflared ACTIF sur ce serveur
```

## Deux architectures possibles pour BooxStream

### Option 1 : Tunnel séparé (comme Affine) ⭐ RECOMMANDÉ

**Architecture** :
```
VM Linux (BooxStream - 192.168.1.202):
  - Tunnel ID: NOUVEAU_TUNNEL_ID (à créer)
  - Config: ~/.cloudflared/config.yml
  - Route: booxstream.kevinvdb.dev → http://localhost:3001
  - cloudflared ACTIF sur cette VM
```

**Avantages** :
- ✅ Cohérent avec Affine
- ✅ Isolation complète
- ✅ Chaque service gère son propre tunnel
- ✅ Pas de conflit avec le gateway

**Inconvénients** :
- ❌ Plus de tunnels à gérer
- ❌ Nécessite de créer un nouveau tunnel dans Cloudflare

### Option 2 : Via Gateway (actuel)

**Architecture** :
```
VM Gateway:
  - Tunnel ID: a40eeeac-5f83-4d51-9da2-67a0c9e0e975
  - Config: /opt/cloudflare/config.yml
  - Route: booxstream.kevinvdb.dev → http://192.168.1.202:3001
  - cloudflared ACTIF sur le gateway

VM Linux (BooxStream):
  - cloudflared INACTIF
```

**Avantages** :
- ✅ Un seul tunnel à gérer
- ✅ Configuration centralisée

**Inconvénients** :
- ❌ Incohérent avec Affine
- ❌ Dépendance au gateway

## Configuration : Tunnel séparé pour BooxStream (comme Affine)

### Étape 1 : Créer un nouveau tunnel dans Cloudflare

1. Allez dans Cloudflare Dashboard → Zero Trust → Networks → Tunnels
2. Créez un nouveau tunnel : "booxstream-tunnel"
3. Notez le **Tunnel ID** (ex: `xxxx-xxxx-xxxx-xxxx`)
4. Notez l'**Account Tag** et le **Tunnel Secret**

### Étape 2 : Créer le fichier credentials sur la VM Linux

Sur la VM Linux (`192.168.1.202`), créez :

```bash
mkdir -p ~/.cloudflared
cat > ~/.cloudflared/BOOXSTREAM_TUNNEL_ID.json << EOF
{"AccountTag":"VOTRE_ACCOUNT_TAG","TunnelSecret":"VOTRE_TUNNEL_SECRET","TunnelID":"BOOXSTREAM_TUNNEL_ID","Endpoint":""}
EOF

chmod 600 ~/.cloudflared/BOOXSTREAM_TUNNEL_ID.json
```

### Étape 3 : Créer la configuration cloudflared

```bash
cat > ~/.cloudflared/config.yml << EOF
tunnel: BOOXSTREAM_TUNNEL_ID
credentials-file: /home/kvdb/.cloudflared/BOOXSTREAM_TUNNEL_ID.json

ingress:
  - hostname: booxstream.kevinvdb.dev
    service: http://localhost:3001
  - service: http_status:404

loglevel: info
no-autoupdate: true
EOF
```

### Étape 4 : Créer l'enregistrement DNS dans Cloudflare

Dans Cloudflare Dashboard → DNS → Records :

- **Type** : `CNAME`
- **Name** : `booxstream`
- **Target** : `BOOXSTREAM_TUNNEL_ID.cfargotunnel.com`
- **Proxy** : ✅ Proxied (orange cloud)

OU via ligne de commande :

```bash
cloudflared tunnel route dns booxstream booxstream.kevinvdb.dev
```

### Étape 5 : Créer le service systemd

```bash
sudo tee /etc/systemd/system/cloudflared-booxstream.service << EOF
[Unit]
Description=Cloudflare Tunnel for BooxStream
After=network.target

[Service]
Type=simple
User=kvdb
ExecStart=/usr/local/bin/cloudflared tunnel --config /home/kvdb/.cloudflared/config.yml run
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable cloudflared-booxstream
sudo systemctl start cloudflared-booxstream
sudo systemctl status cloudflared-booxstream
```

### Étape 6 : Retirer la route du gateway

Dans `/opt/cloudflare/config.yml` sur le gateway, **retirez** :

```yaml
# À RETIRER :
# - hostname: booxstream.kevinvdb.dev
#   service: http://192.168.1.202:3001
```

Puis redémarrez cloudflared sur le gateway :

```bash
sudo systemctl restart cloudflared
```

## Comparaison finale

| Aspect | Tunnel séparé (Affine) | Via Gateway |
|--------|------------------------|-------------|
| **Cohérence avec Affine** | ✅ Oui | ❌ Non |
| **Isolation** | ✅ Complète | ❌ Dépend du gateway |
| **Complexité** | Plus de tunnels | Un seul tunnel |
| **Maintenance** | Par service | Centralisée |

## Recommandation

**Pour être cohérent avec Affine** : Utilisez un tunnel séparé pour BooxStream.

Cela donne :
- Affine : Tunnel `10c995f5...` sur son serveur
- BooxStream : Tunnel `xxxx-xxxx...` sur la VM Linux
- Gateway : Tunnel `a40eeeac...` pour les autres services (traefik, auth, etc.)

Chaque service est indépendant et isolé.

