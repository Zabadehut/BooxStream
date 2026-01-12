#!/bin/bash
# Diagnostic du problème 404 pour BooxStream

echo "╔══════════════════════════════════════════════════════════╗"
echo "║   Diagnostic 404 BooxStream                              ║"
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
    
    LOCAL_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3001/api/hosts 2>/dev/null)
    if [ "$LOCAL_CODE" = "200" ]; then
        echo -e "${GREEN}✓ Service répond localement (Code: $LOCAL_CODE)${NC}"
    else
        echo -e "${RED}✗ Service ne répond pas (Code: $LOCAL_CODE)${NC}"
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
    echo -e "${GREEN}✓ Service cloudflared actif${NC}"
    echo ""
    echo "Config actuelle:"
    if [ -f ~/.cloudflared/config.yml ]; then
        cat ~/.cloudflared/config.yml
    else
        echo -e "${YELLOW}⚠ Config non trouvée${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Service cloudflared inactif${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. Test depuis le réseau local"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

IP=$(hostname -I | awk '{print $1}')
echo "IP de cette machine: $IP"
echo ""

REMOTE_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://$IP:3001/api/hosts 2>/dev/null)
if [ "$REMOTE_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Accessible depuis le réseau local (Code: $REMOTE_CODE)${NC}"
else
    echo -e "${YELLOW}⚠ Code: $REMOTE_CODE${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. Comparaison avec Affine (qui fonctionne)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Test Affine (doit retourner 302):"
AFFINE_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://affine.kevinvdb.dev/ 2>/dev/null)
if [ "$AFFINE_CODE" = "302" ] || [ "$AFFINE_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Affine fonctionne (Code: $AFFINE_CODE)${NC}"
else
    echo -e "${RED}✗ Affine ne fonctionne pas (Code: $AFFINE_CODE)${NC}"
fi

echo ""
echo "Test BooxStream (retourne 404):"
BOOXSTREAM_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://booxstream.kevinvdb.dev/ 2>/dev/null)
echo -e "${RED}✗ BooxStream retourne: $BOOXSTREAM_CODE${NC}"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. Diagnostic du problème"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Le 404 peut venir de:"
echo ""
echo "1. Route non configurée dans cloudflared"
echo "   → Vérifier que booxstream.kevinvdb.dev est dans la config"
echo ""
echo "2. Traefik non configuré pour BooxStream"
echo "   → Vérifier /opt/traefik/dynamic/booxstream.yml"
echo ""
echo "3. Service non accessible depuis Traefik"
echo "   → Depuis le gateway: curl http://192.168.1.202:3001/api/hosts"
echo ""
echo "4. Cloudflared sur gateway et VM ont des configs différentes"
echo "   → Les configs doivent être identiques"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ACTIONS À FAIRE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Sur le GATEWAY, vérifiez:"
echo ""
echo "1. Config cloudflared (/opt/cloudflare/config.yml):"
echo "   cat /opt/cloudflare/config.yml | grep booxstream"
echo ""
echo "2. Config Traefik pour BooxStream:"
echo "   cat /opt/traefik/dynamic/booxstream.yml"
echo "   # OU"
echo "   docker exec traefik cat /dynamic/booxstream.yml"
echo ""
echo "3. Test depuis Traefik vers BooxStream:"
echo "   curl -H 'Host: booxstream.kevinvdb.dev' http://localhost:80"
echo ""
echo "4. Test direct vers BooxStream:"
echo "   curl http://192.168.1.202:3001/api/hosts"
echo ""
echo "5. Logs Traefik:"
echo "   docker logs traefik | grep booxstream"
echo "   # OU"
echo "   journalctl -u traefik | grep booxstream"
echo ""

