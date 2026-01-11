# Script pour voir le statut du service BooxStream
$config = Get-Content "deploy-config.json" | ConvertFrom-Json
$serverHost = $config.server.host
$serverUser = $config.server.user

Write-Host "Statut du service BooxStream Web" -ForegroundColor Cyan
Write-Host ""

ssh "${serverUser}@${serverHost}" "sudo systemctl status booxstream-web"

