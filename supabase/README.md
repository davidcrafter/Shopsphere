# Supabase commerce setup

1. Create a project and apply `migrations/001_initial.sql`, then `migrations/002_dropshipping_commerce.sql`.
2. Configure frontend project URL and anon/publishable key. Never use the service-role key in Vite.
3. Enable Email authentication and add `/account` and `/reset-password` production URLs to Auth redirects.
4. Assign the first administrator through trusted Supabase controls using `app_metadata.role=admin`.
5. Deploy `create-checkout` and `test-payment` only to a non-production/test project while test mode is enabled.
6. Set `ALLOWED_ORIGIN` to the exact frontend origin. Keep `ALLOW_TEST_CHECKOUT=false` in production.
7. Review every RLS policy and execute `docs/TESTING.md` with anonymous, two customer, admin, and service-role contexts.

The public catalog reads `storefront_products`; supplier costs are in `product_private`. Customer orders are filtered by `auth.uid()`. Test data is mode-isolated. Live payment and automated supplier adapters are intentionally fail-closed until provider credentials and official integration requirements are supplied.
