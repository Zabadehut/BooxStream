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

1. Démarrer le serveur sur Rocky Linux 9
2. Configurer l'URL du serveur dans l'app Android (ex: `ws://192.168.1.100:8080`)
3. Démarrer le streaming depuis l'app
4. Ouvrir `http://IP_SERVEUR:3000` dans un navigateur

## Configuration

- **FPS** : 10 images/seconde (modifiable dans `ScreenCaptureService.kt`)
- **Qualité JPEG** : 60% (modifiable dans `ScreenCaptureService.kt`)
- **Port Android WebSocket** : 8080
- **Port Interface Web** : 3000

