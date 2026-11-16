# Firebase Cheatsheet (2026)

Краткий справочник по самым важным командам, паттернам и настройкам Firebase.

---

## 1. Установка и базовые команды CLI

```bash
# Установка / обновление
npm install -g firebase-tools

# Авторизация
firebase login
firebase login:ci                  # для CI/CD

# Проекты
firebase projects:list
firebase use <project-id>
firebase use --add                 # добавить алиас

# Инициализация
firebase init                      # интерактивно
firebase init functions
firebase init firestore
firebase init hosting
firebase init emulators

# Деплой
firebase deploy
firebase deploy --only functions
firebase deploy --only functions:functionName
firebase deploy --only firestore:rules
firebase deploy --only storage
firebase deploy --only hosting

# Логи
firebase functions:log
firebase functions:log --only functionName
```

---

## 2. Структура типичного проекта

```
my-project/
├── .firebaserc              # алиасы проектов
├── firebase.json            # основная конфигурация
├── firestore.rules
├── firestore.indexes.json
├── storage.rules
├── functions/
│   ├── index.js / src/index.ts
│   ├── package.json
│   ├── .runtimeconfig.json  # старый config (лучше secrets)
│   └── tsconfig.json        # если TypeScript
└── public/                  # для Hosting
```

---

## 3. Cloud Functions (2nd Generation)

### Основные импорты (Node.js)

```js
const { onRequest, onCall, HttpsError } = require("firebase-functions/https");
const { onDocumentCreated, onDocumentUpdated, onDocumentDeleted, onDocumentWritten } = require("firebase-functions/firestore");
const { onObjectFinalized, onObjectDeleted } = require("firebase-functions/storage");
const { onSchedule } = require("firebase-functions/scheduler");
const { onUserCreated, onUserDeleted } = require("firebase-functions/identity");
const { onMessagePublished } = require("firebase-functions/pubsub");
const { logger } = require("firebase-functions");
const { defineSecret, defineString } = require("firebase-functions/params");
```

### Примеры функций

```js
// HTTP-функция
exports.helloWorld = onRequest((req, res) => {
  res.send("Hello from Firebase!");
});

// Callable-функция
exports.addNumbers = onCall((request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Требуется авторизация");
  }
  const { a, b } = request.data;
  return { result: a + b };
});

// Firestore trigger
exports.onUserCreate = onDocumentCreated("users/{userId}", async (event) => {
  const data = event.data.data();
  const userId = event.params.userId;
  logger.info("New user:", userId, data);
});

// Storage trigger
exports.generateThumbnail = onObjectFinalized("uploads/{fileName}", async (event) => {
  const filePath = event.data.name;
  // логика обработки
});

// По расписанию (каждый день в 03:00)
exports.dailyCleanup = onSchedule("0 3 * * *", async (event) => {
  // очистка
});
```

### Секреты (рекомендуемый способ)

```bash
firebase functions:secrets:set MY_API_KEY
```

```js
const apiKey = defineSecret("MY_API_KEY");

exports.myFunction = onRequest({ secrets: [apiKey] }, (req, res) => {
  const key = apiKey.value();
});
```

---

## 4. Firestore

```js
const { getFirestore, collection, doc, setDoc, getDoc, updateDoc, deleteDoc,
        query, where, orderBy, limit, onSnapshot, serverTimestamp,
        writeBatch, increment } = require("firebase/firestore");

// Запись
await setDoc(doc(db, "users", uid), {
  name: "Alex",
  createdAt: serverTimestamp()
});

// Обновление
await updateDoc(doc(db, "users", uid), {
  score: increment(1)
});

// Запрос
const q = query(
  collection(db, "posts"),
  where("published", "==", true),
  orderBy("createdAt", "desc"),
  limit(20)
);

// Реал-тайм слушатель
onSnapshot(q, (snapshot) => {
  snapshot.docChanges().forEach(change => {
    if (change.type === "added") { /* ... */ }
  });
});

// Batch-запись
const batch = writeBatch(db);
batch.set(doc1, data1);
batch.update(doc2, data2);
batch.delete(doc3);
await batch.commit();
```

### Правила безопасности (firestore.rules)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /posts/{postId} {
      allow read: if resource.data.published == true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth.uid == resource.data.authorId;
    }
  }
}
```

---

## 5. Authentication

```js
import { getAuth, createUserWithEmailAndPassword, signInWithEmailAndPassword,
         signInWithPopup, GoogleAuthProvider, signInAnonymously,
         onAuthStateChanged, signOut } from "firebase/auth";

