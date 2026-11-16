#!/bin/bash
set -e

APP_NAME="tg-app-x"
PROJECT_ID="simple-function-elkrot" # Укажите ваш Project ID

mkdir -p "$APP_NAME"
cd "$APP_NAME"

# 1. Генерация firebase.json через jq
jq -n \
  --arg codebase "default" \
  --arg resource_dir '$RESOURCE_DIR' \
  '{
    functions: [
      {
        source: "functions",
        codebase: $codebase,
        ignore: [
          "node_modules",
          ".git",
          "firebase-debug.log",
          "firebase-debug.*.log",
          "*.local"
        ],
        predeploy: [
          "npm --prefix \"" + $resource_dir + "\" run build"
        ]
      }
    ]
  }' > firebase.json

# 2. Генерация .firebaserc через jq
jq -n --arg proj "$PROJECT_ID" '{projects: {default: $proj}}' > .firebaserc

# 3. Создание исходников функций
PATH_SRC="./functions/src"
rm -rf "$PATH_SRC"
mkdir -p "$PATH_SRC"

cat << 'EOF' > "$PATH_SRC/index.ts"
import { onRequest } from 'firebase-functions/v2/https';

export const sayHello = onRequest((request, response) => {
  const name = request.query.name || 'Гость';
  response.send(`Привет, ${name}! `);
});
EOF

cd functions

# 4. Установка зависимостей
npm install --save-dev mocha chai ts-node @types/mocha @types/chai

PATH_TEST="./test"
rm -rf "$PATH_TEST"
mkdir -p "$PATH_TEST"

cat << 'EOF' > "$PATH_TEST/index.spec.ts"
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
EOF

# 5. Генерация package.json через jq
jq -n '{
  name: "functions",
  scripts: {
    "build": "tsc",
    "build:watch": "tsc --watch",
    "serve": "npm run build && firebase emulators:start --only functions",
    "shell": "npm run build && firebase functions:shell",
    "start": "npm run shell",
    "deploy": "firebase deploy --only functions",
    "logs": "firebase functions:log",
    "test": "mocha -r ts-node/register '\''test/**/*.spec.ts'\''"
  },
  engines: {
    node: "24"
  },
  main: "lib/index.js",
  dependencies: {
    "firebase-admin": "^13.6.0",
    "firebase-functions": "^7.0.0"
  },
  devDependencies: {
    "typescript": "^6.0.0",
    "firebase-functions-test": "^3.4.1"
  },
  private: true
}' > package.json

# 6. Инициализация tsconfig и модификация с помощью jq
npx tsc --init

JSON_PATH="./tsconfig.json"

# Создаем временный файл, так как jq не умеет перезаписывать файл "на месте" напрямую
tmp_tsconfig=$(mktemp)

# jq загружает tsconfig.json, выставляет или перезаписывает .compilerOptions.types и сохраняет результат
jq '.compilerOptions.types = ["mocha", "chai"]' "$JSON_PATH" > "$tmp_tsconfig" && mv "$tmp_tsconfig" "$JSON_PATH"

# 7. Запуск сборки и тестов
npm test
npm run build

# firebase emulators:start --only functions
# firebase deploy --only functions