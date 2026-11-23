{
  "name": "telegram-mini-app",
  "version": "1.0.0",
  "private": true,
  "description": "Telegram Mini App with React and Firebase",
  "workspaces": [
    "frontend",
    "functions"
  ],
  "scripts": {
    "dev": "npm run dev --workspace=frontend",
    "build": "npm run build --workspace=frontend",
    "build:functions": "npm run build --workspace=functions",
    "serve": "firebase emulators:start",
    "debug": "firebase emulators:start --inspect-functions --log-verbosity debug",
    "deploy": "npm run build && firebase deploy",
    "clean": "powershell -File ./clean.ps1",
    "tailwind": "npx @tailwindcss/cli -i ./frontend/src/index.css -o ./frontend/src/dist.css --watch --workspace=frontend",
	"emulators": "firebase emulators:start --only functions,firestore"
  },
  "devDependencies": {
    "@tailwindcss/vite": "^4.3.3",
    "firebase-tools": "^13.0.0",
    "tailwindcss": "^4.3.3",
    "vite": "^5.4.21"
  }
}
