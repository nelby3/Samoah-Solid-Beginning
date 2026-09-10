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
2. **Run the migrations** in the Supabase SQL editor, in order:
   [`0001_init.sql`](supabase/migrations/0001_init.sql) (schema, grants, RLS
   policies) then [`0002_reexposure_threshold.sql`](supabase/migrations/0002_reexposure_threshold.sql)
   (adds the re-exposure reminder setting).
3. **Configure the client:** copy your Project URL and `anon` key into
   [`config.js`](config.js). Both values are safe to commit — the anon key is
   public by design and every table is guarded by RLS.
   **Never add the `service_role` key to this repo.**
4. **Sign in once** from the app with each adult's email (magic link), so both
   users exist in `auth.users`.
5. **Seed the child + caregivers:** follow the commented steps at the bottom of
   `0001_init.sql` to insert one `children` row and link both adults.
6. **Enable GitHub Pages:** repo Settings → Pages → deploy from `main` / root.

## Editing recipes

Recipe ideas live in [`recipes-seed.json`](recipes-seed.json) and are **inlined
into `index.html`** so the app works offline (no `fetch`). After editing the
JSON, re-inline it:

```bash
python3 - <<'PY'
import pathlib, re
seed = pathlib.Path("recipes-seed.json").read_text().strip()
html = pathlib.Path("index.html").read_text()
html = re.sub(r"const RECIPE_SEED = \{.*?\n\};",
              "const RECIPE_SEED = " + seed + ";", html, count=1, flags=re.S)
pathlib.Path("index.html").write_text(html)
PY
```

## Security model

The anon key ships in public HTML, so row-level security *is* the access
control. Policies restrict every read and write to children the signed-in user
has a `caregivers` row for. See the verification checklist in `BUILD-PLAN.md`
before relying on it.

## Build status

- [x] **Phase 1 — Foundation:** schema, RLS, magic-link auth
- [x] **Phase 2 — Log and history:** log form, history list, edit/delete
- [x] **Phase 3 — Dashboard:** top-9 grid, per-allergen status, tap-to-filter
- [x] **Phase 4 — Re-exposure tracker:** overdue highlighting + strip, configurable threshold
- [x] **Phase 5 — Recipes:** per-allergen ideas (inlined, offline), "log this" prefill
- [ ] Phase 6 — Export
- [ ] Phase 7 — Polish

## Not in scope

No reintroduction schedule, "safe amounts," or medical guidance. The app records
what you enter and nothing more. The re-exposure threshold (Phase 4) is a
personal reminder you set, not a recommendation.
