#!/bin/bash
# Script pour synchroniser la config Cloudflare Tunnel entre gateway et VM Linux
# Option 2 : Configs synchronisées, les deux instances peuvent être actives

echo "╔══════════════════════════════════════════════════════════╗"
echo "║   Synchronisation config Cloudflare Tunnel              ║"
echo "║   Gateway + VM Linux avec configs identiques            ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

TUNNEL_ID="a40eeeac-5f83-4d51-9da2-67a0c9e0e975"
USER=$(whoami)
CREDENTIALS_FILE="/home/$USER/.cloudflared/${TUNNEL_ID}.json"
CONFIG_FILE="/home/$USER/.cloudflared/config.yml"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "CONFIGURATION COMPLÈTE SYNCHRONISÉE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Cette config doit être IDENTIQUE sur le gateway et la VM Linux"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ÉTAPE 1: Vérification des credentials"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -f "$CREDENTIALS_FILE" ]; then
    echo -e "${GREEN}✓ Fichier credentials trouvé${NC}"
else
    echo -e "${YELLOW}⚠ Fichier credentials non trouvé${NC}"
    echo "Copiez-le depuis le gateway ou créez-le avec les credentials du tunnel."
    echo ""
    read -p "Account Tag: " ACCOUNT_TAG
    read -sp "Tunnel Secret: " TUNNEL_SECRET
    echo ""
    
    if [ -z "$ACCOUNT_TAG" ] || [ -z "$TUNNEL_SECRET" ]; then
        echo -e "${RED}✗ Account Tag et Tunnel Secret requis${NC}"
        exit 1
    fi
    
    mkdir -p ~/.cloudflared
    cat > "$CREDENTIALS_FILE" << EOF
{"AccountTag":"$ACCOUNT_TAG","TunnelSecret":"$TUNNEL_SECRET","TunnelID":"$TUNNEL_ID","Endpoint":""}
EOF
    chmod 600 "$CREDENTIALS_FILE"
    echo -e "${GREEN}✓ Fichier credentials créé${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ÉTAPE 2: Création de la config complète synchronisée"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo -e "${CYAN}⚠ IMPORTANT: Cette config doit être IDENTIQUE sur le gateway!${NC}"
echo ""

cat > "$CONFIG_FILE" << 'EOF'
tunnel: a40eeeac-5f83-4d51-9da2-67a0c9e0e975
credentials-file: /home/kvdb/.cloudflared/a40eeeac-5f83-4d51-9da2-67a0c9e0e975.json

ingress:
  # Domaine principal via Traefik
  - hostname: kevinvdb.dev
    service: http://traefik:80
  
  # Services via Traefik
  - hostname: auth.kevinvdb.dev
    service: http://traefik:80
  
  - hostname: home.kevinvdb.dev
    service: http://traefik:80
  
  - hostname: affine.kevinvdb.dev
    service: http://traefik:80
  
  - hostname: traefik.kevinvdb.dev
    service: http://traefik:80
  
  # BooxStream via Traefik (comme les autres)
  - hostname: booxstream.kevinvdb.dev
    service: http://traefik:80
  
  # Catch-all (doit être en dernier)
  - service: http_status:404

loglevel: info
no-autoupdate: true
EOF

# Remplacer le chemin credentials par celui de l'utilisateur actuel
sed -i "s|/home/kvdb|/home/$USER|g" "$CONFIG_FILE"

echo -e "${GREEN}✓ Configuration complète créée: $CONFIG_FILE${NC}"
echo ""
echo "Configuration:"
cat "$CONFIG_FILE"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ÉTAPE 3: Création du service systemd"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

SERVICE_FILE="/etc/systemd/system/cloudflared.service"

if [ -f "$SERVICE_FILE" ]; then
    echo -e "${YELLOW}⚠ Service existe déjà${NC}"
    read -p "Remplacer? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Annulé."
        exit 0
    fi
fi

sudo tee "$SERVICE_FILE" > /dev/null << EOF
[Unit]
Description=Cloudflare Tunnel
After=network.target

[Service]
Type=simple
User=$USER
ExecStart=/usr/local/bin/cloudflared tunnel --config $CONFIG_FILE run
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable cloudflared

echo -e "${GREEN}✓ Service systemd créé${NC}"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ÉTAPE 4: Démarrage du service"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

sudo systemctl start cloudflared
sleep 3

if systemctl is-active --quiet cloudflared; then
    echo -e "${GREEN}✓ Service cloudflared démarré${NC}"
    sudo systemctl status cloudflared --no-pager -l | head -15
else
    echo -e "${RED}✗ Échec du démarrage${NC}"
    sudo journalctl -u cloudflared -n 20 --no-pager
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PROCHAINES ÉTAPES SUR LE GATEWAY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Sur le gateway, assurez-vous que /opt/cloudflare/config.yml"
echo "   a EXACTEMENT la même configuration (copiez celle ci-dessus)"
echo ""
echo "2. Configurez Traefik pour router booxstream.kevinvdb.dev"
echo "   vers http://192.168.1.202:3001"
echo ""
echo "3. (Optionnel) Configurez Authentik pour BooxStream"
echo ""
echo "4. Redémarrez cloudflared sur le gateway:"
echo "   sudo systemctl restart cloudflared"
echo ""

