# Supabase setup — keys you must paste

## 1. Create project
1. Go to https://supabase.com → New project
2. Wait until the project is ready

## 2. Enable Email auth
1. **Authentication** → **Providers** → **Email** → enable
2. For local testing you can disable **Confirm email** under  
   **Authentication** → **Providers** → **Email** → **Confirm email**

## 3. Create profiles table
1. Open **SQL Editor**
2. Paste and run `supabase/profiles.sql`

## 4. Copy keys (Project Settings → API)

| Key | Where to paste | Used by |
|-----|----------------|---------|
| **Project URL** | `frontend/.env` → `SUPABASE_URL` | Flutter app |
| **Project URL** | `backend/.env` → `SUPABASE_URL` | Node API |
| **anon public** | `frontend/.env` → `SUPABASE_ANON_KEY` | Flutter app only |
| **service_role** | `backend/.env` → `SUPABASE_SERVICE_ROLE_KEY` | Backend only — never in Flutter |

### Frontend file
`frontend/.env`
```env
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOi...   # anon public
```

### Backend file
`backend/.env`
```env
PORT=3000
NODE_ENV=development
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOi...   # service_role
```

## 5. Install & run

```bash
# Frontend
cd frontend
flutter pub get
flutter run

# Backend (optional admin signup API)
cd backend
npm install
npm run dev
```

## How auth works now
- **Sign Up screen** → Flutter → **Supabase Auth** (uses `SUPABASE_ANON_KEY`)
- **Backend** `POST /api/auth/signup` → Supabase Admin (uses `service_role`) for server-side user creation if needed

## Security
- ✅ `anon` key in the app is OK (protect data with RLS)
- ❌ Never put `service_role` in Flutter / git / screenshots
