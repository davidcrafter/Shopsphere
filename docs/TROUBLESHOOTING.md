# Troubleshooting

## The storefront shows no products

Confirm `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`, apply all migrations, and ensure products are `published=true`, `status=active`, and have at least one available variant. Demo products appear only when Supabase is not configured and demo data is enabled.

## Checkout says no delivery method is available

Create an active shipping zone, map the destination country code, create an active rate in the cart currency, and select the rate at checkout. Shipping is calculated server-side.

## I cannot access /admin

Confirm the authenticated user has `app_metadata.role = "admin"` or an active `user_roles` admin record. Sign out/in to refresh the JWT. Route protection is not a substitute for database RLS.

## Contact/tracking says unavailable

Deploy `create-contact-message` and `track-order`, configure `ALLOWED_ORIGIN`, apply migration 004, and check Edge Function logs. Rate limits deliberately reject repeated requests.

## Payment is unavailable

This is expected unless a verified provider is configured. Test checkout belongs only in a separate non-production Supabase project with `ALLOW_TEST_CHECKOUT=true`.

## npm install/build fails in the hosted workspace

This environment may block npm registry access. Run the commands in a network-enabled development or CI environment, then resolve all dependency, lint, type, test, and build failures before launch.
