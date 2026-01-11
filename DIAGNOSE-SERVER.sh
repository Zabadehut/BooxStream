#!/bin/bash
# Script de diagnostic complet pour le serveur BooxStream

echo "╔══════════════════════════════════════════════════════════╗"
echo "║   Diagnostic complet BooxStream                        ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# 1. Informations système
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Informations système"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Utilisateur: $(whoami)"
echo "Hostname: $(hostname)"
echo "Date: $(date)"
echo ""

# 2. Vérifier cloudflared
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. Vérification cloudflared"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
CLOUDFLARED_PATH="/usr/local/bin/cloudflared"

if [ -f "$CLOUDFLARED_PATH" ]; then
    echo "✓ Fichier existe: $CLOUDFLARED_PATH"
    echo ""
    echo "Permissions:"
    ls -la "$CLOUDFLARED_PATH"
    echo ""
    echo "Type de fichier:"
    file "$CLOUDFLARED_PATH"
    echo ""
    echo "Test d'exécution:"
    if "$CLOUDFLARED_PATH" --version 2>&1; then
        echo "✓ cloudflared fonctionne en ligne de commande"
    else
        echo "✗ cloudflared ne fonctionne pas"
        echo "Erreur: $?"
    fi
else
    echo "✗ Fichier n'existe pas: $CLOUDFLARED_PATH"
fi
echo ""

# 3. Vérifier SELinux
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. Vérification SELinux"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if command -v getenforce >/dev/null 2>&1; then
    SELINUX_STATUS=$(getenforce)
    echo "Statut SELinux: $SELINUX_STATUS"
    if [ "$SELINUX_STATUS" = "Enforcing" ]; then
        echo "⚠ SELinux est actif, cela peut bloquer cloudflared"
        echo "Vérification des contextes:"
        ls -Z "$CLOUDFLARED_PATH" 2>/dev/null || echo "Impossible de vérifier le contexte"
    fi
else
    echo "SELinux non installé ou non configuré"
fi
echo ""

# 4. Service cloudflared
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. Service cloudflared"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Statut:"
sudo systemctl status cloudflared --no-pager -l | head -20
echo ""
echo "Configuration du service:"
cat /etc/systemd/system/cloudflared.service
echo ""
echo "Derniers logs (50 lignes):"
sudo journalctl -u cloudflared -n 50 --no-pager | tail -30
echo ""

# 5. Fichiers de configuration
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. Fichiers de configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Répertoire .cloudflared:"
ls -la ~/.cloudflared/ 2>/dev/null || echo "Répertoire n'existe pas"
echo ""
echo "config.yml:"
if [ -f ~/.cloudflared/config.yml ]; then
    cat ~/.cloudflared/config.yml
else
    echo "✗ Fichier manquant"
fi
echo ""
echo "credentials.json:"
if [ -f ~/.cloudflared/a40eeeac-5f83-4d51-9da2-67a0c9e0e975.json ]; then
    ls -la ~/.cloudflared/a40eeeac-5f83-4d51-9da2-67a0c9e0e975.json
    echo "Contenu (masqué):"
    cat ~/.cloudflared/a40eeeac-5f83-4d51-9da2-67a0c9e0e975.json | sed 's/"TunnelSecret":"[^"]*"/"TunnelSecret":"***MASQUE***"/'
else
    echo "✗ Fichier manquant"
fi
echo ""

# 6. Service booxstream-web
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "6. Service booxstream-web"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Statut:"
sudo systemctl status booxstream-web --no-pager -l | head -15
echo ""
echo "Test local:"
curl -s -o /dev/null -w "Code HTTP: %{http_code}\n" http://localhost:3001/api/hosts
echo ""
echo "Ports en écoute:"
sudo ss -tlnp | grep 3001
echo ""

# 7. Test du tunnel manuellement
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "7. Test manuel du tunnel"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Arrêt du service pour test manuel..."
sudo systemctl stop cloudflared
echo ""
echo "Test manuel (5 secondes, puis Ctrl+C):"
timeout 5 cloudflared tunnel --config ~/.cloudflared/config.yml run 2>&1 || echo "Test terminé"
echo ""
echo "Redémarrage du service..."
sudo systemctl start cloudflared
echo ""

# 8. Résumé
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Résumé"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "cloudflared:"
if sudo systemctl is-active --quiet cloudflared; then
    echo "  ✓ Service actif"
else
    echo "  ✗ Service inactif"
fi
echo ""
echo "booxstream-web:"
if sudo systemctl is-active --quiet booxstream-web; then
    echo "  ✓ Service actif"
    LOCAL_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3001/api/hosts)
    echo "  Code HTTP local: $LOCAL_CODE"
else
    echo "  ✗ Service inactif"
fi
echo ""
echo "Fichiers de configuration:"
[ -f ~/.cloudflared/config.yml ] && echo "  ✓ config.yml" || echo "  ✗ config.yml manquant"
[ -f ~/.cloudflared/a40eeeac-5f83-4d51-9da2-67a0c9e0e975.json ] && echo "  ✓ credentials.json" || echo "  ✗ credentials.json manquant"
echo ""

