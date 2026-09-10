-- Phase: iron & zinc tracking
-- Run in the Supabase SQL editor after 0002.
--
-- "A serving of each, daily" is widely published complementary-feeding guidance
-- (CDC, WHO, AAP). The app shows that as cited context; the dashboard flag is a
-- reminder interval the caregivers set (nutrient_reminder_days, default 1).

create table if not exists nutrient_servings (
  id          uuid primary key default gen_random_uuid(),
  child_id    uuid not null references children(id) on delete cascade,
  nutrient    text not null check (nutrient in ('iron', 'zinc')),
  served_on   date not null,
  food        text,
  notes       text,
  created_by  uuid references auth.users(id),
  created_at  timestamptz not null default now()
);

create index if not exists nutrient_servings_lookup_idx
  on nutrient_servings (child_id, nutrient, served_on desc);

alter table children
  add column if not exists nutrient_reminder_days integer not null default 1;

-- API access (RLS below still does the row filtering).
grant select, insert, update, delete on public.nutrient_servings to authenticated;
grant update (nutrient_reminder_days) on public.children to authenticated;

alter table nutrient_servings enable row level security;

drop policy if exists "caregiver nutrient access" on nutrient_servings;
create policy "caregiver nutrient access" on nutrient_servings
  for all
  using      (child_id in (select child_id from caregivers where user_id = auth.uid()))
  with check (child_id in (select child_id from caregivers where user_id = auth.uid()));
