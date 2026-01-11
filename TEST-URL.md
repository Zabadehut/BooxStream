# Tests URL et configuration Authentik

## URL à utiliser dans Authentik

Avec Cloudflare Tunnel configuré, l'URL publique de votre application est :

```
https://booxstream.kevinvdb.dev
```

### Configuration Authentik

#### Pour les Providers (OAuth, SAML, etc.)
- **URL de redirection** : `https://booxstream.kevinvdb.dev/api/auth/callback` (ou selon votre configuration)
- **URL de l'application** : `https://booxstream.kevinvdb.dev`

#### Pour les Applications
- **URL interne** : `http://localhost:3001` (si Authentik est sur le même serveur)
- **URL externe** : `https://booxstream.kevinvdb.dev`
- **URL publique** : `https://booxstream.kevinvdb.dev`

## Commandes curl détaillées pour tester

### 1. Test de base avec headers complets

```bash
# Test de l'API avec tous les détails
curl -v https://booxstream.kevinvdb.dev/api/hosts

# Test avec affichage des headers de réponse
curl -i https://booxstream.kevinvdb.dev/api/hosts

# Test avec headers de requête et réponse
curl -v -H "Accept: application/json" https://booxstream.kevinvdb.dev/api/hosts
```

### 2. Test avec code de statut HTTP

```bash
# Afficher seulement le code de statut
curl -s -o /dev/null -w "Code HTTP: %{http_code}\n" https://booxstream.kevinvdb.dev/api/hosts

# Afficher le code de statut et le temps de réponse
curl -s -o /dev/null -w "Code HTTP: %{http_code}\nTemps: %{time_total}s\n" https://booxstream.kevinvdb.dev/api/hosts
```

### 3. Test de l'interface web

```bash
# Test de la page d'accueil
curl -v https://booxstream.kevinvdb.dev/

# Test avec suivi des redirections
curl -L -v https://booxstream.kevinvdb.dev/
```

### 4. Test depuis le serveur (local)

```bash
# Test du serveur local directement
curl -v http://localhost:3001/api/hosts

# Comparaison local vs externe
echo "=== Test local ==="
curl -s http://localhost:3001/api/hosts
echo ""
echo "=== Test externe ==="
curl -s https://booxstream.kevinvdb.dev/api/hosts
```

### 5. Test avec formatage JSON

```bash
# Si jq est installé
curl -s https://booxstream.kevinvdb.dev/api/hosts | jq .

# Sinon, avec python
curl -s https://booxstream.kevinvdb.dev/api/hosts | python3 -m json.tool
```

### 6. Test complet avec toutes les informations

```bash
curl -v \
  -H "User-Agent: BooxStream-Test" \
  -H "Accept: application/json" \
  -w "\n\n=== Statistiques ===\nCode HTTP: %{http_code}\nTemps total: %{time_total}s\nTaille: %{size_download} bytes\n" \
  https://booxstream.kevinvdb.dev/api/hosts
```

## Script de test complet

```bash
#!/bin/bash
echo "=== Test complet BooxStream ==="
echo ""

echo "1. Test serveur local..."
curl -s -o /dev/null -w "  Code: %{http_code} | Temps: %{time_total}s\n" http://localhost:3001/api/hosts

echo ""
echo "2. Test via Cloudflare Tunnel..."
curl -s -o /dev/null -w "  Code: %{http_code} | Temps: %{time_total}s\n" https://booxstream.kevinvdb.dev/api/hosts

echo ""
echo "3. Contenu de la réponse..."
curl -s https://booxstream.kevinvdb.dev/api/hosts | head -20

echo ""
echo "4. Headers de réponse..."
curl -I https://booxstream.kevinvdb.dev/api/hosts | head -10
```

