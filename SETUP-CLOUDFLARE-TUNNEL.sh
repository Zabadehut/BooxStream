#!/bin/bash
# Script d'installation Cloudflare Tunnel pour BooxStream
# Usage: ./SETUP-CLOUDFLARE-TUNNEL.sh

# Ne pas arrêter sur erreur pour certaines commandes optionnelles
set -e

echo "=== Configuration Cloudflare Tunnel pour BooxStream ==="
echo ""

# 1. Installer cloudflared (si pas déjà installé)
echo "1. Vérification de cloudflared..."
if ! command -v cloudflared >/dev/null 2>&1; then
    echo "   Installation de cloudflared..."
    cd /tmp
    if [ ! -f "cloudflared-linux-amd64" ]; then
        wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
    fi
    sudo mv cloudflared-linux-amd64 /usr/local/bin/cloudflared
    sudo chmod +x /usr/local/bin/cloudflared
    sudo chown root:root /usr/local/bin/cloudflared
else
    echo "   cloudflared déjà installé"
fi

echo "   Version:"
cloudflared --version
echo ""

# 2. Authentifier (si pas déjà authentifié)
echo "2. Vérification de l'authentification..."
if [ ! -f ~/.cloudflared/cert.pem ]; then
    echo "   Authentification Cloudflare..."
    echo "   Une fenêtre de navigateur va s'ouvrir pour vous connecter."
    cloudflared tunnel login
else
    echo "   Déjà authentifié (cert.pem existe)"
fi
echo ""

# 3. Utiliser le tunnel existant
echo "3. Sélection du tunnel..."

# Tunnel ID existant (gateway-tunnel)
EXISTING_TUNNEL_ID="491bddf7-fbfa-4f8e-8e1f-417dccee4c17"
EXISTING_TUNNEL_NAME="gateway-tunnel"

# Lister tous les tunnels disponibles
echo "   Recherche des tunnels disponibles..."
TUNNEL_LIST=$(cloudflared tunnel list 2>/dev/null || echo "")

if [ -z "$TUNNEL_LIST" ]; then
    echo "   ERREUR: Impossible de lister les tunnels. Vérifiez votre authentification."
    exit 1
fi

# Vérifier si le tunnel avec cet ID existe
TUNNEL_INFO=$(echo "$TUNNEL_LIST" | grep "$EXISTING_TUNNEL_ID" || echo "")

if [ -n "$TUNNEL_INFO" ]; then
    echo "   ✓ Tunnel trouvé: $EXISTING_TUNNEL_ID"
    TUNNEL_ID="$EXISTING_TUNNEL_ID"
    TUNNEL_NAME=$(echo "$TUNNEL_INFO" | awk '{print $2}')
    if [ -z "$TUNNEL_NAME" ] || [ "$TUNNEL_NAME" = "$EXISTING_TUNNEL_ID" ]; then
        TUNNEL_NAME="$EXISTING_TUNNEL_NAME"
    fi
    echo "   Nom du tunnel: $TUNNEL_NAME"
else
    echo "   Tunnel $EXISTING_TUNNEL_ID non trouvé dans la liste."
    echo "   Tunnels disponibles:"
    echo "$TUNNEL_LIST" | tail -n +2 | nl -w2 -s'. '
    echo ""
    # Chercher gateway-tunnel en priorité
    GATEWAY_TUNNEL=$(echo "$TUNNEL_LIST" | grep -i "gateway" || echo "")
    if [ -n "$GATEWAY_TUNNEL" ]; then
        echo "   Utilisation du tunnel gateway-tunnel trouvé..."
        TUNNEL_ID=$(echo "$GATEWAY_TUNNEL" | awk '{print $1}')
        TUNNEL_NAME=$(echo "$GATEWAY_TUNNEL" | awk '{print $2}')
    else
        echo "   Utilisation du premier tunnel disponible..."
        TUNNEL_ID=$(echo "$TUNNEL_LIST" | tail -n +2 | head -1 | awk '{print $1}')
        TUNNEL_NAME=$(echo "$TUNNEL_LIST" | tail -n +2 | head -1 | awk '{print $2}')
    fi
    if [ -z "$TUNNEL_NAME" ] || [ "$TUNNEL_NAME" = "$TUNNEL_ID" ]; then
        TUNNEL_NAME="gateway-tunnel"
    fi
    echo "   Tunnel sélectionné: $TUNNEL_NAME (ID: $TUNNEL_ID)"
