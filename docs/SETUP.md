# Setup: log in as admin and control the dashboard

The admin dashboard needs a Supabase backend. In demo mode (no Supabase) you
cannot log in and the dashboard has no data. Follow these six steps once.

## 1. Create a Supabase project
Go to https://supabase.com → **New project**. When it's ready, open
**Project Settings → API** and copy:
- **Project URL**
- **anon public** key

## 2. Point the app at it
Edit `.env.local` and fill in the two values:

```
VITE_SUPABASE_URL=https://xxxxxxxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOi...your-anon-key...
```

Once set, demo products disappear and the app uses your real database.

## 3. Create the database (one paste)
In the Supabase dashboard → **SQL Editor** → **New query**, paste the entire
contents of [`supabase/full_setup.sql`](../supabase/full_setup.sql) and click
**Run**. (This is migrations 001–004 combined, already in the correct order.)

## 4. Create your user
- Supabase dashboard → **Authentication → Providers** → make sure **Email** is enabled.
- Run the app (`npm run dev`) and register at `http://localhost:5173/register`
  with your email + password.

## 5. Grant yourself the admin role (the key step)
Admin is controlled by `app_metadata.role = "admin"` in your login token.
In the Supabase **SQL Editor**, run this once (use your email):

```sql
update auth.users
set raw_app_meta_data = raw_app_meta_data || '{"role":"admin"}'::jsonb
where email = 'you@example.com';
```

## 6. Refresh your session, then open the dashboard
- **Sign out and sign back in** (required — your browser needs a fresh token
  containing the new role).
- Go to **`http://localhost:5173/admin`**.

You now control everything: products, categories, collections, inventory,
orders, discounts, reviews, suppliers, shipping, content/blog, contact
messages, analytics, and settings.

### Notes
- Visiting `/admin` without the role redirects you to `/account` — that's the
  access guard working, not a bug.
- The role is also enforced in the database by the `is_admin()` function behind
  every admin table, so it is safe.
