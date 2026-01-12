# Script pour vérifier les logs de l'application Release
# Usage : .\check-logs-release.ps1

Write-Host "📋 Vérification des logs BooxStream (Release)" -ForegroundColor Cyan
Write-Host ""

$adbPath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

if (-not (Test-Path $adbPath)) {
    Write-Host "❌ ADB non trouvé à : $adbPath" -ForegroundColor Red
    Write-Host "   Assurez-vous qu'Android Studio est installé." -ForegroundColor Yellow
    exit 1
}

Write-Host "🔍 Nettoyage des logs précédents..." -ForegroundColor Gray
& $adbPath logcat -c

Write-Host ""
Write-Host "📱 Surveillez les logs (Ctrl+C pour arrêter)..." -ForegroundColor Yellow
Write-Host "   Filtres : AndroidRuntime, FATAL, BooxStream, ScreenCapture, MainActivity" -ForegroundColor Gray
Write-Host ""

# Filtrer les logs pertinents
& $adbPath logcat | Select-String -Pattern "AndroidRuntime|FATAL|BooxStream|ScreenCapture|MainActivity|DeviceManager|ApiClient" -Context 3,3
