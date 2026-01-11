# Script de deploiement simplifie BooxStream
param(
    [switch]$GitOnly,
    [switch]$ServerOnly
)

$ErrorActionPreference = "Continue"

$configPath = Join-Path $PSScriptRoot "deploy-config.json"
if (-not (Test-Path $configPath)) {
    Write-Host "ERREUR: deploy-config.json introuvable" -ForegroundColor Red
    exit 1
}

$config = Get-Content $configPath | ConvertFrom-Json
$serverHost = $config.server.host
$serverUser = $config.server.user
$deployPath = $config.server.deployPath
$branch = $config.git.branch

Write-Host "Deploiement BooxStream" -ForegroundColor Cyan
Write-Host ""

# 1. Push GitHub
if (-not $ServerOnly) {
    Write-Host "Push vers GitHub..." -ForegroundColor Yellow
    
    $status = git status --porcelain
    if ($status) {
        $commitMsg = Read-Host "Message de commit (ou 'skip')"
        if ($commitMsg -and $commitMsg -ne "skip") {
            git add .
            git commit -m $commitMsg
        }
    }
    
    git push origin $branch
    if ($LASTEXITCODE -eq 0) {
        Write-Host "OK: Code pousse vers GitHub" -ForegroundColor Green
    } else {
        Write-Host "ERREUR: Push GitHub echoue" -ForegroundColor Red
        if (-not $GitOnly) {
            $continue = Read-Host "Continuer deploiement serveur? (y/n)"
            if ($continue -ne "y") { exit 1 }
        }
    }
    Write-Host ""
}

# 2. Deploiement serveur
if (-not $GitOnly) {
    Write-Host "Deploiement sur serveur $serverUser@$serverHost..." -ForegroundColor Yellow
    
    $deployScript = @"
#!/bin/bash
set -e
DEPLOY_PATH="$deployPath"
REPO_URL="https://github.com/Zabadehut/BooxStream.git"
BRANCH="$branch"

echo "Clonage/Mise a jour..."
if [ -d "`$DEPLOY_PATH" ]; then
    cd "`$DEPLOY_PATH"
    git fetch origin
    git reset --hard origin/`$BRANCH
    git clean -fd
else
    sudo mkdir -p "`$(dirname "`$DEPLOY_PATH")"
    sudo chown `$USER:`$USER "`$(dirname "`$DEPLOY_PATH")"
    git clone -b "`$BRANCH" "`$REPO_URL" "`$DEPLOY_PATH"
    cd "`$DEPLOY_PATH"
fi

echo "Installation dependances web..."
if [ -d "web" ]; then
    cd web
    npm install
    cd ..
fi

echo "Installation dependances server..."
if [ -d "server" ]; then
    cd server
    npm install
    cd ..
fi

echo "Configuration du service systemd..."
if [ -f "web/booxstream-web.service" ]; then
    # Creer le fichier .env si necessaire
    if [ ! -f "web/.env" ]; then
        echo "Creation du fichier .env..."
        # Generer JWT_SECRET (utiliser openssl si disponible, sinon /dev/urandom)
        if command -v openssl >/dev/null 2>&1; then
            JWT_SECRET=`$(openssl rand -hex 32)
        else
            JWT_SECRET=`$(head -c 32 /dev/urandom | hexdump -ve '1/1 "%.2x"')
        fi
        cat > web/.env << EOF
PORT=3001
JWT_SECRET=`$JWT_SECRET
DB_PATH=`$DEPLOY_PATH/web/booxstream.db
DOMAIN=booxstream.kevinvdb.dev
EOF
        echo "Fichier .env cree avec JWT_SECRET genere"
    fi
    
    # Copier le service systemd
    sudo cp web/booxstream-web.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable booxstream-web
    sudo systemctl restart booxstream-web
    
    echo "Service booxstream-web configure et demarre"
    sudo systemctl status booxstream-web --no-pager -l | head -20
else
    echo "ATTENTION: Fichier booxstream-web.service non trouve"
fi

echo "Deploiement termine!"
"@
    
    $tempFile = [System.IO.Path]::GetTempFileName() + ".sh"
    # Écrire avec fins de ligne Unix (LF seulement)
    $deployScript -join "`n" | Out-File -FilePath $tempFile -Encoding ASCII -NoNewline
    
    try {
        scp $tempFile "${serverUser}@${serverHost}:/tmp/deploy.sh"
        # Convertir les fins de ligne sur le serveur avant d'exécuter
        ssh "${serverUser}@${serverHost}" "dos2unix /tmp/deploy.sh 2>/dev/null || sed -i 's/\r$//' /tmp/deploy.sh; chmod +x /tmp/deploy.sh && bash /tmp/deploy.sh"
        Write-Host "OK: Deploiement serveur termine" -ForegroundColor Green
    } catch {
        Write-Host "ERREUR: $($_.Exception.Message)" -ForegroundColor Red
    } finally {
        if (Test-Path $tempFile) {
            Remove-Item $tempFile -ErrorAction SilentlyContinue
        }
    }
}

Write-Host ""
Write-Host "Deploiement termine!" -ForegroundColor Green

