# Script PowerShell pour connecter BooxStream à GitHub
# Utilisation: .\setup-github.ps1

Write-Host "🔗 Configuration du dépôt GitHub pour BooxStream" -ForegroundColor Cyan
Write-Host ""

# Demander l'URL du dépôt GitHub
$repoUrl = Read-Host "Entrez l'URL de votre dépôt GitHub (ex: https://github.com/Zabadehut/BooxStream.git)"

if ($repoUrl) {
    Write-Host "`n📡 Ajout du remote GitHub..." -ForegroundColor Yellow
    git remote add origin $repoUrl
    
    Write-Host "✅ Remote ajouté!" -ForegroundColor Green
    Write-Host "`n📤 Vérification de la configuration..." -ForegroundColor Yellow
    git remote -v
    
    Write-Host "`n🚀 Pour pousser le code, exécutez:" -ForegroundColor Cyan
    Write-Host "   git push -u origin master" -ForegroundColor White
} else {
    Write-Host "❌ URL non fournie. Annulation." -ForegroundColor Red
}

