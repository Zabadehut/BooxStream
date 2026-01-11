# Compilation de l'APK BooxStream pour FTP

## Génération de l'APK

### Option 1 : Script PowerShell (recommandé)

```powershell
# Compiler l'APK debug (rapide)
.\build-apk.ps1

# Ou compiler l'APK release (signé, pour production)
.\build-apk-release.ps1
```

L'APK sera généré dans le dossier `releases/` avec un nom incluant la date/heure :
- `BooxStream-20260111-153045.apk` (debug)
- `BooxStream-release-20260111-153045.apk` (release)

### Option 2 : Android Studio

1. Ouvrir le projet dans Android Studio
2. Build → Build Bundle(s) / APK(s) → Build APK(s)
3. L'APK sera dans : `android-app/app/build/outputs/apk/debug/app-debug.apk`
4. Copier dans le dossier `releases/` si besoin

### Option 3 : Ligne de commande Gradle

```bash
cd android-app
./gradlew assembleDebug
```

L'APK sera dans : `android-app/app/build/outputs/apk/debug/app-debug.apk`

## Upload sur FTP

Une fois l'APK généré :

1. **Trouver l'APK** : Dans le dossier `releases/`
2. **Uploader sur votre FTP** : Utiliser FileZilla, WinSCP, ou votre client FTP
3. **Partager le lien** : Exemple : `ftp://votre-serveur.com/BooxStream.apk`

## Installation sur la tablette Boox

### Méthode 1 : Téléchargement direct

1. Sur la tablette, ouvrir un navigateur
2. Aller sur l'URL FTP/HTTP de l'APK
3. Télécharger l'APK
4. Autoriser l'installation depuis sources inconnues
5. Installer

### Méthode 2 : Transfert USB

1. Copier l'APK sur la tablette via USB
2. Ouvrir le gestionnaire de fichiers
3. Cliquer sur l'APK
4. Installer

### Autoriser les sources inconnues

Sur la tablette Boox :
- Paramètres → Sécurité → Autoriser les sources inconnues
- Ou lors de l'installation, autoriser pour cette source

## Structure du dossier releases

```
releases/
├── BooxStream-20260111-153045.apk
├── BooxStream-release-20260111-153045.apk
└── README.md
```

## Notes

- Les APK dans `releases/` sont ignorés par Git (normal)
- Le dossier `releases/` peut être uploadé tel quel sur votre FTP
- Pour chaque nouvelle version, générer un nouvel APK avec le script

