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
