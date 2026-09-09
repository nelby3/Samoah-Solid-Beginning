-- Allergen Tracker — initial schema + row-level security
-- Paste this whole file into the Supabase SQL editor and run it once.
--
-- RLS is a correctness requirement here, not hardening: the anon key ships
-- in public HTML, so without these policies every row is world-readable.

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

-- One child record; both parents link to it via caregivers.
create table if not exists children (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  birth_date  date,
  created_at  timestamptz not null default now()
);

-- Maps auth users to the children they can see.
create table if not exists caregivers (
  user_id   uuid not null references auth.users(id) on delete cascade,
  child_id  uuid not null references children(id) on delete cascade,
  primary key (user_id, child_id)
);

-- Every exposure event.
create table if not exists introductions (
  id           uuid primary key default gen_random_uuid(),
  child_id     uuid not null references children(id) on delete cascade,
  allergen     text not null,                    -- top-9 id, or free text for "other"
  is_top_nine  boolean not null default true,
  served_on    date not null,                    -- date, NOT timestamptz: avoids day-boundary drift
  amount       text,                             -- 'taste' | 'partial' | 'full'
  reaction     text not null default 'none',     -- 'none' | 'mild' | 'moderate' | 'severe'
  notes        text,
  recipe_used  text,
  created_by   uuid references auth.users(id),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create index if not exists introductions_child_served_idx
  on introductions (child_id, served_on desc);
create index if not exists introductions_child_allergen_idx
  on introductions (child_id, allergen);

-- Keep updated_at fresh on edits.
create or replace function set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists introductions_set_updated_at on introductions;
create trigger introductions_set_updated_at
  before update on introductions
  for each row execute function set_updated_at();

-- ---------------------------------------------------------------------------
-- Row-level security
-- ---------------------------------------------------------------------------

alter table children      enable row level security;
alter table caregivers    enable row level security;
alter table introductions enable row level security;

-- Introductions: full read/write, but only for children you're a caregiver for.
drop policy if exists "caregiver access" on introductions;
create policy "caregiver access" on introductions
  for all
  using (
    child_id in (select child_id from caregivers where user_id = auth.uid())
  )
  with check (
    child_id in (select child_id from caregivers where user_id = auth.uid())
  );

-- Children: read only, and only your own.
drop policy if exists "own children" on children;
create policy "own children" on children
  for select
  using (
    id in (select child_id from caregivers where user_id = auth.uid())
  );

-- Caregivers: you can see your own mapping rows.
drop policy if exists "own caregiver rows" on caregivers;
create policy "own caregiver rows" on caregivers
  for select
  using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Seed the one child + link caregivers
-- ---------------------------------------------------------------------------
-- Run the steps below AFTER both adults have signed in once (magic link),
-- so their rows exist in auth.users.
--
--   1. Create the child:
--        insert into children (name, birth_date)
--        values ('CHILD NAME', 'YYYY-MM-DD')
--        returning id;
--
--   2. Find the adult user ids:
--        select id, email from auth.users;
--
--   3. Link both adults to the child (repeat for each user id):
--        insert into caregivers (user_id, child_id)
--        values ('USER-UUID', 'CHILD-UUID');
--
-- To verify RLS: create a third test user, do NOT add a caregivers row for
-- them, sign in as them, and confirm `select * from introductions` returns
-- zero rows.
