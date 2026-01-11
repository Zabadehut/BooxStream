# Script pour compiler et installer l'application BooxStream sur la tablette connectee
# Usage: .\build-and-install.ps1

Write-Host "=== Compilation et installation de BooxStream ===" -ForegroundColor Cyan
Write-Host ""

# Verifier que ADB est disponible
$adbPath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
if (-not (Test-Path $adbPath)) {
    Write-Host "ERREUR: ADB non trouve. Assurez-vous qu'Android Studio est installe." -ForegroundColor Red
    exit 1
}

# Verifier qu'un appareil est connecte (optionnel pour la compilation)
Write-Host "Verification de la connexion..." -ForegroundColor Yellow
$devices = & $adbPath devices | Select-String "device$"
if ($devices) {
    Write-Host "Appareil connecte: $($devices -replace '\s+device$', '')" -ForegroundColor Green
    $deviceConnected = $true
} else {
    Write-Host "Aucun appareil connecte. La compilation continuera, mais l'installation sera ignoree." -ForegroundColor Yellow
    $deviceConnected = $false
}
Write-Host ""

# Trouver le JDK d'Android Studio
Write-Host "Recherche du JDK..." -ForegroundColor Yellow
$jdkPaths = @(
    "$env:LOCALAPPDATA\Android Studio\jbr",
    "$env:ProgramFiles\Android\Android Studio\jbr",
    "$env:ProgramFiles (x86)\Android\Android Studio\jbr"
)
$jdkPath = $null
foreach ($path in $jdkPaths) {
    $javaPath = Join-Path $path "bin\java.exe"
    if (Test-Path $javaPath) {
        $jdkPath = $path
        break
    }
}

if (-not $jdkPath) {
    Write-Host "ERREUR: JDK non trouve. Assurez-vous qu'Android Studio est installe." -ForegroundColor Red
    exit 1
}

Write-Host "JDK trouve: $jdkPath" -ForegroundColor Green
$env:JAVA_HOME = $jdkPath
$javaBinPath = Join-Path $jdkPath "bin"
$env:PATH = "$javaBinPath;$env:PATH"
Write-Host "JAVA_HOME defini: $env:JAVA_HOME" -ForegroundColor Gray
Write-Host ""

# Verifier si Gradle wrapper existe
$gradlewPath = Join-Path $PSScriptRoot "gradlew.bat"
if (-not (Test-Path $gradlewPath)) {
    Write-Host "ERREUR: gradlew.bat non trouve." -ForegroundColor Red
    Write-Host "Ouvrez le projet dans Android Studio pour generer le wrapper Gradle." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "OU utilisez Android Studio directement:" -ForegroundColor Cyan
    Write-Host "  1. Selectionnez votre tablette dans le menu deroulant"
    Write-Host "  2. Cliquez sur Run ou Shift+F10"
    exit 1
}

# Verifier que Java est accessible
$javaExe = Join-Path $javaBinPath "java.exe"
if (-not (Test-Path $javaExe)) {
    Write-Host "ERREUR: java.exe non trouve a $javaExe" -ForegroundColor Red
    exit 1
}

# Compiler l'APK
Write-Host "Compilation de l'APK..." -ForegroundColor Yellow
Write-Host "Utilisation de Java: $javaExe" -ForegroundColor Gray
Write-Host "JAVA_HOME: $jdkPath" -ForegroundColor Gray

# Creer un wrapper batch temporaire pour passer JAVA_HOME a gradlew.bat
# Utiliser des guillemets pour gerer les chemins avec espaces
$wrapperBatch = Join-Path $env:TEMP "gradlew-wrapper-$(Get-Random).bat"
$batchContent = @"
@echo off
set "JAVA_HOME=$jdkPath"
set "PATH=$javaBinPath;%PATH%"
cd /d "$PSScriptRoot"
call "$gradlewPath" assembleDebug
exit /b %ERRORLEVEL%
"@
$batchContent | Out-File -FilePath $wrapperBatch -Encoding ASCII -NoNewline

try {
    Write-Host "Execution du wrapper batch..." -ForegroundColor Gray
    $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "`"$wrapperBatch`"" -Wait -PassThru -NoNewWindow
    $exitCode = $process.ExitCode
} finally {
    # Nettoyer le fichier temporaire
    if (Test-Path $wrapperBatch) {
        Remove-Item $wrapperBatch -Force -ErrorAction SilentlyContinue
    }
}

if ($exitCode -ne 0) {
    Write-Host "ERREUR: La compilation a echoue (code: $exitCode)." -ForegroundColor Red
    exit 1
}
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERREUR: La compilation a echoue." -ForegroundColor Red
    exit 1
}

# Trouver l'APK genere
$apkPath = "app\build\outputs\apk\debug\app-debug.apk"
if (-not (Test-Path $apkPath)) {
    Write-Host "ERREUR: APK non trouve a $apkPath" -ForegroundColor Red
    exit 1
}

Write-Host "APK compile avec succes: $apkPath" -ForegroundColor Green
Write-Host ""

# Installer seulement si un appareil est connecte
if ($deviceConnected) {
    # Desinstaller l'ancienne version si elle existe
    Write-Host "Verification de l'installation existante..." -ForegroundColor Yellow
    $installed = & $adbPath shell "pm list packages" | Select-String "com.example.booxstreamer"
    if ($installed) {
        Write-Host "Desinstallation de l'ancienne version..." -ForegroundColor Yellow
        & $adbPath uninstall com.example.booxstreamer
    }

    # Installer la nouvelle version
    Write-Host "Installation de l'application..." -ForegroundColor Yellow
    & $adbPath install -r $apkPath
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "Installation reussie !" -ForegroundColor Green
        Write-Host ""
        Write-Host "Pour lancer l'application:" -ForegroundColor Cyan
        Write-Host "  .\adb-helper.ps1 shell am start -n com.example.booxstreamer/.MainActivity"
        Write-Host ""
        Write-Host "OU trouvez 'BooxStream' dans le launcher de votre tablette." -ForegroundColor Cyan
    } else {
        Write-Host "ERREUR: L'installation a echoue." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host ""
    Write-Host "APK compile avec succes mais non installe (aucun appareil connecte)." -ForegroundColor Yellow
    Write-Host "Pour installer:" -ForegroundColor Cyan
    Write-Host "  1. Connectez votre tablette via USB" -ForegroundColor Gray
    Write-Host "  2. Activez le debogage USB" -ForegroundColor Gray
    Write-Host "  3. Relancez ce script ou utilisez: adb install -r $apkPath" -ForegroundColor Gray
}
