$AppName = "tg-app-x"
$projectId = "simple-function-elkrot" # Укажите ваш Project ID

mkdir $AppName
cd $AppName

$firebaseJson = @{
    functions = @(
        @{
            source = "functions"
            codebase = "default"
            ignore = @(
                "node_modules",
                ".git",
                "firebase-debug.log",
                "firebase-debug.*.log",
                "*.local"
            )
            predeploy = @(
                "npm --prefix `"$RESOURCE_DIR`" run build"
            )
        }
    )
} | ConvertTo-Json -Depth 10

Set-Content -Path ".\firebase.json" -Value $firebaseJson -Encoding UTF8


$firebaseRc = @{
    projects = @{
        default = $projectId
    }
} | ConvertTo-Json

Set-Content -Path ".\.firebaserc" -Value $firebaseRc -Encoding UTF8

$path = ".\functions\src"

# Если папка существует — удаляем её со всем содержимым
if (Test-Path -Path $path) {
    Remove-Item -Path $path -Recurse -Force
}

# Создаем чистую папку
New-Item -Path $path -ItemType Directory -Force

$content =@'
import { onRequest } from 'firebase-functions/v2/https';

export const sayHello = onRequest((request, response) => {
  const name = request.query.name || 'Гость';
  response.send(`Привет, ${name}! `);
});
'@

Set-Content -Path ".\functions\src\index.ts" -Value $content -Encoding UTF8

cd functions

npm install --save-dev mocha chai ts-node @types/mocha @types/chai
$path = ".\test"

# Если папка существует — удаляем её со всем содержимым
if (Test-Path -Path $path) {
    Remove-Item -Path $path -Recurse -Force
}

# Создаем чистую папку
New-Item -Path $path -ItemType Directory -Force


$content =@"
import { expect } from 'chai';
// Импортируем функцию (в реальных проектах логику лучше выносить отдельно)
import * as myFunctions from '../src/index'; 

describe('Cloud Functions Tests', () => {
  it('должна возвращать приветствие с именем', () => {
    // В простых тестах мы имитируем объекты request и response
    const req = { query: { name: 'TestUser' } } as any;
    const res = {
      send: (data: string) => {
        expect(data).to.equal('Привет, TestUser!');
      }
    } as any;

    myFunctions.sayHello(req, res);
  });
});
"@ 
Set-Content -Path ".\test\index.spec.ts"  -Value $content -Encoding UTF8



# 1. Путь к package.json
$packageJsonPath = ".\package.json"

# Создаем директорию, если её ещё нет
$parentDir = Split-Path -Path $packageJsonPath
if ($parentDir -and -not (Test-Path -Path $parentDir)) {
    New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
}

# 2. Формируем объект структуры package.json
$packageData = [ordered]@{
    name            = "functions"
    scripts         = [ordered]@{
        "build"       = "tsc"
        "build:watch" = "tsc --watch"
        "serve"       = "npm run build && firebase emulators:start --only functions"
        "shell"       = "npm run build && firebase functions:shell"
        "start"       = "npm run shell"
        "deploy"      = "firebase deploy --only functions"
        "logs"        = "firebase functions:log"
		"test"        = "mocha -r ts-node/register 'test/**/*.spec.ts'"
    }
    engines         = [ordered]@{
        node = "24"
    }
    main            = "lib/index.js"
    dependencies    = [ordered]@{
        "firebase-admin"     = "^13.6.0"
        "firebase-functions" = "^7.0.0"
    }
    devDependencies = [ordered]@{
        "typescript"              = "^6.0.0"
        "firebase-functions-test" = "^3.4.1"
    }
    private         = $true
}

# 3. Сериализуем в JSON с достаточной глубиной
$jsonContent = $packageData | ConvertTo-Json -Depth 10

# 4. Записываем файл в UTF-8 без BOM
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText((New-Item -Path $packageJsonPath -ItemType File -Force).FullName, $jsonContent, $utf8NoBom)




npx tsc --init

$jsonPath = ".\tsconfig.json"
$tsconfig = Get-Content -Path $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json

# 2. Проверяем, существует ли секция "compilerOptions". Если нет — создаем её
if (-not $tsconfig.PSObject.Properties['compilerOptions']) {
    $tsconfig | Add-Member -MemberType NoteProperty -Name "compilerOptions" -Value ([PSCustomObject]@{})
}

# 3. Добавляем или перезаписываем скрипт "types"
$typesValue = @("mocha", "chai")
$tsconfig.compilerOptions | Add-Member -MemberType NoteProperty -Name "types" -Value $typesValue -Force

# 4. Преобразуем объект обратно в JSON и сохраняем в файл
$tsconfig | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding UTF8


npm test
npm run build

#firebase emulators:start --only functions
#firebase deploy --only functions