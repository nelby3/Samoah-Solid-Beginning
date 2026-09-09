# Allergen Tracker — Build Plan

A private, two-person web app for tracking allergen introduction for one child. Static frontend on GitHub Pages, Supabase for data and auth.

---

## 1. Scope decisions

| Decision | Choice |
|---|---|
| Access model | Shared — two adult accounts, one child record |
| Allergen grid | Top 9 only |
| Other allergens | Free-text field on the log form; appear in history, not on the grid |
| Re-exposure tracker | Yes — flags allergens not served in N days (N user-configurable, default 7) |
| Export | Yes — CSV and a printable summary view |
| Recipes | Yes — 3 per top-9 allergen, seeded from `recipes-seed.json` |
| Symptom checklist | No — free-text notes only |
| Photos | No |
| Reintroduction schedule | Deliberately excluded — see §6 |

---

## 2. Stack

- **Frontend:** single `index.html`, vanilla JS, no build step. Tailwind via CDN.
- **Data + auth:** Supabase (Postgres, magic-link auth, row-level security)
- **Hosting:** GitHub Pages, served from `main` branch root
- **Client:** `@supabase/supabase-js@2` via jsDelivr CDN

Rationale for no build step: a single static file means no CI, no node_modules, and GitHub Pages serves it directly. The app is small enough that a framework buys nothing.

---

## 3. Data model

```sql
-- One child record; both parents link to it.
create table children (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  birth_date date,
  created_at timestamptz default now()
);

-- Maps auth users to the children they can see.
create table caregivers (
  user_id uuid references auth.users(id) on delete cascade,
  child_id uuid references children(id) on delete cascade,
  primary key (user_id, child_id)
);

-- Every exposure event.
create table introductions (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references children(id) on delete cascade,
  allergen text not null,          -- top-9 id, or free text for others
  is_top_nine boolean default true,
  served_on date not null,
  amount text,                     -- 'taste' | 'partial' | 'full'
  reaction text not null,          -- 'none' | 'mild' | 'moderate' | 'severe'
  notes text,
  recipe_used text,
  created_by uuid references auth.users(id),
  created_at timestamptz default now()
);

create index on introductions (child_id, served_on desc);
create index on introductions (child_id, allergen);
```

**RLS is mandatory.** The anon key ships in public HTML — without RLS the data is world-readable.

```sql
alter table children enable row level security;
alter table caregivers enable row level security;
alter table introductions enable row level security;

-- Read/write only for children you're a caregiver for.
create policy "caregiver access" on introductions
  for all using (
    child_id in (select child_id from caregivers where user_id = auth.uid())
  ) with check (
    child_id in (select child_id from caregivers where user_id = auth.uid())
  );

create policy "own children" on children
  for select using (
    id in (select child_id from caregivers where user_id = auth.uid())
  );

create policy "own caregiver rows" on caregivers
  for select using (user_id = auth.uid());
```

Recipes stay in a static JS file — no table needed, they never change per-user.

---

## 4. Build phases

Build and verify each phase before starting the next.

**Phase 1 — Foundation**
Supabase project, migrations above, RLS policies, magic-link auth. Manually insert one `children` row and two `caregivers` rows. Static `index.html` with login/logout and a "signed in as X" line. Deploy to Pages and confirm login works from the live URL.

**Phase 2 — Log and history**
Log form (allergen picker, date, amount, reaction, notes, recipe). Reverse-chronological history list. Edit and delete on each row. This phase alone makes the app usable.

**Phase 3 — Dashboard**
Grid of the top 9. Each tile: allergen name, status (never tried / introduced / reaction noted), exposure count, days since last serving. Tapping a tile filters history to that allergen.

**Phase 4 — Re-exposure tracker**
Highlight tiles where `days since last serving > threshold`. Settings control for the threshold. A "needs attention" strip at the top of the dashboard listing overdue allergens.

**Phase 5 — Recipes**
Load `recipes-seed.json` into a static JS constant. On each allergen tile, a "recipes" view showing the 3 options with prep steps. A "log this" button on a recipe prefills the log form with that allergen and recipe name.