const auth = getAuth();

// Email / Password
await createUserWithEmailAndPassword(auth, email, password);
await signInWithEmailAndPassword(auth, email, password);

// Google
const provider = new GoogleAuthProvider();
await signInWithPopup(auth, provider);

// Анонимный вход
await signInAnonymously(auth);

// Слушатель состояния
onAuthStateChanged(auth, (user) => {
  if (user) {
    console.log("User UID:", user.uid);
  } else {
    // не авторизован
  }
});

// Выход
await signOut(auth);
```

---

## 6. Cloud Storage

```js
import { getStorage, ref, uploadBytes, getDownloadURL, deleteObject } from "firebase/storage";

const storage = getStorage();
const storageRef = ref(storage, `images/${file.name}`);

// Загрузка
await uploadBytes(storageRef, file);
const url = await getDownloadURL(storageRef);

// Удаление
await deleteObject(storageRef);
```

---

## 7. Emulators (Local Emulator Suite)

```bash
# Инициализация
firebase init emulators

# Запуск
firebase emulators:start
firebase emulators:start --only functions,firestore,auth
firebase emulators:start --import=./emulator-data --export-on-exit

# Запуск + тесты
firebase emulators:exec "npm test"
```

### Подключение клиента к эмуляторам

**Web:**
```js
import { connectFunctionsEmulator } from "firebase/functions";
import { connectFirestoreEmulator } from "firebase/firestore";
import { connectAuthEmulator } from "firebase/auth";
import { connectStorageEmulator } from "firebase/storage";

connectFunctionsEmulator(getFunctions(), "127.0.0.1", 5001);
connectFirestoreEmulator(getFirestore(), "127.0.0.1", 8080);
connectAuthEmulator(getAuth(), "http://127.0.0.1:9099");
connectStorageEmulator(getStorage(), "127.0.0.1", 9199);
```

**Flutter:**
```dart
FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
```

**Android (Kotlin):**
```kotlin
Firebase.functions.useEmulator("10.0.2.2", 5001)
Firebase.firestore.useEmulator("10.0.2.2", 8080)
```

**UI эмуляторов:** [http://localhost:4000](http://localhost:4000)

### Порты по умолчанию

| Сервис              | Порт  |
|---------------------|-------|
| Emulator UI         | 4000  |
| Functions           | 5001  |
| Firestore           | 8080  |
| Authentication      | 9099  |
| Realtime Database   | 9000  |
| Storage             | 9199  |
| Hosting             | 5000  |
| Pub/Sub             | 8085  |

---

## 8. Полезные настройки firebase.json

```json
{
  "functions": [
    {
      "source": "functions",
      "codebase": "default",
      "ignore": ["node_modules", ".git", "firebase-debug.log", "firebase-debug.*.log"],
      "predeploy": ["npm --prefix \"$RESOURCE_DIR\" run lint", "npm --prefix \"$RESOURCE_DIR\" run build"]
    }
  ],
  "emulators": {
    "functions": { "port": 5001 },
    "firestore": { "port": 8080 },
    "auth": { "port": 9099 },
    "storage": { "port": 9199 },
    "ui": { "enabled": true, "port": 4000 },
    "singleProjectMode": true
  },
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  }
}
```

---

## 9. Бесплатные лимиты (Blaze plan)

| Продукт              | Бесплатно                          |
|----------------------|------------------------------------|
| Cloud Functions      | 2 000 000 вызовов / месяц          |
|                      | 400 000 GB-секунд                  |
|                      | 5 GB исходящего трафика            |
| Firestore            | 50 000 чтений / день               |
|                      | 20 000 записей / день              |
|                      | 1 GiB хранилища                    |
| Cloud Storage        | 5 GB хранилища                     |
| Hosting              | 10 GB хранилища                    |
|                      | 360 МБ трафика / день              |

> Даже на Blaze-плане при соблюдении лимитов вы платите **0 ₽**.

---

## 10. Полезные ссылки

- [Официальная документация](https://firebase.google.com/docs)
- [Cloud Functions](https://firebase.google.com/docs/functions)
- [Emulator Suite](https://firebase.google.com/docs/emulator-suite)
- [Примеры функций](https://github.com/firebase/functions-samples)
- [Pricing](https://firebase.google.com/pricing)
- [Status](https://status.firebase.google.com)

---

**Совет:** Всегда разрабатывай и тестируй через эмуляторы. Деплой в продакшен — только после проверки.

Удачной разработки! 🚀
