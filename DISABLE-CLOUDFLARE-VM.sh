#!/bin/bash
# Script pour désactiver cloudflared sur la VM Linux
# BooxStream sera géré par le tunnel principal sur le gateway

echo "╔══════════════════════════════════════════════════════════╗"
echo "║   Désactivation cloudflared sur VM Linux                ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ÉTAPE 1: Arrêt du service cloudflared"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if systemctl is-active --quiet cloudflared; then
    echo -e "${YELLOW}Arrêt du service cloudflared...${NC}"
    sudo systemctl stop cloudflared
    sleep 2
    
    if systemctl is-active --quiet cloudflared; then
        echo -e "${RED}✗ Échec de l'arrêt${NC}"
        exit 1
    else
        echo -e "${GREEN}✓ Service arrêté${NC}"
    fi
else
    echo -e "${GREEN}✓ Service déjà arrêté${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ÉTAPE 2: Désactivation du service"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if systemctl is-enabled --quiet cloudflared 2>/dev/null; then
    echo -e "${YELLOW}Désactivation du service cloudflared...${NC}"
    sudo systemctl disable cloudflared
    
    if systemctl is-enabled --quiet cloudflared 2>/dev/null; then
        echo -e "${RED}✗ Échec de la désactivation${NC}"
        exit 1
    else
        echo -e "${GREEN}✓ Service désactivé${NC}"
    fi
else
    echo -e "${GREEN}✓ Service déjà désactivé${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ÉTAPE 3: Vérification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if systemctl is-active --quiet cloudflared; then
    echo -e "${RED}✗ Le service est toujours actif${NC}"
    echo "  Vérifiez manuellement: sudo systemctl status cloudflared"
    exit 1
else
    echo -e "${GREEN}✓ Service cloudflared inactif${NC}"
fi

if systemctl is-enabled --quiet cloudflared 2>/dev/null; then
    echo -e "${RED}✗ Le service est toujours activé au démarrage${NC}"
    exit 1
else
    echo -e "${GREEN}✓ Service désactivé au démarrage${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ÉTAPE 4: Vérification du service BooxStream"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if systemctl is-active --quiet booxstream-web; then
    echo -e "${GREEN}✓ Service booxstream-web actif${NC}"
    
    # Test local
    LOCAL_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3001/api/hosts 2>/dev/null)
    if [ "$LOCAL_CODE" = "200" ]; then
        echo -e "${GREEN}✓ Service répond localement (Code: $LOCAL_CODE)${NC}"
    else
        echo -e "${YELLOW}⚠ Service ne répond pas localement (Code: $LOCAL_CODE)${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Service booxstream-web inactif${NC}"
    echo "  Démarrez-le avec: sudo systemctl start booxstream-web"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PROCHAINES ÉTAPES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${CYAN}1. Sur votre GATEWAY, modifiez /opt/cloudflare/config.yml${NC}"
echo ""
echo "   Ajoutez cette route dans la section ingress:"
echo ""
echo "   ingress:"
echo "     # ... vos routes existantes ..."
echo "     - hostname: booxstream.kevinvdb.dev"
echo "       service: http://192.168.1.202:3001"
echo "     - service: http_status:404"
echo ""
echo -e "${CYAN}2. Redémarrez cloudflared sur le GATEWAY:${NC}"
echo ""
echo "   sudo systemctl restart cloudflared"
echo ""
echo -e "${CYAN}3. Testez l'accès:${NC}"
echo ""
echo "   curl https://booxstream.kevinvdb.dev/api/hosts"
echo ""
echo -e "${GREEN}✓ Configuration terminée sur cette VM${NC}"
echo ""

