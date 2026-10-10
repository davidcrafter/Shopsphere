# Commerce test plan

## Automated source/unit checks included

- `npm test` uses Node's test runner to verify RWF minor-unit behavior and manual-store source/security contract assertions.
- TypeScript syntax, route inventory, migration, and no-import scans are also run during agent validation when dependencies are unavailable.

## Required integration tests in a disposable Supabase project

1. Anonymous users cannot read private products, supplier costs, customer records, support messages, payments, audit events, or other customers' orders.
2. Customer A cannot access Customer B addresses, wishlists, orders, return requests, contact messages, or review drafts.
3. Admin product creation persists manual source, images, variants, cost data, SEO fields, and archive state without rewriting historical order snapshots.
4. Wishlist local state merges correctly after sign-in without inserting demo/non-UUID records.
5. Coupon/zone shipping eligibility is validated server-side; browser totals and coupon discounts are ignored.
6. Identical idempotent checkout retries return the same order; changed payloads with the same key are rejected.
7. Test payment approval/decline is idempotent and cannot affect live metrics, inventory, or fulfillment.
8. Manual inventory adjustment cannot produce negative stock; the movement ledger has an authorized actor and reason.
9. Contact and tracking functions enforce validation/rate limits and do not disclose customer details to incorrect email/order combinations.
10. Reviews require an eligible delivered purchase and only approved reviews appear publicly.
11. Category/collection/content/blog/FAQ publishing hides drafts from public views.
12. Manual fulfillment, return, refund, and audit state transitions are reviewed against store policy.
13. All customer/admin responsive routes are tested in Chrome at 320px, 375px, 430px, 768px, 1024px, and desktop widths.

No production launch is complete until database RLS, Edge Function, live payment webhook, test/browser, lint, type, and build checks pass in a configured environment.
