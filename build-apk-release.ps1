# Script pour compiler l'APK BooxStream en mode RELEASE (signé)
# Nécessite une clé de signature

$ErrorActionPreference = "Stop"

Write-Host "🔨 Compilation de l'APK BooxStream (RELEASE)" -ForegroundColor Cyan
Write-Host ""

$androidAppPath = Join-Path $PSScriptRoot "android-app"
$releasesPath = Join-Path $PSScriptRoot "releases"
$keystorePath = Join-Path $androidAppPath "booxstream.keystore"

# Vérifier que le dossier android-app existe
if (-not (Test-Path $androidAppPath)) {
    Write-Host "❌ Dossier android-app introuvable!" -ForegroundColor Red
    exit 1
}

# Créer le dossier releases
if (-not (Test-Path $releasesPath)) {
    New-Item -ItemType Directory -Path $releasesPath | Out-Null
}

# Vérifier/créer la clé de signature
if (-not (Test-Path $keystorePath)) {
    Write-Host "🔑 Création de la clé de signature..." -ForegroundColor Yellow
    Write-Host "⚠️  Vous devrez entrer des informations pour la clé" -ForegroundColor Yellow
    Write-Host ""
    
    $keytool = "$env:JAVA_HOME\bin\keytool.exe"
    if (-not (Test-Path $keytool)) {
        $keytool = "keytool"
    }
    
    & $keytool -genkey -v -keystore $keystorePath -alias booxstream -keyalg RSA -keysize 2048 -validity 10000
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Erreur lors de la création de la clé" -ForegroundColor Red
        exit 1
    }
}

# Vérifier que Gradle est disponible
$gradleWrapper = Join-Path $androidAppPath "gradlew.bat"
if (-not (Test-Path $gradleWrapper)) {
    Write-Host "❌ Gradle wrapper introuvable" -ForegroundColor Red
    Write-Host "💡 Ouvrez le projet dans Android Studio d'abord" -ForegroundColor Yellow
    exit 1
}

Write-Host "📦 Compilation de l'APK RELEASE..." -ForegroundColor Yellow

# Aller dans le dossier android-app
Push-Location $androidAppPath

try {
    # Nettoyer
    Write-Host "🧹 Nettoyage..." -ForegroundColor Yellow
    & .\gradlew.bat clean
    
    # Compiler l'APK release
    Write-Host "🔨 Compilation RELEASE..." -ForegroundColor Yellow
    & .\gradlew.bat assembleRelease
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Erreur lors de la compilation" -ForegroundColor Red
        exit 1
    }
    
    # Trouver l'APK généré
    $apkPath = Join-Path $androidAppPath "app\build\outputs\apk\release\app-release.apk"
    
    if (-not (Test-Path $apkPath)) {
        Write-Host "❌ APK non trouvé: $apkPath" -ForegroundColor Red
        exit 1
    }
    
    # Créer un nom avec version
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $apkName = "BooxStream-release-$timestamp.apk"
    $destinationPath = Join-Path $releasesPath $apkName
    
    # Copier l'APK
    Copy-Item $apkPath $destinationPath -Force
    
    # Afficher les informations
    $apkSize = (Get-Item $destinationPath).Length / 1MB
    
    Write-Host ""
    Write-Host "✅ APK RELEASE compilé avec succès!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📦 Fichier: $destinationPath" -ForegroundColor Cyan
    Write-Host "📊 Taille: $([math]::Round($apkSize, 2)) MB" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "🌐 Prêt à être uploadé sur votre FTP!" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Erreur: $_" -ForegroundColor Red
    exit 1
} finally {
    Pop-Location
}

