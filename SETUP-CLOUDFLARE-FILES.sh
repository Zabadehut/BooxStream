#!/bin/bash
# Script pour créer les fichiers Cloudflare Tunnel en tant que kvdb

echo "=== Création des fichiers Cloudflare Tunnel ==="
echo ""
echo "IMPORTANT: Ce script doit être exécuté en tant que kvdb"
echo "Si vous êtes root, exécutez: su - kvdb"
echo ""

# Vérifier que nous sommes kvdb
if [ "$USER" != "kvdb" ]; then
    echo "ERREUR: Vous devez être connecté en tant que kvdb"
    echo "Exécutez: su - kvdb"
    exit 1
fi

TUNNEL_ID="a40eeeac-5f83-4d51-9da2-67a0c9e0e975"
CREDENTIALS_FILE="$HOME/.cloudflared/$TUNNEL_ID.json"
CONFIG_FILE="$HOME/.cloudflared/config.yml"

# Créer le répertoire
mkdir -p ~/.cloudflared

echo "1. Création du fichier credentials..."
echo ""
echo "Vous devez obtenir AccountTag et TunnelSecret depuis Cloudflare Dashboard:"
echo "  Zero Trust → Networks → Tunnels → gateway-tunnel → Credentials"
echo ""

read -p "AccountTag: " ACCOUNT_TAG
read -p "TunnelSecret: " TUNNEL_SECRET

if [ -z "$ACCOUNT_TAG" ] || [ -z "$TUNNEL_SECRET" ]; then
    echo "ERREUR: AccountTag et TunnelSecret sont requis"
    exit 1
fi

# Créer le fichier credentials
cat > "$CREDENTIALS_FILE" << EOF
{"AccountTag":"$ACCOUNT_TAG","TunnelSecret":"$TUNNEL_SECRET","TunnelID":"$TUNNEL_ID","Endpoint":""}
EOF

chmod 600 "$CREDENTIALS_FILE"

echo ""
echo "✓ Fichier credentials créé: $CREDENTIALS_FILE"
echo ""

# Créer le fichier de configuration
echo "2. Création du fichier de configuration..."
cat > "$CONFIG_FILE" << EOF
tunnel: $TUNNEL_ID
credentials-file: $CREDENTIALS_FILE

ingress:
  # Interface web + WebSocket (port 3001)
  - hostname: booxstream.kevinvdb.dev
    service: http://localhost:3001
  
  # Catch-all
  - service: http_status:404
EOF

chmod 600 "$CONFIG_FILE"

echo "✓ Fichier config créé: $CONFIG_FILE"
echo ""

# Vérification
echo "3. Vérification des fichiers créés:"
echo ""
ls -la ~/.cloudflared/
echo ""
echo "Contenu du fichier credentials:"
cat "$CREDENTIALS_FILE"
echo ""
echo "Contenu du fichier config:"
cat "$CONFIG_FILE"
echo ""

echo "=== Fichiers créés avec succès! ==="
echo ""
echo "Vous pouvez maintenant redémarrer le service:"
echo "  sudo systemctl restart cloudflared"
echo "  sudo systemctl status cloudflared"
echo ""
echo "Pour tester:"
echo "  curl https://booxstream.kevinvdb.dev/api/hosts"
echo ""

