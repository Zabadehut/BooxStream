#!/bin/bash
# Script pour diagnostiquer et résoudre le conflit de tunnel Cloudflare

echo "╔══════════════════════════════════════════════════════════╗"
echo "║   Diagnostic conflit Cloudflare Tunnel                   ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PROBLÈME IDENTIFIÉ"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${RED}⚠ CONFLIT DÉTECTÉ${NC}"
echo ""
echo "Vous avez DEUX serveurs qui utilisent le MÊME tunnel Cloudflare:"
echo "  - Gateway (gère traefik, auth, homepage, etc.)"
echo "  - VM Linux (gère uniquement booxstream)"
echo ""
echo "Quand la VM Linux démarre cloudflared avec seulement:"
echo "  - booxstream.kevinvdb.dev → localhost:3001"
echo ""
echo "Elle écrase la configuration complète du tunnel qui devrait avoir:"
echo "  - traefik.kevinvdb.dev → ..."
echo "  - auth.kevinvdb.dev → ..."
echo "  - homepage.kevinvdb.dev → ..."
echo "  - booxstream.kevinvdb.dev → ..."
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "SOLUTIONS POSSIBLES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${CYAN}Option 1: Désactiver cloudflared sur la VM Linux${NC}"
echo "  Le tunnel principal (sur le gateway) gère déjà booxstream"
echo "  → Désactiver le service cloudflared sur cette VM"
echo ""
echo -e "${CYAN}Option 2: Synchroniser les configurations${NC}"
echo "  Les deux serveurs doivent avoir la MÊME config.yml complète"
echo "  → Ajouter toutes les routes dans ~/.cloudflared/config.yml"
echo ""
echo -e "${CYAN}Option 3: Tunnel séparé pour BooxStream${NC}"
echo "  Créer un nouveau tunnel uniquement pour booxstream"
echo "  → Plus complexe mais plus isolé"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "VÉRIFICATION ACTUELLE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Vérifier la config actuelle
if [ -f ~/.cloudflared/config.yml ]; then
    echo -e "${CYAN}Config actuelle sur cette VM:${NC}"
    cat ~/.cloudflared/config.yml
    echo ""
else
    echo -e "${YELLOW}⚠ Pas de config trouvée${NC}"
fi

# Vérifier si le service est actif
if systemctl is-active --quiet cloudflared; then
    echo -e "${RED}✗ Service cloudflared ACTIF sur cette VM${NC}"
    echo "  → C'est probablement la cause du conflit!"
    echo ""
    echo "Pour désactiver temporairement:"
    echo "  sudo systemctl stop cloudflared"
    echo "  sudo systemctl disable cloudflared"
else
    echo -e "${GREEN}✓ Service cloudflared INACTIF sur cette VM${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "RECOMMANDATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}→ Option 1 recommandée:${NC}"
echo "  Le tunnel principal sur votre gateway devrait gérer booxstream"
echo "  Il suffit d'ajouter la route dans la config du gateway:"
echo ""
echo "  Sur votre gateway, ajoutez dans /opt/cloudflare/config.yml:"
echo ""
echo "  ingress:"
echo "    # ... autres routes existantes ..."
echo "    - hostname: booxstream.kevinvdb.dev"
echo "      service: http://192.168.1.202:3001"
echo "    - service: http_status:404"
echo ""
echo "  Puis désactivez cloudflared sur cette VM Linux."
echo ""

