# Samoah — Solid Beginning

A private, two-person web app for tracking allergen introduction for one child.
Static frontend on GitHub Pages, [Supabase](https://supabase.com) for data and auth.

Full design rationale and phase breakdown: [BUILD-PLAN.md](BUILD-PLAN.md).

## Stack

- **Frontend:** single `index.html`, vanilla JS, no build step. Tailwind + Supabase JS via CDN.
- **Data + auth:** Supabase (Postgres, magic-link auth, row-level security).
- **Hosting:** GitHub Pages from `main` branch root.

## Setup

1. **Create a Supabase project** at [supabase.com](https://supabase.com).
2. **Run the migration:** open the Supabase SQL editor, paste
   [`supabase/migrations/0001_init.sql`](supabase/migrations/0001_init.sql), run it once.
   This creates the schema **and** the row-level security policies.
3. **Configure the client:** copy your Project URL and `anon` key into
   [`config.js`](config.js). Both values are safe to commit — the anon key is
   public by design and every table is guarded by RLS.
   **Never add the `service_role` key to this repo.**
4. **Sign in once** from the app with each adult's email (magic link), so both
   users exist in `auth.users`.
5. **Seed the child + caregivers:** follow the commented steps at the bottom of
   `0001_init.sql` to insert one `children` row and link both adults.
6. **Enable GitHub Pages:** repo Settings → Pages → deploy from `main` / root.

## Security model

The anon key ships in public HTML, so row-level security *is* the access
control. Policies restrict every read and write to children the signed-in user
has a `caregivers` row for. See the verification checklist in `BUILD-PLAN.md`
before relying on it.

## Build status

- [x] **Phase 1 — Foundation:** schema, RLS, magic-link auth
- [ ] Phase 2 — Log and history
- [ ] Phase 3 — Dashboard
- [ ] Phase 4 — Re-exposure tracker
- [ ] Phase 5 — Recipes
- [ ] Phase 6 — Export
- [ ] Phase 7 — Polish

## Not in scope

No reintroduction schedule, "safe amounts," or medical guidance. The app records
what you enter and nothing more. The re-exposure threshold (Phase 4) is a
personal reminder you set, not a recommendation.
