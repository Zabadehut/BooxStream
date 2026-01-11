# Script de restauration BooxStream
# Restaure le code depuis GitHub ou depuis une sauvegarde

param(
    [string]$From = "git",
    [string]$BackupPath = "",
    [switch]$ServerOnly
)

$ErrorActionPreference = "Stop"

# Charger la configuration
$configPath = Join-Path $PSScriptRoot "deploy-config.json"
if (-not (Test-Path $configPath)) {
    Write-Host "❌ Fichier de configuration introuvable: $configPath" -ForegroundColor Red
    exit 1
}

$config = Get-Content $configPath | ConvertFrom-Json

Write-Host "🔄 Restauration BooxStream" -ForegroundColor Cyan
Write-Host ""

if ($From -eq "git") {
    Write-Host "📥 Restauration depuis GitHub..." -ForegroundColor Yellow
    
    $branch = $config.git.branch
    Write-Host "📋 Récupération de origin/$branch..." -ForegroundColor Yellow
    
    git fetch origin
    git reset --hard "origin/$branch"
    git clean -fd
    
    Write-Host "✅ Code restauré depuis GitHub" -ForegroundColor Green
    
} elseif ($From -eq "backup" -and $BackupPath) {
    Write-Host "📥 Restauration depuis sauvegarde..." -ForegroundColor Yellow
    
    if (-not (Test-Path $BackupPath)) {
        Write-Host "❌ Fichier de sauvegarde introuvable: $BackupPath" -ForegroundColor Red
        exit 1
    }
    
    # Extraire la sauvegarde
    $backupDir = Join-Path $env:TEMP "booxstream-restore"
    if (Test-Path $backupDir) {
        Remove-Item $backupDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $backupDir | Out-Null
    
    Write-Host "📦 Extraction de la sauvegarde..." -ForegroundColor Yellow
    Expand-Archive -Path $BackupPath -DestinationPath $backupDir -Force
    
    # Copier les fichiers
    Write-Host "📋 Copie des fichiers..." -ForegroundColor Yellow
    Copy-Item -Path "$backupDir\*" -Destination $PSScriptRoot -Recurse -Force
    
    Remove-Item $backupDir -Recurse -Force
    Write-Host "✅ Code restauré depuis sauvegarde" -ForegroundColor Green
    
} else {
    Write-Host "❌ Source de restauration invalide" -ForegroundColor Red
    Write-Host "Usage: .\restore.ps1 -From git" -ForegroundColor Yellow
    Write-Host "      .\restore.ps1 -From backup -BackupPath path\to\backup.zip" -ForegroundColor Yellow
    exit 1
}

if ($ServerOnly) {
    Write-Host ""
    Write-Host "🖥️  Restauration sur le serveur..." -ForegroundColor Yellow
    
    $serverHost = $config.server.host
    $serverUser = $config.server.user
    $deployPath = $config.server.deployPath
    
    if ($serverUser -eq "your_user") {
        $serverUser = Read-Host "Nom d'utilisateur SSH"
    }
    
    $restoreScript = @"
#!/bin/bash
set -e

DEPLOY_PATH="$deployPath"
REPO_URL="https://github.com/Zabadehut/BooxStream.git"
BRANCH="$($config.git.branch)"

echo "📥 Restauration depuis GitHub..."
if [ -d "`$DEPLOY_PATH" ]; then
    cd "`$DEPLOY_PATH"
    git fetch origin
    git reset --hard origin/`$BRANCH
    git clean -fd
    cd server
    npm install --production
    sudo systemctl restart booxstream
    echo "✅ Serveur restauré"
else
    echo "❌ Dépôt non trouvé sur le serveur"
fi
"@
    
    $tempScript = [System.IO.Path]::GetTempFileName() + ".sh"
    $restoreScript | Out-File -FilePath $tempScript -Encoding UTF8
    
    try {
        scp $tempScript "${serverUser}@${serverHost}:/tmp/restore-booxstream.sh"
        ssh "${serverUser}@${serverHost}" "chmod +x /tmp/restore-booxstream.sh && /tmp/restore-booxstream.sh"
        Write-Host "✅ Serveur restauré" -ForegroundColor Green
    } catch {
        Write-Host "❌ Erreur restauration serveur: $_" -ForegroundColor Red
    } finally {
        Remove-Item $tempScript -ErrorAction SilentlyContinue
    }
}

Write-Host ""
Write-Host "✨ Restauration terminée!" -ForegroundColor Green

