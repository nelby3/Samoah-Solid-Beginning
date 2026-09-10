-- Multiple allergens per entry
-- Run in the Supabase SQL editor after 0002.
--
-- One introduction can now be tagged with several allergens (e.g. a food that
-- contains both egg and wheat). The old single `allergen` / `is_top_nine`
-- columns are kept but no longer used by the app.

alter table introductions add column if not exists allergens text[];

update introductions
set allergens = case
  when allergens is not null and array_length(allergens, 1) is not null then allergens
  when allergen is not null then array[allergen]
  else '{}'::text[]
end
where allergens is null or array_length(allergens, 1) is null;

alter table introductions alter column allergens set default '{}';
alter table introductions alter column allergens set not null;
alter table introductions alter column allergen drop not null;

-- Fast "entries tagged with allergen X" lookups.
create index if not exists introductions_allergens_gin on introductions using gin (allergens);
