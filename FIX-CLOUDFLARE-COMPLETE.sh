#!/bin/bash
# Script complet pour corriger cloudflared

echo "╔══════════════════════════════════════════════════════════╗"
echo "║   Correction complète Cloudflare Tunnel                 ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

CLOUDFLARED_PATH="/usr/local/bin/cloudflared"

# 1. Vérifier que cloudflared existe
echo "1. Vérification de cloudflared..."
if [ ! -f "$CLOUDFLARED_PATH" ]; then
    echo "   ✗ cloudflared n'existe pas à $CLOUDFLARED_PATH"
    echo "   Installation..."
    cd /tmp
    if [ ! -f "cloudflared-linux-amd64" ]; then
        wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
    fi
    sudo mv cloudflared-linux-amd64 "$CLOUDFLARED_PATH"
else
    echo "   ✓ cloudflared existe"
fi

# 2. Afficher les permissions actuelles
echo ""
echo "2. Permissions actuelles:"
ls -la "$CLOUDFLARED_PATH"
echo ""

# 3. Corriger les permissions
echo "3. Correction des permissions..."
sudo chmod +x "$CLOUDFLARED_PATH"
sudo chown root:root "$CLOUDFLARED_PATH"

echo ""
echo "4. Permissions après correction:"
ls -la "$CLOUDFLARED_PATH"
echo ""

# 5. Vérifier que ça fonctionne en ligne de commande
echo "5. Test de cloudflared:"
"$CLOUDFLARED_PATH" --version
if [ $? -eq 0 ]; then
    echo "   ✓ cloudflared fonctionne en ligne de commande"
else
    echo "   ✗ cloudflared ne fonctionne pas"
    exit 1
fi
echo ""

# 6. Vérifier le service systemd
echo "6. Vérification du service systemd..."
cat /etc/systemd/system/cloudflared.service | grep -E "(ExecStart|User)"
echo ""

# 7. Vérifier les fichiers de configuration
echo "7. Vérification des fichiers de configuration..."
if [ -f ~/.cloudflared/config.yml ]; then
    echo "   ✓ config.yml existe"
    cat ~/.cloudflared/config.yml
else
    echo "   ✗ config.yml manquant"
fi
echo ""

if [ -f ~/.cloudflared/a40eeeac-5f83-4d51-9da2-67a0c9e0e975.json ]; then
    echo "   ✓ credentials.json existe"
    ls -la ~/.cloudflared/a40eeeac-5f83-4d51-9da2-67a0c9e0e975.json
else
    echo "   ✗ credentials.json manquant"
fi
echo ""

# 8. Redémarrer le service
echo "8. Redémarrage du service..."
sudo systemctl daemon-reload
sudo systemctl restart cloudflared
sleep 3

echo ""
echo "9. Statut du service:"
sudo systemctl status cloudflared --no-pager -l | head -30
echo ""

# 10. Voir les logs si échec
if ! sudo systemctl is-active --quiet cloudflared; then
    echo "10. Logs d'erreur (50 dernières lignes):"
    sudo journalctl -u cloudflared -n 50 --no-pager | tail -20
fi

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║   Correction terminée                                    ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

