# Guide de compilation et installation - Application Android BooxStream

## Prérequis

- **Android Studio** : Télécharger depuis https://developer.android.com/studio
- **JDK 8 ou supérieur** : Inclus avec Android Studio
- **Tablette Boox** : Avec USB debugging activé

## Installation

### 1. Ouvrir le projet dans Android Studio

1. Ouvrir Android Studio
2. File → Open
3. Sélectionner le dossier `android-app/`
4. Attendre la synchronisation Gradle

### 2. Configurer la tablette Boox

Sur la tablette :
1. Paramètres → À propos de la tablette
2. Appuyer 7 fois sur "Numéro de build" pour activer les options développeur
3. Paramètres → Options développeur
4. Activer "Débogage USB"
5. Connecter la tablette via USB

### 3. Compiler et installer

#### Option A : Depuis Android Studio (recommandé)

1. Dans Android Studio, cliquer sur le menu déroulant en haut (à côté de l'icône play)
2. Sélectionner votre tablette Boox
3. Cliquer sur le bouton "Run" (▶️) ou appuyer sur `Shift+F10`
4. L'application sera compilée et installée automatiquement

#### Option B : Générer un APK

1. Build → Build Bundle(s) / APK(s) → Build APK(s)
2. Attendre la compilation
3. Un message apparaîtra avec le chemin de l'APK
4. Transférer l'APK sur la tablette et l'installer

#### Option C : Ligne de commande (Gradle)

```bash
cd android-app
./gradlew assembleDebug
```

L'APK sera dans : `android-app/app/build/outputs/apk/debug/app-debug.apk`

## Configuration de l'application

Au premier lancement :
1. L'application génère automatiquement un UUID unique
2. L'UUID est affiché dans l'interface
3. L'app s'enregistre automatiquement sur le site web (booxstream.kevinvdb.dev)

### URL de l'API

Par défaut : `https://booxstream.kevinvdb.dev`

Vous pouvez modifier cette URL dans l'application si nécessaire.

## Utilisation

1. **Vérifier l'UUID** : L'UUID unique de votre tablette est affiché
2. **Vérifier l'URL de l'API** : Doit pointer vers votre serveur
3. **Démarrer le streaming** :
   - Cliquer sur "Démarrer le streaming"
   - Autoriser la capture d'écran
   - Le streaming démarre automatiquement

## Vérification

Une fois l'app installée et le streaming démarré :

1. Ouvrir `http://192.168.1.202:3001` (ou votre domaine)
2. Votre tablette devrait apparaître dans la liste des hôtes
3. Cliquer "Voir le stream" pour visualiser

## Dépannage

### L'app ne s'enregistre pas
- Vérifier la connexion internet
- Vérifier l'URL de l'API
- Vérifier les logs Android (logcat dans Android Studio)

### Le streaming ne démarre pas
- Vérifier que la permission de capture d'écran est accordée
- Vérifier que l'URL de l'API est correcte
- Vérifier les logs du service

### L'app ne se connecte pas au WebSocket
- Vérifier que le serveur web est démarré
- Vérifier que le port 8080 est ouvert
- Vérifier les logs du serveur

