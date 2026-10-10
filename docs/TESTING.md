# Commerce test plan

## Automated/static checks completed in the build workspace

- TypeScript/TSX syntax transpilation passed for all 66 frontend source files.
- Required 24-route inventory passed.
- Six catalog/money behavior checks passed.
- Eleven sitemap/configuration and commerce trust-boundary assertions passed.

## Integration checks required with your Supabase project

These cannot be truthfully marked passed without applying the migrations and configuring test credentials:

1. Anonymous user cannot read profiles, addresses, orders, payments, supplier data, or costs.
2. Customer A cannot read Customer B's order, address, shipment, history, or payment status.
3. Customer cannot call admin product or fulfillment RPCs.
4. Admin can create a draft product, stable variants, private costs, upload an image, edit without replacing variant IDs, publish, and unpublish.
5. Duplicate supplier external ID updates one draft rather than creating duplicates.
6. Browser-submitted prices/totals are ignored by checkout.
7. Replayed identical checkout attempt returns the same order.
8. Test approval and decline are idempotent; neither affects live metrics, supplier queue, or inventory.
9. Test order cannot enter `admin_update_fulfillment`.
10. Live provider webhook signature and duplicate event handling pass provider test vectors after an adapter is implemented.
11. Password recovery sets a new password; expired/reused links fail safely.
12. Cart quantity/variant, search/filter/sort, checkout validation, mobile navigation, all routes, and keyboard focus are tested in Chrome/Safari/Firefox.

Run frontend checks with `npm run typecheck`, `npm run lint`, and `npm run build`. Run migrations against a disposable Supabase project before production.
