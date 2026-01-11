#!/bin/bash
# Vérification de la configuration du gateway

echo "╔══════════════════════════════════════════════════════════╗"
echo "║   Vérification configuration Gateway                    ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ANALYSE DE LA CONFIGURATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo -e "${CYAN}Configuration actuelle:${NC}"
echo ""
echo "  Routes via Traefik:"
echo "    - kevinvdb.dev → traefik:80"
echo "    - auth.kevinvdb.dev → traefik:80"
echo "    - home.kevinvdb.dev → traefik:80"
echo "    - affine.kevinvdb.dev → traefik:80"
echo "    - traefik.kevinvdb.dev → traefik:80"
echo ""
echo "  Route directe:"
echo "    - booxstream.kevinvdb.dev → 192.168.1.202:3001"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "OPTIONS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo -e "${CYAN}Option 1: Passer par Traefik (recommandé pour cohérence)${NC}"
echo ""
echo "  ingress:"
echo "    - hostname: booxstream.kevinvdb.dev"
echo "      service: http://traefik:80"
echo ""
echo "  Avantages:"
echo "    ✓ Cohérence avec les autres services"
echo "    ✓ Traefik gère SSL, authentification, etc."
echo "    ✓ Configuration centralisée dans Traefik"
echo ""
echo "  Nécessite:"
echo "    → Configuration Traefik pour router vers 192.168.1.202:3001"
echo ""

echo -e "${CYAN}Option 2: Routage direct (actuel)${NC}"
echo ""
echo "  ingress:"
echo "    - hostname: booxstream.kevinvdb.dev"
echo "      service: http://192.168.1.202:3001"
echo ""
echo "  Avantages:"
echo "    ✓ Plus simple (pas besoin de config Traefik)"
echo "    ✓ Accès direct au service"
echo ""
echo "  Inconvénients:"
echo "    ✗ Pas de gestion SSL par Traefik"
echo "    ✗ Pas d'authentification via Authentik"
echo "    ✗ Incohérent avec les autres services"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "RECOMMANDATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo -e "${GREEN}→ Option 1 recommandée si vous utilisez Authentik${NC}"
echo "  BooxStream devrait passer par Traefik pour bénéficier de:"
echo "    - Authentification Authentik"
echo "    - Gestion SSL centralisée"
echo "    - Cohérence avec les autres services"
echo ""
echo -e "${GREEN}→ Option 2 OK si BooxStream doit être accessible publiquement${NC}"
echo "  Sans authentification, routage direct fonctionne"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST DE LA CONFIGURATION ACTUELLE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Test depuis le gateway vers BooxStream:"
if command -v curl >/dev/null 2>&1; then
    CODE=$(curl -s -o /dev/null -w "%{http_code}" http://192.168.1.202:3001/api/hosts 2>/dev/null)
    if [ "$CODE" = "200" ]; then
        echo -e "${GREEN}✓ Accessible depuis le gateway (Code: $CODE)${NC}"
    else
        echo -e "${YELLOW}⚠ Code: $CODE${NC}"
        echo "  Vérifiez que le service BooxStream est actif sur 192.168.1.202:3001"
    fi
else
    echo -e "${YELLOW}⚠ curl non disponible pour le test${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "CONFIGURATION TRAEFIK (si Option 1)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Si vous choisissez l'Option 1, ajoutez dans Traefik:"
echo ""
echo "  # Dans votre config Traefik (docker-compose ou traefik.yml)"
echo "  http:"
echo "    routers:"
echo "      booxstream:"
echo "        rule: \"Host(\`booxstream.kevinvdb.dev\`)\""
echo "        service: booxstream"
echo "        # Middleware pour Authentik si nécessaire"
echo ""
echo "    services:"
echo "      booxstream:"
echo "        loadBalancer:"
echo "          servers:"
echo "            - url: \"http://192.168.1.202:3001\""
echo ""

