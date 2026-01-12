# Script de génération du keystore pour BooxStream
# Usage : .\generate-keystore.ps1

Write-Host "🔐 Génération du keystore BooxStream" -ForegroundColor Cyan
Write-Host ""

# Rechercher keytool dans les installations Android Studio et JDK
function Find-Keytool {
    $possiblePaths = @(
        # JDK fourni avec Android Studio
        "$env:LOCALAPPDATA\Android\Sdk\jdk\*\bin\keytool.exe",
        "$env:ProgramFiles\Android\Android Studio\jbr\bin\keytool.exe",
        "$env:ProgramFiles\Android\Android Studio\jre\bin\keytool.exe",
        # Installations JDK standard
        "$env:ProgramFiles\Java\jdk*\bin\keytool.exe",
        "$env:ProgramFiles\Microsoft\jdk*\bin\keytool.exe",
        "$env:ProgramFiles\Eclipse Adoptium\jdk*\bin\keytool.exe",
        # Chemin dans le PATH
        "keytool.exe"
    )
    
    foreach ($path in $possiblePaths) {
        $resolved = Get-ChildItem $path -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($resolved) {
            return $resolved.FullName
        }
    }
    
    # Essayer de trouver via 'where'
    try {
        $wherePath = (Get-Command keytool -ErrorAction SilentlyContinue).Source
        if ($wherePath) {
            return $wherePath
        }
    } catch {}
    
    return $null
}

$keytoolPath = Find-Keytool

if (-not $keytoolPath) {
    Write-Host "❌ Erreur : keytool introuvable" -ForegroundColor Red
    Write-Host ""
    Write-Host "keytool fait partie du JDK. Options :" -ForegroundColor Yellow
    Write-Host "  1. Installer Android Studio (inclut le JDK)" -ForegroundColor White
    Write-Host "  2. Installer un JDK séparément (https://adoptium.net/)" -ForegroundColor White
    Write-Host "  3. Ajouter le JDK au PATH Windows" -ForegroundColor White
    Write-Host ""
    Write-Host "Chemins recherchés :" -ForegroundColor Gray
    Write-Host "  - $env:LOCALAPPDATA\Android\Sdk\jdk\*\bin\keytool.exe" -ForegroundColor Gray
    Write-Host "  - $env:ProgramFiles\Android\Android Studio\jbr\bin\keytool.exe" -ForegroundColor Gray
    Write-Host "  - $env:ProgramFiles\Java\jdk*\bin\keytool.exe" -ForegroundColor Gray
    exit 1
}

Write-Host "✓ keytool trouvé : $keytoolPath" -ForegroundColor Green
Write-Host ""

$keystorePath = "booxstream-release.keystore"

# Vérifier si le keystore existe déjà
if (Test-Path $keystorePath) {
    Write-Host "⚠️  Le keystore existe déjà : $keystorePath" -ForegroundColor Yellow
    $overwrite = Read-Host "Voulez-vous le remplacer ? (oui/non)"
    if ($overwrite -ne "oui") {
        Write-Host "❌ Annulé" -ForegroundColor Red
        exit 1
    }
    Remove-Item $keystorePath
}

Write-Host "📋 Informations requises pour le certificat :" -ForegroundColor Green
Write-Host ""

# Demander les informations
$keystorePassword = Read-Host "Mot de passe du keystore (minimum 6 caractères)" -AsSecureString
$keystorePasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($keystorePassword)
)

$keyPassword = Read-Host "Mot de passe de la clé (minimum 6 caractères)" -AsSecureString
$keyPasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($keyPassword)
)

$name = Read-Host "Votre nom ou nom de l'entreprise"
$organization = Read-Host "Organisation (ex: BooxStream)"
$city = Read-Host "Ville"
$state = Read-Host "État/Province"
$country = Read-Host "Code pays (2 lettres, ex: FR)"

Write-Host ""
Write-Host "🔧 Génération du keystore..." -ForegroundColor Cyan

# Construire le DN (Distinguished Name)
$dn = "CN=$name, O=$organization, L=$city, ST=$state, C=$country"

# Générer le keystore
$env:KEYSTORE_PASS = $keystorePasswordPlain
$env:KEY_PASS = $keyPasswordPlain

try {
    & $keytoolPath -genkey -v `
        -keystore $keystorePath `
        -alias booxstream `
        -keyalg RSA `
        -keysize 2048 `
        -validity 10000 `
        -storepass $keystorePasswordPlain `
        -keypass $keyPasswordPlain `
        -dname $dn

    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Keystore généré avec succès : $keystorePath" -ForegroundColor Green
        Write-Host ""
        Write-Host "📝 Créez maintenant le fichier keystore.env avec ces informations :" -ForegroundColor Yellow
        Write-Host "---" -ForegroundColor Gray
        Write-Host "BOOXSTREAM_KEYSTORE_FILE=booxstream-release.keystore" -ForegroundColor White
        Write-Host "BOOXSTREAM_KEYSTORE_PASSWORD=$keystorePasswordPlain" -ForegroundColor White
        Write-Host "BOOXSTREAM_KEY_ALIAS=booxstream" -ForegroundColor White
        Write-Host "BOOXSTREAM_KEY_PASSWORD=$keyPasswordPlain" -ForegroundColor White
        Write-Host "---" -ForegroundColor Gray
        Write-Host ""
        Write-Host "⚠️  IMPORTANT : Ne commitez JAMAIS ce fichier dans Git !" -ForegroundColor Red
        Write-Host "⚠️  Sauvegardez le keystore et les mots de passe en lieu sûr !" -ForegroundColor Red
        
        # Proposer de créer le fichier keystore.env
        Write-Host ""
        $createEnv = Read-Host "Voulez-vous créer le fichier keystore.env automatiquement ? (oui/non)"
        if ($createEnv -eq "oui") {
            $envContent = @"
# Configuration du keystore pour la signature de l'application
# NE JAMAIS COMMITER CE FICHIER DANS GIT !

BOOXSTREAM_KEYSTORE_FILE=booxstream-release.keystore
BOOXSTREAM_KEYSTORE_PASSWORD=$keystorePasswordPlain
BOOXSTREAM_KEY_ALIAS=booxstream
BOOXSTREAM_KEY_PASSWORD=$keyPasswordPlain
"@
            $envContent | Out-File -FilePath "keystore.env" -Encoding UTF8
            Write-Host "✅ Fichier keystore.env créé" -ForegroundColor Green
        }
    } else {
        Write-Host "❌ Erreur lors de la génération du keystore" -ForegroundColor Red
        exit 1
    }
} finally {
    # Nettoyer les variables d'environnement
    Remove-Item Env:\KEYSTORE_PASS -ErrorAction SilentlyContinue
    Remove-Item Env:\KEY_PASS -ErrorAction SilentlyContinue
}

