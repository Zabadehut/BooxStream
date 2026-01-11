# Test de connexion SSH
$config = Get-Content "deploy-config.json" | ConvertFrom-Json
$serverHost = $config.server.host
$serverUser = $config.server.user

Write-Host "Test de connexion SSH a $serverUser@$serverHost..." -ForegroundColor Yellow

try {
    $result = ssh -o ConnectTimeout=5 -o BatchMode=yes "${serverUser}@${serverHost}" "echo 'Connexion OK'"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "OK: Connexion SSH fonctionnelle" -ForegroundColor Green
    } else {
        Write-Host "ERREUR: Connexion SSH echouee (code: $LASTEXITCODE)" -ForegroundColor Red
        Write-Host "Verifiez:" -ForegroundColor Yellow
        Write-Host "  - Clé SSH configurée" -ForegroundColor Yellow
        Write-Host "  - Serveur accessible" -ForegroundColor Yellow
        Write-Host "  - Utilisateur correct" -ForegroundColor Yellow
    }
} catch {
    Write-Host "ERREUR: $($_.Exception.Message)" -ForegroundColor Red
}

