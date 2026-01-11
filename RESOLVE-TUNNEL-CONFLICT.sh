#!/bin/bash
# Script pour résoudre le conflit de tunnel Cloudflare

echo "╔══════════════════════════════════════════════════════════╗"
echo "║   Résolution conflit Cloudflare Tunnel                 ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ÉTAPE 1: Désactiver cloudflared sur cette VM"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Arrêter le service
if systemctl is-active --quiet cloudflared; then
    echo -e "${YELLOW}Arrêt du service cloudflared...${NC}"
    sudo systemctl stop cloudflared
    echo -e "${GREEN}✓ Service arrêté${NC}"
else
    echo -e "${GREEN}✓ Service déjà arrêté${NC}"
fi

# Désactiver le service
if systemctl is-enabled --quiet cloudflared 2>/dev/null; then
    echo -e "${YELLOW}Désactivation du service cloudflared...${NC}"
    sudo systemctl disable cloudflared
    echo -e "${GREEN}✓ Service désactivé${NC}"
else
    echo -e "${GREEN}✓ Service déjà désactivé${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ÉTAPE 2: Vérification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if systemctl is-active --quiet cloudflared; then
    echo -e "${RED}✗ Le service est toujours actif${NC}"
    echo "  → Vérifiez manuellement: sudo systemctl status cloudflared"
else
    echo -e "${GREEN}✓ Le service cloudflared est maintenant inactif${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ÉTAPE 3: Configuration à faire sur le GATEWAY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${CYAN}Sur votre serveur GATEWAY, modifiez:${NC}"
echo "  /opt/cloudflare/config.yml"
echo ""
echo -e "${CYAN}Ajoutez cette route dans la section ingress:${NC}"
echo ""
echo "  ingress:"
echo "    # ... vos routes existantes (traefik, auth, homepage, etc.) ..."
echo "    - hostname: booxstream.kevinvdb.dev"
echo "      service: http://192.168.1.202:3001"
echo "    # Catch-all (doit être en dernier)"
echo "    - service: http_status:404"
echo ""
echo -e "${CYAN}Puis redémarrez cloudflared sur le gateway:${NC}"
echo "  sudo systemctl restart cloudflared"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "VÉRIFICATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Une fois la config modifiée sur le gateway, testez:"
echo ""
echo "  1. Votre domaine principal:"
echo "     curl https://kevinvdb.dev"
echo ""
echo "  2. BooxStream:"
echo "     curl https://booxstream.kevinvdb.dev/api/hosts"
echo ""
echo "  3. Autres services (traefik, auth, homepage):"
echo "     curl https://traefik.kevinvdb.dev"
echo "     curl https://auth.kevinvdb.dev"
echo ""
echo -e "${GREEN}✓ Configuration terminée sur cette VM${NC}"
echo ""

