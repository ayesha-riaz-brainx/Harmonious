-- AI coach, quick capture, Journey, and You settings
-- Run in Supabase SQL Editor (safe to re-run)
-- Also included at the end of setup_all.sql

alter table public.daily_logs
  add column if not exists sleep_hours numeric;

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
