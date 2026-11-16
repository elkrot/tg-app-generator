$AppName = "tg-app-x"

mkdir $AppName
cd $AppName
firebase init functions

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


# 1. Читаем файл package.json как JSON (с учетом кодировки UTF-8)
$jsonPath = ".\package.json"
$packageJson = Get-Content -Path $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json

# 2. Проверяем, существует ли секция "scripts". Если нет — создаем её
if (-not $packageJson.PSObject.Properties['scripts']) {
    $packageJson | Add-Member -MemberType NoteProperty -Name "scripts" -Value ([PSCustomObject]@{})
}

# 3. Добавляем или перезаписываем скрипт "test"
$testCommand = 'mocha -r ts-node/register "test/**/*.spec.ts"'
$packageJson.scripts | Add-Member -MemberType NoteProperty -Name "test" -Value $testCommand -Force

# 4. Преобразуем объект обратно в JSON и сохраняем в файл
$packageJson | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding UTF8

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
firebase emulators:start --only functions
#firebase deploy --only functions