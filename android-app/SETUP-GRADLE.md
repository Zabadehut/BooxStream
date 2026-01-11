# Configuration du wrapper Gradle

Le wrapper Gradle est incomplet. Voici comment le generer completement.

## Solution 1 : Depuis Android Studio (RECOMMANDE)

1. Ouvrir Android Studio
2. File → Open → Selectionner le dossier `android-app`
3. Android Studio va automatiquement :
   - Generer le wrapper Gradle complet
   - Synchroniser les dependances
   - Creer tous les fichiers necessaires

4. Une fois la synchronisation terminee, vous pouvez :
   - Cliquer sur Run (Shift+F10) pour compiler et installer
   - OU utiliser le script `.\build-and-install.ps1`

## Solution 2 : Generer le wrapper manuellement

Si vous avez Gradle installe globalement :

```powershell
cd android-app
gradle wrapper --gradle-version 8.5
```

## Solution 3 : Telecharger gradle-wrapper.jar

Le fichier `gradle-wrapper.jar` peut etre telecharge depuis :
https://raw.githubusercontent.com/gradle/gradle/master/gradle/wrapper/gradle-wrapper.jar

Placez-le dans : `android-app/gradle/wrapper/gradle-wrapper.jar`

## Verification

Apres avoir genere le wrapper, verifiez que ces fichiers existent :

- `gradlew.bat` (ou `gradlew` sur Linux/Mac)
- `gradle/wrapper/gradle-wrapper.properties`
- `gradle/wrapper/gradle-wrapper.jar`

Ensuite, vous pouvez utiliser `.\build-and-install.ps1`

