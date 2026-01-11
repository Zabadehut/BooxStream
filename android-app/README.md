# Application Android - BooxStream

Application Android pour capturer et streamer l'écran d'une tablette Boox vers un serveur WebSocket.

## Prérequis

- Android Studio
- SDK Android 21 minimum (Android 5.0)
- Tablette Android avec support MediaProjection

## Installation

1. Ouvrir le projet dans Android Studio
2. Synchroniser les dépendances Gradle
3. Compiler l'APK ou installer directement sur la tablette

## Configuration

L'URL du serveur WebSocket peut être configurée dans l'interface :
- Format : `ws://IP:PORT` (ex: `ws://192.168.1.100:8080`)

## Permissions

L'application demande automatiquement :
- Permission de capture d'écran (MediaProjection)
- Permission de notification (Android 13+)

## Utilisation

1. Entrer l'URL du serveur WebSocket
2. Cliquer sur "Démarrer le streaming"
3. Autoriser la capture d'écran
4. Le streaming démarre automatiquement

## Paramètres techniques

- **FPS** : 10 images/seconde
- **Résolution** : Résolution d'écran divisée par 2
- **Compression** : JPEG 60%
- **Format** : RGBA_8888 → JPEG

