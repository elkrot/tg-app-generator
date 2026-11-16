# Установка / обновление Firebase CLI
npm install -g firebase-tools
firebase login
firebase init
firebase init emulators
cd functions
firebase functions:config:get > .runtimeconfig.json

firebase emulators:start --inspect-functions

#Сохранение данных между перезапусками
Bashfirebase emulators:start --import=./emulator-data --export-on-exit

#Подключение клиента к эмулятору функций
Web (JavaScript/TypeScript)
JavaScriptimport { getFunctions, connectFunctionsEmulator } from "firebase/functions";

const functions = getFunctions();
connectFunctionsEmulator(functions, "127.0.0.1", 5001);
Android (Kotlin)
Kotlinval functions = Firebase.functions
functions.useEmulator("10.0.2.2", 5001)  // 10.0.2.2 — localhost с эмулятора Android

# Запустить все настроенные эмуляторы
firebase emulators:start

# Только Functions
firebase emulators:start --only functions

# Functions + Firestore
firebase emulators:start --only functions,firestore

# Запуск + выполнение тестов
firebase emulators:exec "npm test"

# Очистка кэша эмуляторов
firebase emulators:start --clear

# Просмотр логов только Functions
firebase emulators:start --only functions