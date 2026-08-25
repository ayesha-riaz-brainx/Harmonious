-- Health tracker JSON on profiles (manual conditions, records, symptoms, progress)
-- Run in Supabase SQL Editor (safe to re-run)

alter table public.profiles
  add column if not exists health_tracker jsonb not null default '{}'::jsonb;

comment on column public.profiles.health_tracker is
  'Manual health tracker payload: conditions, records, symptoms (no file uploads).';
