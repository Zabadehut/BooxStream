# Script de sauvegarde BooxStream
# Crée une archive du projet

param(
    [string]$OutputPath = "backups"
)

$ErrorActionPreference = "Stop"

Write-Host "💾 Sauvegarde BooxStream" -ForegroundColor Cyan
Write-Host ""

# Créer le dossier de sauvegarde
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath | Out-Null
}

# Nom du fichier avec timestamp
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupName = "booxstream-backup-$timestamp.zip"
$backupPath = Join-Path $OutputPath $backupName

Write-Host "📦 Création de l'archive..." -ForegroundColor Yellow

# Exclure les fichiers temporaires
$excludeItems = @(
    "node_modules",
    ".gradle",
    "build",
    ".idea",
    ".git",
    "*.log",
    "backups"
)

# Créer l'archive
$itemsToBackup = Get-ChildItem -Path $PSScriptRoot -Exclude $excludeItems

$tempDir = Join-Path $env:TEMP "booxstream-backup"
if (Test-Path $tempDir) {
    Remove-Item $tempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $tempDir | Out-Null

foreach ($item in $itemsToBackup) {
    Copy-Item -Path $item.FullName -Destination $tempDir -Recurse -Force
}

Compress-Archive -Path "$tempDir\*" -DestinationPath $backupPath -Force
Remove-Item $tempDir -Recurse -Force

$backupSize = (Get-Item $backupPath).Length / 1MB

Write-Host "✅ Sauvegarde créée: $backupPath" -ForegroundColor Green
Write-Host "📊 Taille: $([math]::Round($backupSize, 2)) MB" -ForegroundColor Cyan
Write-Host ""

