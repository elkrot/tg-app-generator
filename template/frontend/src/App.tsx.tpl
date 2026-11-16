import { useEffect, useState } from 'react';
import { db } from './config/firebase';
import { doc, getDoc } from 'firebase/firestore';
import { getAuth, signInWithCustomToken } from 'firebase/auth';

async function loginWithTelegram(): Promise<string> {
  const initData = window.Telegram.WebApp.initData;
  const logs: string[] = ["🚀 Начало авторизации\n"];
  
  try {
    logs.push("📤 Отправка запроса к Firebase Function...\n");
    const response = await fetch("http:localhost:5001/tgapplication-elkrot/us-central1/authTelegram", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ initData })
    });

    if (!response.ok) {
      logs.push(`❌ Сервер вернул ошибку: ${response.status}\n`);
      throw new Error(`HTTP ${response.status}`);
    }

    const { customToken } = await response.json();
    logs.push("✅ Токен успешно получен\n");
    
    logs.push("🔐 Авторизация в Firebase...\n");
    const auth = getAuth();
    await signInWithCustomToken(auth, customToken);
    logs.push("✅ Авторизация успешна!\n");
    
  } catch (error) {
    logs.push(`❌ Ошибка: ${error}\n`);
  }
  
  return logs.join("");
}

function App() {
  const [isAuthorized, setIsAuthorized] = useState(false);
  const [authLog, setAuthLog] = useState<string>("");
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const initApp = async () => {
      // Проверка Firebase
      try {
        const docRef = doc(db, "test", "connection");
        await getDoc(docRef);
        console.log("✅ Firebase работает успешно!");
      } catch (error) {
        console.error("❌ Ошибка подключения к Firebase:", error);
      }

      // Авторизация через Telegram
      if (window.Telegram?.WebApp) {
        const tg = window.Telegram.WebApp;
        tg.ready();
        
        const log = await loginWithTelegram();
        setAuthLog(log);
        console.log(log);
        
        if (log.includes("✅ Авторизация успешна!")) {
          setIsAuthorized(true);
        }
      } else {
        setAuthLog("❌ Telegram WebApp не найден\n");
      }
      
      setIsLoading(false);
    };

    initApp();
  }, []);

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen bg-stone-950 text-white">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-amber-500 mx-auto"></div>
          <p className="mt-4 text-stone-400">Загрузка...</p>
        </div>
      </div>
    );
  }

  const user = window.Telegram?.WebApp?.initDataUnsafe?.user;
  const theme = window.Telegram?.WebApp?.themeParams;
  const bgColor = theme?.bg_color || '#0a0a0a';
  const buttonColor = theme?.button_color || '#3b82f6';
  const linkColor = theme?.link_color || '#06b6d4';
  const hintColor = theme?.hint_color || '#6b7280';

  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-stone-950 text-white p-6">
      {/* Ваш основной UI */}
      {isAuthorized ? (
        // Контент для авторизованного пользователя
        <div>Пользователь авторизован</div>
      ) : (
        // Показываем логи если не авторизован
        <div className="max-w-md w-full bg-gray-900 p-4 rounded-lg">
          <h3 className="text-amber-400 mb-2">🔍 Логи авторизации:</h3>
          <pre className="text-xs text-stone-300 whitespace-pre-wrap font-mono">
            {authLog || "Нет данных"}
          </pre>
        </div>
      )}
      <div className="text-center space-y-4">
        <div className="w-24 h-24 bg-amber-500 rounded-full mx-auto flex items-center justify-center text-4xl">
          🎸
        </div>
        <h1 className="text-3xl font-bold">Guitar Teacher</h1>
        <p className="text-stone-400">Твой личный кабинет</p>
      </div>

      <button 
        onClick={() => alert('Вход выполнен!')}
        className="mt-12 w-full py-4 bg-amber-500 hover:bg-amber-400 text-black font-bold rounded-xl transition-all active:scale-95"
      >
        Войти через Telegram
      </button>


<div className="relative max-w-md w-full">
        {/* Анимированная подсветка */}
        <div className="absolute inset-0 rounded-2xl blur-xl animate-pulse" 
             style={{ backgroundColor: `${buttonColor}20` }}></div>
        
        {/* Основная карточка */}
        <div className="relative backdrop-blur-sm rounded-2xl p-6 shadow-2xl border"
             style={{ 
               backgroundColor: `${bgColor}cc`, 
               borderColor: `${linkColor}50` 
             }}>
          
          {/* Статус */}
          <div className="flex items-center justify-between mb-6">
            <div className="flex items-center gap-3">
              <div className="w-3 h-3 rounded-full animate-pulse" 
                   style={{ backgroundColor: linkColor, boxShadow: `0 0 10px ${linkColor}50` }}></div>
              <span className="text-sm font-mono tracking-wider" style={{ color: linkColor }}>ONLINE</span>
            </div>
            {user?.is_premium && (
              <div className="px-3 py-1 rounded-full text-xs font-bold tracking-wide"
                   style={{ backgroundColor: buttonColor, color: theme?.button_text_color || '#fff' }}>
                ⭐ PREMIUM
              </div>
            )}
          </div>

          {/* Аватар */}
          <div className="flex justify-center mb-6">
            <div className="relative">
              <div className="w-20 h-20 rounded-full flex items-center justify-center shadow-lg"
                   style={{ 
                     background: `linear-gradient(135deg, ${linkColor}, ${buttonColor})`,
                     boxShadow: `0 10px 30px ${linkColor}30`
                   }}>
                <span className="text-2xl font-bold text-white">
                  {user?.first_name?.charAt(0).toUpperCase() || '?'}
                </span>
              </div>
              <div className="absolute -bottom-1 -right-1 w-6 h-6 rounded-full border-2 animate-pulse"
                   style={{ backgroundColor: linkColor, borderColor: bgColor }}></div>
            </div>
          </div>

          {/* Информация */}
          <div className="space-y-3">
            {[
              { label: 'NAME', value: `${user?.first_name || 'Unknown'} ${user?.last_name || ''}` },
              { label: 'USERNAME', value: `@${user?.username || 'anonymous'}` },
              { label: 'USER ID', value: `#${user?.id || '000000'}` },
              user?.language_code ? { label: 'LANGUAGE', value: user.language_code.toUpperCase() } : null
            ].filter((item): item is { label: string; value: string } => item !== null).map((item, i) => (
              <div key={i} className="rounded-lg p-3 border"
                   style={{ backgroundColor: `${bgColor}80`, borderColor: `${hintColor}30` }}>
                <div className="flex justify-between items-center">
                  <span className="text-sm font-mono" style={{ color: hintColor }}>{item.label}</span>
                  <span className="font-semibold" style={{ color: i % 2 ? linkColor : buttonColor }}>
                    {item.value}
                  </span>
                </div>
              </div>
            ))}
          </div>

          {/* Статус бар */}
          <div className="mt-6 pt-4 border-t flex items-center justify-between text-xs"
               style={{ borderColor: `${hintColor}30` }}>
            <div className="flex items-center gap-2">
              <div className="w-2 h-2 rounded-full animate-pulse" style={{ backgroundColor: buttonColor }}></div>
              <span className="font-mono" style={{ color: hintColor }}>TELEGRAM WEB APP</span>
            </div>
            <span className="font-mono" style={{ color: hintColor }}>v1.0.0</span>
          </div>
        </div>
      </div>



    </div>
  );
}

export default App;

