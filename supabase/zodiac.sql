-- Zodiac sign for Daily Cosmic Check-in (run in Supabase SQL Editor)
alter table public.profiles
  add column if not exists zodiac_sign text;
