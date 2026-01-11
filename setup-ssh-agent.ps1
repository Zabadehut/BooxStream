# Script pour configurer ssh-agent et éviter de taper la passphrase plusieurs fois

Write-Host "Configuration de ssh-agent..." -ForegroundColor Cyan
Write-Host ""

# Vérifier si ssh-agent est déjà démarré
$agentProcess = Get-Process ssh-agent -ErrorAction SilentlyContinue

if (-not $agentProcess) {
    Write-Host "Démarrage de ssh-agent..." -ForegroundColor Yellow
    Start-Service ssh-agent -ErrorAction SilentlyContinue
    
    # Si le service n'existe pas, démarrer manuellement
    if (-not (Get-Service ssh-agent -ErrorAction SilentlyContinue)) {
        Write-Host "Service ssh-agent non trouvé, démarrage manuel..." -ForegroundColor Yellow
        Start-Process ssh-agent
        Start-Sleep -Seconds 2
    }
}

# Ajouter la clé à ssh-agent
$keyPath = "$env:USERPROFILE\.ssh\id_rsa"

if (Test-Path $keyPath) {
    Write-Host "Ajout de la clé SSH à ssh-agent..." -ForegroundColor Yellow
    Write-Host "Vous devrez entrer votre passphrase UNE SEULE FOIS" -ForegroundColor Cyan
    Write-Host ""
    
    # Ajouter la clé
    ssh-add $keyPath
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Clé ajoutée à ssh-agent!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Vous pouvez maintenant utiliser les scripts de déploiement" -ForegroundColor Green
        Write-Host "sans retaper votre passphrase." -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "❌ Erreur lors de l'ajout de la clé" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Clé SSH introuvable: $keyPath" -ForegroundColor Red
    Write-Host "Générez d'abord une clé avec: ssh-keygen -t rsa -b 4096" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Pour vérifier les clés chargées:" -ForegroundColor Cyan
Write-Host "  ssh-add -l" -ForegroundColor White

