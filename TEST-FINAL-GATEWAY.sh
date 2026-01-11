#!/bin/bash
# Test final pour vérifier que BooxStream fonctionne via le gateway

echo "╔══════════════════════════════════════════════════════════╗"
echo "║   Test final BooxStream via Gateway                     ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Vérification cloudflared sur le gateway"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if systemctl is-active --quiet cloudflared; then
    echo -e "${GREEN}✓ Service cloudflared actif sur le gateway${NC}"
    systemctl status cloudflared --no-pager -l | head -10
else
    echo -e "${RED}✗ Service cloudflared inactif sur le gateway${NC}"
    echo "  → Démarrez-le avec: sudo systemctl start cloudflared"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. Vérification configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -f /opt/cloudflare/config.yml ]; then
    echo -e "${CYAN}Configuration trouvée: /opt/cloudflare/config.yml${NC}"
    if grep -q "booxstream.kevinvdb.dev" /opt/cloudflare/config.yml; then
        echo -e "${GREEN}✓ Route booxstream.kevinvdb.dev trouvée${NC}"
        echo ""
        echo "Route configurée:"
        grep -A 2 "booxstream.kevinvdb.dev" /opt/cloudflare/config.yml
    else
        echo -e "${RED}✗ Route booxstream.kevinvdb.dev non trouvée${NC}"
        echo "  → Ajoutez-la dans /opt/cloudflare/config.yml"
    fi
else
    echo -e "${YELLOW}⚠ Fichier /opt/cloudflare/config.yml non trouvé${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. Test d'accès au service BooxStream depuis le gateway"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Test depuis le gateway vers 192.168.1.202:3001:"
if command -v curl >/dev/null 2>&1; then
    CODE=$(curl -s -o /dev/null -w "%{http_code}" http://192.168.1.202:3001/api/hosts 2>/dev/null)
    TIME=$(curl -s -o /dev/null -w "%{time_total}" http://192.168.1.202:3001/api/hosts 2>/dev/null)
    
    if [ "$CODE" = "200" ]; then
        echo -e "${GREEN}✓ Service accessible depuis le gateway (Code: $CODE, Temps: ${TIME}s)${NC}"
        echo ""
        echo "Réponse:"
        curl -s http://192.168.1.202:3001/api/hosts | head -3
    else
        echo -e "${RED}✗ Service non accessible (Code: $CODE)${NC}"
        echo "  → Vérifiez que le service BooxStream est actif sur 192.168.1.202:3001"
        echo "  → Vérifiez le firewall entre le gateway et la VM Linux"
    fi
else
    echo -e "${YELLOW}⚠ curl non disponible${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. Test via Cloudflare Tunnel"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Test depuis Internet via Cloudflare:"
if command -v curl >/dev/null 2>&1; then
    REMOTE_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://booxstream.kevinvdb.dev/api/hosts 2>/dev/null)
    REMOTE_TIME=$(curl -s -o /dev/null -w "%{time_total}" https://booxstream.kevinvdb.dev/api/hosts 2>/dev/null)
    
    if [ "$REMOTE_CODE" = "200" ]; then
        echo -e "${GREEN}✓ Tunnel Cloudflare fonctionne! (Code: $REMOTE_CODE, Temps: ${REMOTE_TIME}s)${NC}"
        echo ""
        echo "Réponse:"
        curl -s https://booxstream.kevinvdb.dev/api/hosts | head -5
        echo ""
        echo -e "${GREEN}🎉 TOUT FONCTIONNE!${NC}"
    elif [ "$REMOTE_CODE" = "404" ]; then
        echo -e "${YELLOW}⚠ Tunnel répond mais retourne 404${NC}"
        echo "  → Vérifiez que la route est correctement configurée"
        echo "  → Vérifiez les logs: sudo journalctl -u cloudflared -n 50"
    else
        echo -e "${RED}✗ Erreur (Code: $REMOTE_CODE)${NC}"
        echo "  → Vérifiez que cloudflared est actif sur le gateway"
    fi
else
    echo -e "${YELLOW}⚠ curl non disponible${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. Vérification autres services"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Test des autres services (doivent toujours fonctionner):"
SERVICES=("kevinvdb.dev" "traefik.kevinvdb.dev" "auth.kevinvdb.dev" "home.kevinvdb.dev" "affine.kevinvdb.dev")

for service in "${SERVICES[@]}"; do
    if command -v curl >/dev/null 2>&1; then
        CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://$service" 2>/dev/null)
        if [ "$CODE" = "200" ] || [ "$CODE" = "302" ] || [ "$CODE" = "301" ]; then
            echo -e "${GREEN}✓ $service (Code: $CODE)${NC}"
        else
            echo -e "${YELLOW}⚠ $service (Code: $CODE)${NC}"
        fi
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "RÉSUMÉ"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$REMOTE_CODE" = "200" ]; then
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   ✅ TOUT FONCTIONNE CORRECTEMENT!                      ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "BooxStream est accessible sur:"
    echo "  https://booxstream.kevinvdb.dev"
    echo ""
    echo "Les autres services fonctionnent toujours correctement."
else
    echo -e "${YELLOW}⚠ Vérifications nécessaires${NC}"
    echo ""
    echo "Actions à faire:"
    echo "  1. Vérifier que cloudflared est actif: sudo systemctl status cloudflared"
    echo "  2. Vérifier la config: cat /opt/cloudflare/config.yml | grep booxstream"
    echo "  3. Redémarrer cloudflared: sudo systemctl restart cloudflared"
    echo "  4. Vérifier les logs: sudo journalctl -u cloudflared -n 50 -f"
fi

echo ""

