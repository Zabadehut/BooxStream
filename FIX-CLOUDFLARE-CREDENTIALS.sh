#!/bin/bash
# Script pour corriger les credentials Cloudflare Tunnel

echo "=== Correction des credentials Cloudflare Tunnel ==="
echo ""

TUNNEL_ID="a40eeeac-5f83-4d51-9da2-67a0c9e0e975"
TUNNEL_NAME="gateway-tunnel"
USER=$(whoami)
CREDENTIALS_FILE="/home/$USER/.cloudflared/$TUNNEL_ID.json"

echo "Tunnel ID: $TUNNEL_ID"
echo "Tunnel Name: $TUNNEL_NAME"
echo "Credentials file: $CREDENTIALS_FILE"
echo ""

# Vérifier si le fichier existe
if [ -f "$CREDENTIALS_FILE" ]; then
    echo "✓ Le fichier credentials existe déjà"
    ls -la "$CREDENTIALS_FILE"
    exit 0
fi

echo "⚠ Le fichier credentials n'existe pas: $CREDENTIALS_FILE"
echo ""

# Option 1: Vérifier si on peut obtenir le token depuis Cloudflare
echo "Option 1: Générer un token depuis Cloudflare Dashboard"
echo ""
echo "1. Allez dans Cloudflare Zero Trust Dashboard:"
echo "   https://one.dash.cloudflare.com/"
echo ""
echo "2. Networks → Tunnels → gateway-tunnel"
echo ""
echo "3. Cliquez sur 'Configure' puis 'Create a tunnel token'"
echo ""
echo "4. Copiez le token et exécutez:"
echo "   cloudflared service install <TOKEN>"
echo ""
echo "OU"
echo ""
echo "Option 2: Télécharger le fichier credentials depuis le Dashboard"
echo ""
echo "1. Dans le tunnel gateway-tunnel, section 'Credentials'"
echo "2. Téléchargez le fichier JSON"
echo "3. Copiez-le sur le serveur:"
echo "   scp credentials.json kvdb@192.168.1.202:~/.cloudflared/$TUNNEL_ID.json"
echo ""
echo "OU"
echo ""
echo "Option 3: Utiliser cloudflared tunnel token (si disponible)"
echo ""
echo "Essayons de générer un token..."
echo ""

# Essayer de générer un token
if command -v cloudflared >/dev/null 2>&1; then
    echo "Tentative de génération d'un token pour le tunnel..."
    echo "Note: Cela nécessite les permissions appropriées dans Cloudflare"
    
    # Afficher les informations du tunnel
    echo ""
    echo "Informations du tunnel:"
    cloudflared tunnel info $TUNNEL_NAME 2>&1 || cloudflared tunnel info $TUNNEL_ID 2>&1
    
    echo ""
    echo "Pour créer un token, utilisez Cloudflare Dashboard ou:"
    echo "  cloudflared tunnel token <TUNNEL_NAME_OR_ID>"
    echo ""
fi

echo ""
echo "=== Instructions ==="
echo ""
echo "Une fois que vous avez le fichier credentials, placez-le ici:"
echo "  $CREDENTIALS_FILE"
echo ""
echo "Puis redémarrez le service:"
echo "  sudo systemctl restart cloudflared"
echo "  sudo systemctl status cloudflared"
echo ""

