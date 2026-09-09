// Supabase connection settings for the Allergen Tracker.
//
// These two values are safe to commit: the anon key is designed to be public
// and every table is protected by row-level security (see supabase/migrations).
// NEVER put the service_role key in this file or anywhere else in this repo.
//
// Fill these in from your Supabase project:
//   Project Settings -> API -> Project URL   and   Project API keys -> anon / public

window.APP_CONFIG = {
  SUPABASE_URL: "https://YOUR-PROJECT-REF.supabase.co",
  SUPABASE_ANON_KEY: "YOUR-ANON-KEY",
};
