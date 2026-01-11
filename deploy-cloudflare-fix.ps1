# Script de déploiement pour la correction Cloudflare Tunnel
# Usage: .\deploy-cloudflare-fix.ps1

$ErrorActionPreference = "Stop"

Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Déploiement correction Cloudflare Tunnel              ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# 1. Vérifier que nous sommes dans le bon répertoire
if (-not (Test-Path "web/server.js")) {
    Write-Host "ERREUR: web/server.js introuvable" -ForegroundColor Red
    Write-Host "Exécutez ce script depuis la racine du projet BooxStream" -ForegroundColor Yellow
    exit 1
}

# 2. Vérifier les modifications
Write-Host "1. Vérification des modifications..." -ForegroundColor Yellow
$status = git status --porcelain web/server.js
if (-not $status) {
    Write-Host "   Aucune modification détectée dans web/server.js" -ForegroundColor Yellow
    $continue = Read-Host "   Continuer quand même? (y/n)"
    if ($continue -ne "y") {
        exit 0
    }
} else {
    Write-Host "   Modifications détectées:" -ForegroundColor Green
    git diff web/server.js | Select-Object -First 10
    Write-Host ""
}

# 3. Ajouter le fichier
Write-Host "2. Ajout du fichier à Git..." -ForegroundColor Yellow
git add web/server.js
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✓ Fichier ajouté" -ForegroundColor Green
} else {
    Write-Host "   ✗ Erreur lors de l'ajout" -ForegroundColor Red
    exit 1
}
Write-Host ""

# 4. Commiter
Write-Host "3. Commit des modifications..." -ForegroundColor Yellow
$commitMsg = "Serveur écoute sur 0.0.0.0 pour Cloudflare Tunnel"
git commit -m $commitMsg
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✓ Commit créé: $commitMsg" -ForegroundColor Green
} else {
    Write-Host "   ✗ Erreur lors du commit" -ForegroundColor Red
    exit 1
}
Write-Host ""

# 5. Push vers GitHub
Write-Host "4. Push vers GitHub..." -ForegroundColor Yellow
git push origin main
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✓ Code poussé vers GitHub" -ForegroundColor Green
} else {
    Write-Host "   ✗ Erreur lors du push" -ForegroundColor Red
    $continue = Read-Host "   Continuer le déploiement serveur? (y/n)"
    if ($continue -ne "y") {
        exit 1
    }
}
Write-Host ""

# 6. Déploiement sur le serveur
Write-Host "5. Déploiement sur le serveur..." -ForegroundColor Yellow
if (Test-Path "deploy-simple.ps1") {
    & .\deploy-simple.ps1 -ServerOnly
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✓ Déploiement serveur terminé" -ForegroundColor Green
    } else {
        Write-Host "   ✗ Erreur lors du déploiement serveur" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "   ✗ deploy-simple.ps1 introuvable" -ForegroundColor Red
    exit 1
}
Write-Host ""

# 7. Instructions finales
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   Déploiement terminé!                                  ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Prochaines étapes sur le serveur:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Corriger les permissions de cloudflared:" -ForegroundColor Yellow
Write-Host "   sudo chmod +x /usr/local/bin/cloudflared" -ForegroundColor White
Write-Host "   sudo chown root:root /usr/local/bin/cloudflared" -ForegroundColor White
Write-Host ""
Write-Host "2. Redémarrer les services:" -ForegroundColor Yellow
Write-Host "   sudo systemctl restart cloudflared" -ForegroundColor White
Write-Host "   sudo systemctl restart booxstream-web" -ForegroundColor White
Write-Host ""
Write-Host "3. Vérifier le statut:" -ForegroundColor Yellow
Write-Host "   sudo systemctl status cloudflared" -ForegroundColor White
Write-Host "   sudo systemctl status booxstream-web" -ForegroundColor White
Write-Host ""
Write-Host "4. Tester:" -ForegroundColor Yellow
Write-Host "   curl https://booxstream.kevinvdb.dev/api/hosts" -ForegroundColor White
Write-Host ""

