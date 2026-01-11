# Script pour ajouter les fichiers manquants a Git
# Usage: .\add-to-git.ps1

Write-Host "=== Ajout des fichiers manquants a Git ===" -ForegroundColor Cyan
Write-Host ""

# Fichiers critiques pour le serveur
$criticalFiles = @(
    "SETUP-CLOUDFLARE-TUNNEL.sh",
    "web/FIX-DOMAIN.md",
    "CHECK-SERVER-LOGS.md",
    "CHECK-SERVICE.md",
    "VERIFY-DEPLOY.md"
)

# Fichiers de documentation Cloudflare
$cloudflareDocs = @(
    "CLOUDFLARE-TUNNEL.md",
    "CLOUDFLARE-TUNNEL-SIMPLE.md",
    "CONFIG-CNAME.md",
    "CONFIG-DOMAIN.md"
)

# Scripts Android
$androidScripts = @(
    "android-app/build-and-install.ps1",
    "android-app/adb-helper.ps1",
    "android-app/check-app.ps1",
    "android-app/check-logs.ps1",
    "android-app/debug-stream.ps1",
    "android-app/quick-debug.ps1"
)

# Documentation Android
$androidDocs = @(
    "android-app/DEBUG-GUIDE.md",
    "android-app/SETUP-GRADLE.md",
    "android-app/TROUBLESHOOTING.md"
)

# Ressources Android (icones)
$androidResources = @(
    "android-app/app/src/main/res/drawable/",
    "android-app/app/src/main/res/mipmap-*/"
)

Write-Host "Ajout des fichiers critiques..." -ForegroundColor Yellow
foreach ($file in $criticalFiles) {
    if (Test-Path $file) {
        git add $file
        Write-Host "  [+] $file" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Ajout de la documentation Cloudflare..." -ForegroundColor Yellow
foreach ($file in $cloudflareDocs) {
    if (Test-Path $file) {
        git add $file
        Write-Host "  [+] $file" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Ajout des scripts Android..." -ForegroundColor Yellow
foreach ($file in $androidScripts) {
    if (Test-Path $file) {
        git add $file
        Write-Host "  [+] $file" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Ajout de la documentation Android..." -ForegroundColor Yellow
foreach ($file in $androidDocs) {
    if (Test-Path $file) {
        git add $file
        Write-Host "  [+] $file" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Ajout des ressources Android (icones)..." -ForegroundColor Yellow
git add android-app/app/src/main/res/
Write-Host "  [+] Ressources Android" -ForegroundColor Green

Write-Host ""
Write-Host "Ajout des autres fichiers modifies..." -ForegroundColor Yellow
git add android-app/gradle/wrapper/gradle-wrapper.jar
git add android-app/gradlew.bat
git add android-app/BUILD.md
git add android-app/FIX-GRADLE.md

Write-Host ""
Write-Host "=== Resume ===" -ForegroundColor Cyan
git status --short | Select-Object -First 20

Write-Host ""
Write-Host "Pour commiter et pousser:" -ForegroundColor Yellow
Write-Host "  git commit -m 'Ajout scripts, documentation et ressources pour Cloudflare Tunnel'" -ForegroundColor White
Write-Host "  git push origin main" -ForegroundColor White

