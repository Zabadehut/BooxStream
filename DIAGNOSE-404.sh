#!/bin/bash
# Diagnostic du problème 404

echo "╔══════════════════════════════════════════════════════════╗"
echo "║   Diagnostic problème 404 BooxStream                    ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Vérification service BooxStream local"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if systemctl is-active --quiet booxstream-web; then
    echo -e "${GREEN}✓ Service booxstream-web actif${NC}"
    
    # Test local
    LOCAL_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3001/api/hosts)
    if [ "$LOCAL_CODE" = "200" ]; then
        echo -e "${GREEN}✓ Service répond localement (Code: $LOCAL_CODE)${NC}"
        echo "Réponse:"
        curl -s http://localhost:3001/api/hosts | head -3
    else
        echo -e "${RED}✗ Service ne répond pas localement (Code: $LOCAL_CODE)${NC}"
    fi
else
    echo -e "${RED}✗ Service booxstream-web inactif${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. Vérification cloudflared sur cette VM"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if systemctl is-active --quiet cloudflared; then
    echo -e "${RED}✗ Service cloudflared ACTIF sur cette VM${NC}"
    echo "  → C'est probablement la cause du problème!"
    echo "  → Il écrase la configuration du gateway"
    echo ""
    echo "Pour résoudre:"
    echo "  sudo systemctl stop cloudflared"
    echo "  sudo systemctl disable cloudflared"
else
    echo -e "${GREEN}✓ Service cloudflared inactif sur cette VM${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. Configuration cloudflared actuelle"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -f ~/.cloudflared/config.yml ]; then
    echo -e "${CYAN}Config sur cette VM:${NC}"
    cat ~/.cloudflared/config.yml
else
    echo -e "${YELLOW}⚠ Pas de config trouvée${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. Test d'accès depuis le réseau local"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Obtenir l'IP de la machine
IP=$(hostname -I | awk '{print $1}')
echo "IP de cette machine: $IP"
echo ""

# Test depuis l'IP locale
echo "Test depuis l'IP locale ($IP:3001):"
REMOTE_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://$IP:3001/api/hosts 2>/dev/null)
if [ "$REMOTE_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Accessible depuis le réseau local (Code: $REMOTE_CODE)${NC}"
else
    echo -e "${YELLOW}⚠ Code: $REMOTE_CODE${NC}"
    echo "  (Peut être normal si le firewall bloque)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. Ports en écoute"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Ports 3001 et 8080 en écoute:"
ss -tlnp | grep -E ':(3001|8080)' || echo "Aucun port trouvé"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "RÉSUMÉ ET ACTIONS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if systemctl is-active --quiet cloudflared; then
    echo -e "${RED}⚠ PROBLÈME TROUVÉ: cloudflared est actif sur cette VM${NC}"
    echo ""
    echo "Actions à faire:"
    echo "  1. Désactiver cloudflared sur cette VM:"
    echo "     sudo systemctl stop cloudflared"
    echo "     sudo systemctl disable cloudflared"
    echo ""
    echo "  2. Vérifier que la route est ajoutée sur le GATEWAY"
    echo "     Dans /opt/cloudflare/config.yml du gateway:"
    echo "     - hostname: booxstream.kevinvdb.dev"
    echo "       service: http://192.168.1.202:3001"
    echo ""
    echo "  3. Redémarrer cloudflared sur le GATEWAY:"
    echo "     sudo systemctl restart cloudflared"
else
    echo -e "${GREEN}✓ cloudflared est inactif sur cette VM${NC}"
    echo ""
    echo "Le problème vient probablement de la configuration du GATEWAY."
    echo "Vérifiez que:"
    echo "  1. La route booxstream.kevinvdb.dev est dans /opt/cloudflare/config.yml"
    echo "  2. Le service cloudflared est actif sur le gateway"
    echo "  3. Le gateway peut accéder à 192.168.1.202:3001"
fi

echo ""

