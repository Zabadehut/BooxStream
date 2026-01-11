#!/bin/bash
# Script de test complet pour BooxStream

echo "╔══════════════════════════════════════════════════════════╗"
echo "║         Test complet BooxStream                         ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Test serveur local
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Test du serveur local (localhost:3001)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

LOCAL_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3001/api/hosts)
LOCAL_TIME=$(curl -s -o /dev/null -w "%{time_total}" http://localhost:3001/api/hosts)

if [ "$LOCAL_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Serveur local répond${NC} (Code: $LOCAL_CODE, Temps: ${LOCAL_TIME}s)"
    echo ""
    echo "Réponse:"
    curl -s http://localhost:3001/api/hosts | head -5
else
    echo -e "${RED}✗ Serveur local ne répond pas${NC} (Code: $LOCAL_CODE)"
fi

echo ""
echo ""

# 2. Test via Cloudflare Tunnel
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. Test via Cloudflare Tunnel (https://booxstream.kevinvdb.dev)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

REMOTE_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://booxstream.kevinvdb.dev/api/hosts)
REMOTE_TIME=$(curl -s -o /dev/null -w "%{time_total}" https://booxstream.kevinvdb.dev/api/hosts)

if [ "$REMOTE_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Tunnel Cloudflare fonctionne${NC} (Code: $REMOTE_CODE, Temps: ${REMOTE_TIME}s)"
    echo ""
    echo "Réponse:"
    curl -s https://booxstream.kevinvdb.dev/api/hosts | head -5
elif [ "$REMOTE_CODE" = "404" ]; then
    echo -e "${YELLOW}⚠ Tunnel répond mais retourne 404${NC}"
    echo "   Le tunnel fonctionne mais ne route pas vers le serveur local"
elif [ "$REMOTE_CODE" = "000" ]; then
    echo -e "${RED}✗ Tunnel ne répond pas${NC} (Pas de connexion)"
else
    echo -e "${RED}✗ Erreur${NC} (Code: $REMOTE_CODE)"
fi

echo ""
echo ""

# 3. Test de l'interface web
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. Test de l'interface web"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

WEB_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://booxstream.kevinvdb.dev/)

if [ "$WEB_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Interface web accessible${NC} (Code: $WEB_CODE)"
elif [ "$WEB_CODE" = "404" ]; then
    echo -e "${YELLOW}⚠ Interface web retourne 404${NC}"
else
    echo -e "${RED}✗ Interface web non accessible${NC} (Code: $WEB_CODE)"
fi

echo ""
echo ""

# 4. Headers de réponse
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. Headers de réponse"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

curl -I -s https://booxstream.kevinvdb.dev/api/hosts | head -10

echo ""
echo ""

# 5. Résumé
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Résumé"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Serveur local:     Code $LOCAL_CODE (${LOCAL_TIME}s)"
echo "Cloudflare Tunnel: Code $REMOTE_CODE (${REMOTE_TIME}s)"
echo "Interface web:     Code $WEB_CODE"
echo ""

if [ "$LOCAL_CODE" = "200" ] && [ "$REMOTE_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Tout fonctionne correctement!${NC}"
elif [ "$LOCAL_CODE" = "200" ] && [ "$REMOTE_CODE" != "200" ]; then
    echo -e "${YELLOW}⚠ Le serveur local fonctionne mais le tunnel a un problème${NC}"
    echo "   Vérifiez: sudo systemctl status cloudflared"
else
    echo -e "${RED}✗ Le serveur local ne fonctionne pas${NC}"
    echo "   Vérifiez: sudo systemctl status booxstream-web"
fi

echo ""

