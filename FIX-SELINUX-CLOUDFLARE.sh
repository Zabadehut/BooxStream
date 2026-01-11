#!/bin/bash
# Script pour corriger le problème SELinux avec cloudflared

echo "╔══════════════════════════════════════════════════════════╗"
echo "║   Correction SELinux pour cloudflared                    ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

CLOUDFLARED_PATH="/usr/local/bin/cloudflared"

# 1. Vérifier SELinux
echo "1. Vérification SELinux..."
SELINUX_STATUS=$(getenforce)
echo "   Statut: $SELINUX_STATUS"
echo ""

if [ "$SELINUX_STATUS" != "Enforcing" ]; then
    echo "   SELinux n'est pas en mode Enforcing, le problème vient d'ailleurs"
    exit 1
fi

# 2. Afficher le contexte actuel
echo "2. Contexte SELinux actuel:"
ls -Z "$CLOUDFLARED_PATH"
echo ""

# 3. Corriger le contexte SELinux
echo "3. Correction du contexte SELinux..."
echo "   Option A: Définir le contexte bin_t (binaire système)"
sudo setsebool -P httpd_can_network_connect 1
sudo semanage fcontext -a -t bin_t "$CLOUDFLARED_PATH" 2>/dev/null || \
sudo semanage fcontext -m -t bin_t "$CLOUDFLARED_PATH" 2>/dev/null || \
echo "   semanage non disponible, utilisation de chcon..."

sudo chcon -t bin_t "$CLOUDFLARED_PATH" 2>/dev/null || {
    echo "   ⚠ chcon a échoué, essai avec un contexte alternatif..."
    sudo chcon -t usr_t "$CLOUDFLARED_PATH" 2>/dev/null || \
    sudo chcon -t system_u:object_r:bin_t:s0 "$CLOUDFLARED_PATH" 2>/dev/null || \
    echo "   ⚠ Impossible de changer le contexte, essai désactivation temporaire SELinux"
}

echo ""
echo "4. Nouveau contexte:"
ls -Z "$CLOUDFLARED_PATH"
echo ""

# 4. Alternative: Désactiver SELinux temporairement (pour test)
echo "5. Si le problème persiste, vous pouvez désactiver SELinux temporairement:"
echo "   sudo setenforce 0"
echo "   (Mode permissif - pour test seulement)"
echo ""

# 5. Redémarrer le service
echo "6. Redémarrage du service..."
sudo systemctl daemon-reload
sudo systemctl restart cloudflared
sleep 3

echo ""
echo "7. Statut du service:"
sudo systemctl status cloudflared --no-pager -l | head -25

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║   Correction terminée                                    ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

if sudo systemctl is-active --quiet cloudflared; then
    echo "✓ Service cloudflared fonctionne!"
    echo ""
    echo "Test:"
    echo "  curl https://booxstream.kevinvdb.dev/api/hosts"
else
    echo "✗ Le service ne fonctionne toujours pas"
    echo ""
    echo "Essayez de désactiver SELinux temporairement pour tester:"
    echo "  sudo setenforce 0"
    echo "  sudo systemctl restart cloudflared"
    echo "  sudo systemctl status cloudflared"
    echo ""
    echo "Si ça fonctionne, configurez SELinux correctement:"
    echo "  sudo semanage fcontext -a -t bin_t '/usr/local/bin/cloudflared'"
    echo "  sudo restorecon -v /usr/local/bin/cloudflared"
    echo "  sudo setenforce 1"
fi
echo ""

