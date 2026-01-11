#!/bin/bash
# Script de vérification complète du tunnel Cloudflare

echo "=== Vérification du tunnel Cloudflare ==="
echo ""

TUNNEL_ID="a40eeeac-5f83-4d51-9da2-67a0c9e0e975"
CREDENTIALS_FILE="$HOME/.cloudflared/$TUNNEL_ID.json"
CONFIG_FILE="$HOME/.cloudflared/config.yml"

# 1. Vérifier le fichier credentials
echo "1. Vérification du fichier credentials..."
if [ -f "$CREDENTIALS_FILE" ]; then
    echo "   ✓ Fichier existe: $CREDENTIALS_FILE"
    ls -la "$CREDENTIALS_FILE"
    echo ""
    echo "   Contenu:"
    cat "$CREDENTIALS_FILE"
    echo ""
else
    echo "   ✗ Fichier manquant: $CREDENTIALS_FILE"
    echo "   Vous devez créer ce fichier avec AccountTag et TunnelSecret"
    exit 1
fi

# 2. Vérifier la configuration
echo "2. Vérification de la configuration..."
if [ -f "$CONFIG_FILE" ]; then
    echo "   ✓ Configuration existe: $CONFIG_FILE"
    echo ""
    echo "   Contenu:"
    cat "$CONFIG_FILE"
    echo ""
else
    echo "   ✗ Configuration manquante: $CONFIG_FILE"
    exit 1
fi

# 3. Vérifier le service cloudflared
echo "3. Statut du service cloudflared..."
sudo systemctl status cloudflared --no-pager -l | head -20
echo ""

# 4. Vérifier les logs récents
echo "4. Derniers logs (50 lignes):"
sudo journalctl -u cloudflared -n 50 --no-pager | tail -20
echo ""

# 5. Vérifier que le serveur local fonctionne
echo "5. Test du serveur local..."
if curl -s http://localhost:3001/api/hosts > /dev/null; then
    echo "   ✓ Serveur local répond sur localhost:3001"
    curl -s http://localhost:3001/api/hosts | head -5
else
    echo "   ✗ Serveur local ne répond pas sur localhost:3001"
    echo "   Vérifiez: sudo systemctl status booxstream-web"
fi
echo ""

# 6. Test de l'accès via le domaine
echo "6. Test de l'accès via le domaine..."
if curl -s https://booxstream.kevinvdb.dev/api/hosts > /dev/null; then
    echo "   ✓ Domaine accessible: https://booxstream.kevinvdb.dev"
    curl -s https://booxstream.kevinvdb.dev/api/hosts | head -5
else
    echo "   ✗ Domaine non accessible ou erreur"
    echo "   Vérifiez les logs du tunnel ci-dessus"
fi
echo ""

echo "=== Vérification terminée ==="
echo ""
echo "Si le service ne fonctionne pas, essayez:"
echo "  sudo systemctl stop cloudflared"
echo "  cloudflared tunnel --config ~/.cloudflared/config.yml run"
echo "  (Cela affichera les erreurs en temps réel)"

