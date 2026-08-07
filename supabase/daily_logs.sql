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
