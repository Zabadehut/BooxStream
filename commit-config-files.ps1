# Script pour commiter les fichiers de configuration Cloudflare Tunnel

Write-Host "=== Ajout des fichiers de configuration ===" -ForegroundColor Cyan
Write-Host ""

# Fichiers à ajouter
$files = @(
    "DISABLE-CLOUDFLARE-VM.sh",
    "CONFIG-BOOXSTREAM-GATEWAY.md",
    "VERIFY-GATEWAY-CONFIG.sh",
    "RESOLVE-TUNNEL-CONFLICT.sh",
    "RESOLVE-CONFLICT.md",
    "GATEWAY-CONFIG-EXAMPLE.yml",
    "DIAGNOSE-404.sh",
    "CHECK-CONFIG-CONFLICTS.sh",
    "FIX-TUNNEL-CONFLICT.sh",
    "VERIFY-NO-CONFLICT.md",
    "TEST-FINAL.sh"
)

Write-Host "Fichiers à ajouter:" -ForegroundColor Yellow
foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "  ✓ $file" -ForegroundColor Green
        git add $file
    } else {
        Write-Host "  ✗ $file (non trouvé)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== Commit ===" -ForegroundColor Cyan
Write-Host ""

$msg = "Configuration Cloudflare Tunnel: scripts et documentation pour resoudre conflit avec gateway"
git commit -m $msg

Write-Host ""
Write-Host "=== Statut ===" -ForegroundColor Cyan
Write-Host ""

git status --short

Write-Host ""
Write-Host "=== Pour pousser ===" -ForegroundColor Yellow
Write-Host '  git push' -ForegroundColor Gray
Write-Host ""
