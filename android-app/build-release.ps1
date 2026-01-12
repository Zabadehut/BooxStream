# Script de build en mode Release avec signature
# Usage : .\build-release.ps1

Write-Host "🚀 Build BooxStream en mode Release" -ForegroundColor Cyan
Write-Host ""

# Rechercher Java dans les installations Android Studio et JDK
function Find-JavaHome {
    Write-Host "🔍 Recherche de Java..." -ForegroundColor Gray

    # Si déjà configuré et valide
    if ($env:JAVA_HOME -and (Test-Path "$env:JAVA_HOME\bin\java.exe")) {
        Write-Host "   ✓ Trouvé (JAVA_HOME) : $env:JAVA_HOME" -ForegroundColor Green
        return $env:JAVA_HOME
    }

    # Test direct du chemin exact connu
    $knownJavaPath = "C:\Program Files\Android\Android Studio\jbr\bin\java.exe"
    if (Test-Path -LiteralPath $knownJavaPath -ErrorAction SilentlyContinue) {
        Write-Host "   ✓ Trouvé (chemin direct) : C:\Program Files\Android\Android Studio\jbr" -ForegroundColor Green
        return "C:\Program Files\Android\Android Studio\jbr"
    }

    $possiblePaths = @(
        # JDK fourni avec Android Studio (ordre de priorité)
        "$env:LOCALAPPDATA\Android Studio\jbr",
        "$env:ProgramFiles\Android\Android Studio\jbr",
        "$env:ProgramFiles (x86)\Android\Android Studio\jbr",
        "$env:LOCALAPPDATA\Android\Sdk\jdk\*",
        "$env:ProgramFiles\Android\Android Studio\jre",
        # Installations JDK standard
        "$env:ProgramFiles\Java\jdk*",
        "$env:ProgramFiles\Microsoft\jdk*",
        "$env:ProgramFiles\Eclipse Adoptium\jdk*"
    )

    foreach ($path in $possiblePaths) {
        Write-Host "   Vérification : $path" -ForegroundColor DarkGray

        # Vérifier les chemins directs
        if ($path -notlike "*`**") {
            # Normaliser le chemin et tester directement
            $normalizedPath = [System.IO.Path]::GetFullPath($path)
            $javaExe = [System.IO.Path]::Combine($normalizedPath, "bin", "java.exe")
            
            # Test direct avec le chemin complet
            if (Test-Path -LiteralPath $javaExe -ErrorAction SilentlyContinue) {
                Write-Host "   ✓ Trouvé : $normalizedPath" -ForegroundColor Green
                return $normalizedPath
            }
            
            # Test alternatif avec Join-Path
            $javaExeAlt = Join-Path $path "bin\java.exe"
            if (Test-Path -LiteralPath $javaExeAlt -ErrorAction SilentlyContinue) {
                Write-Host "   ✓ Trouvé : $path" -ForegroundColor Green
                return $path
            }
        } else {
            # Vérifier les chemins avec wildcard
            try {
                $resolved = Get-ChildItem $path -ErrorAction SilentlyContinue |
                           Where-Object { 
                               $javaPath = Join-Path $_.FullName "bin\java.exe"
                               Test-Path -LiteralPath $javaPath -ErrorAction SilentlyContinue
                           } |
                           Select-Object -First 1
                if ($resolved) {
                    Write-Host "   ✓ Trouvé : $($resolved.FullName)" -ForegroundColor Green
                    return $resolved.FullName
                }
            } catch {
                # Ignorer les erreurs de chemin invalide
            }
        }
    }

    Write-Host "   ❌ Aucun JDK trouvé" -ForegroundColor Red
    return $null
}

