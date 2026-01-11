# Script pour copier la clé SSH sur le serveur (Windows)
$config = Get-Content "deploy-config.json" | ConvertFrom-Json
$serverHost = $config.server.host
$serverUser = $config.server.user

$pubKeyPath = "$env:USERPROFILE\.ssh\id_rsa.pub"

if (-not (Test-Path $pubKeyPath)) {
    Write-Host "ERREUR: Clé publique introuvable: $pubKeyPath" -ForegroundColor Red
    Write-Host "Générez d'abord une clé avec: ssh-keygen -t rsa -b 4096" -ForegroundColor Yellow
    exit 1
}

Write-Host "Copie de la clé SSH sur le serveur..." -ForegroundColor Yellow
Write-Host "Vous devrez entrer votre mot de passe SSH" -ForegroundColor Cyan
Write-Host ""

$pubKey = Get-Content $pubKeyPath

# Copier la clé sur le serveur
ssh "${serverUser}@${serverHost}" "mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo '$pubKey' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"

if ($LASTEXITCODE -eq 0) {
    Write-Host "OK: Clé SSH copiée avec succès!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Test de la connexion..." -ForegroundColor Yellow
    ssh -o ConnectTimeout=5 "${serverUser}@${serverHost}" "echo 'Connexion SSH sans mot de passe OK!'"
} else {
    Write-Host "ERREUR: Échec de la copie de la clé" -ForegroundColor Red
}

