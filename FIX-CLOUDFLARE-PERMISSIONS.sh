#!/bin/bash
# Script pour corriger les permissions de cloudflared

echo "=== Correction des permissions cloudflared ==="
echo ""

CLOUDFLARED_PATH="/usr/local/bin/cloudflared"

# Vérifier si cloudflared existe
if [ ! -f "$CLOUDFLARED_PATH" ]; then
    echo "ERREUR: cloudflared n'existe pas à $CLOUDFLARED_PATH"
    echo "Installation de cloudflared..."
    cd /tmp
    if [ ! -f "cloudflared-linux-amd64" ]; then
        wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
    fi
    sudo mv cloudflared-linux-amd64 "$CLOUDFLARED_PATH"
fi

# Afficher les permissions actuelles
echo "Permissions actuelles:"
ls -la "$CLOUDFLARED_PATH"
echo ""

# Corriger les permissions
echo "Correction des permissions..."
sudo chmod +x "$CLOUDFLARED_PATH"
sudo chown root:root "$CLOUDFLARED_PATH"

echo ""
echo "Permissions après correction:"
ls -la "$CLOUDFLARED_PATH"
echo ""

# Vérifier que ça fonctionne
echo "Test de cloudflared:"
"$CLOUDFLARED_PATH" --version
echo ""

# Redémarrer le service
echo "Redémarrage du service cloudflared..."
sudo systemctl restart cloudflared
sleep 2

echo ""
echo "Statut du service:"
sudo systemctl status cloudflared --no-pager -l | head -20

echo ""
echo "=== Correction terminée! ==="
echo ""
echo "Si le service fonctionne toujours pas, vérifiez:"
echo "  1. Le fichier credentials existe: ~/.cloudflared/a40eeeac-5f83-4d51-9da2-67a0c9e0e975.json"
echo "  2. La configuration est correcte: cat ~/.cloudflared/config.yml"
echo "  3. Les logs: sudo journalctl -u cloudflared -n 50"
echo ""

