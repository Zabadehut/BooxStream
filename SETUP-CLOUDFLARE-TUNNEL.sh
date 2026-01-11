#!/bin/bash
# Script d'installation Cloudflare Tunnel pour BooxStream
# Usage: ./SETUP-CLOUDFLARE-TUNNEL.sh

set -e

echo "=== Configuration Cloudflare Tunnel pour BooxStream ==="
echo ""

# 1. Installer cloudflared (si pas déjà installé)
echo "1. Vérification de cloudflared..."
if ! command -v cloudflared >/dev/null 2>&1; then
    echo "   Installation de cloudflared..."
    cd /tmp
    if [ ! -f "cloudflared-linux-amd64" ]; then
        wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
    fi
    sudo mv cloudflared-linux-amd64 /usr/local/bin/cloudflared
    sudo chmod +x /usr/local/bin/cloudflared
else
    echo "   cloudflared déjà installé"
fi

echo "   Version:"
cloudflared --version
echo ""

# 2. Authentifier (si pas déjà authentifié)
echo "2. Vérification de l'authentification..."
if [ ! -f ~/.cloudflared/cert.pem ]; then
    echo "   Authentification Cloudflare..."
    echo "   Une fenêtre de navigateur va s'ouvrir pour vous connecter."
    cloudflared tunnel login
else
    echo "   Déjà authentifié"
fi
echo ""

# 3. Utiliser le tunnel existant ou permettre la sélection
echo "3. Sélection du tunnel..."

# Tunnel ID existant (peut être modifié)
EXISTING_TUNNEL_ID="a40eeeac-5f83-4d51-9da2-67a0c9e0e975"

# Vérifier si le tunnel existe
TUNNEL_EXISTS=$(cloudflared tunnel list 2>/dev/null | grep -q "$EXISTING_TUNNEL_ID" && echo "yes" || echo "no")

if [ "$TUNNEL_EXISTS" = "yes" ]; then
    echo "   Utilisation du tunnel existant: $EXISTING_TUNNEL_ID"
    TUNNEL_ID="$EXISTING_TUNNEL_ID"
    TUNNEL_NAME=$(cloudflared tunnel list 2>/dev/null | grep "$EXISTING_TUNNEL_ID" | awk '{print $2}')
    if [ -z "$TUNNEL_NAME" ]; then
        TUNNEL_NAME="booxstream"
    fi
else
    echo "   Tunnel $EXISTING_TUNNEL_ID non trouvé."
    echo "   Liste des tunnels disponibles:"
    TUNNELS=$(cloudflared tunnel list 2>/dev/null | tail -n +2 || echo "")
    
    if [ -z "$TUNNELS" ]; then
        echo "   Aucun tunnel trouvé. Création d'un nouveau tunnel..."
        TUNNEL_NAME="booxstream"
        cloudflared tunnel create $TUNNEL_NAME
        TUNNEL_ID=$(cloudflared tunnel list | grep $TUNNEL_NAME | awk '{print $1}')
    else
        echo "$TUNNELS" | nl -w2 -s'. '
        echo ""
        read -p "   Utiliser un tunnel existant? (numéro) ou 'n' pour créer un nouveau: " TUNNEL_CHOICE
        
        if [ "$TUNNEL_CHOICE" = "n" ] || [ -z "$TUNNEL_CHOICE" ]; then
            echo "   Création d'un nouveau tunnel..."
            TUNNEL_NAME="booxstream"
            cloudflared tunnel create $TUNNEL_NAME
            TUNNEL_ID=$(cloudflared tunnel list | grep $TUNNEL_NAME | awk '{print $1}')
        else
            TUNNEL_ID=$(echo "$TUNNELS" | sed -n "${TUNNEL_CHOICE}p" | awk '{print $1}')
            TUNNEL_NAME=$(echo "$TUNNELS" | sed -n "${TUNNEL_CHOICE}p" | awk '{print $2}')
        fi
    fi
fi

echo "   Tunnel sélectionné: $TUNNEL_NAME (ID: $TUNNEL_ID)"
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
# Utiliser le nom du tunnel ou l'ID si le nom n'est pas disponible
DNS_TUNNEL_ID=${TUNNEL_NAME:-$TUNNEL_ID}
cloudflared tunnel route dns $DNS_TUNNEL_ID booxstream.kevinvdb.dev 2>/dev/null || {
    echo "   Note: La route DNS existe peut-être déjà. Vérification..."
    cloudflared tunnel route dns list | grep booxstream.kevinvdb.dev || echo "   Route DNS à configurer manuellement si nécessaire"
}
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

