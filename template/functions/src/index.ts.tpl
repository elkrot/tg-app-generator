

import { onRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { getAuth } from "firebase-admin/auth";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import * as crypto from "crypto";
import { defineSecret } from "firebase-functions/params";

// Инициализация Firebase Admin
admin.initializeApp();
const auth = getAuth();
const firestore = getFirestore();

// Определение секрета для безопасности
const TELEGRAM_BOT_TOKEN = defineSecret("TELEGRAM_BOT_TOKEN");

interface TelegramUser {
  id: number;
  first_name: string;
  username?: string;
  [key: string]: any;
}

export const authTelegram = onRequest(
  { secrets: [TELEGRAM_BOT_TOKEN] },
  async (req, res) => {
    // Установка CORS заголовков
    res.set("Access-Control-Allow-Origin", "*");
    
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const { initData }: { initData: string } = req.body;

    if (!initData) {
      res.status(400).send("Missing initData");
      return;
    }

    try {
      const botToken = TELEGRAM_BOT_TOKEN.value();
      
      // 1. Валидация данных
      const isValid = validateTelegramWebAppData(initData, botToken);
      if (!isValid) {
        res.status(401).send("Invalid Telegram Data");
        return;
      }

      // 2. Парсинг данных
      const urlParams = new URLSearchParams(initData);
      const userJson = urlParams.get("user");
      
      if (!userJson) {
        res.status(400).send("User data missing");
        return;
      }

      const user: TelegramUser = JSON.parse(userJson);
      const telegramId = user.id.toString();

      // 3. Генерация кастомного токена Firebase
      const customToken = await auth.createCustomToken(telegramId);

      // 4. Синхронизация данных в Firestore
      await firestore.collection("users").doc(telegramId).set({
        username: user.username || null,
        firstName: user.first_name,
        lastLogin: FieldValue.serverTimestamp(),
      }, { merge: true });

      res.status(200).json({ customToken });
    } catch (error) {
      console.error("Auth error:", error);
      res.status(500).send("Internal Server Error");
    }
  }
);

/**
 * Валидация подписи Telegram (HMAC-SHA256)
 */
function validateTelegramWebAppData(initData: string, botToken: string): boolean {
  const urlParams = new URLSearchParams(initData);
  const hash = urlParams.get("hash");
  urlParams.delete("hash");
  
  const sortedParams = Array.from(urlParams.entries())
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([key, value]) => `${key}=${value}`)
    .join("\n");

  const secretKey = crypto
    .createHmac("sha256", "WebAppData")
    .update(botToken)
    .digest();

  const checkHash = crypto
    .createHmac("sha256", secretKey)
    .update(sortedParams)
    .digest("hex");

  return checkHash === hash;
}
