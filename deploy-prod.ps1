# Script de deploiement complet pour la production
# Deploie tous les fichiers sur le serveur et teste

param(
    [switch]$SkipGit,
    [switch]$SkipTest
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

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DEPLOIEMENT PRODUCTION BOOXSTREAM" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Push vers GitHub
if (-not $SkipGit) {
    Write-Host "[1/4] Push vers GitHub..." -ForegroundColor Yellow
    
    $status = git status --porcelain
    if ($status) {
        Write-Host "  Changements detectes, commit necessaire..." -ForegroundColor Yellow
        $commitMsg = Read-Host "  Message de commit (ou 'skip' pour ignorer)"
        if ($commitMsg -and $commitMsg -ne "skip") {
            git add .
            git commit -m $commitMsg
            Write-Host "  Commit cree" -ForegroundColor Green
        }
    }
    
    Write-Host "  Push vers origin/$branch..." -ForegroundColor Yellow
    git push origin $branch
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  OK: Code pousse vers GitHub" -ForegroundColor Green
    } else {
        Write-Host "  ERREUR: Push GitHub echoue" -ForegroundColor Red
        $continue = Read-Host "  Continuer deploiement serveur? (y/n)"
        if ($continue -ne "y") { exit 1 }
    }
    Write-Host ""
}

# 2. Deploiement sur le serveur
Write-Host "[2/4] Deploiement sur serveur $serverUser@$serverHost..." -ForegroundColor Yellow

$deployScript = @"
#!/bin/bash
set -e

DEPLOY_PATH="$deployPath"
REPO_URL="https://github.com/Zabadehut/BooxStream.git"
BRANCH="$branch"

echo "  Clonage/Mise a jour du depot..."
if [ -d "`$DEPLOY_PATH" ] && [ -d "`$DEPLOY_PATH/.git" ]; then
    cd "`$DEPLOY_PATH"
    git fetch origin
    git reset --hard origin/`$BRANCH
    git clean -fd
    echo "  Depot mis a jour"
else
    sudo mkdir -p "`$(dirname "`$DEPLOY_PATH")"
    sudo chown `$USER:`$USER "`$(dirname "`$DEPLOY_PATH")"
    git clone -b "`$BRANCH" "`$REPO_URL" "`$DEPLOY_PATH"
    cd "`$DEPLOY_PATH"
    echo "  Depot clone"
fi

echo "  Installation dependances web..."
if [ -d "web" ]; then
    cd web
    if [ -f "package.json" ]; then
        npm install --production
        echo "  Dependances web installees"
    fi
    cd ..
fi

echo "  Installation dependances server (legacy)..."
if [ -d "server" ]; then
    cd server
    if [ -f "package.json" ]; then
        npm install --production
        echo "  Dependances server installees"
    fi
    cd ..
fi

echo "  Configuration du fichier .env..."
if [ -d "web" ] && [ ! -f "web/.env" ]; then
    JWT_SECRET=`$(openssl rand -hex 32)
    cat > web/.env << EOF
PORT=3001
JWT_SECRET=`$JWT_SECRET
DB_PATH=/opt/booxstream/web/booxstream.db
DOMAIN=booxstream.kevinvdb.dev
EOF
    echo "  Fichier .env cree"
fi

echo "  Configuration du service systemd..."
if [ -f "web/booxstream-web.service" ]; then
    sudo cp web/booxstream-web.service /etc/systemd/system/
    sudo systemctl daemon-reload
    echo "  Service systemd configure"
fi

echo "  Deploiement termine!"
"@

$tempFile = [System.IO.Path]::GetTempFileName() + ".sh"
# Écrire avec fins de ligne Unix
$deployScript -join "`n" | Out-File -FilePath $tempFile -Encoding ASCII -NoNewline

try {
    Write-Host "  Upload du script de deploiement..." -ForegroundColor Yellow
    scp $tempFile "${serverUser}@${serverHost}:/tmp/deploy-prod.sh" | Out-Null
    
    Write-Host "  Execution sur le serveur..." -ForegroundColor Yellow
    ssh "${serverUser}@${serverHost}" "dos2unix /tmp/deploy-prod.sh 2>/dev/null || sed -i 's/\r$//' /tmp/deploy-prod.sh; chmod +x /tmp/deploy-prod.sh && bash /tmp/deploy-prod.sh"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  OK: Deploiement serveur termine" -ForegroundColor Green
    } else {
        Write-Host "  ERREUR: Deploiement echoue (code: $LASTEXITCODE)" -ForegroundColor Red
    }
} catch {
    Write-Host "  ERREUR: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    if (Test-Path $tempFile) {
        Remove-Item $tempFile -ErrorAction SilentlyContinue
    }
}

Write-Host ""

# 3. Redemarrage du service
Write-Host "[3/4] Redemarrage du service..." -ForegroundColor Yellow

try {
    ssh "${serverUser}@${serverHost}" "sudo systemctl restart booxstream-web"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  OK: Service redemarre" -ForegroundColor Green
    } else {
        Write-Host "  ATTENTION: Service non redemarre (peut-etre non configure)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ATTENTION: Impossible de redemarrer le service" -ForegroundColor Yellow
}

Write-Host ""

# 4. Tests
if (-not $SkipTest) {
    Write-Host "[4/4] Tests de verification..." -ForegroundColor Yellow
    
    # Test 1: Service actif
    Write-Host "  Test 1: Statut du service..." -ForegroundColor Cyan
    $serviceStatus = ssh "${serverUser}@${serverHost}" "sudo systemctl is-active booxstream-web 2>&1"
    if ($serviceStatus -match "active") {
        Write-Host "    OK: Service actif" -ForegroundColor Green
    } else {
        Write-Host "    ATTENTION: Service non actif" -ForegroundColor Yellow
    }
    
    # Test 2: Ports ouverts
    Write-Host "  Test 2: Ports ouverts..." -ForegroundColor Cyan
    $port3001 = ssh "${serverUser}@${serverHost}" "sudo ss -tlnp | grep ':3001' | wc -l"
    $port8080 = ssh "${serverUser}@${serverHost}" "sudo ss -tlnp | grep ':8080' | wc -l"
    if ([int]$port3001 -gt 0) {
        Write-Host "    OK: Port 3001 ouvert" -ForegroundColor Green
    } else {
        Write-Host "    ATTENTION: Port 3001 non ouvert" -ForegroundColor Yellow
    }
    if ([int]$port8080 -gt 0) {
        Write-Host "    OK: Port 8080 ouvert" -ForegroundColor Green
    } else {
        Write-Host "    ATTENTION: Port 8080 non ouvert" -ForegroundColor Yellow
    }
    
    # Test 3: HTTP accessible
    Write-Host "  Test 3: HTTP accessible..." -ForegroundColor Cyan
    try {
        $response = Invoke-WebRequest -Uri "http://${serverHost}:3001" -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Host "    OK: HTTP accessible (code 200)" -ForegroundColor Green
        }
    } catch {
        Write-Host "    ATTENTION: HTTP non accessible: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DEPLOIEMENT TERMINE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Acces:" -ForegroundColor Yellow
Write-Host "  Web: http://${serverHost}:3001" -ForegroundColor White
Write-Host "  Logs: ssh ${serverUser}@${serverHost} 'sudo journalctl -u booxstream-web -f'" -ForegroundColor White
Write-Host ""

