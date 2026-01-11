#!/bin/bash
# Solution rapide pour SELinux

echo "=== Correction rapide SELinux ==="
echo ""

# Option 1: Corriger le contexte
echo "1. Correction du contexte SELinux..."
sudo chcon -t bin_t /usr/local/bin/cloudflared 2>/dev/null || \
sudo chcon -t usr_t /usr/local/bin/cloudflared 2>/dev/null || \
sudo chcon system_u:object_r:bin_t:s0 /usr/local/bin/cloudflared 2>/dev/null

echo "Nouveau contexte:"
ls -Z /usr/local/bin/cloudflared
echo ""

# Redémarrer
echo "2. Redémarrage du service..."
sudo systemctl daemon-reload
sudo systemctl restart cloudflared
sleep 2

echo ""
echo "3. Statut:"
sudo systemctl status cloudflared --no-pager -l | head -20

echo ""
if sudo systemctl is-active --quiet cloudflared; then
    echo "✓ Service fonctionne!"
else
    echo "✗ Service ne fonctionne toujours pas"
    echo ""
    echo "Solution temporaire (désactiver SELinux):"
    echo "  sudo setenforce 0"
    echo "  sudo systemctl restart cloudflared"
fi
echo ""

