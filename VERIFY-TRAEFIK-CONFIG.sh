#!/bin/bash
# Script pour vérifier la configuration Traefik sur le gateway

echo "╔══════════════════════════════════════════════════════════╗"
echo "║   Vérification configuration Traefik                    ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Vérification fichiers de configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

CONFIG_DIR="/opt/traefik/config"

if [ -d "$CONFIG_DIR" ]; then
    echo -e "${GREEN}✓ Répertoire trouvé: $CONFIG_DIR${NC}"
    echo ""
    echo "Fichiers présents:"
    ls -la "$CONFIG_DIR" | grep -E '\.(yml|yaml)$'
else
    echo -e "${RED}✗ Répertoire non trouvé: $CONFIG_DIR${NC}"
    echo "  Vérifiez le chemin de configuration Traefik"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. Vérification fichier booxstream.yml"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

BOOXSTREAM_CONFIG="$CONFIG_DIR/booxstream.yml"

if [ -f "$BOOXSTREAM_CONFIG" ]; then
    echo -e "${GREEN}✓ Fichier trouvé: $BOOXSTREAM_CONFIG${NC}"
    echo ""
    echo "Contenu:"
    cat "$BOOXSTREAM_CONFIG"
else
    echo -e "${RED}✗ Fichier non trouvé: $BOOXSTREAM_CONFIG${NC}"
    echo ""
    echo "Créez le fichier avec:"
    echo "  sudo nano $BOOXSTREAM_CONFIG"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. Vérification Traefik (Docker)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if command -v docker >/dev/null 2>&1; then
    echo "Containers Traefik:"
    docker ps | grep traefik || echo "Aucun container Traefik trouvé"
    
    echo ""
    echo "Vérification si Traefik charge les fichiers:"
    if docker ps | grep -q traefik; then
        TRAEFIK_CONTAINER=$(docker ps | grep traefik | awk '{print $1}')
        echo "Container: $TRAEFIK_CONTAINER"
        echo ""
        echo "Logs récents (dernières 20 lignes):"
        docker logs --tail 20 "$TRAEFIK_CONTAINER" 2>&1 | grep -i "booxstream\|error\|warn" || echo "Aucun log pertinent"
    fi
else
    echo -e "${YELLOW}⚠ Docker non trouvé${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. Test de connexion"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Test API (doit fonctionner sans auth):"
API_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST https://booxstream.kevinvdb.dev/api/hosts/register \
  -H "Content-Type: application/json" \
  -d '{"uuid":"test","name":"Test"}' 2>/dev/null)

if [ "$API_CODE" = "200" ] || [ "$API_CODE" = "400" ]; then
    echo -e "${GREEN}✓ API répond (Code: $API_CODE)${NC}"
    echo "  (400 est normal si UUID invalide)"
else
    echo -e "${RED}✗ API ne répond pas correctement (Code: $API_CODE)${NC}"
fi

echo ""
echo "Test interface web (doit rediriger vers Authentik):"
WEB_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://booxstream.kevinvdb.dev/ 2>/dev/null)

if [ "$WEB_CODE" = "302" ] || [ "$WEB_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Interface web répond (Code: $WEB_CODE)${NC}"
else
    echo -e "${YELLOW}⚠ Interface web (Code: $WEB_CODE)${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. Actions à faire"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ ! -f "$BOOXSTREAM_CONFIG" ]; then
    echo "1. Créer le fichier $BOOXSTREAM_CONFIG"
    echo "   (Copiez le contenu de booxstream.yml)"
    echo ""
fi

echo "2. Vérifier que Traefik charge le répertoire config"
echo "   (Vérifiez docker-compose.yml ou traefik.yml)"
echo ""
echo "3. Redémarrer Traefik:"
echo "   docker-compose restart traefik"
echo "   # OU"
echo "   docker restart traefik"
echo ""
echo "4. Vérifier les logs:"
echo "   docker logs traefik | grep booxstream"
echo ""

