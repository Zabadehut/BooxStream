# BooxStream

Système complet de streaming d'écran depuis une tablette Android Boox vers une interface web via un serveur relais WebSocket.

## Architecture

- **Application Android** : Capture d'écran et streaming WebSocket
- **Serveur Rocky Linux 9** : Relais WebSocket entre Android et navigateurs
- **Interface Web** : Visualisation en temps réel du flux vidéo

## Structure du projet

```
.
├── android-app/          # Application Android
│   ├── app/
│   │   ├── build.gradle
│   │   ├── src/
│   │   │   └── main/
│   │   │       ├── AndroidManifest.xml
│   │   │       ├── java/com/example/booxstreamer/
│   │   │       │   ├── MainActivity.kt
│   │   │       │   └── ScreenCaptureService.kt
│   │   │       └── res/
│   │   │           └── layout/
│   │   │               └── activity_main.xml
│   └── README.md
├── server/               # Serveur Node.js
│   ├── server.js
│   ├── package.json
│   ├── public/
│   │   └── index.html
│   └── README.md
└── README.md
```

## Installation

### Application Android

1. Ouvrir le projet dans Android Studio
2. Synchroniser Gradle
3. Compiler et installer sur la tablette Boox

### Serveur Rocky Linux 9

Voir `server/README.md` pour les instructions détaillées.

## Utilisation

1. Démarrer le serveur sur Rocky Linux 9 (IP: 192.168.1.202)
2. Configurer l'URL du serveur dans l'app Android : `ws://192.168.1.202:8080`
3. Démarrer le streaming depuis l'app
4. Ouvrir `http://192.168.1.202:3000` dans un navigateur

## Configuration

- **FPS** : 10 images/seconde (modifiable dans `ScreenCaptureService.kt`)
- **Qualité JPEG** : 60% (modifiable dans `ScreenCaptureService.kt`)
- **Port Android WebSocket** : 8080
- **Port Interface Web** : 3000

## Déploiement

### Configuration initiale

1. **Configurer le déploiement** : Éditez `deploy-config.json` avec vos paramètres :
   ```json
   {
     "server": {
       "host": "192.168.1.202",
       "user": "votre_utilisateur",
       "deployPath": "/opt/booxstream"
     },
     "git": {
       "remote": "origin",
       "branch": "main"
     }
   }
   ```

2. **Premier déploiement sur le serveur** :
   ```bash
   # Sur le serveur Rocky Linux
   sudo mkdir -p /opt/booxstream
   sudo chown votre_utilisateur:votre_utilisateur /opt/booxstream
   git clone https://github.com/Zabadehut/BooxStream.git /opt/booxstream
   cd /opt/booxstream/server
   npm install
   ```

### Scripts de déploiement (Windows)

- **`deploy.ps1`** : Déploie vers GitHub et le serveur
  ```powershell
  .\deploy.ps1              # Déploie tout
  .\deploy.ps1 -GitOnly      # Push GitHub uniquement
  .\deploy.ps1 -ServerOnly   # Serveur uniquement
  ```

- **`restore.ps1`** : Restaure depuis GitHub ou une sauvegarde
  ```powershell
  .\restore.ps1 -From git              # Restaure depuis GitHub
  .\restore.ps1 -From backup -BackupPath backup.zip
  ```

- **`backup.ps1`** : Crée une sauvegarde locale
  ```powershell
  .\backup.ps1
  ```

### Scripts serveur (Rocky Linux)

- **`server/deploy-server.sh`** : Déploie après un git pull
  ```bash
  cd /opt/booxstream
  git pull
  ./server/deploy-server.sh
  ```

- **`server/restore-server.sh`** : Restaure depuis GitHub
  ```bash
  ./server/restore-server.sh
  ```

