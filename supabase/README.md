# Supabase setup

1. Create a Supabase project and apply `migrations/001_initial.sql` in the SQL editor or with `supabase db push`.
2. Copy the project URL and **anon/publishable** key to `.env.local`. Never use the service-role key in Vite.
3. Enable Email OTP authentication and add your production `/admin/import` URL to Auth redirect URLs.
4. Create the administrator in Supabase Auth. Set `app_metadata.role` to `admin` from the Supabase dashboard or a secure server-side process. Never let a browser assign its own role.
5. Test all RLS policies with anon and admin accounts before launch.

The importer accepts approved AliExpress affiliate portal CSV/JSON exports and creates unpublished drafts. It does not scrape AliExpress or call undocumented APIs. Prices are intentionally not published from the import; verify current data and set `price_verified_at` before displaying it.

For production newsletters, add CAPTCHA/rate limiting through an Edge Function and configure a confirmed opt-in email provider for the jurisdictions you serve.