**Phase 6 — Export**
CSV download of all introductions. A print-friendly summary page grouped by allergen with dates and reactions, for appointments.

**Phase 7 — Polish**
PWA manifest and icons so it installs to the home screen. Optimistic UI on writes so it feels instant on a phone. Empty states.

---

## 5. Verification checklist

- [ ] Open the live URL in a private window while logged out — no data visible, no console errors leaking rows
- [ ] Log in as account B, confirm you see entries created by account A
- [ ] Create a test Supabase user not in `caregivers` — confirm they see zero rows
- [ ] `service_role` key appears nowhere in the repo (`git log -S "service_role"`)
- [ ] Date entry works correctly across a timezone boundary (store dates as `date`, not `timestamptz`)
- [ ] Editing an entry updates the dashboard counts immediately

---

## 6. Excluded by design

The app does not encode reintroduction intervals, safe quantities, or guidance on which allergens to introduce when. Those are clinical decisions. The re-exposure threshold is a user-set reminder, not a recommendation — the default is a placeholder, and the settings screen should say so plainly.

---

# Claude Code prompt

Copy everything below into Claude Code, with `recipes-seed.json` in the project directory.

---

I'm building a private web app to track allergen introduction for my infant. Two users (me and my wife), one child. I want to host it on GitHub Pages as a static site with Supabase as the backend.

**Constraints — please follow these strictly:**

- Single `index.html` file, vanilla JavaScript, no build step and no npm. Tailwind via CDN, Supabase JS client via jsDelivr CDN.
- Only the Supabase **anon** key goes in the client. Never write the `service_role` key into any file in this repo.
- Because the anon key is public, **row-level security is not optional** — every table gets RLS enabled with policies before any UI is written. Treat this as a correctness requirement, not a hardening step.
- Store `served_on` as a Postgres `date`, not a timestamp, to avoid timezone drift on the day boundary.
- Do not build in any reintroduction schedule, "safe amount," or medical guidance. The app records what I enter and nothing more.

**Work in phases.** After each phase, stop, tell me what to verify manually, and wait for me to confirm before moving on. Do not build ahead.

**Phase 1 — Foundation.** Write the SQL migration (schema plus RLS policies) as a file I can paste into the Supabase SQL editor. Then build `index.html` with magic-link auth: login form, logout, and a line showing who's signed in. Nothing else yet.

**Phase 2 — Log and history.** Log form: allergen (dropdown of the top 9, plus an "other" option that reveals a text field), date served, amount (taste / partial serving / full serving), reaction (none / mild / moderate / severe), free-text notes. Below it, a reverse-chronological list of all entries with edit and delete.

**Phase 3 — Dashboard.** A grid of the top 9 allergens: peanut, egg, dairy, wheat, soy, tree nuts, fish, shellfish, sesame. Each tile shows status (never tried / introduced / reaction noted), number of exposures, and days since last serving. Tapping a tile filters the history list to that allergen. Non-top-9 allergens appear only in history, never on the grid.

**Phase 4 — Re-exposure tracker.** Highlight tiles where days-since-last-serving exceeds a threshold. Threshold is user-configurable in a settings panel, default 7. The settings panel must state that this is a personal reminder I set, not a recommendation from the app.

**Phase 5 — Recipes.** Load `recipes-seed.json` from the project root into a static JS constant (inline it into `index.html` — no fetch, since it must work offline). Each allergen tile gets a "recipes" view showing its options with prep steps and time. A "log this" button on a recipe opens the log form prefilled with that allergen and recipe name.

**Phase 6 — Export.** A CSV download of all entries, and a print-friendly summary grouped by allergen showing dates and reactions.

**Phase 7 — Polish.** PWA manifest and icons for home-screen install. Optimistic UI on writes. Sensible empty states.

**Design direction:** this gets used one-handed on a phone at 6am. Large tap targets, high contrast, minimal chrome. The dashboard is the landing screen; logging a new entry should be reachable in one tap from it.

Start with Phase 1. Ask me for my Supabase project URL and anon key when you need them.
