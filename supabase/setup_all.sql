-- ============================================================
-- RUN THIS ONCE in Supabase → SQL Editor → New query → Run
-- Creates profiles + all profile-setup columns Harmonious needs
-- Safe to re-run
-- ============================================================

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text,
  email text unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles
  add column if not exists display_name text,
  add column if not exists age integer,
  add column if not exists gender text,
  add column if not exists height numeric,
  add column if not exists weight numeric,
  add column if not exists country text,
  add column if not exists weight_unit text default 'kg',
  add column if not exists height_unit text default 'cm',
  add column if not exists onboarding_completed boolean not null default false,
  add column if not exists profile_setup_completed boolean not null default false,
  add column if not exists onboarding_data jsonb not null default '{}'::jsonb,
  add column if not exists ai_profile jsonb not null default '{}'::jsonb,
  add column if not exists activity_level text,
  add column if not exists birthday date;

alter table public.profiles
  add column if not exists zodiac_sign text;

alter table public.profiles enable row level security;

drop policy if exists "Users can read own profile" on public.profiles;
create policy "Users can read own profile"
  on public.profiles for select using (auth.uid() = id);

drop policy if exists "Users can insert own profile" on public.profiles;
create policy "Users can insert own profile"
  on public.profiles for insert with check (auth.uid() = id);

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile"
  on public.profiles for update using (auth.uid() = id);

drop policy if exists "Users can delete own profile" on public.profiles;
create policy "Users can delete own profile"
  on public.profiles for delete using (auth.uid() = id);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, email, display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

create or replace function public.set_profiles_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute procedure public.set_profiles_updated_at();
-- Daily tracking for Harmonious home dashboard
-- Run in Supabase SQL Editor (safe to re-run)

create table if not exists public.daily_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  log_date date not null default (timezone('utc', now()))::date,
  weight numeric,
  water_liters numeric not null default 0,
  calories integer not null default 0,
  exercise_minutes integer not null default 0,
  mood text,
  tasks jsonb not null default '[]'::jsonb,
  ai_brief jsonb not null default '{}'::jsonb,
  ai_insights jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, log_date)
);

alter table public.daily_logs enable row level security;

drop policy if exists "Users read own daily logs" on public.daily_logs;
create policy "Users read own daily logs"
  on public.daily_logs for select using (auth.uid() = user_id);

drop policy if exists "Users insert own daily logs" on public.daily_logs;
create policy "Users insert own daily logs"
  on public.daily_logs for insert with check (auth.uid() = user_id);

drop policy if exists "Users update own daily logs" on public.daily_logs;
create policy "Users update own daily logs"
  on public.daily_logs for update using (auth.uid() = user_id);

drop policy if exists "Users delete own daily logs" on public.daily_logs;
create policy "Users delete own daily logs"
  on public.daily_logs for delete using (auth.uid() = user_id);

alter table public.daily_logs
  add column if not exists sleep_hours numeric;

-- ============================================================
-- AI coach, quick capture, Journey, and You settings
-- ============================================================

alter table public.profiles
  add column if not exists ai_memory jsonb not null default '{}'::jsonb,
  add column if not exists health_info jsonb not null default '{}'::jsonb,
  add column if not exists app_settings jsonb not null default '{
    "ai_personality": "Supportive",
    "communication_style": "Balanced",
    "memory_enabled": true,
    "theme": "Dark",
    "privacy_mode": "Standard"
  }'::jsonb;

create table if not exists public.captures (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  type text not null,
  payload jsonb not null default '{}'::jsonb,
  captured_at timestamptz not null default now()
);

create index if not exists captures_user_time_idx
  on public.captures (user_id, captured_at desc);

alter table public.captures enable row level security;

drop policy if exists "Users read own captures" on public.captures;
create policy "Users read own captures"
  on public.captures for select using (auth.uid() = user_id);

drop policy if exists "Users insert own captures" on public.captures;
create policy "Users insert own captures"
  on public.captures for insert with check (auth.uid() = user_id);

drop policy if exists "Users update own captures" on public.captures;
create policy "Users update own captures"
  on public.captures for update using (auth.uid() = user_id);

drop policy if exists "Users delete own captures" on public.captures;
create policy "Users delete own captures"
  on public.captures for delete using (auth.uid() = user_id);

create table if not exists public.ai_messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null check (role in ('user', 'assistant')),
  coach text not null default 'Life Coach',
  content text not null,
  created_at timestamptz not null default now()
);

create index if not exists ai_messages_user_time_idx
  on public.ai_messages (user_id, created_at desc);

alter table public.ai_messages enable row level security;

drop policy if exists "Users read own AI messages" on public.ai_messages;
create policy "Users read own AI messages"
  on public.ai_messages for select using (auth.uid() = user_id);

drop policy if exists "Users insert own AI messages" on public.ai_messages;
create policy "Users insert own AI messages"
  on public.ai_messages for insert with check (auth.uid() = user_id);

drop policy if exists "Users delete own AI messages" on public.ai_messages;
create policy "Users delete own AI messages"
  on public.ai_messages for delete using (auth.uid() = user_id);

-- Password reset OTP codes (Mailtrap email flow)
create table if not exists public.password_resets (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  code_hash text not null,
  expires_at timestamptz not null,
  used_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists password_resets_email_idx
  on public.password_resets (email, created_at desc);

alter table public.password_resets enable row level security;
