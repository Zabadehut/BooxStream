# Script pour verifier l'etat de l'application BooxStream
# Usage: .\check-app.ps1

$adbPath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

if (-not (Test-Path $adbPath)) {
    Write-Host "ERREUR: ADB non trouve." -ForegroundColor Red
    exit 1
}

Write-Host "=== Verification de l'application BooxStream ===" -ForegroundColor Cyan
Write-Host ""

# Verifier si l'app est installee
Write-Host "1. Verification de l'installation..." -ForegroundColor Yellow
$packages = & $adbPath shell "pm list packages"
$installed = $packages | Select-String "com.example.booxstreamer"

if ($installed) {
    Write-Host "   ✓ Application INSTALLEE" -ForegroundColor Green
    Write-Host "   Package: com.example.booxstreamer" -ForegroundColor Gray
} else {
    Write-Host "   ✗ Application NON INSTALLEE" -ForegroundColor Red
    Write-Host ""
    Write-Host "   Pour installer:" -ForegroundColor Yellow
    Write-Host "   - Depuis Android Studio: Run (Shift+F10)" -ForegroundColor Cyan
    Write-Host "   - Ou: .\build-and-install.ps1" -ForegroundColor Cyan
    exit 1
}

Write-Host ""

# Verifier si l'app est en cours d'execution
Write-Host "2. Verification des processus en cours..." -ForegroundColor Yellow
$processes = & $adbPath shell "ps"
$running = $processes | Select-String "booxstreamer"

if ($running) {
    Write-Host "   ✓ Application EN COURS D'EXECUTION" -ForegroundColor Green
    $running | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }
} else {
    Write-Host "   ✗ Application NON EN COURS D'EXECUTION" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   Pour lancer l'application:" -ForegroundColor Yellow
    Write-Host "   .\adb-helper.ps1 shell 'am start -n com.example.booxstreamer/.MainActivity'" -ForegroundColor Cyan
}

Write-Host ""

# Verifier l'activite actuelle
Write-Host "3. Activite actuellement affichee..." -ForegroundColor Yellow
$window = & $adbPath shell "dumpsys window windows | grep -E 'mCurrentFocus|mFocusedApp'"
if ($window) {
    $window | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }
    if ($window -match "booxstreamer") {
        Write-Host "   ✓ BooxStream est l'application active" -ForegroundColor Green
    } else {
        Write-Host "   ℹ Une autre application est active" -ForegroundColor Yellow
    }
} else {
    Write-Host "   (Impossible de determiner)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== Commandes utiles ===" -ForegroundColor Cyan
Write-Host "Lancer l'app:     .\adb-helper.ps1 shell am start -n com.example.booxstreamer/.MainActivity" -ForegroundColor Gray
Write-Host "Voir les logs:    .\adb-helper.ps1 logcat | Select-String BooxStream" -ForegroundColor Gray
Write-Host "Arreter l'app:    .\adb-helper.ps1 shell am force-stop com.example.booxstreamer" -ForegroundColor Gray

