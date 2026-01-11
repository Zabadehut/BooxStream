#!/bin/bash
# Script pour décoder le token Cloudflare et créer le fichier credentials

TOKEN="eyJhIjoiNTE1NjcxNmFlNTY2MTc3ODNkOWI2OWU5ZjU3MzhlZGUiLCJzIjoiNFlBR211UjlFMFZBRit3c3BqMHhxZ3dxNWpoem5qQkFEMVVydXgzczVkVT0iLCJ0IjoiYTQwZWVlYWMtNWY4My00ZDUxLTlkYTItNjdhMGM5ZTBlOTc1In0="

echo "=== Décodage du token Cloudflare ==="
echo ""

# Décoder le token (base64)
DECODED=$(echo "$TOKEN" | base64 -d 2>/dev/null || echo "$TOKEN" | base64decode 2>/dev/null)

if [ -z "$DECODED" ]; then
    echo "ERREUR: Impossible de décoder le token"
    exit 1
fi

echo "Token décodé (JSON):"
echo "$DECODED" | python3 -m json.tool 2>/dev/null || echo "$DECODED"
echo ""

# Extraire les valeurs (si jq est disponible)
if command -v jq >/dev/null 2>&1; then
    ACCOUNT_TAG=$(echo "$DECODED" | jq -r '.a' 2>/dev/null)
    TUNNEL_SECRET=$(echo "$DECODED" | jq -r '.s' 2>/dev/null)
    TUNNEL_ID=$(echo "$DECODED" | jq -r '.t' 2>/dev/null)
    
    echo "Valeurs extraites:"
    echo "  AccountTag: $ACCOUNT_TAG"
    echo "  TunnelSecret: $TUNNEL_SECRET"
    echo "  TunnelID: $TUNNEL_ID"
    echo ""
    
    # Créer le fichier credentials
    CREDENTIALS_FILE="$HOME/.cloudflared/$TUNNEL_ID.json"
    mkdir -p ~/.cloudflared
    
    cat > "$CREDENTIALS_FILE" << EOF
{"AccountTag":"$ACCOUNT_TAG","TunnelSecret":"$TUNNEL_SECRET","TunnelID":"$TUNNEL_ID","Endpoint":""}
EOF
    
    chmod 600 "$CREDENTIALS_FILE"
    
    echo "✓ Fichier credentials créé: $CREDENTIALS_FILE"
    echo ""
    echo "Contenu:"
    cat "$CREDENTIALS_FILE"
    echo ""
else
    echo "jq n'est pas installé. Valeurs manuelles:"
    echo "Le token décodé contient les valeurs 'a' (AccountTag), 's' (TunnelSecret), 't' (TunnelID)"
    echo "Extrayez-les manuellement depuis le JSON ci-dessus"
fi

