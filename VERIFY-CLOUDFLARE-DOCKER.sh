#!/bin/bash
# Vérifier si cloudflared est dans Docker

echo "╔══════════════════════════════════════════════════════════╗"
echo "║   Vérification cloudflared (Docker ou systemd)          ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Vérification Docker"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if command -v docker >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Docker installé${NC}"
    
    # Chercher un conteneur cloudflared
    CLOUDFLARE_CONTAINER=$(docker ps -a --filter "name=cloudflared" --format "{{.Names}}" | head -1)
    
    if [ -n "$CLOUDFLARE_CONTAINER" ]; then
        echo -e "${CYAN}📦 Conteneur cloudflared trouvé: $CLOUDFLARE_CONTAINER${NC}"
        echo ""
        echo "Statut:"
        docker ps --filter "name=cloudflared" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        echo ""
        echo "Configuration du conteneur:"
        docker inspect $CLOUDFLARE_CONTAINER --format '{{range .Mounts}}{{.Source}} -> {{.Destination}}{{println}}{{end}}' | grep -i config || echo "Pas de montage config trouvé"
    else
        echo -e "${YELLOW}⚠ Aucun conteneur cloudflared trouvé${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Docker non installé${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. Vérification systemd"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if systemctl list-units --type=service --all | grep -q cloudflared; then
    echo -e "${CYAN}📋 Service systemd cloudflared trouvé${NC}"
    systemctl status cloudflared --no-pager -l | head -10
else
    echo -e "${YELLOW}⚠ Aucun service systemd cloudflared trouvé${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. Vérification docker-compose"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Chercher docker-compose.yml avec cloudflared
if [ -f /opt/cloudflare/docker-compose.yml ]; then
    echo -e "${CYAN}📄 docker-compose.yml trouvé: /opt/cloudflare/docker-compose.yml${NC}"
    cat /opt/cloudflare/docker-compose.yml
elif [ -f /opt/cloudflare/docker-compose.yaml ]; then
    echo -e "${CYAN}📄 docker-compose.yaml trouvé: /opt/cloudflare/docker-compose.yaml${NC}"
    cat /opt/cloudflare/docker-compose.yaml
else
    echo -e "${YELLOW}⚠ Aucun docker-compose.yml trouvé dans /opt/cloudflare/${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "RÉSUMÉ"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -n "$CLOUDFLARE_CONTAINER" ]; then
    echo -e "${GREEN}✓ cloudflared est dans Docker${NC}"
    echo ""
    echo "Pour redémarrer:"
    echo "  docker restart $CLOUDFLARE_CONTAINER"
    echo ""
    echo "Pour voir les logs:"
    echo "  docker logs $CLOUDFLARE_CONTAINER -f"
elif systemctl is-active --quiet cloudflared 2>/dev/null; then
    echo -e "${GREEN}✓ cloudflared est un service systemd${NC}"
    echo ""
    echo "Pour redémarrer:"
    echo "  sudo systemctl restart cloudflared"
else
    echo -e "${YELLOW}⚠ Format de cloudflared non déterminé${NC}"
fi

echo ""

