#!/bin/bash
# Test final pour vérifier que tout fonctionne

echo "╔══════════════════════════════════════════════════════════╗"
echo "║   Test final BooxStream                                  ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Test serveur local
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Test serveur local"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
LOCAL_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3001/api/hosts)
if [ "$LOCAL_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Serveur local répond${NC} (Code: $LOCAL_CODE)"
    echo "Réponse:"
    curl -s http://localhost:3001/api/hosts | head -3
else
    echo -e "${RED}✗ Serveur local ne répond pas${NC} (Code: $LOCAL_CODE)"
fi
echo ""

# 2. Test via Cloudflare Tunnel
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. Test via Cloudflare Tunnel"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
REMOTE_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://booxstream.kevinvdb.dev/api/hosts)
REMOTE_TIME=$(curl -s -o /dev/null -w "%{time_total}" https://booxstream.kevinvdb.dev/api/hosts)

if [ "$REMOTE_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Tunnel Cloudflare fonctionne!${NC} (Code: $REMOTE_CODE, Temps: ${REMOTE_TIME}s)"
    echo ""
    echo "Réponse:"
    curl -s https://booxstream.kevinvdb.dev/api/hosts | head -5
    echo ""
    echo -e "${GREEN}🎉 TOUT FONCTIONNE!${NC}"
elif [ "$REMOTE_CODE" = "404" ]; then
    echo -e "${YELLOW}⚠ Tunnel répond mais retourne 404${NC}"
    echo "   Le tunnel fonctionne mais ne route pas vers le serveur local"
    echo "   Vérifiez la configuration du tunnel"
else
    echo -e "${RED}✗ Erreur${NC} (Code: $REMOTE_CODE)"
fi
echo ""

# 3. Statut des services
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. Statut des services"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if sudo systemctl is-active --quiet cloudflared; then
    echo -e "${GREEN}✓ cloudflared: actif${NC}"
else
    echo -e "${RED}✗ cloudflared: inactif${NC}"
fi

if sudo systemctl is-active --quiet booxstream-web; then
    echo -e "${GREEN}✓ booxstream-web: actif${NC}"
else
    echo -e "${RED}✗ booxstream-web: inactif${NC}"
fi
echo ""

# 4. Résumé
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Résumé"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Serveur local:     Code $LOCAL_CODE"
echo "Cloudflare Tunnel: Code $REMOTE_CODE (${REMOTE_TIME}s)"
echo ""

if [ "$LOCAL_CODE" = "200" ] && [ "$REMOTE_CODE" = "200" ]; then
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   ✅ TOUT FONCTIONNE CORRECTEMENT!                      ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Votre application est accessible sur:"
    echo "  https://booxstream.kevinvdb.dev"
    echo ""
    echo "Pour Authentik, utilisez cette URL dans la configuration."
elif [ "$LOCAL_CODE" = "200" ] && [ "$REMOTE_CODE" != "200" ]; then
    echo -e "${YELLOW}⚠ Le serveur local fonctionne mais le tunnel a un problème${NC}"
    echo "   Vérifiez les logs: sudo journalctl -u cloudflared -n 50"
fi
echo ""

