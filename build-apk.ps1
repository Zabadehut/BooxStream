# Script pour compiler l'APK BooxStream
# Génère un APK prêt à être déployé sur FTP

$ErrorActionPreference = "Stop"

Write-Host "🔨 Compilation de l'APK BooxStream" -ForegroundColor Cyan
Write-Host ""

$androidAppPath = Join-Path $PSScriptRoot "android-app"
$releasesPath = Join-Path $PSScriptRoot "releases"

# Vérifier que le dossier android-app existe
if (-not (Test-Path $androidAppPath)) {
    Write-Host "❌ Dossier android-app introuvable!" -ForegroundColor Red
    exit 1
}

# Créer le dossier releases
if (-not (Test-Path $releasesPath)) {
    New-Item -ItemType Directory -Path $releasesPath | Out-Null
}

# Vérifier que Gradle est disponible
$gradleWrapper = Join-Path $androidAppPath "gradlew.bat"
if (-not (Test-Path $gradleWrapper)) {
    Write-Host "⚠️  Gradle wrapper introuvable" -ForegroundColor Yellow
    Write-Host "💡 Le wrapper sera créé lors de la première ouverture dans Android Studio" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Cyan
    Write-Host "1. Ouvrir le projet dans Android Studio et laisser Gradle se configurer" -ForegroundColor White
    Write-Host "2. Utiliser Android Studio pour générer l'APK (Build → Build APK)" -ForegroundColor White
    exit 1
}

Write-Host "📦 Compilation de l'APK..." -ForegroundColor Yellow

# Aller dans le dossier android-app
Push-Location $androidAppPath

try {
    # Nettoyer les builds précédents
    Write-Host "🧹 Nettoyage..." -ForegroundColor Yellow
    & .\gradlew.bat clean
    
    # Compiler l'APK debug
    Write-Host "🔨 Compilation..." -ForegroundColor Yellow
    & .\gradlew.bat assembleDebug
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Erreur lors de la compilation" -ForegroundColor Red
        exit 1
    }
    
    # Trouver l'APK généré
    $apkPath = Join-Path $androidAppPath "app\build\outputs\apk\debug\app-debug.apk"
    
    if (-not (Test-Path $apkPath)) {
        Write-Host "❌ APK non trouvé: $apkPath" -ForegroundColor Red
        exit 1
    }
    
    # Créer un nom avec timestamp
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $apkName = "BooxStream-$timestamp.apk"
    $destinationPath = Join-Path $releasesPath $apkName
    
    # Copier l'APK
    Copy-Item $apkPath $destinationPath -Force
    
    # Afficher les informations
    $apkSize = (Get-Item $destinationPath).Length / 1MB
    
    Write-Host ""
    Write-Host "✅ APK compilé avec succès!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📦 Fichier: $destinationPath" -ForegroundColor Cyan
    Write-Host "📊 Taille: $([math]::Round($apkSize, 2)) MB" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "🌐 Prêt à être uploadé sur votre FTP!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Pour installer sur la tablette:" -ForegroundColor Yellow
    Write-Host "1. Télécharger l'APK depuis le FTP" -ForegroundColor White
    Write-Host "2. Transférer sur la tablette" -ForegroundColor White
    Write-Host "3. Autoriser l'installation depuis sources inconnues" -ForegroundColor White
    Write-Host "4. Installer l'APK" -ForegroundColor White
    
} catch {
    Write-Host "❌ Erreur: $_" -ForegroundColor Red
    exit 1
} finally {
    Pop-Location
}

