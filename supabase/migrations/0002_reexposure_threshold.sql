-- Phase 4 — re-exposure reminder threshold
-- Run this in the Supabase SQL editor after 0001_init.sql.
--
-- The threshold is a personal reminder the caregivers set. It is not medical
-- guidance and the app says so on the settings screen.

alter table children
  add column if not exists reexposure_threshold_days integer not null default 7;

-- Caregivers may update their own child row (currently just the threshold).
drop policy if exists "caregiver updates own child" on children;
create policy "caregiver updates own child" on children
  for update
  using      (id in (select child_id from caregivers where user_id = auth.uid()))
  with check (id in (select child_id from caregivers where user_id = auth.uid()));

-- Only the threshold column is writable through the API.
grant update (reexposure_threshold_days) on public.children to authenticated;
