# Slot 1 Tasks (Harmonious)

```
slot 1 tasks/
├── frontend/          # Flutter app
├── backend/           # Express + Supabase Admin API
├── supabase/          # SQL scripts
└── SUPABASE_SETUP.md
```

## Documentation

- **[Complete App Flows](docs/FLOWS.md)** — navigation, tabs, quick capture, AI tools, backend data flow, and user journeys

## Auth flow

```
Splash → (session?)
  yes → profile setup? → onboarding? → Home
  no  → Welcome → Sign Up / Login → Profile Setup → AI Onboarding → Home
```

## Frontend

```bash
cd frontend
# ensure .env has SUPABASE_URL + SUPABASE_ANON_KEY
# for store / real devices also set API_BASE_URL=https://your-deployed-api
flutter pub get
./run_emulator.sh
```

## Backend

```bash
cd backend
# ensure .env has SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY
npm install
npm run dev
```

## Store / production checklist

1. Deploy `backend/` to a public HTTPS host (Render, Railway, Fly, VPS, etc.).
2. In `frontend/.env` set `API_BASE_URL` to that URL (no trailing slash), then rebuild the APK/IPA.
3. Supabase → Authentication → URL Configuration:
   - **Site URL:** `https://harmonious.onrender.com/auth/email-confirmed`
   - **Redirect URLs:** add both:
     - `https://harmonious.onrender.com/auth/email-confirmed`
     - `https://harmonious.onrender.com/auth/reset-password`
4. Supabase → Authentication → Email Templates → **Confirm signup**: paste HTML from `backend/email-templates/confirm-signup.html` (subject: `Verify your Harmonious email`).
5. On Render backend env, add `SUPABASE_ANON_KEY` (same anon key as `frontend/.env`) so `/auth/reset-password` works. **No SMTP needed** — sign-up and forgot-password emails are sent by Supabase.

### API

| Method | Path | Auth |
|--------|------|------|
| POST | `/api/auth/signup` | no |
| POST | `/api/auth/login` | no |
| POST | `/api/auth/forgot-password` | no |
| DELETE | `/api/auth/account` | Bearer token |
| GET | `/api/profile/me` | Bearer token |
| PUT | `/api/profile/me` | Bearer token |

## Supabase SQL (run in SQL Editor)

1. `supabase/profiles.sql` (if not already)
2. **`supabase/profiles_extend.sql`** ← required for profile setup fields

## Theme

Harmonious dark theme across auth screens. Layouts scroll and scale so content fits phone screens.
