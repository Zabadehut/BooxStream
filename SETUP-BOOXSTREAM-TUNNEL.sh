#!/bin/bash
# Script pour créer un tunnel Cloudflare séparé pour BooxStream (comme Affine)

echo "╔══════════════════════════════════════════════════════════╗"
echo "║   Configuration tunnel Cloudflare pour BooxStream       ║"
echo "║   (Architecture comme Affine)                            ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PRÉREQUIS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Avant de continuer, vous devez avoir :"
echo "  1. Créé un nouveau tunnel dans Cloudflare Dashboard"
echo "  2. Noté le Tunnel ID"
echo "  3. Noté l'Account Tag et Tunnel Secret"
echo ""
read -p "Avez-vous créé le tunnel dans Cloudflare Dashboard? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Créez d'abord le tunnel dans Cloudflare Dashboard${NC}"
    echo ""
    echo "1. Allez dans: Zero Trust → Networks → Tunnels"
    echo "2. Créez un nouveau tunnel: 'booxstream-tunnel'"
    echo "3. Notez le Tunnel ID, Account Tag et Tunnel Secret"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "INFORMATIONS DU TUNNEL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

read -p "Tunnel ID: " TUNNEL_ID
read -p "Account Tag: " ACCOUNT_TAG
read -sp "Tunnel Secret: " TUNNEL_SECRET
echo ""

if [ -z "$TUNNEL_ID" ] || [ -z "$ACCOUNT_TAG" ] || [ -z "$TUNNEL_SECRET" ]; then
    echo -e "${RED}✗ Toutes les informations sont requises${NC}"
    exit 1
fi

USER=$(whoami)
CREDENTIALS_FILE="/home/$USER/.cloudflared/${TUNNEL_ID}.json"
CONFIG_FILE="/home/$USER/.cloudflared/config.yml"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ÉTAPE 1: Création du fichier credentials"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

mkdir -p ~/.cloudflared

cat > "$CREDENTIALS_FILE" << EOF
{"AccountTag":"$ACCOUNT_TAG","TunnelSecret":"$TUNNEL_SECRET","TunnelID":"$TUNNEL_ID","Endpoint":""}
EOF

chmod 600 "$CREDENTIALS_FILE"

echo -e "${GREEN}✓ Fichier credentials créé: $CREDENTIALS_FILE${NC}"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ÉTAPE 2: Création de la configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

cat > "$CONFIG_FILE" << EOF
tunnel: $TUNNEL_ID
credentials-file: $CREDENTIALS_FILE

ingress:
  - hostname: booxstream.kevinvdb.dev
    service: http://localhost:3001
  - service: http_status:404

loglevel: info
no-autoupdate: true
EOF

echo -e "${GREEN}✓ Configuration créée: $CONFIG_FILE${NC}"
echo ""
echo "Configuration:"
cat "$CONFIG_FILE"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ÉTAPE 3: Création de l'enregistrement DNS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Création de l'enregistrement DNS dans Cloudflare..."
if command -v cloudflared >/dev/null 2>&1; then
    cloudflared tunnel route dns booxstream booxstream.kevinvdb.dev
    echo -e "${GREEN}✓ Enregistrement DNS créé${NC}"
else
    echo -e "${YELLOW}⚠ cloudflared non trouvé, créez l'enregistrement manuellement:${NC}"
    echo ""
    echo "Dans Cloudflare Dashboard → DNS → Records:"
    echo "  Type: CNAME"
    echo "  Name: booxstream"
    echo "  Target: ${TUNNEL_ID}.cfargotunnel.com"
    echo "  Proxy: ✅ Proxied (orange cloud)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ÉTAPE 4: Création du service systemd"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

SERVICE_FILE="/etc/systemd/system/cloudflared-booxstream.service"

sudo tee "$SERVICE_FILE" > /dev/null << EOF
[Unit]
Description=Cloudflare Tunnel for BooxStream
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
sudo systemctl enable cloudflared-booxstream

echo -e "${GREEN}✓ Service systemd créé: $SERVICE_FILE${NC}"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ÉTAPE 5: Démarrage du service"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

sudo systemctl start cloudflared-booxstream
sleep 2

if systemctl is-active --quiet cloudflared-booxstream; then
    echo -e "${GREEN}✓ Service cloudflared-booxstream démarré${NC}"
    echo ""
    echo "Statut:"
    sudo systemctl status cloudflared-booxstream --no-pager -l | head -15
else
    echo -e "${RED}✗ Échec du démarrage${NC}"
    echo ""
    echo "Logs:"
    sudo journalctl -u cloudflared-booxstream -n 20 --no-pager
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ÉTAPE 6: Vérification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Test local:"
LOCAL_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3001/api/hosts 2>/dev/null)
if [ "$LOCAL_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Service BooxStream répond localement (Code: $LOCAL_CODE)${NC}"
else
    echo -e "${YELLOW}⚠ Service BooxStream ne répond pas (Code: $LOCAL_CODE)${NC}"
fi

echo ""
echo "Test via Cloudflare Tunnel (attendez quelques secondes pour la propagation DNS):"
echo "  curl https://booxstream.kevinvdb.dev/api/hosts"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "RÉSUMÉ"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}✓ Tunnel Cloudflare configuré pour BooxStream${NC}"
echo ""
echo "Fichiers créés:"
echo "  - $CREDENTIALS_FILE"
echo "  - $CONFIG_FILE"
echo "  - $SERVICE_FILE"
echo ""
echo "Service: cloudflared-booxstream"
echo "  Status: sudo systemctl status cloudflared-booxstream"
echo "  Logs: sudo journalctl -u cloudflared-booxstream -f"
echo ""
echo -e "${CYAN}N'oubliez pas de retirer la route booxstream du gateway!${NC}"
echo ""

