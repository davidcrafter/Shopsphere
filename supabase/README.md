# Supabase setup

1. Create separate development/staging/production Supabase projects. Do not mix test and live payment data.
2. Apply migrations in order: `001_initial.sql`, `002_dropshipping_commerce.sql`, `003_ibyizamart_rebrand.sql`, then `004_manual_store_operations.sql`.
3. Configure browser-safe `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`; never expose `SUPABASE_SERVICE_ROLE_KEY`.
4. Enable Email Auth and add `/account`, `/reset-password`, `/verify-email`, and production origins to allowed redirect URLs.
5. Provision administrator roles through trusted Supabase controls, never a public registration flow.
6. Create manual products, shipping zones/rates, content, and policies in the protected admin routes.
7. Deploy public support/tracking functions with `ALLOWED_ORIGIN` configured exactly. Deploy test checkout only to an isolated non-production project.
8. Test RLS across anonymous, two customer, admin, and service-role contexts before launch.

The public storefront uses narrow views such as `storefront_products`; supplier costs, internal notes, payment metadata, audit entries, and private support content are excluded. Products are manual-only: no external catalog ingestion, scraping, synchronization, or automated supplier ordering feature is present.
