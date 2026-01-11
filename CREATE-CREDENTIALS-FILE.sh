#!/bin/bash
# Script pour créer le fichier credentials Cloudflare Tunnel

echo "=== Création du fichier credentials Cloudflare Tunnel ==="
echo ""

TUNNEL_ID="a40eeeac-5f83-4d51-9da2-67a0c9e0e975"
CREDENTIALS_FILE="$HOME/.cloudflared/$TUNNEL_ID.json"

echo "Tunnel ID: $TUNNEL_ID"
echo "Fichier: $CREDENTIALS_FILE"
echo ""

# Vérifier si le fichier existe déjà
if [ -f "$CREDENTIALS_FILE" ]; then
    echo "⚠ Le fichier existe déjà:"
    ls -la "$CREDENTIALS_FILE"
    echo ""
    read -p "Voulez-vous le remplacer? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Annulé."
        exit 0
    fi
fi

# Créer le répertoire si nécessaire
mkdir -p ~/.cloudflared

echo "Vous devez obtenir les valeurs suivantes depuis Cloudflare Dashboard:"
echo "  1. AccountTag"
echo "  2. TunnelSecret"
echo ""
echo "Allez dans: Zero Trust → Networks → Tunnels → gateway-tunnel"
echo "Section 'Credentials' ou 'Configuration'"
echo ""

read -p "AccountTag: " ACCOUNT_TAG
read -p "TunnelSecret: " TUNNEL_SECRET

if [ -z "$ACCOUNT_TAG" ] || [ -z "$TUNNEL_SECRET" ]; then
    echo "ERREUR: AccountTag et TunnelSecret sont requis"
    exit 1
fi

# Créer le fichier JSON
cat > "$CREDENTIALS_FILE" << EOF
{"AccountTag":"$ACCOUNT_TAG","TunnelSecret":"$TUNNEL_SECRET","TunnelID":"$TUNNEL_ID","Endpoint":""}
EOF

# Corriger les permissions
chmod 600 "$CREDENTIALS_FILE"

echo ""
echo "✓ Fichier créé: $CREDENTIALS_FILE"
echo ""
echo "Permissions:"
ls -la "$CREDENTIALS_FILE"
echo ""

# Vérifier le format JSON (si jq est disponible)
if command -v jq >/dev/null 2>&1; then
    echo "Vérification du format JSON:"
    if jq . "$CREDENTIALS_FILE" >/dev/null 2>&1; then
        echo "✓ Format JSON valide"
    else
        echo "⚠ Format JSON invalide"
    fi
fi

echo ""
echo "=== Fichier créé avec succès! ==="
echo ""
echo "Vous pouvez maintenant tester:"
echo "  cloudflared tunnel --config ~/.cloudflared/config.yml run"
echo ""
echo "Ou redémarrer le service:"
echo "  sudo systemctl restart cloudflared"
echo "  sudo systemctl status cloudflared"
echo ""

