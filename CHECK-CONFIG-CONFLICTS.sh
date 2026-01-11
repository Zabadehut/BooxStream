#!/bin/bash
# Script pour vérifier les configurations et détecter les conflits

echo "╔══════════════════════════════════════════════════════════╗"
echo "║   Vérification des configurations                        ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Configuration Cloudflare Tunnel"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Config dans /opt/cloudflare/
if [ -f /opt/cloudflare/config.yml ]; then
    echo -e "${CYAN}📁 /opt/cloudflare/config.yml${NC}"
    cat /opt/cloudflare/config.yml
    echo ""
else
    echo -e "${YELLOW}⚠ /opt/cloudflare/config.yml non trouvé${NC}"
fi

# Config dans ~/.cloudflared/
if [ -f ~/.cloudflared/config.yml ]; then
    echo -e "${CYAN}📁 ~/.cloudflared/config.yml${NC}"
    cat ~/.cloudflared/config.yml
    echo ""
else
    echo -e "${YELLOW}⚠ ~/.cloudflared/config.yml non trouvé${NC}"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. Configuration Traefik"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -d /opt/traefik ]; then
    echo -e "${CYAN}📁 Contenu de /opt/traefik/${NC}"
    ls -la /opt/traefik/
    echo ""
    
    # Chercher docker-compose
    if [ -f /opt/traefik/docker-compose.yml ]; then
        echo -e "${CYAN}📄 docker-compose.yml${NC}"
        cat /opt/traefik/docker-compose.yml
        echo ""
    fi
    
    # Chercher traefik.yml
    if [ -f /opt/traefik/traefik.yml ]; then
        echo -e "${CYAN}📄 traefik.yml${NC}"
        cat /opt/traefik/traefik.yml
        echo ""
    fi
    
    # Chercher autres fichiers de config
    find /opt/traefik -name "*.yml" -o -name "*.yaml" 2>/dev/null | while read f; do
        if [ "$f" != "/opt/traefik/docker-compose.yml" ] && [ "$f" != "/opt/traefik/traefik.yml" ]; then
            echo -e "${CYAN}📄 $f${NC}"
            cat "$f" | head -30
            echo ""
        fi
    done
else
    echo -e "${YELLOW}⚠ /opt/traefik/ non trouvé${NC}"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. Configuration Authentik"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -d /opt/authentik ]; then
    echo -e "${CYAN}📁 Contenu de /opt/authentik/${NC}"
    ls -la /opt/authentik/
    echo ""
    
    # Chercher docker-compose
    if [ -f /opt/authentik/docker-compose.yml ]; then
        echo -e "${CYAN}📄 docker-compose.yml${NC}"
        cat /opt/authentik/docker-compose.yml
        echo ""
    fi
else
    echo -e "${YELLOW}⚠ /opt/authentik/ non trouvé${NC}"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. Configuration Homepage"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -d /opt/homepage ]; then
    echo -e "${CYAN}📁 Contenu de /opt/homepage/${NC}"
    ls -la /opt/homepage/
    echo ""
    
    # Chercher docker-compose
    if [ -f /opt/homepage/docker-compose.yml ]; then
        echo -e "${CYAN}📄 docker-compose.yml${NC}"
        cat /opt/homepage/docker-compose.yml
        echo ""
    fi
else
    echo -e "${YELLOW}⚠ /opt/homepage/ non trouvé${NC}"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. Services cloudflared actifs"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if systemctl is-active --quiet cloudflared; then
    echo -e "${GREEN}✓ Service cloudflared actif${NC}"
    systemctl status cloudflared --no-pager -l | head -15
else
    echo -e "${RED}✗ Service cloudflared inactif${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "6. Processus cloudflared en cours"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

ps aux | grep cloudflared | grep -v grep || echo "Aucun processus cloudflared trouvé"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Résumé"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Configurations trouvées:"
[ -f /opt/cloudflare/config.yml ] && echo "  ✓ /opt/cloudflare/config.yml"
[ -f ~/.cloudflared/config.yml ] && echo "  ✓ ~/.cloudflared/config.yml"
[ -d /opt/traefik ] && echo "  ✓ /opt/traefik/"
[ -d /opt/authentik ] && echo "  ✓ /opt/authentik/"
[ -d /opt/homepage ] && echo "  ✓ /opt/homepage/"
echo ""

