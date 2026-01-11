# Vérification du service BooxStream sur Rocky Linux

## Après le déploiement

### 1. Vérifier que le service est actif

```bash
ssh kvdb@192.168.1.202
sudo systemctl status booxstream-web
```

**Résultat attendu** : `active (running)`

### 2. Vérifier les logs du service

```bash
# Logs en temps réel
sudo journalctl -u booxstream-web -f

# Derniers logs
sudo journalctl -u booxstream-web -n 50 --no-pager
```

**Résultat attendu** : Vous devriez voir :
```
╔════════════════════════════════════════╗
║   BooxStream Web Server démarré!      ║
╠════════════════════════════════════════╣
║ 🌐 API Web: http://localhost:3001      ║
║ 📱 Android WebSocket: port 8080        ║
║ 👁️  Viewer WebSocket: port 3001        ║
╚════════════════════════════════════════╝
```

### 3. Vérifier que le service écoute sur les ports

```bash
sudo netstat -tlnp | grep -E '3001|8080'
# ou
sudo ss -tlnp | grep -E '3001|8080'
```

**Résultat attendu** :
- Port 3001 : Écoute (interface web + WebSocket viewers)
- Port 8080 : Écoute (WebSocket Android)

### 4. Tester l'API localement

```bash
curl http://localhost:3001/api/hosts
```

**Résultat attendu** : `[]` (liste vide si aucun hôte enregistré) ou une liste JSON d'hôtes

### 5. Si le service ne démarre pas

```bash
# Voir les erreurs détaillées
sudo journalctl -u booxstream-web -n 100 --no-pager

# Vérifier le fichier .env
cat /opt/booxstream/web/.env

# Vérifier que Node.js est installé
node --version
npm --version

# Tester manuellement
cd /opt/booxstream/web
node server.js
```

### 6. Redémarrer le service

```bash
sudo systemctl restart booxstream-web
sudo systemctl status booxstream-web
```

## Commandes utiles

```bash
# Démarrer le service
sudo systemctl start booxstream-web

# Arrêter le service
sudo systemctl stop booxstream-web

# Redémarrer le service
sudo systemctl restart booxstream-web

# Voir les logs en temps réel
sudo journalctl -u booxstream-web -f

# Voir les 100 dernières lignes
sudo journalctl -u booxstream-web -n 100

# Voir les logs depuis aujourd'hui
sudo journalctl -u booxstream-web --since today
```

