#!/bin/bash

# Остановка выполнения при ошибках
set -e

APP_NAME="tg-app-x"
PROJECT_ID="simple-function-elkrot" # Укажите ваш Project ID

mkdir -p "$APP_NAME"
cd "$APP_NAME"

# Запись firebase.json
cat << 'EOF' > ./firebase.json
{
  "functions": [
    {
      "source": "functions",
      "codebase": "default",
      "ignore": [
        "node_modules",
        ".git",
        "firebase-debug.log",
        "firebase-debug.*.log",
        "*.local"
      ],
      "predeploy": [
        "npm --prefix \"$RESOURCE_DIR\" run build"
      ]
    }
  ]
}
EOF

# Запись .firebaserc
cat << EOF > ./.firebaserc
{
  "projects": {
    "default": "$PROJECT_ID"
  }
}
EOF

# Пересоздание директории functions/src
rm -rf ./functions/src
mkdir -p ./functions/src

# Запись functions/src/index.ts
cat << 'EOF' > ./functions/src/index.ts
import { onRequest } from 'firebase-functions/v2/https';

export const sayHello = onRequest((request, response) => {
  const name = request.query.name || 'Гость';
  response.send(`Привет, ${name}! `);
});
EOF

cd functions

# Установка зависимостей
npm install --save-dev mocha chai ts-node @types/mocha @types/chai

# Пересоздание директории test
rm -rf ./test
mkdir -p ./test

# Запись test/index.spec.ts
cat << 'EOF' > ./test/index.spec.ts
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

# Генерация package.json
cat << 'EOF' > ./package.json
{
  "name": "functions",
  "scripts": {
    "build": "tsc",
    "build:watch": "tsc --watch",
    "serve": "npm run build && firebase emulators:start --only functions",
    "shell": "npm run build && firebase functions:shell",
    "start": "npm run shell",
    "deploy": "firebase deploy --only functions",
    "logs": "firebase functions:log",
    "test": "mocha -r ts-node/register 'test/**/*.spec.ts'"
  },
  "engines": {
    "node": "24"
  },
  "main": "lib/index.js",
  "dependencies": {
    "firebase-admin": "^13.6.0",
    "firebase-functions": "^7.0.0"
  },
  "devDependencies": {
    "typescript": "^6.0.0",
    "firebase-functions-test": "^3.4.1"
  },
  "private": true
}
EOF

# Инициализация tsconfig.json
npx tsc --init

# Обновление types в tsconfig.json с помощью jq
tmp_json=$(mktemp)
jq '.compilerOptions.types = ["mocha", "chai"]' ./tsconfig.json > "$tmp_json" && mv "$tmp_json" ./tsconfig.json

# Выполнение тестов и сборка
npm test
npm run build

# firebase emulators:start --only functions
# firebase deploy --only functions