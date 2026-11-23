param(
    [Parameter(Mandatory)]
    [string]$CurrentDir,

    [Parameter(Mandatory)]
    [string]$AppName,

    [Parameter(Mandatory)]
    [string]$OutputDir
)

$AppFullPath = Join-Path -Path $OutputDir -ChildPath $AppName 
Write-Host "✅ START GENERATE" -ForegroundColor Green

Remove-Item -Path $AppFullPath -Recurse -Force -ErrorAction SilentlyContinue

mkdir $AppFullPath
cd $AppFullPath
git init

Write-Host "✅ FRONTEND START" -ForegroundColor Green
mkdir frontend
$frontendPath = Join-Path -Path $AppFullPath -ChildPath "frontend"
cd $frontendPath
npx create-vite@latest . --template react-ts --no-interactive 
npm init -y 

Write-Host "FRONTEND FINISHED" -ForegroundColor Green

cd $frontendPath
mkdir -p .cert && mkcert -key-file ./.cert/localhost-key.pem -cert-file ./.cert/localhost.pem 'tg.local'
Write-Host " CERT INSTALLED" -ForegroundColor Green

cd $AppFullPath


Write-Host "✅ FUNCTIONS"  -ForegroundColor Green

#firebase init functions
$functionsPath = Join-Path -Path $AppFullPath -ChildPath "functions"


Write-Host "FINISH  FUNCTIONS"  -ForegroundColor Green

cd $CurrentDir
$templatePath = Join-Path -Path $CurrentDir -ChildPath "template"
$genPath = Join-Path -Path $CurrentDir -ChildPath "generate.ps1"

# Генерация проекта из шаблона 
. $genPath -TemplateRoot $templatePath -TargetRoot $AppFullPath -Namespace $AppName

cd $AppFullPath


#npm install firebase
#firebase init 



