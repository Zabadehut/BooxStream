# Vérification des logs serveur BooxStream

## Vérifier les logs du service

```bash
ssh kvdb@192.168.1.202

# Logs en temps réel
sudo journalctl -u booxstream-web -f

# Derniers logs (50 lignes)
sudo journalctl -u booxstream-web -n 50 --no-pager

# Logs depuis aujourd'hui
sudo journalctl -u booxstream-web --since today --no-pager

# Logs avec erreurs seulement
sudo journalctl -u booxstream-web -p err --no-pager
```

## Vérifier que le service écoute

```bash
# Vérifier les ports
sudo netstat -tlnp | grep -E '3001|8080'
# ou
sudo ss -tlnp | grep -E '3001|8080'
```

## Tester l'API localement

```bash
# Tester l'endpoint d'enregistrement
curl -X POST http://localhost:3001/api/hosts/register \
  -H "Content-Type: application/json" \
  -d '{"uuid":"test-uuid-123","name":"Test Device"}'

# Lister les hôtes
curl http://localhost:3001/api/hosts
```

## Vérifier la configuration

```bash
# Vérifier le fichier .env
cat /opt/booxstream/web/.env

# Vérifier que la base de données existe
ls -lh /opt/booxstream/web/booxstream.db

# Vérifier les permissions
ls -la /opt/booxstream/web/
```

## Redémarrer le service si nécessaire

```bash
sudo systemctl restart booxstream-web
sudo systemctl status booxstream-web
```

