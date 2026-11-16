import React, { useEffect, useState } from 'react';
import { signInWithCustomToken } from 'firebase/auth';
import { auth} from '../config/firebase';

const AuthPage: React.FC = () => {
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const authenticate = async () => {
      try {
        // 1. Получаем данные из Telegram
        const webApp = window?.Telegram?.WebApp;
        const initData = webApp?.initData;

        if (!initData) {
          throw new Error("Приложение запущено вне Telegram");
        }

        // 2. Отправляем на наш Firebase Function
        const response = await fetch('YOUR_CLOUD_FUNCTION_URL/authTelegram', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ initData }),
        });

        if (!response.ok) throw new Error("Ошибка сервера при авторизации");

        const { customToken } = await response.json();

        // 3. Логинимся в Firebase
        await signInWithCustomToken(auth, customToken);
        
        console.log("Авторизация успешна!");
        setLoading(false);
      } catch (err: any) {
        console.error(err);
        setError(err.message);
        setLoading(false);
      }
    };

    authenticate();
  }, []);

  if (loading) return <div>Загрузка авторизации...</div>;
  if (error) return <div>Ошибка: {error}</div>;

  return <div>Авторизация успешна! Добро пожаловать.</div>;
};

export default AuthPage;