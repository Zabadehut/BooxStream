#!/bin/bash
# Script de déploiement à copier sur le serveur
# Usage: Copiez ce fichier sur le serveur et exécutez-le

set -e

DEPLOY_PATH="/opt/booxstream"
REPO_URL="https://github.com/Zabadehut/BooxStream.git"
BRANCH="main"

echo "🚀 Déploiement BooxStream sur le serveur"
echo ""

# Créer le répertoire si nécessaire
if [ -d "$DEPLOY_PATH" ] && [ -d "$DEPLOY_PATH/.git" ]; then
    echo "📥 Mise à jour du dépôt existant..."
    cd "$DEPLOY_PATH"
    git fetch origin
    git reset --hard origin/$BRANCH
    git clean -fd
else
    echo "📥 Clonage du dépôt..."
    sudo mkdir -p "$(dirname "$DEPLOY_PATH")"
    sudo chown $USER:$USER "$(dirname "$DEPLOY_PATH")"
    git clone -b "$BRANCH" "$REPO_URL" "$DEPLOY_PATH"
    cd "$DEPLOY_PATH"
fi

# Installer les dépendances du site web
if [ -d "web" ]; then
    echo "📦 Installation des dépendances web..."
    cd web
    npm install
    cd ..
fi

# Installer les dépendances du serveur (legacy)
if [ -d "server" ]; then
    echo "📦 Installation des dépendances server..."
    cd server
    npm install
    cd ..
fi

# Créer le fichier .env pour le site web si nécessaire
if [ ! -f "web/.env" ]; then
    echo "⚙️  Création du fichier .env..."
    cat > web/.env << 'EOF'
PORT=3001
JWT_SECRET=changez-cette-cle-secrete-en-production-$(openssl rand -hex 32)
DB_PATH=/opt/booxstream/web/booxstream.db
DOMAIN=booxstream.kevinvdb.dev
EOF
fi

echo ""
echo "✅ Déploiement terminé!"
echo ""
echo "Pour démarrer le site web:"
echo "  cd /opt/booxstream/web"
echo "  node server.js"

