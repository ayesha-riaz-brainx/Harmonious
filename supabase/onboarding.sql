-- Run in Supabase SQL Editor (safe to re-run)
-- Stores Module 2 AI onboarding answers + generated profile summary

alter table public.profiles
  add column if not exists onboarding_data jsonb not null default '{}'::jsonb,
  add column if not exists ai_profile jsonb not null default '{}'::jsonb,
  add column if not exists activity_level text,
  add column if not exists birthday date;
