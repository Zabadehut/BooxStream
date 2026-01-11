# Script pour voir les logs du service BooxStream depuis Windows
param(
    [switch]$Follow
)

$config = Get-Content "deploy-config.json" | ConvertFrom-Json
$serverHost = $config.server.host
$serverUser = $config.server.user

Write-Host "Logs du service BooxStream Web" -ForegroundColor Cyan
Write-Host "Serveur: $serverUser@$serverHost" -ForegroundColor Yellow
Write-Host ""

if ($Follow) {
    Write-Host "Appuyez sur Ctrl+C pour quitter" -ForegroundColor Yellow
    Write-Host ""
    ssh "${serverUser}@${serverHost}" "sudo journalctl -u booxstream-web -f"
} else {
    ssh "${serverUser}@${serverHost}" "sudo journalctl -u booxstream-web -n 50 --no-pager"
}

