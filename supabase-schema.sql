-- ============================================================================
-- Linkflow — Supabase schema + RLS
-- One-paste script. Run once in Supabase SQL editor right after project create.
-- Idempotent: safe to re-run.
-- ============================================================================

-- 1. profiles table -----------------------------------------------------------
create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  email       text not null,
  created_at  timestamptz not null default now(),
  is_admin    boolean not null default false
);

-- 2. handle_new_user trigger: auto-create profile row on auth.users insert -----
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 3. is_admin() helper (avoids recursive RLS evaluation when used in policies) -
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((select is_admin from public.profiles where id = auth.uid()), false);
$$;

-- 4. Row-Level Security on profiles -------------------------------------------
alter table public.profiles enable row level security;

-- SELECT: a user sees their own row; admins see everyone.
drop policy if exists "profiles_select_self_or_admin" on public.profiles;
create policy "profiles_select_self_or_admin"
  on public.profiles
  for select
  using ( auth.uid() = id or public.is_admin() );

-- UPDATE: a user can update their own row but cannot flip is_admin on themselves.
-- Admins can update anyone, including is_admin.
drop policy if exists "profiles_update_self_no_role" on public.profiles;
create policy "profiles_update_self_no_role"
  on public.profiles
  for update
  using ( auth.uid() = id )
  with check ( auth.uid() = id and is_admin = (select is_admin from public.profiles where id = auth.uid()) );

drop policy if exists "profiles_update_admin" on public.profiles;
create policy "profiles_update_admin"
  on public.profiles
  for update
  using ( public.is_admin() )
  with check ( public.is_admin() );

-- INSERT: handled by the trigger above (security definer); no direct insert policy needed.
-- DELETE: no policy = denied. Deletes happen via auth.users cascade only.

-- 5. After first signup, run manually to seed Viktor as admin: ----------------
-- update public.profiles set is_admin = true where email = 'lowenherzviktor@gmail.com';