# Configurer JAVA_HOME si nécessaire
if (-not $env:JAVA_HOME -or -not (Test-Path "$env:JAVA_HOME\bin\java.exe")) {
    $javaHome = Find-JavaHome
    
    if (-not $javaHome) {
        Write-Host "❌ Erreur : JAVA_HOME introuvable" -ForegroundColor Red
        Write-Host ""
        Write-Host "Java est nécessaire pour Gradle. Options :" -ForegroundColor Yellow
        Write-Host "  1. Installer Android Studio (inclut le JDK)" -ForegroundColor White
        Write-Host "  2. Définir JAVA_HOME manuellement" -ForegroundColor White
        Write-Host ""
        Write-Host "Chemins recherchés :" -ForegroundColor Gray
        Write-Host "  - $env:LOCALAPPDATA\Android\Sdk\jdk\*" -ForegroundColor Gray
        Write-Host "  - $env:ProgramFiles\Android\Android Studio\jbr" -ForegroundColor Gray
        Write-Host "  - $env:ProgramFiles\Java\jdk*" -ForegroundColor Gray
        exit 1
    }
    
    $env:JAVA_HOME = $javaHome
    $javaBinPath = Join-Path $javaHome "bin"
    $env:PATH = "$javaBinPath;$env:PATH"
    Write-Host "✓ JAVA_HOME configuré : $javaHome" -ForegroundColor Green
} else {
    Write-Host "✓ JAVA_HOME déjà configuré : $env:JAVA_HOME" -ForegroundColor Green
    $javaBinPath = Join-Path $env:JAVA_HOME "bin"
    if ($env:PATH -notlike "*$javaBinPath*") {
        $env:PATH = "$javaBinPath;$env:PATH"
    }
}

Write-Host ""

# Vérifier si le keystore existe
$keystorePath = "booxstream-release.keystore"
if (-not (Test-Path $keystorePath)) {
    Write-Host "❌ Keystore introuvable : $keystorePath" -ForegroundColor Red
    Write-Host "   Exécutez d'abord : .\generate-keystore.ps1" -ForegroundColor Yellow
    exit 1
}

# Vérifier si le fichier keystore.env existe
if (-not (Test-Path "keystore.env")) {
    Write-Host "❌ Fichier keystore.env introuvable" -ForegroundColor Red
    Write-Host "   Créez ce fichier avec les informations du keystore" -ForegroundColor Yellow
    exit 1
}

# Charger les variables d'environnement depuis keystore.env
Write-Host "📋 Chargement de la configuration..." -ForegroundColor Cyan
Get-Content "keystore.env" | ForEach-Object {
    if ($_ -match '^([^#][^=]+)=(.+)$') {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim()
        [Environment]::SetEnvironmentVariable($name, $value)
        Write-Host "   ✓ $name configuré" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "🔧 Nettoyage..." -ForegroundColor Cyan
.\gradlew.bat clean

Write-Host ""
Write-Host "🔨 Build de l'APK signé..." -ForegroundColor Cyan
.\gradlew.bat assembleRelease

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Build réussi !" -ForegroundColor Green
    Write-Host ""
    Write-Host "📦 APK signé disponible :" -ForegroundColor Cyan
    Write-Host "   app\build\outputs\apk\release\app-release.apk" -ForegroundColor White
    Write-Host ""
    Write-Host "🔍 Pour vérifier la signature :" -ForegroundColor Yellow
    Write-Host "   jarsigner -verify -verbose -certs app\build\outputs\apk\release\app-release.apk" -ForegroundColor White
    Write-Host ""
    Write-Host "📤 Pour installer sur la tablette :" -ForegroundColor Yellow
    Write-Host "   adb install -r app\build\outputs\apk\release\app-release.apk" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "❌ Erreur lors du build" -ForegroundColor Red
    exit 1
}

# Nettoyer les variables d'environnement
Get-Content "keystore.env" | ForEach-Object {
    if ($_ -match '^([^#][^=]+)=(.+)$') {
        $name = $matches[1].Trim()
        Remove-Item "Env:\$name" -ErrorAction SilentlyContinue
    }
}

