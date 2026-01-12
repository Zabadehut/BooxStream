#!/bin/bash
# Script pour corriger le fichier booxstream.yml sur le gateway

echo "╔══════════════════════════════════════════════════════════╗"
echo "║   Correction booxstream.yml sur le gateway              ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

CONFIG_FILE="/opt/traefik/config/booxstream.yml"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Vérification du fichier actuel"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}✗ Fichier non trouvé: $CONFIG_FILE${NC}"
    echo "Création du fichier..."
    mkdir -p "$(dirname "$CONFIG_FILE")"
else
    echo -e "${GREEN}✓ Fichier trouvé${NC}"
    echo ""
    echo "Contenu actuel:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    cat "$CONFIG_FILE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. Vérification de la section services"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if grep -q "services:" "$CONFIG_FILE" 2>/dev/null && grep -q "booxstream-backend:" "$CONFIG_FILE" 2>/dev/null; then
    echo -e "${GREEN}✓ Section services présente${NC}"
    echo ""
    echo "Vérification de l'indentation..."
    # Vérifier que services est bien indenté sous http
    if grep -A 5 "services:" "$CONFIG_FILE" | grep -q "^  services:"; then
        echo -e "${GREEN}✓ Indentation correcte${NC}"
    else
        echo -e "${YELLOW}⚠ Problème d'indentation détecté${NC}"
    fi
else
    echo -e "${RED}✗ Section services manquante${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. Création du fichier corrigé"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

cat > "$CONFIG_FILE" << 'EOF'
http:
  routers:
    # Route publique pour l'API mobile (sans Authentik)
    booxstream-api:
      rule: "Host(`booxstream.kevinvdb.dev`) && PathPrefix(`/api/`)"
      entrypoints:
        - web
      service: booxstream-backend
      priority: 10

    # Route publique pour WebSocket Android (sans Authentik)
    booxstream-ws:
      rule: "Host(`booxstream.kevinvdb.dev`) && Path(`/android-ws`)"
      entrypoints:
        - web
      service: booxstream-backend
      priority: 10

    # Route principale avec Authentik (interface web)
    booxstream:
      rule: "Host(`booxstream.kevinvdb.dev`)"
      entrypoints:
        - web
      middlewares:
        - authentik-forward-auth
      service: booxstream-backend
      priority: 1

  services:
    booxstream-backend:
      loadBalancer:
        servers:
          - url: "http://192.168.1.202:3001"
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Fichier créé avec succès${NC}"
else
    echo -e "${RED}✗ Erreur lors de la création du fichier${NC}"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. Vérification du format YAML"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Vérifier avec python si disponible
if command -v python3 >/dev/null 2>&1; then
    python3 -c "import yaml; yaml.safe_load(open('$CONFIG_FILE'))" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Format YAML valide${NC}"
    else
        echo -e "${RED}✗ Format YAML invalide${NC}"
        echo "Vérifiez le fichier manuellement"
    fi
else
    echo -e "${YELLOW}⚠ python3 non disponible, vérification YAML ignorée${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. Affichage du fichier final"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

cat "$CONFIG_FILE"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "6. Redémarrage de Traefik"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Redémarrage de Traefik..."
if docker ps | grep -q traefik; then
    docker restart traefik
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Traefik redémarré${NC}"
    else
        echo -e "${RED}✗ Erreur lors du redémarrage${NC}"
        echo "Redémarrez manuellement: docker restart traefik"
    fi
elif systemctl list-units | grep -q traefik; then
    sudo systemctl restart traefik
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Traefik redémarré${NC}"
    else
        echo -e "${RED}✗ Erreur lors du redémarrage${NC}"
        echo "Redémarrez manuellement: sudo systemctl restart traefik"
    fi
else
    echo -e "${YELLOW}⚠ Traefik non trouvé (Docker ou systemd)${NC}"
    echo "Redémarrez Traefik manuellement"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "RÉSUMÉ"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}✓ Fichier $CONFIG_FILE corrigé${NC}"
echo ""
echo "Vérifiez les logs Traefik:"
echo "  docker logs traefik | grep booxstream"
echo ""
echo "Les erreurs 'service does not exist' devraient disparaître."

