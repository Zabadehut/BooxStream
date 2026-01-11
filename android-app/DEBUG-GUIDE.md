# Guide de débogage - BooxStream Android

## Problème : Erreur lors du lancement du stream

### Étape 1 : Préparer la capture des logs

Ouvrez un terminal PowerShell et exécutez :

```powershell
cd android-app
.\debug-stream.ps1
```

**OU** pour voir les erreurs récentes :

```powershell
.\quick-debug.ps1
```

### Étape 2 : Lancer le stream depuis l'application

1. Ouvrez l'application BooxStream sur la tablette
2. Vérifiez l'URL de l'API affichée
3. Cliquez sur "Démarrer le streaming"
4. Autorisez la capture d'écran si demandé

### Étape 3 : Analyser les logs

Les logs devraient afficher :

#### Si l'enregistrement échoue :
```
ApiClient: Tentative d'enregistrement hôte: [URL]
ApiClient: Erreur enregistrement hôte: [détails]
ApiClient: URL: [URL utilisée]
```

#### Si le WebSocket échoue :
```
ScreenCaptureService: URL WebSocket construite: [URL]
ScreenCaptureService: Tentative de connexion WebSocket à: [URL]
ScreenCaptureService: Erreur WebSocket: [détails]
```

## Erreurs courantes et solutions

### 1. "Erreur enregistrement hôte" - IOException

**Cause** : L'application ne peut pas se connecter au serveur

**Vérifications** :
- L'URL de l'API est-elle correcte ? (doit être `http://192.168.1.202:3001` ou votre domaine)
- Le serveur est-il accessible depuis la tablette ?
- Le service `booxstream-web` tourne-t-il sur le serveur ?

**Solution** :
```bash
# Sur le serveur
ssh kvdb@192.168.1.202
sudo systemctl status booxstream-web
curl http://localhost:3001/api/hosts
```

### 2. "Erreur WebSocket" - Connection refused

**Cause** : Le port 8080 n'est pas accessible ou le serveur n'écoute pas

**Vérifications** :
- Le serveur écoute-t-il sur le port 8080 ?
- Le firewall autorise-t-il le port 8080 ?

**Solution** :
```bash
# Sur le serveur
sudo netstat -tlnp | grep 8080
sudo firewall-cmd --list-ports
```

### 3. "Erreur authentification" - Token invalide

**Cause** : Le token JWT n'est pas valide ou expiré

**Solution** : Relancez l'application pour obtenir un nouveau token

### 4. URL WebSocket incorrecte

**Symptôme** : L'URL WebSocket construite ne correspond pas au serveur

**Vérification** : Regardez dans les logs :
```
ScreenCaptureService: URL WebSocket construite: ws://192.168.1.202:8080
```

Si l'URL est incorrecte, vérifiez l'URL de l'API dans l'application.

## Commandes utiles

### Voir tous les logs BooxStream
```powershell
.\adb-helper.ps1 logcat | Select-String "booxstreamer"
```

### Voir seulement les erreurs
```powershell
.\adb-helper.ps1 logcat | Select-String "booxstreamer.*E|ERROR|Exception|Failed"
```

### Vérifier que l'app est installée
```powershell
.\check-app.ps1
```

### Vérifier le serveur
```bash
ssh kvdb@192.168.1.202
sudo journalctl -u booxstream-web -f
```

## Test manuel de l'API

Pour tester si le serveur répond correctement :

```bash
ssh kvdb@192.168.1.202

# Tester l'enregistrement
curl -X POST http://localhost:3001/api/hosts/register \
  -H "Content-Type: application/json" \
  -d '{"uuid":"test-uuid-123","name":"Test Device","public_ip":"192.168.1.100"}'

# Devrait retourner un JSON avec success: true et un token
```

Si cela fonctionne, le problème vient de la connexion réseau entre la tablette et le serveur.

