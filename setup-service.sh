#!/bin/bash
# Script à exécuter sur le serveur pour configurer le service

set -e

echo "Configuration du service BooxStream Web"
echo ""

# Mettre à jour le projet
cd /opt/booxstream
git pull origin main

# Vérifier que le fichier de service existe
if [ ! -f "web/booxstream-web.service" ]; then
    echo "ERREUR: Fichier booxstream-web.service introuvable"
    echo "Le projet doit etre a jour. Executez: git pull origin main"
    exit 1
fi

# Créer le fichier .env si nécessaire
if [ ! -f "web/.env" ]; then
    echo "Creation du fichier .env..."
    JWT_SECRET=$(openssl rand -hex 32)
    cat > web/.env << EOF
PORT=3001
JWT_SECRET=$JWT_SECRET
DB_PATH=/opt/booxstream/web/booxstream.db
DOMAIN=booxstream.kevinvdb.dev
EOF
    echo "Fichier .env cree avec JWT_SECRET genere"
fi

# Installer les dépendances si nécessaire
if [ ! -d "web/node_modules" ]; then
    echo "Installation des dependances..."
    cd web
    npm install
    cd ..
fi

# Copier le fichier de service
echo "Copie du fichier de service systemd..."
sudo cp web/booxstream-web.service /etc/systemd/system/

# Recharger systemd
sudo systemctl daemon-reload

# Activer le service
sudo systemctl enable booxstream-web

# Démarrer le service
echo "Demarrage du service..."
sudo systemctl start booxstream-web

# Afficher le statut
echo ""
echo "Statut du service:"
sudo systemctl status booxstream-web --no-pager -l

echo ""
echo "Pour voir les logs en temps reel:"
echo "  sudo journalctl -u booxstream-web -f"

