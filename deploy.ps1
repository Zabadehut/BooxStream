# Script de déploiement BooxStream
# Déploie le code vers GitHub et le serveur Rocky Linux

param(
    [switch]$GitOnly,
    [switch]$ServerOnly,
    [switch]$SkipGit,
    [switch]$SkipServer
)

$ErrorActionPreference = "Stop"

# Charger la configuration
$configPath = Join-Path $PSScriptRoot "deploy-config.json"
if (-not (Test-Path $configPath)) {
    Write-Host "❌ Fichier de configuration introuvable: $configPath" -ForegroundColor Red
    Write-Host "💡 Créez le fichier deploy-config.json avec vos paramètres" -ForegroundColor Yellow
    exit 1
}

$config = Get-Content $configPath | ConvertFrom-Json

Write-Host "🚀 Déploiement BooxStream" -ForegroundColor Cyan
Write-Host ""

# 1. Push vers GitHub
if (-not $SkipGit -and -not $ServerOnly) {
    Write-Host "📤 Push vers GitHub..." -ForegroundColor Yellow
    
    try {
        # Vérifier les changements
        $status = git status --porcelain
        if ($status) {
            Write-Host "📝 Changements détectés, commit nécessaire..." -ForegroundColor Yellow
            $commitMessage = Read-Host "Message de commit (ou 'skip' pour ignorer)"
            
            if ($commitMessage -and $commitMessage -ne "skip") {
                git add .
                git commit -m $commitMessage
                Write-Host "✅ Commit créé" -ForegroundColor Green
            } else {
                Write-Host "⏭️  Commit ignoré" -ForegroundColor Yellow
            }
        }
        
        # Push vers GitHub
        $branch = $config.git.branch
        Write-Host "📤 Push vers origin/$branch..." -ForegroundColor Yellow
        git push -u origin $branch
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Code poussé vers GitHub" -ForegroundColor Green
        } else {
            Write-Host "❌ Erreur lors du push GitHub" -ForegroundColor Red
            if (-not $SkipServer) {
                $continue = Read-Host "Continuer le déploiement serveur? (y/n)"
                if ($continue -ne "y") { exit 1 }
            }
        }
    } catch {
        Write-Host "❌ Erreur GitHub: $_" -ForegroundColor Red
        if (-not $SkipServer) {
            $continue = Read-Host "Continuer le déploiement serveur? (y/n)"
            if ($continue -ne "y") { exit 1 }
        }
    }
    Write-Host ""
}

# 2. Déploiement sur le serveur
if (-not $SkipServer -and -not $GitOnly) {
    Write-Host "🖥️  Déploiement sur le serveur Rocky Linux..." -ForegroundColor Yellow
    
    $serverHost = $config.server.host
    $serverUser = $config.server.user
    $deployPath = $config.server.deployPath
    
    if ($serverUser -eq "your_user") {
        Write-Host "⚠️  Configuration serveur non définie dans deploy-config.json" -ForegroundColor Yellow
        $serverUser = Read-Host "Nom d'utilisateur SSH"
    }
    
    Write-Host "📡 Connexion à $serverUser@$serverHost..." -ForegroundColor Yellow
    
    $branch = $config.git.branch
    
    # Exécuter les commandes directement via SSH
    $sshCommands = @(
        "cd $deployPath || (mkdir -p $(Split-Path $deployPath -Parent) && git clone -b $branch https://github.com/Zabadehut/BooxStream.git $deployPath && cd $deployPath)",
        "cd $deployPath",
        "git fetch origin",
        "git reset --hard origin/$branch",
        "git clean -fd",
        "cd server",
        "npm install --production",
        "sudo systemctl restart booxstream || echo 'Service non configuré'"
    ) -join " && "
    
    try {
        ssh "${serverUser}@${serverHost}" $sshCommands
        Write-Host "✅ Déploiement serveur terminé" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Erreur déploiement serveur: $_" -ForegroundColor Red
        Write-Host "💡 Vérifiez:" -ForegroundColor Yellow
        Write-Host "   - Connexion SSH fonctionnelle" -ForegroundColor Yellow
        Write-Host "   - Clé SSH configurée" -ForegroundColor Yellow
        Write-Host "   - Permissions sudo sur le serveur" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "✨ Déploiement terminé!" -ForegroundColor Green
