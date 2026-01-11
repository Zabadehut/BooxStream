#!/bin/bash
# Script d'installation Cloudflare Tunnel pour BooxStream
# Usage: ./SETUP-CLOUDFLARE-TUNNEL.sh

set -e

echo "=== Installation Cloudflare Tunnel pour BooxStream ==="
echo ""

# 1. Installer cloudflared
echo "1. Installation de cloudflared..."
cd /tmp
if [ ! -f "cloudflared-linux-amd64" ]; then
    wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
fi
sudo mv cloudflared-linux-amd64 /usr/local/bin/cloudflared
sudo chmod +x /usr/local/bin/cloudflared

echo "   Version installée:"
cloudflared --version
echo ""

# 2. Authentifier
echo "2. Authentification Cloudflare..."
echo "   Une fenêtre de navigateur va s'ouvrir pour vous connecter."
cloudflared tunnel login
echo ""

# 3. Créer le tunnel
echo "3. Création du tunnel..."
TUNNEL_NAME="booxstream"
cloudflared tunnel create $TUNNEL_NAME

# Récupérer le Tunnel ID
TUNNEL_ID=$(cloudflared tunnel list | grep $TUNNEL_NAME | awk '{print $1}')
echo "   Tunnel ID: $TUNNEL_ID"
echo ""

# 4. Créer la configuration
echo "4. Création de la configuration..."
mkdir -p ~/.cloudflared

cat > ~/.cloudflared/config.yml << EOF
tunnel: $TUNNEL_ID
credentials-file: /home/$USER/.cloudflared/$TUNNEL_ID.json

ingress:
  # Interface web + WebSocket (port 3001)
  - hostname: booxstream.kevinvdb.dev
    service: http://localhost:3001
  
  # Catch-all
  - service: http_status:404
EOF

echo "   Configuration créée: ~/.cloudflared/config.yml"
echo ""

# 5. Configurer le DNS
echo "5. Configuration DNS..."
cloudflared tunnel route dns $TUNNEL_NAME booxstream.kevinvdb.dev
echo "   DNS configuré pour booxstream.kevinvdb.dev"
echo ""

# 6. Créer le service systemd
echo "6. Création du service systemd..."
sudo tee /etc/systemd/system/cloudflared.service > /dev/null << EOF
[Unit]
Description=Cloudflare Tunnel
After=network.target

[Service]
Type=simple
User=$USER
ExecStart=/usr/local/bin/cloudflared tunnel --config /home/$USER/.cloudflared/config.yml run
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable cloudflared
sudo systemctl start cloudflared

echo "   Service créé et démarré"
echo ""

# 7. Afficher le statut
echo "7. Statut du service:"
sudo systemctl status cloudflared --no-pager -l | head -20
echo ""

echo "=== Installation terminée! ==="
echo ""
echo "Pour voir les logs en temps réel:"
echo "  sudo journalctl -u cloudflared -f"
echo ""
echo "Pour tester l'accès:"
echo "  curl https://booxstream.kevinvdb.dev/api/hosts"
echo ""
echo "Note: L'application Android utilisera automatiquement"
echo "      wss://booxstream.kevinvdb.dev/android-ws pour le WebSocket"