fi

echo "   Tunnel ID: $TUNNEL_ID"
echo "   Tunnel Name: $TUNNEL_NAME"
echo ""

# 4. Créer la configuration
echo "4. Création de la configuration..."
mkdir -p ~/.cloudflared

cat > ~/.cloudflared/config.yml << EOF
tunnel: $TUNNEL_ID
credentials-file: /home/$USER/.cloudflared/$TUNNEL_ID.json

ingress:
  # Interface web + WebSocket (port 3001)
  - hostname: booxstream.kevinvdb.dev
    service: http://localhost:3001
  
  # Catch-all
  - service: http_status:404
EOF

echo "   Configuration créée: ~/.cloudflared/config.yml"
echo ""

# 5. Configurer le DNS
echo "5. Configuration DNS..."
# Utiliser le nom du tunnel ou l'ID si le nom n'est pas disponible
DNS_TUNNEL_ID=${TUNNEL_NAME:-$TUNNEL_ID}
echo "   Configuration DNS pour booxstream.kevinvdb.dev avec tunnel: $DNS_TUNNEL_ID"

# Désactiver temporairement set -e pour cette commande
set +e
DNS_RESULT=$(cloudflared tunnel route dns $DNS_TUNNEL_ID booxstream.kevinvdb.dev 2>&1)
DNS_EXIT_CODE=$?
set -e

if [ $DNS_EXIT_CODE -eq 0 ]; then
    echo "   ✓ DNS configuré avec succès"
else
    # Vérifier si c'est parce que la route existe déjà
    if echo "$DNS_RESULT" | grep -qi "already exists\|already configured"; then
        echo "   ✓ Route DNS existe déjà (c'est normal)"
    else
        echo "   ⚠ Note: Erreur lors de la configuration DNS:"
        echo "   $DNS_RESULT"
        echo "   Vérification des routes DNS existantes..."
        set +e
        EXISTING_ROUTES=$(cloudflared tunnel route dns list 2>/dev/null | grep -E "(booxstream|$TUNNEL_ID)" || echo "")
        set -e
        if [ -n "$EXISTING_ROUTES" ]; then
            echo "   Routes existantes trouvées:"
            echo "$EXISTING_ROUTES"
        else
            echo "   Aucune route trouvée. Vous devrez peut-être configurer le DNS manuellement."
        fi
    fi
fi
echo ""

# 6. Créer le service systemd
echo "6. Création du service systemd..."
sudo tee /etc/systemd/system/cloudflared.service > /dev/null << EOF
[Unit]
Description=Cloudflare Tunnel
After=network.target

[Service]
Type=simple
User=$USER
ExecStart=/usr/local/bin/cloudflared tunnel --config /home/$USER/.cloudflared/config.yml run
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable cloudflared
sudo systemctl start cloudflared

echo "   Service créé et démarré"
echo ""

# 7. Afficher le statut
echo "7. Statut du service:"
sudo systemctl status cloudflared --no-pager -l | head -20
echo ""

echo "=== Installation terminée! ==="
echo ""
echo "Pour voir les logs en temps réel:"
echo "  sudo journalctl -u cloudflared -f"
echo ""
echo "Pour tester l'accès:"
echo "  curl https://booxstream.kevinvdb.dev/api/hosts"
echo ""
echo "Note: L'application Android utilisera automatiquement"
echo "      wss://booxstream.kevinvdb.dev/android-ws pour le WebSocket"

