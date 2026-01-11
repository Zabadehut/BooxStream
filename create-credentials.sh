#!/bin/bash
# Script pour créer le fichier credentials Cloudflare Tunnel

TUNNEL_ID="a40eeeac-5f83-4d51-9da2-67a0c9e0e975"
CREDENTIALS_FILE="$HOME/.cloudflared/$TUNNEL_ID.json"

echo "=== Création du fichier credentials ==="
echo ""
echo "Tunnel ID: $TUNNEL_ID"
echo "Fichier: $CREDENTIALS_FILE"
echo ""
echo "Vous devez obtenir AccountTag et TunnelSecret depuis Cloudflare Dashboard:"
echo "  Zero Trust → Networks → Tunnels → gateway-tunnel → Credentials"
echo ""

read -p "AccountTag: " ACCOUNT_TAG
read -p "TunnelSecret: " TUNNEL_SECRET

if [ -z "$ACCOUNT_TAG" ] || [ -z "$TUNNEL_SECRET" ]; then
    echo "ERREUR: AccountTag et TunnelSecret sont requis"
    exit 1
fi

# Créer le répertoire si nécessaire
mkdir -p ~/.cloudflared

# Créer le fichier JSON (format une seule ligne comme l'exemple)
cat > "$CREDENTIALS_FILE" << EOF
{"AccountTag":"$ACCOUNT_TAG","TunnelSecret":"$TUNNEL_SECRET","TunnelID":"$TUNNEL_ID","Endpoint":""}
EOF

# Corriger les permissions
chmod 600 "$CREDENTIALS_FILE"

echo ""
echo "✓ Fichier créé: $CREDENTIALS_FILE"
echo ""
echo "Vérification:"
ls -la "$CREDENTIALS_FILE"
echo ""
echo "Contenu:"
cat "$CREDENTIALS_FILE"
echo ""
echo "=== Fichier créé avec succès! ==="
echo ""
echo "Vous pouvez maintenant:"
echo "  sudo systemctl restart cloudflared"
echo "  sudo systemctl status cloudflared"

