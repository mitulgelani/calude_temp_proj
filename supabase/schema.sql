-- Hookline database schema. Paste into Supabase → SQL Editor → Run. Safe to re-run.
create extension if not exists pgcrypto;

-- Profiles (one per auth user) -------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  full_name text,
  plan text not null default 'free' check (plan in ('free', 'creator', 'studio')),
  plan_renews_at timestamptz,
  created_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email, full_name)
  values (new.id, new.email, coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name'))
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- Connected Instagram accounts -------------------------------------------------
create table if not exists public.ig_accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  ig_user_id text not null unique,
  username text,
  name text,
  profile_picture_url text,
  access_token_enc text not null,          -- AES-256-GCM, never sent to the browser
  token_expires_at timestamptz,
  webhook_subscribed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Automations ------------------------------------------------------------------
create table if not exists public.automations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  ig_account_id uuid not null references public.ig_accounts (id) on delete cascade,
  name text not null,
  trigger text not null default 'comment' check (trigger in ('comment', 'dm')),
  media_id text,                            -- null = any post or Reel
  media_permalink text,
  media_thumbnail text,
  match_mode text not null default 'contains' check (match_mode in ('contains', 'exact', 'any')),
  keywords text[] not null default '{}',
  dm_message text not null,
  link_url text,
  follow_gate boolean not null default false,
  opener_message text,
  public_replies text[] not null default '{}',
  short_code text not null unique,
  is_active boolean not null default true,
  sent_count integer not null default 0,
  click_count integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists automations_account_idx on public.automations (ig_account_id, is_active, trigger);

-- Every matched comment / DM ---------------------------------------------------
create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  ig_account_id uuid not null references public.ig_accounts (id) on delete cascade,
  automation_id uuid references public.automations (id) on delete set null,
  kind text not null default 'comment' check (kind in ('comment', 'dm')),
  external_id text not null,                -- comment id or message id; dedupes webhook retries
  media_id text,
  from_id text,
  from_username text,
  recipient_id text,
  text text,
  status text not null default 'matched' check (status in ('matched', 'sent', 'failed', 'skipped', 'queued')),
  error text,
  sent_at timestamptz,
  created_at timestamptz not null default now(),
  unique (ig_account_id, external_id)
);
create index if not exists events_user_created_idx on public.events (user_id, created_at desc);
create index if not exists events_queue_idx on public.events (status, created_at) where status = 'queued';
create index if not exists events_account_sent_idx on public.events (ig_account_id, sent_at);

-- Follow-to-unlock conversations -------------------------------------------------
create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  ig_account_id uuid not null references public.ig_accounts (id) on delete cascade,
  automation_id uuid not null references public.automations (id) on delete cascade,
  igsid text not null,
  comment_id text,
  stage text not null default 'awaiting_reply' check (stage in ('awaiting_reply', 'awaiting_follow', 'done')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (ig_account_id, igsid, automation_id)
);

-- Contacts (everyone who received a DM) ------------------------------------------
create table if not exists public.contacts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  ig_account_id uuid not null references public.ig_accounts (id) on delete cascade,
  igsid text not null,
  username text,
  interactions integer not null default 1,
  first_seen_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  unique (ig_account_id, igsid)
);

-- Link clicks --------------------------------------------------------------------
create table if not exists public.clicks (
  id bigint generated always as identity primary key,
  automation_id uuid not null references public.automations (id) on delete cascade,
  created_at timestamptz not null default now()
);

-- Counters -----------------------------------------------------------------------
create or replace function public.increment_sent(a_id uuid)
returns void language sql security definer set search_path = public as $$
  update public.automations set sent_count = sent_count + 1 where id = a_id;
$$;

create or replace function public.register_click(code text)
returns text language plpgsql security definer set search_path = public as $$
declare target text; aid uuid;
begin
  select id, link_url into aid, target from public.automations where short_code = code;
  if aid is null then return null; end if;
  update public.automations set click_count = click_count + 1 where id = aid;
  insert into public.clicks (automation_id) values (aid);
  return target;
end $$;

revoke execute on function public.increment_sent(uuid) from public, anon, authenticated;
revoke execute on function public.register_click(text) from public, anon, authenticated;
revoke execute on function public.handle_new_user() from public, anon, authenticated;

-- Row level security: users only ever see their own rows ---------------------------
alter table public.profiles enable row level security;
alter table public.ig_accounts enable row level security;
alter table public.automations enable row level security;
alter table public.events enable row level security;
alter table public.conversations enable row level security;
alter table public.contacts enable row level security;
alter table public.clicks enable row level security;

drop policy if exists "own profile" on public.profiles;
create policy "own profile" on public.profiles for select using (auth.uid() = id);

drop policy if exists "own accounts read" on public.ig_accounts;
create policy "own accounts read" on public.ig_accounts for select using (auth.uid() = user_id);
drop policy if exists "own accounts delete" on public.ig_accounts;
create policy "own accounts delete" on public.ig_accounts for delete using (auth.uid() = user_id);

drop policy if exists "own automations" on public.automations;
create policy "own automations" on public.automations for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "own events" on public.events;
create policy "own events" on public.events for select using (auth.uid() = user_id);

drop policy if exists "own contacts" on public.contacts;
create policy "own contacts" on public.contacts for select using (auth.uid() = user_id);

drop policy if exists "own clicks" on public.clicks;
create policy "own clicks" on public.clicks for select
  using (exists (select 1 from public.automations a where a.id = automation_id and a.user_id = auth.uid()));
-- conversations: service role only (no policies = no access for users).

-- Never expose encrypted tokens to the browser, even to their owner.
revoke select on public.ig_accounts from anon, authenticated;
grant select (id, user_id, ig_user_id, username, name, profile_picture_url, token_expires_at, webhook_subscribed, created_at, updated_at)
  on public.ig_accounts to authenticated;
