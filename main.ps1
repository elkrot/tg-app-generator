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
npm intsall
cd ..\..\
Write-Host "FRONTEND FINISHED" -ForegroundColor Green

cd $frontendPath
mkdir -p .cert && mkcert -key-file ./.cert/localhost-key.pem -cert-file ./.cert/localhost.pem 'tg.local'
Write-Host " CERT INSTALLED" -ForegroundColor Green

cd $AppFullPath
npm install firebase
firebase init 

Write-Host "✅ FUNCTIONS"  -ForegroundColor Green

firebase init functions
$functionsPath = Join-Path -Path $AppFullPath -ChildPath "functions"
cd $functionsPath
npm init -y 
npm intsall

Write-Host "FINISH  FUNCTIONS"  -ForegroundColor Green

cd $CurrentDir
$templatePath = Join-Path -Path $CurrentDir -ChildPath "template"
$genPath = Join-Path -Path $CurrentDir -ChildPath "generate.ps1"

# Генерация проекта из шаблона 
. $genPath -TemplateRoot $templatePath -TargetRoot $AppFullPath -Namespace $AppName

cd $AppFullPath
# Добавляем локальные файлы .env в gitignore
echo ".env.local" >> .gitignore
echo ".env.*.local" >> .gitignore

# Также стоит добавить папку node_modules и папку сборки, 
# если они вдруг не были добавлены ранее
echo "node_modules/" >> .gitignore
echo "dist/" >> .gitignore

Write-Host "NPM INSTALL"  -ForegroundColor Green
cd $frontendPath
npm install --save-dev tailwindcss @tailwindcss/vite
npm install --save-dev @types/telegram-web-app
npm install --save-dev vite@^5.2.0

npm install @telegram-apps/sdk
npm install --save-dev @telegram-apps/sdk-react
npm install

cd $functionsPath
npm install --save-dev @types/express
npm install firebase-functions@latest firebase-admin@latest
npm install --save-dev typescript@latest @types/node@latest
npm intsall

cd $AppFullPath
npm install --workspace=frontend --save-dev vite@^5.2.0 tailwindcss@^4.3.3 @tailwindcss/vite@^4.3.3
npm install --workspace=frontend firebase@^12.18.0
npm install --prefix functions

Write-Host "FINISH GENERATE "  -ForegroundColor Green




