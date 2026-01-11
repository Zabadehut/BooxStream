# Guide de dépannage - BooxStream Android

## Problème 1 : Erreur EDT (Event Dispatch Thread)

### Symptôme
```
java.lang.IllegalStateException: This method is forbidden on EDT because it does not pump the event queue.
```

### Cause
Cette erreur est un bug connu d'Android Studio lié au plugin Gradle. Elle n'empêche généralement pas la compilation mais peut causer des problèmes de synchronisation.

### Solutions

#### Solution 1 : Invalider les caches (recommandé)
1. Dans Android Studio : **File → Invalidate Caches / Restart**
2. Sélectionner **Invalidate and Restart**
3. Attendre le redémarrage complet
4. Re-synchroniser le projet : **File → Sync Project with Gradle Files**

#### Solution 2 : Redémarrer Android Studio
1. Fermer complètement Android Studio
2. Redémarrer Android Studio
3. Ouvrir le projet à nouveau

#### Solution 3 : Nettoyer le projet
```bash
cd android-app
./gradlew clean
```

Puis dans Android Studio : **Build → Rebuild Project**

#### Solution 4 : Vérifier la configuration JDK
1. **File → Project Structure**
2. **SDK Location** → Vérifier que le JDK est correctement configuré
3. Si Java 21 est utilisé, s'assurer que Gradle 8.5+ est configuré (déjà fait)

## Problème 2 : L'application n'apparaît pas sur la tablette

### Vérifications préalables

#### 1. Vérifier que l'application est installée
```bash
# Depuis Android Studio, Terminal
adb devices
adb shell pm list packages | grep booxstreamer
```

Si l'application n'est pas listée, elle n'est pas installée.

#### 2. Vérifier que l'application est visible
```bash
adb shell pm list packages -3 | grep booxstreamer
```

#### 3. Vérifier les permissions de lancement
```bash
adb shell pm dump com.example.booxstreamer | grep -A 5 "Activity"
```

### Solutions

#### Solution 1 : Réinstaller l'application
1. Désinstaller l'ancienne version :
   ```bash
   adb uninstall com.example.booxstreamer
   ```

2. Réinstaller depuis Android Studio :
   - Sélectionner votre tablette dans le menu déroulant
   - Cliquer sur **Run** (▶️) ou `Shift+F10`

#### Solution 2 : Vérifier l'icône de lancement
L'icône a été créée dans les dossiers `mipmap-*`. Si l'application n'apparaît toujours pas :

1. Vérifier que les fichiers existent :
   - `app/src/main/res/mipmap-*/ic_launcher.xml`
   - `app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`

2. Rebuild le projet :
   - **Build → Clean Project**
   - **Build → Rebuild Project**

#### Solution 3 : Forcer l'affichage dans le launcher
```bash
# Vérifier que l'activité principale est bien configurée comme LAUNCHER
adb shell am start -n com.example.booxstreamer/.MainActivity
```

Si cela fonctionne, l'application devrait apparaître dans le launcher.

#### Solution 4 : Vérifier le manifest
S'assurer que dans `AndroidManifest.xml` :
- `android:exported="true"` est présent sur l'activité principale
- L'intent-filter contient `MAIN` et `LAUNCHER`

#### Solution 5 : Redémarrer le launcher de la tablette
Sur la tablette :
1. Paramètres → Applications → Toutes les applications
2. Trouver "BooxStream" ou "com.example.booxstreamer"
3. Si présente, forcer l'arrêt puis relancer

Ou redémarrer complètement la tablette.

## Problème 3 : Synchronisation Gradle échoue

### Vérifications
1. **Version de Gradle** : Doit être 8.5+ (déjà configuré)
2. **Version de Java** : Compatible avec Gradle 8.5 (Java 8-19)
3. **Connexion Internet** : Nécessaire pour télécharger les dépendances

### Solutions
1. **File → Sync Project with Gradle Files**
2. Vérifier les logs dans **View → Tool Windows → Build**
3. Si erreur de réseau, vérifier le proxy dans **File → Settings → Appearance & Behavior → System Settings → HTTP Proxy**

## Vérification finale

Après avoir appliqué les solutions :

1. **Build → Clean Project**
2. **Build → Rebuild Project**
3. **Run** l'application sur la tablette
4. Vérifier que l'application apparaît dans le launcher de la tablette

## Commandes utiles ADB

```bash
# Lister les appareils connectés
adb devices

# Installer l'APK directement
adb install -r app/build/outputs/apk/debug/app-debug.apk

# Désinstaller l'application
adb uninstall com.example.booxstreamer

# Voir les logs en temps réel
adb logcat | grep -i booxstream

# Redémarrer le launcher
adb shell am force-stop com.android.launcher
```

