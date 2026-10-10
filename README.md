# IBYIZAMART — Manual Dropshipping Store

IBYIZAMART is a React, TypeScript, Vite, Tailwind, Supabase ecommerce storefront for a **manual product catalog and manual supplier fulfillment workflow**. It is not an affiliate website and does not ingest products from any external catalog.

## What is included

- Premium responsive storefront with announcement bar, search suggestions, categories, collections, best sellers, promotions, blog, newsletter, and configurable homepage content.
- Manual product administration: variants, RWF-ready retail pricing, image galleries, private supplier/cost fields, stock settings, SEO, archive workflow, and profit/margin estimates.
- Private manual supplier records; no product import, scraping, synchronization, or automatic supplier-order submission.
- Guest-local and authenticated-synced carts, wishlists, coupon UI, server-priced test checkout, order confirmation, customer account, addresses, secure tracking, support requests, and verified-purchase review moderation.
- Protected admin areas for dashboard, analytics, products, categories, collections, inventory, orders, payments, returns, discounts, shipping, reviews, contacts, blog, homepage/policy content, suppliers, newsletter, and settings.
- Supabase migrations with RLS, public/private projections, manual-catalog enforcement, shipping zones/rates, discounts/redemptions, reviews, wishlists, support, content, inventory ledger, returns, notifications, and audit events.
- Edge Functions for checkout, test payment, support intake, and secure guest tracking. A live payment webhook intentionally fails closed until a provider is verified.

## Local setup

```bash
npm install
cp .env.example .env.local
npm run dev
```

Open `http://localhost:5173`. Without Supabase, the UI uses clearly labeled demo catalog records only. Demo records cannot be checked out or synced to a customer account.

## Backend setup

1. Create a Supabase project.
2. Apply migrations in order: `001_initial.sql`, `002_dropshipping_commerce.sql`, `003_ibyizamart_rebrand.sql`, `004_manual_store_operations.sql`.
3. Add `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` to `.env.local`.
4. Follow `supabase/README.md` to configure Auth, roles, storage, RLS tests, and Edge Functions.
5. Create all products manually through `/admin/products` and set `VITE_ENABLE_DEMO_DATA=false` in production.

## Current payment status

The application includes a secure **test-only** payment workflow for isolated non-production use. It never charges money, affects live revenue/profit, changes live inventory, or enters supplier fulfillment. No live provider is implemented or claimed operational. The operating currency is RWF; do not publish another currency until a reviewed conversion, delivery, checkout, and accounting implementation exists. Review `docs/PAYMENTS.md` before selecting a provider.

## Documentation

- `docs/ADMIN.md` — manual operating guide
- `docs/SUPPLIERS.md` — manual supplier and fulfillment policy
- `docs/PAYMENTS.md` — test/live provider boundary
- `docs/LAUNCH_CHECKLIST.md` — deployment and Rwanda launch checks
- `docs/BACKUP_RECOVERY.md` — backup/restore procedure
- `docs/TROUBLESHOOTING.md` — common setup failures
- `docs/TESTING.md` and `tests/README.md` — verification scope and required database/browser tests

## Test and build

```bash
npm run typecheck
npm run lint
npm test
npm run build
npm run preview
```

This hosted workspace may block npm registry downloads. Run the commands above in a network-enabled local or CI environment before launch. See `docs/LAUNCH_CHECKLIST.md` for the full production checklist.
