# 🛡️ Guide de Sécurité et Signature - BooxStream

## 📋 Table des matières
1. [Pourquoi l'application est détectée comme un virus ?](#pourquoi)
2. [Solutions implémentées](#solutions)
3. [Génération du keystore](#generation-keystore)
4. [Build en mode Release](#build-release)
5. [Vérification de la sécurité](#verification)
6. [Bonnes pratiques](#bonnes-pratiques)

---

## 🤔 Pourquoi l'application est détectée comme un virus ? {#pourquoi}

### Raisons courantes :

1. **Permissions sensibles**
   - `MEDIA_PROJECTION` : Capture d'écran (utilisé par les spywares)
   - `FOREGROUND_SERVICE` : Service en arrière-plan
   - `INTERNET` : Connexion réseau

2. **Signature de debug**
   - Les APK signés avec le certificat debug sont suspects
   - Signature générée automatiquement, non vérifiable

3. **Code non obfusqué**
   - Sans ProGuard/R8, le code est facilement analysable
   - Les antivirus peuvent identifier des patterns suspects

4. **Package générique**
   - `com.example.*` est utilisé dans beaucoup de malwares de test

5. **Pas de vérification Google Play**
   - Les apps non publiées sur le Play Store sont plus suspectes

---

## ✅ Solutions implémentées {#solutions}

### 1. Signature officielle avec keystore
✅ Configuration du `build.gradle` pour utiliser un keystore de production
✅ Scripts PowerShell pour générer et gérer le keystore
✅ Variables d'environnement pour sécuriser les mots de passe

### 2. Obfuscation ProGuard
✅ Activation de `minifyEnabled` et `shrinkResources`
✅ Règles ProGuard personnalisées pour BooxStream
✅ Protection du code source

### 3. Politique de confidentialité
✅ Document expliquant les permissions et l'utilisation des données
✅ Transparence sur le fonctionnement de l'application

### 4. Documentation et transparence
✅ Code open-source
✅ Explication claire de chaque permission
✅ Commentaires détaillés dans le code

---

## 🔐 Génération du keystore {#generation-keystore}

### Étape 1 : Exécuter le script de génération

```powershell
cd android-app
.\generate-keystore.ps1
```

### Étape 2 : Fournir les informations

Le script vous demandera :
- **Mot de passe du keystore** : Choisissez un mot de passe fort (min. 6 caractères)
- **Mot de passe de la clé** : Peut être identique ou différent
- **Nom/Organisation** : Votre identité
- **Ville, État, Pays** : Informations géographiques

### Étape 3 : Sauvegarder le keystore

⚠️ **TRÈS IMPORTANT** :
- Sauvegardez `booxstream-release.keystore` en lieu sûr
- Notez les mots de passe dans un gestionnaire de mots de passe
- **Si vous perdez le keystore, vous ne pourrez plus mettre à jour l'application !**

### Fichiers générés :
- `booxstream-release.keystore` : Le certificat (ne pas commiter dans Git)
- `keystore.env` : Configuration (ne pas commiter dans Git)

---

## 🔨 Build en mode Release {#build-release}

### Build avec signature :

```powershell
cd android-app
.\build-release.ps1
```

Ce script :
1. Charge la configuration depuis `keystore.env`
2. Nettoie le projet
3. Compile en mode Release avec signature
4. Génère un APK signé et optimisé

### APK généré :
```
android-app\app\build\outputs\apk\release\app-release.apk
```

### Installation sur la tablette :

```powershell
adb install -r app\build\outputs\apk\release\app-release.apk
```

---

## 🔍 Vérification de la sécurité {#verification}

### 1. Vérifier la signature de l'APK

```powershell
jarsigner -verify -verbose -certs app\build\outputs\apk\release\app-release.apk
```

**Résultat attendu :**
```
jar verified.
```

### 2. Analyser avec VirusTotal

1. Allez sur [VirusTotal.com](https://www.virustotal.com/)
2. Uploadez `app-release.apk`
3. Attendez l'analyse (60+ antivirus)

**Résultats attendus :**
- ✅ 0-2 détections : Normal (faux positifs possibles)
- ⚠️ 3-5 détections : Acceptable
- ❌ 6+ détections : Problème à investiguer

### 3. Vérifier les permissions

```powershell
aapt dump permissions app\build\outputs\apk\release\app-release.apk
```

**Permissions attendues uniquement :**
- `android.permission.INTERNET`
- `android.permission.FOREGROUND_SERVICE`
- `android.permission.FOREGROUND_SERVICE_MEDIA_PROJECTION`
- `android.permission.POST_NOTIFICATIONS`

### 4. Analyser avec Android Studio

1. Ouvrir Android Studio
2. **Build > Analyze APK...**
3. Sélectionner `app-release.apk`
4. Vérifier :
   - Taille de l'APK (doit être < 5 MB)
   - Permissions
   - Classes obfusquées (noms courts : a, b, c, etc.)

---

## 📚 Bonnes pratiques {#bonnes-pratiques}

### ✅ À FAIRE

1. **Signer TOUJOURS avec le même keystore**
   - Utilisez le même certificat pour toutes les versions
   - Une fois publié, impossible de changer

2. **Incrémenter versionCode et versionName**
   - `versionCode` : Entier croissant (1, 2, 3...)
   - `versionName` : Version lisible ("1.0", "1.1", "2.0"...)

3. **Tester l'APK signé avant distribution**
   - Installer sur un appareil réel
   - Vérifier toutes les fonctionnalités

4. **Documenter les changements**
   - Tenir un changelog à jour
   - Expliquer les nouvelles permissions

5. **Backup du keystore**
   - Copier sur plusieurs supports sécurisés
   - Utiliser un gestionnaire de mots de passe

### ❌ À ÉVITER

1. **Ne JAMAIS commiter dans Git :**
   - `*.keystore` ou `*.jks`
   - `keystore.env`
   - Mots de passe en clair

2. **Ne JAMAIS partager le keystore**
   - C'est votre identité de développeur
   - Si compromis, votre réputation est en danger

3. **Ne JAMAIS utiliser le build debug en production**
   - Non sécurisé
   - Détecté comme suspect

4. **Ne JAMAIS publier avec `minifyEnabled false`**
   - Code exposé
   - Plus vulnérable aux attaques

---

## 🎯 Checklist avant distribution

- [ ] Keystore de production généré et sauvegardé
- [ ] `build.gradle` configuré pour la signature
- [ ] ProGuard activé (`minifyEnabled true`)
- [ ] Build en mode Release réussi
- [ ] Signature vérifiée avec `jarsigner`
- [ ] APK testé sur un appareil réel
- [ ] Scan VirusTotal OK (< 3 détections)
- [ ] Permissions vérifiées
- [ ] `versionCode` et `versionName` incrémentés
- [ ] Documentation à jour

---

## 🆘 En cas de problème

### "Keystore was tampered with, or password was incorrect"
➡️ Mot de passe incorrect dans `keystore.env`

### "Cannot recover key"
➡️ `keyPassword` différent de `storePassword` et mal configuré

### "Entry *.class not found"
➡️ Problème avec ProGuard, vérifier `proguard-rules.pro`

### VirusTotal détecte > 5 antivirus
➡️ Vérifier :
1. Pas de code suspect dans les dépendances
2. URLs WebSocket correctes (pas de domaines suspects)
3. Permissions justifiées

---

## 📞 Support

Pour toute question de sécurité :
- Issues GitHub : [Votre repo]
- Documentation : Ce fichier
- Logs : `.\check-logs.ps1` pour diagnostiquer

---

**Dernière mise à jour : Janvier 2026**

