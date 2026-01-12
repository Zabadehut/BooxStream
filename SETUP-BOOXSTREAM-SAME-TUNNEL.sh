#!/bin/bash
# Script pour configurer BooxStream avec le MÊME tunnel que le gateway
# Architecture comme Affine : cloudflared actif sur la VM avec le tunnel partagé

echo "╔══════════════════════════════════════════════════════════╗"
echo "║   Configuration BooxStream avec tunnel gateway          ║"
echo "║   (Même tunnel, cloudflared actif sur VM)               ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Tunnel ID du gateway (MÊME que le gateway)
TUNNEL_ID="a40eeeac-5f83-4d51-9da2-67a0c9e0e975"
USER=$(whoami)
CREDENTIALS_FILE="/home/$USER/.cloudflared/${TUNNEL_ID}.json"
CONFIG_FILE="/home/$USER/.cloudflared/config.yml"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "INFORMATIONS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Tunnel ID: $TUNNEL_ID (même que le gateway)"
echo "User: $USER"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ÉTAPE 1: Vérification des credentials"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -f "$CREDENTIALS_FILE" ]; then
    echo -e "${GREEN}✓ Fichier credentials trouvé: $CREDENTIALS_FILE${NC}"
    echo "Contenu (masqué):"
    cat "$CREDENTIALS_FILE" | sed 's/"TunnelSecret":"[^"]*"/"TunnelSecret":"***MASQUE***"/'
else
    echo -e "${YELLOW}⚠ Fichier credentials non trouvé: $CREDENTIALS_FILE${NC}"
    echo ""
    echo "Vous devez créer ce fichier avec les credentials du tunnel."
    echo "Obtenez-les depuis le gateway ou Cloudflare Dashboard."
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
echo "ÉTAPE 2: Création de la configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo -e "${CYAN}⚠ IMPORTANT: La config doit être identique au gateway!${NC}"
echo ""
echo "Cette config route uniquement booxstream.kevinvdb.dev"
echo "Le gateway doit avoir TOUTES les routes dans sa config."
echo ""

cat > "$CONFIG_FILE" << EOF
tunnel: $TUNNEL_ID
credentials-file: $CREDENTIALS_FILE

ingress:
  # BooxStream uniquement
  - hostname: booxstream.kevinvdb.dev
    service: http://localhost:3001
  # Catch-all
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
echo "ÉTAPE 3: Création du service systemd"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

SERVICE_FILE="/etc/systemd/system/cloudflared.service"

# Vérifier si le service existe déjà
if [ -f "$SERVICE_FILE" ]; then
    echo -e "${YELLOW}⚠ Service existe déjà: $SERVICE_FILE${NC}"
    echo "Voulez-vous le remplacer? (y/n)"
    read -n 1 -r
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

echo -e "${GREEN}✓ Service systemd créé: $SERVICE_FILE${NC}"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ÉTAPE 4: Démarrage du service"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

sudo systemctl start cloudflared
sleep 3

if systemctl is-active --quiet cloudflared; then
    echo -e "${GREEN}✓ Service cloudflared démarré${NC}"
    echo ""
    echo "Statut:"
    sudo systemctl status cloudflared --no-pager -l | head -15
else
    echo -e "${RED}✗ Échec du démarrage${NC}"
    echo ""
    echo "Logs:"
    sudo journalctl -u cloudflared -n 20 --no-pager
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ÉTAPE 5: Vérification"
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
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚠ ATTENTION IMPORTANTE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${YELLOW}Si plusieurs instances cloudflared utilisent le même tunnel${NC}"
echo -e "${YELLOW}avec des configs différentes, la dernière qui démarre écrase les routes!${NC}"
echo ""
echo "Solutions possibles:"
echo "  1. Désactiver cloudflared sur le gateway (si BooxStream gère tout)"
echo "  2. Synchroniser les configs (même config complète partout)"
echo "  3. Utiliser un tunnel séparé pour BooxStream"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "RÉSUMÉ"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}✓ cloudflared configuré pour BooxStream${NC}"
echo ""
echo "Fichiers:"
echo "  - $CREDENTIALS_FILE"
echo "  - $CONFIG_FILE"
echo "  - $SERVICE_FILE"
echo ""
echo "Service: cloudflared"
echo "  Status: sudo systemctl status cloudflared"
echo "  Logs: sudo journalctl -u cloudflared -f"
echo ""
echo "Test:"
echo "  curl https://booxstream.kevinvdb.dev/api/hosts"
echo ""

