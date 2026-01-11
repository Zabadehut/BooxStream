#!/bin/bash
# Script de restauration sur le serveur Rocky Linux
# Restaure depuis GitHub

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DEPLOY_PATH="${DEPLOY_PATH:-/opt/booxstream}"

echo "🔄 Restauration BooxStream sur le serveur"
echo ""

# Vérifier si le dépôt existe
if [ ! -d "$DEPLOY_PATH" ]; then
    echo "❌ Dépôt non trouvé: $DEPLOY_PATH"
    echo "💡 Clonez d'abord le dépôt:"
    echo "   git clone https://github.com/Zabadehut/BooxStream.git $DEPLOY_PATH"
    exit 1
fi

# Aller dans le dépôt
cd "$DEPLOY_PATH"

# Récupérer les dernières modifications
echo "📥 Récupération depuis GitHub..."
git fetch origin
git reset --hard origin/main
git clean -fd

# Installer les dépendances
echo "📦 Installation des dépendances..."
cd server
npm install --production

# Redémarrer le service
if systemctl is-active --quiet booxstream 2>/dev/null; then
    echo "🔄 Redémarrage du service..."
    sudo systemctl restart booxstream
    echo "✅ Service redémarré"
fi

echo ""
echo "✨ Restauration terminée!"

