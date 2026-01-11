# Connexion au serveur pour diagnostic

## Connexion SSH

```bash
ssh kvdb@192.168.1.202
# Mot de passe: Zabadehut1491!
```

## Script de diagnostic

Une fois connecté, exécutez le script de diagnostic :

```bash
# Si le script est déjà sur le serveur
cd /opt/booxstream
chmod +x DIAGNOSE-SERVER.sh
./DIAGNOSE-SERVER.sh

# OU copier depuis votre PC
scp DIAGNOSE-SERVER.sh kvdb@192.168.1.202:/tmp/
ssh kvdb@192.168.1.202
chmod +x /tmp/DIAGNOSE-SERVER.sh
/tmp/DIAGNOSE-SERVER.sh
```

## Commandes de diagnostic rapide

```bash
# 1. Vérifier cloudflared
ls -la /usr/local/bin/cloudflared
file /usr/local/bin/cloudflared
/usr/local/bin/cloudflared --version

# 2. Vérifier le service
sudo systemctl status cloudflared
sudo journalctl -u cloudflared -n 50

# 3. Vérifier la configuration
cat ~/.cloudflared/config.yml
ls -la ~/.cloudflared/

# 4. Vérifier le serveur web
sudo systemctl status booxstream-web
curl http://localhost:3001/api/hosts
sudo ss -tlnp | grep 3001

# 5. Test manuel du tunnel
sudo systemctl stop cloudflared
cloudflared tunnel --config ~/.cloudflared/config.yml run
# (Voir les erreurs en temps réel, puis Ctrl+C)
```

## Solutions possibles

### Si cloudflared ne fonctionne pas :

1. **Réinstaller cloudflared** :
```bash
cd /tmp
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
sudo mv cloudflared-linux-amd64 /usr/local/bin/cloudflared
sudo chmod +x /usr/local/bin/cloudflared
sudo chown root:root /usr/local/bin/cloudflared
```

2. **Vérifier SELinux** :
```bash
getenforce
# Si "Enforcing", essayer:
sudo setenforce 0  # Temporaire
# Ou configurer SELinux correctement
```

3. **Vérifier les permissions** :
```bash
sudo chmod 755 /usr/local/bin/cloudflared
sudo chown root:root /usr/local/bin/cloudflared
```

