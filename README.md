# IBYIZAMART Dropshipping Store

IBYIZAMART is a React/TypeScript/Vite storefront with owned retail pricing, variants, persistent cart, Supabase customer accounts, server-priced test checkout, private order tracking, and an RLS-secured admin dashboard. It is no longer an affiliate website: there are no seller redirects or affiliate purchase links.

## Included

- Premium responsive homepage, seven categories, best sellers, new arrivals, configured deals, benefits, newsletter, and commerce footer
- Product variants, store retail prices, stock state, cart quantities and local guest cart persistence
- Authenticated server-priced checkout boundary with payload-bound idempotency
- Test-payment approval/decline flow isolated from live revenue, inventory, fulfillment, and supplier operations
- Customer registration/login/logout/reset, address book, order history, private order details, and tracking
- Admin overview, atomic product/variant/private-cost editing, image upload, categories, order fulfillment state machine, customers, supplier CSV imports, marketing, and settings
- Separate public catalog projection and private supplier cost tables
- Commerce database for variants, profiles, addresses, carts, orders/items, payments/refunds, shipments, suppliers, discounts, settings, and audit history
- Edge Function adapter contracts for payments and suppliers
- SEO metadata, product structured data for live products only, sitemap, robots rules, accessibility, and deployment files

## Run locally

Requires Node 20.19+ or 22.12+:

```bash
npm install
cp .env.example .env.local
npm run dev
```

Open `http://localhost:5173`. With no Supabase credentials, the design and demo catalog are viewable. Demo products cannot be added to a payable checkout.

## Enable the backend

1. Create a Supabase project.
2. Apply the migrations in `supabase/migrations` in order: `001_initial.sql`, `002_dropshipping_commerce.sql`, then `003_ibyizamart_rebrand.sql`.
3. Add `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` to `.env.local`.
4. Follow `supabase/README.md` and `docs/ADMIN.md`.
5. Create real products/variants in `/admin`; disable demo data in production with `VITE_ENABLE_DEMO_DATA=false`.
6. For test checkout only, follow `docs/PAYMENTS.md`. Do not enable the test finalizer in production.

## Brand configuration

The store name, slogan, and description are set in `src/config/site.ts`, and every page reads them from there. The page title shown before the app loads is in `index.html`. New order numbers use the `IBY-` prefix set in `supabase/migrations/003_ibyizamart_rebrand.sql`.

## Architecture

```text
src/components    reusable storefront, cart, account, and admin UI
src/providers     authentication, catalog, and persistent cart state
src/pages         public, customer, checkout, policy, and admin routes
src/services      Supabase, checkout, orders, admin, supplier adapters
supabase/migrations normalized commerce schema, RLS, views, atomic RPCs
supabase/functions trusted checkout/payment/supplier boundaries
docs               admin, payments, suppliers, and test procedures
```

All authoritative money uses integer minor units and an ISO currency code. The browser subtotal is advisory; `create_order_from_cart` reloads prices and availability and calculates the accepted total. Costs and supplier identities are absent from public views.

## Credentials and approvals still required

- Supabase project, public anon key, Auth/email configuration, and securely assigned administrator
- Production domain, support email, legal entity, policies, shipping zones/fees, tax strategy, and professional legal/tax review
- A payment provider proven to support your merchant country, settlement account, currencies, products, and customers; API/webhook secrets stay server-side
- AliExpress or another supplier account/API approval for automation; authorized product/image data and supplier credentials stay server-side
- Transactional email provider and optional CAPTCHA/rate limiting for public forms
- Optional Plausible domain for consented analytics

No live payment gateway or automated supplier API is claimed operational. The live webhook endpoint fails closed until a provider adapter is selected, implemented with official documentation, and verified in test mode.

## Documentation

- `docs/PAYMENTS.md` — test mode and live-provider requirements
- `docs/SUPPLIERS.md` — AliExpress CSV and adapter architecture
- `docs/ADMIN.md` — administrator setup and workflows
- `docs/TESTING.md` — completed checks and credential-dependent tests
- `supabase/README.md` — database/Auth/Edge Function setup

## Build and deploy

```bash
npm run typecheck
npm run lint
npm run build
npm run preview
```

Deploy `dist` to Netlify or Vercel using the included configuration. Set production environment variables in the host, update `example.com` in `public/robots.txt` and `public/sitemap.xml`, set Supabase Auth redirects, and deploy Edge Functions separately.

## Current verification limitation

The build workspace blocks npm registry downloads (HTTP 403), so dependency-based typecheck/lint/bundle and browser automation cannot be claimed here. Syntax, route, configuration, schema-boundary, and stale-affiliate checks are recorded in `docs/TESTING.md`. Run all package and Supabase integration checks in a network-enabled disposable environment before accepting live orders.
