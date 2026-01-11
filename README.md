# BooxStream

Système complet de streaming d'écran depuis une tablette Android Boox vers une interface web via un serveur relais WebSocket avec authentification et gestion centralisée.

## Architecture

- **Site Web** (booxstream.kevinvdb.dev) : Gestion des hôtes, authentification, création de sessions
- **Application Android** : Capture d'écran, UUID unique, authentification JWT
- **Serveur WebSocket** : Relais authentifié entre Android et viewers
- **Interface Web** : Sélection d'hôte et visualisation en temps réel

## Nouveautés

✅ **Authentification JWT** : Sécurisation des connexions  
✅ **UUID unique** : Identification unique par appareil Android  
✅ **Gestion centralisée** : Site web pour gérer les hôtes  
✅ **Sessions** : Création de sessions temporaires pour les viewers  
✅ **IP publique** : Détection et enregistrement automatique

## Structure du projet

```
.
├── android-app/          # Application Android
│   ├── app/
│   │   ├── build.gradle
│   │   ├── src/main/
│   │   │   ├── AndroidManifest.xml
│   │   │   ├── java/com/example/booxstreamer/
│   │   │   │   ├── MainActivity.kt
│   │   │   │   ├── ScreenCaptureService.kt
│   │   │   │   ├── DeviceManager.kt      # Gestion UUID
│   │   │   │   └── ApiClient.kt          # Client API
│   │   │   └── res/layout/
│   │   │       └── activity_main.xml
│   └── README.md
├── web/                  # Site web et API
│   ├── server.js         # Serveur Express + WebSocket
│   ├── package.json
│   ├── public/
│   │   └── index.html    # Interface de gestion
│   └── README.md
├── server/               # Serveur Node.js (legacy)
│   └── ...
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

### 1. Démarrer le site web

```bash
cd web
npm install
cp .env.example .env
# Éditer .env avec vos paramètres
npm start
```

### 2. Configurer l'application Android

1. Ouvrir l'app sur la tablette Boox
2. L'app génère automatiquement un UUID unique
3. S'enregistre sur le site web (booxstream.kevinvdb.dev)
4. Reçoit un token JWT d'authentification

### 3. Démarrer le streaming

1. Dans l'app Android, cliquer sur "Démarrer le streaming"
2. Autoriser la capture d'écran
3. Le streaming démarre automatiquement

### 4. Visualiser depuis le web

1. Ouvrir https://booxstream.kevinvdb.dev
2. Voir la liste des hôtes disponibles
3. Cliquer sur "Voir le stream" pour un hôte
4. Le stream s'affiche en temps réel

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

