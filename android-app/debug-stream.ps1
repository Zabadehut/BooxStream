# Script pour deboguer les erreurs de streaming
# Usage: .\debug-stream.ps1

$adbPath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

if (-not (Test-Path $adbPath)) {
    Write-Host "ERREUR: ADB non trouve." -ForegroundColor Red
    exit 1
}

Write-Host "=== Debug Streaming BooxStream ===" -ForegroundColor Cyan
Write-Host ""

# Verifier qu'un appareil est connecte
$devices = & $adbPath devices | Select-String "device$"
if (-not $devices) {
    Write-Host "ERREUR: Aucun appareil Android connecte." -ForegroundColor Red
    exit 1
}

Write-Host "Appareil connecte: $($devices -replace '\s+device$', '')" -ForegroundColor Green
Write-Host ""

# Effacer les logs
Write-Host "Effacement des logs..." -ForegroundColor Yellow
& $adbPath logcat -c

Write-Host ""
Write-Host "=== Instructions ===" -ForegroundColor Cyan
Write-Host "1. Lancez le stream depuis l'application" -ForegroundColor Yellow
Write-Host "2. Attendez quelques secondes" -ForegroundColor Yellow
Write-Host "3. Appuyez sur Ctrl+C pour arreter la capture" -ForegroundColor Yellow
Write-Host ""
Write-Host "Capture des logs en cours..." -ForegroundColor Green
Write-Host ""

# Capturer les logs avec filtres specifiques
& $adbPath logcat | Select-String -Pattern "ScreenCaptureService|ApiClient|WebSocket|booxstreamer.*[EW]|AndroidRuntime.*FATAL" -Context 1,2

