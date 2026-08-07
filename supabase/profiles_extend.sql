-- Run in Supabase SQL Editor (safe to re-run)
-- Extends profiles for Initial Profile Setup + onboarding

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
  add column if not exists profile_setup_completed boolean not null default false;

-- Keep updated_at fresh
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

-- Ensure delete policy for account deletion cleanup (auth cascade already handles row)
drop policy if exists "Users can delete own profile" on public.profiles;
create policy "Users can delete own profile"
  on public.profiles
  for delete
  using (auth.uid() = id);
