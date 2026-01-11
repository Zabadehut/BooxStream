# Script rapide pour voir les erreurs BooxStream
# Usage: .\quick-debug.ps1

$adbPath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

if (-not (Test-Path $adbPath)) {
    Write-Host "ERREUR: ADB non trouve." -ForegroundColor Red
    exit 1
}

Write-Host "=== Logs BooxStream (erreurs et debug) ===" -ForegroundColor Cyan
Write-Host ""

# Afficher les derniers logs avec filtres specifiques
$logs = & $adbPath logcat -d -t 500 | Select-String -Pattern "ApiClient|ScreenCaptureService|WebSocket|booxstreamer.*[EWD]|AndroidRuntime.*FATAL" -Context 1,2

if ($logs) {
    $logs | Select-Object -Last 80 | ForEach-Object {
        if ($_ -match "ERROR|FATAL|Exception|Failed|Erreur") {
            Write-Host $_ -ForegroundColor Red
        } elseif ($_ -match "DEBUG|WebSocket|connect|authentif") {
            Write-Host $_ -ForegroundColor Yellow
        } else {
            Write-Host $_ -ForegroundColor Gray
        }
    }
} else {
    Write-Host "Aucun log BooxStream trouve. Lancez l'application et essayez de demarrer le stream." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Pour voir les logs en temps reel:" -ForegroundColor Cyan
Write-Host "  .\debug-stream.ps1" -ForegroundColor Gray

