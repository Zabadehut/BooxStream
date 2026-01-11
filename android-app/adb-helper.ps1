# Script helper pour utiliser ADB facilement
# Usage: .\adb-helper.ps1 <command>
# Exemples:
#   .\adb-helper.ps1 devices
#   .\adb-helper.ps1 install app-debug.apk
#   .\adb-helper.ps1 shell "pm list packages | grep booxstreamer"

$adbPath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

if (-not (Test-Path $adbPath)) {
    Write-Host "ERREUR: ADB non trouvé à $adbPath" -ForegroundColor Red
    Write-Host "Assurez-vous qu'Android Studio est installé et que le SDK Android est configuré." -ForegroundColor Yellow
    exit 1
}

if ($args.Count -eq 0) {
    Write-Host "Usage: .\adb-helper.ps1 <command> [arguments...]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Commandes utiles:" -ForegroundColor Cyan
    Write-Host "  devices                    - Lister les appareils connectés"
    Write-Host "  install <apk>              - Installer un APK"
    Write-Host "  uninstall <package>        - Désinstaller une application"
    Write-Host "  shell <command>            - Exécuter une commande shell"
    Write-Host "  logcat                     - Voir les logs en temps réel"
    Write-Host ""
    Write-Host "Exemples:" -ForegroundColor Cyan
    Write-Host "  .\adb-helper.ps1 devices"
    Write-Host "  .\adb-helper.ps1 shell 'pm list packages | grep booxstreamer'"
    Write-Host "  .\adb-helper.ps1 install app\build\outputs\apk\debug\app-debug.apk"
    Write-Host "  .\adb-helper.ps1 shell 'am start -n com.example.booxstreamer/.MainActivity'"
    exit 0
}

# Exécuter la commande ADB
& $adbPath $args

