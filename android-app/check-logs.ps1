# Script pour verifier les logs Android de BooxStream
# Usage: .\check-logs.ps1 [filter]

param(
    [string]$Filter = "booxstreamer"
)

$adbPath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

if (-not (Test-Path $adbPath)) {
    Write-Host "ERREUR: ADB non trouve." -ForegroundColor Red
    exit 1
}

Write-Host "=== Logs BooxStream ===" -ForegroundColor Cyan
Write-Host "Filtre: $Filter" -ForegroundColor Gray
Write-Host ""

# Verifier qu'un appareil est connecte
$devices = & $adbPath devices | Select-String "device$"
if (-not $devices) {
    Write-Host "ERREUR: Aucun appareil Android connecte." -ForegroundColor Red
    exit 1
}

Write-Host "Appareil connecte: $($devices -replace '\s+device$', '')" -ForegroundColor Green
Write-Host ""

# Afficher les logs
Write-Host "Derniers logs (appuyez sur Ctrl+C pour arreter):" -ForegroundColor Yellow
Write-Host ""

& $adbPath logcat -c
& $adbPath logcat | Select-String $Filter

