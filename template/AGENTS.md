# Project Context: Telegram Bot & Mini App

## Tech Stack
- **Frontend (Mini App):** React 18+, TypeScript, Vite, Tailwind CSS, `@twa-dev/sdk`
- **Backend (Bot & Webhooks):** Firebase Cloud Functions (Node.js 20, TypeScript), `grammy` (Telegram Bot framework)
- **Database & Auth:** Firebase Firestore, Firebase Authentication (Custom tokens via Telegram `initData` validation)
- **Hosting:** Firebase Hosting

## Architecture Rules
1. Keep frontend code in `/src` and Firebase Functions (bot logic) in `/functions/src`.
2. Never expose `BOT_TOKEN` in the Vite frontend (`VITE_*` variables). Store it strictly in Firebase Functions secrets/environment.
3. Validate Telegram `WebApp.initData` on the backend (Firebase Functions) using HMAC-SHA256 before writing sensitive user data to Firestore.
4. Use `grammy` in webhook mode (not long-polling) so it integrates natively with Firebase HTTPS Functions.

## Commands
- Frontend dev: `npm run dev`
- Build frontend: `npm run build`
- Firebase emulators: `firebase emulators:start`
- Deploy: `firebase deploy`