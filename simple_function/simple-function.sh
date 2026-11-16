#!/bin/bash
#sudo apt install jq
# Остановка выполнения при ошибках
set -e

APP_NAME="tg-app-x"

mkdir -p "$APP_NAME"
cd "$APP_NAME"
firebase init functions

# Запись файла src/index.ts
cat << 'EOF' > ./functions/src/index.ts
import { onRequest } from 'firebase-functions/v2/https';

export const sayHello = onRequest((request, response) => {
  const name = request.query.name || 'Гость';
  response.send(`Привет, ${name}! `);
});
EOF

cd functions

npm install --save-dev mocha chai ts-node @types/mocha @types/chai

# Пересоздание директории test
rm -rf ./test
mkdir -p ./test

# Запись файла test/index.spec.ts
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

# Обновление package.json с помощью jq
tmp_json=$(mktemp)
jq '.scripts.test = "mocha -r ts-node/register \"test/**/*.spec.ts\""' ./package.json > "$tmp_json" && mv "$tmp_json" ./package.json

# Обновление tsconfig.json с помощью jq
jq '.compilerOptions.types = ["mocha", "chai"]' ./tsconfig.json > "$tmp_json" && mv "$tmp_json" ./tsconfig.json

npm test

npm run build
firebase emulators:start --only functions
# firebase deploy --only functions