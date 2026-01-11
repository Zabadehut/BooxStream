#!/bin/bash
# Script pour redémarrer cloudflared (Docker ou systemd)

echo "╔══════════════════════════════════════════════════════════╗"
echo "║   Redémarrage cloudflared                               ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Détecter si c'est Docker ou systemd
CLOUDFLARE_CONTAINER=$(docker ps -a --filter "name=cloudflared" --format "{{.Names}}" 2>/dev/null | head -1)

if [ -n "$CLOUDFLARE_CONTAINER" ]; then
    echo -e "${CYAN}📦 Conteneur Docker trouvé: $CLOUDFLARE_CONTAINER${NC}"
    echo ""
    
    # Vérifier si le conteneur est dans docker-compose
    if [ -f /opt/cloudflare/docker-compose.yml ] || [ -f /opt/cloudflare/docker-compose.yaml ]; then
        echo -e "${YELLOW}Redémarrage via docker-compose...${NC}"
        cd /opt/cloudflare
        docker-compose restart cloudflared || docker compose restart cloudflared
    else
        echo -e "${YELLOW}Redémarrage du conteneur...${NC}"
        docker restart $CLOUDFLARE_CONTAINER
    fi
    
    sleep 2
    
    if docker ps --filter "name=cloudflared" --format "{{.Status}}" | grep -q "Up"; then
        echo -e "${GREEN}✓ cloudflared redémarré${NC}"
        echo ""
        echo "Statut:"
        docker ps --filter "name=cloudflared" --format "table {{.Names}}\t{{.Status}}"
    else
        echo -e "${RED}✗ Échec du redémarrage${NC}"
        exit 1
    fi
    
elif systemctl list-units --type=service --all | grep -q cloudflared; then
    echo -e "${CYAN}📋 Service systemd trouvé${NC}"
    echo ""
    echo -e "${YELLOW}Redémarrage du service...${NC}"
    sudo systemctl restart cloudflared
    sleep 2
    
    if systemctl is-active --quiet cloudflared; then
        echo -e "${GREEN}✓ cloudflared redémarré${NC}"
        systemctl status cloudflared --no-pager -l | head -10
    else
        echo -e "${RED}✗ Échec du redémarrage${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ cloudflared non trouvé (ni Docker ni systemd)${NC}"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Vérification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Test de la route booxstream:"
sleep 3
CODE=$(curl -s -o /dev/null -w "%{http_code}" https://booxstream.kevinvdb.dev/api/hosts 2>/dev/null)
if [ "$CODE" = "200" ]; then
    echo -e "${GREEN}✓ Route fonctionne (Code: $CODE)${NC}"
else
    echo -e "${YELLOW}⚠ Code: $CODE${NC}"
    echo "  Vérifiez la configuration et les logs"
fi

echo ""

