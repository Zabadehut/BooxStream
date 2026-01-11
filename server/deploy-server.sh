#!/bin/bash
# Script de déploiement sur le serveur Rocky Linux
# À exécuter sur le serveur après un git pull

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SERVER_DIR="$SCRIPT_DIR"

echo "🚀 Déploiement BooxStream sur le serveur"
echo ""

# Vérifier que nous sommes dans le bon répertoire
if [ ! -f "$SERVER_DIR/server.js" ]; then
    echo "❌ Erreur: server.js non trouvé dans $SERVER_DIR"
    exit 1
fi

# Installer/mettre à jour les dépendances
echo "📦 Installation des dépendances..."
cd "$SERVER_DIR"
npm install --production

# Redémarrer le service si configuré
if systemctl is-active --quiet booxstream 2>/dev/null; then
    echo "🔄 Redémarrage du service booxstream..."
    sudo systemctl restart booxstream
    echo "✅ Service redémarré"
elif systemctl list-unit-files | grep -q booxstream; then
    echo "⚠️  Service booxstream configuré mais non actif"
    echo "💡 Démarrez avec: sudo systemctl start booxstream"
else
    echo "ℹ️  Service systemd non configuré"
    echo "💡 Pour démarrer manuellement: cd $SERVER_DIR && node server.js"
fi

echo ""
echo "✨ Déploiement terminé!"

