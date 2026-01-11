#!/bin/bash
# Script pour mettre à jour la configuration Cloudflare Tunnel vers gateway-tunnel

echo "=== Mise à jour de la configuration Cloudflare Tunnel ==="
echo ""

# Tunnel ID gateway-tunnel
TUNNEL_ID="491bddf7-fbfa-4f8e-8e1f-417dccee4c17"
TUNNEL_NAME="gateway-tunnel"
USER=$(whoami)

echo "Tunnel ID: $TUNNEL_ID"
echo "Tunnel Name: $TUNNEL_NAME"
echo "User: $USER"
echo ""

# Vérifier que le fichier credentials existe
CREDENTIALS_FILE="/home/$USER/.cloudflared/$TUNNEL_ID.json"
if [ ! -f "$CREDENTIALS_FILE" ]; then
    echo "⚠ ATTENTION: Le fichier credentials n'existe pas: $CREDENTIALS_FILE"
    echo "   Vérifiez que vous avez les bonnes permissions pour ce tunnel."
    echo ""
    read -p "Continuer quand même? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Créer le répertoire si nécessaire
mkdir -p ~/.cloudflared

# Créer la nouvelle configuration
echo "Création de la nouvelle configuration..."
cat > ~/.cloudflared/config.yml << EOF
tunnel: $TUNNEL_ID
credentials-file: $CREDENTIALS_FILE

ingress:
  # Interface web + WebSocket (port 3001)
  - hostname: booxstream.kevinvdb.dev
    service: http://localhost:3001
  
  # Catch-all
  - service: http_status:404
EOF

echo "✓ Configuration créée: ~/.cloudflared/config.yml"
echo ""

# Afficher la configuration
echo "Configuration actuelle:"
cat ~/.cloudflared/config.yml
echo ""

# Redémarrer le service cloudflared
echo "Redémarrage du service cloudflared..."
sudo systemctl restart cloudflared
sleep 2

echo ""
echo "Statut du service:"
sudo systemctl status cloudflared --no-pager -l | head -20

echo ""
echo "=== Mise à jour terminée! ==="
echo ""
echo "Pour voir les logs en temps réel:"
echo "  sudo journalctl -u cloudflared -f"
echo ""
echo "Pour tester l'accès:"
echo "  curl https://booxstream.kevinvdb.dev/api/hosts"
echo ""

