# Script pour copier l'APK release dans le dossier releases
# Usage : .\copy-to-releases.ps1

Write-Host "📦 Copie de l'APK release vers le dossier de téléchargement" -ForegroundColor Cyan
Write-Host ""

$sourcePath = "app\build\outputs\apk\release\app-release.apk"
$destPath = "..\releases\android\booxstream.apk"

if (-not (Test-Path $sourcePath)) {
    Write-Host "❌ APK release non trouvé à : $sourcePath" -ForegroundColor Red
    Write-Host "   Exécutez d'abord : .\build-release.ps1" -ForegroundColor Yellow
    exit 1
}

# Créer le dossier si nécessaire
$destDir = Split-Path $destPath
if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
}

# Copier le fichier
Copy-Item -Path $sourcePath -Destination $destPath -Force

$fileSize = [math]::Round((Get-Item $destPath).Length / 1MB, 2)

Write-Host "✅ APK copié avec succès !" -ForegroundColor Green
Write-Host ""
Write-Host "📍 Emplacement : $destPath" -ForegroundColor White
Write-Host "📊 Taille : $fileSize MB" -ForegroundColor White
Write-Host ""
Write-Host "🌐 Disponible sur le serveur web à :" -ForegroundColor Cyan
Write-Host "   /api/download/android" -ForegroundColor White
Write-Host ""
Write-Host "N'oubliez pas de déployer le dossier 'releases' sur le serveur !" -ForegroundColor Yellow
