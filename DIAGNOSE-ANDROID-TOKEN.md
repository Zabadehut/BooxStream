# Diagnostic erreur token Android

## Problème

L'application Android ne peut pas se connecter au serveur WebSocket et affiche "erreur token d'authentification".

## Flux d'authentification

1. **Enregistrement** : L'app Android appelle `/api/hosts/register` et reçoit un token JWT
2. **Connexion WebSocket** : L'app se connecte à `wss://booxstream.kevinvdb.dev/android-ws`
3. **Authentification** : L'app envoie `{"type": "auth", "token": "..."}`
4. **Réponse serveur** : Le serveur doit répondre `{"type": "authenticated"}` ou `{"type": "error", "message": "..."}`

## Corrections apportées

### 1. Gestion de l'upgrade HTTP vers WebSocket

Le serveur ne gérait pas correctement l'upgrade HTTP pour `/android-ws` via Traefik. 

**Avant** :
```javascript
const wssAndroid = new WebSocket.Server({ 
    server: server,
    path: '/android-ws'
});
```

**Après** :
```javascript
const wssAndroid = new WebSocket.Server({ noServer: true });

server.on('upgrade', (request, socket, head) => {
    if (request.url === '/android-ws') {
        wssAndroid.handleUpgrade(request, socket, head, (ws) => {
            wssAndroid.emit('connection', ws, request);
        });
    } else {
        wssViewers.handleUpgrade(request, socket, head, (ws) => {
            wssViewers.emit('connection', ws, request);
        });
    }
});
```

## Vérifications

### 1. Vérifier que le serveur écoute correctement

```bash
# Sur le serveur
sudo systemctl status booxstream-web
sudo journalctl -u booxstream-web -n 50 -f
```

Vous devriez voir :
- `📱 Connexion Android WebSocket (HTTP)` quand l'app se connecte
- `✅ Hôte authentifié: [uuid]` si l'authentification réussit
- `Erreur message WebSocket:` si l'authentification échoue

### 2. Vérifier le token JWT

Le token doit être valide et contenir :
```json
{
  "uuid": "...",
  "type": "host"
}
```

### 3. Vérifier les logs Android

Sur la tablette, utilisez `adb logcat` :

```powershell
cd android-app
.\check-logs.ps1
```

Cherchez :
- `ScreenCaptureService: URL WebSocket construite: ...`
- `ScreenCaptureService: Tentative de connexion WebSocket à: ...`
- `ScreenCaptureService: WebSocket connecté, authentification...`
- `ScreenCaptureService: Erreur authentification: ...`

### 4. Tester manuellement le WebSocket

Depuis le serveur :

```bash
# Installer wscat si nécessaire
npm install -g wscat

# Tester la connexion WebSocket
wscat -c wss://booxstream.kevinvdb.dev/android-ws

# Une fois connecté, envoyer :
{"type":"auth","token":"VOTRE_TOKEN_JWT"}
```

## Causes possibles

1. **Token invalide** : Le token JWT n'est pas valide ou a expiré
2. **JWT_SECRET différent** : Le secret utilisé pour signer le token est différent de celui utilisé pour vérifier
3. **Type de token incorrect** : Le token doit avoir `type: "host"`
4. **Problème de connexion WebSocket** : Traefik ne route pas correctement vers le serveur
5. **Problème d'upgrade HTTP** : Le serveur ne gère pas correctement l'upgrade HTTP vers WebSocket

## Solution

1. **Redéployer le serveur** avec les corrections :
```bash
# Depuis votre PC
git add web/server.js
git commit -m "Correction gestion upgrade WebSocket pour /android-ws"
git push
.\deploy-simple.ps1 -ServerOnly
```

2. **Vérifier les logs** après redéploiement

3. **Tester depuis l'app Android** et vérifier les logs

## Logs attendus (succès)

**Serveur** :
```
📱 Connexion Android WebSocket (HTTP)
✅ Hôte authentifié: [uuid]
```

**Android** :
```
ScreenCaptureService: URL WebSocket construite: wss://booxstream.kevinvdb.dev/android-ws
ScreenCaptureService: Tentative de connexion WebSocket à: wss://booxstream.kevinvdb.dev/android-ws
ScreenCaptureService: WebSocket connecté, authentification...
ScreenCaptureService: Authentifié avec succès
```

