-- Password reset OTP codes (Mailtrap email flow)
-- Safe to re-run

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

-- Backend uses service_role; no public policies needed.
drop policy if exists "No public access to password resets" on public.password_resets;
