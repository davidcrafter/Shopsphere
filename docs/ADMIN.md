# Administrator guide

## Provision the first administrator

1. Apply migrations in order: `001_initial.sql`, `002_dropshipping_commerce.sql`, `003_ibyizamart_rebrand.sql`, and `004_manual_store_operations.sql`.
2. Enable Supabase Email authentication and create the user normally.
3. Assign `app_metadata.role = "admin"` with the Supabase dashboard or trusted server-side tooling.
4. Sign out and sign in again so the browser receives a fresh JWT.
5. Never provide a public browser form that grants an administrator role.

## Manual store operations

- **Products:** Create all products manually, upload/reorder images, define variants, prices, stock, private costs, SEO, and publication state.
- **Categories and collections:** Build customer navigation and curated collections manually.
- **Inventory:** Adjust tracked stock through the Inventory screen; every adjustment is written to the private movement ledger.
- **Suppliers:** Keep private manual supplier records only. Do not import products or place supplier orders automatically.
- **Orders:** Record verified fulfillment references, carriers, and tracking only after evidence is available. Test orders are never eligible for fulfillment.
- **Discounts:** Create codes here; server checkout validates date, currency, amount, total-use, and customer-use limits. Test usage does not consume live redemption limits.
- **Reviews:** Approve, reject, or hide eligible customer reviews before they become public.
- **Content:** Edit announcement/hero/promo content, FAQs, published policy content, and blog posts.
- **Support:** Review customer contact messages and record private notes/status.

## Financial definitions

Estimated gross profit is the selling price minus recorded supplier product cost, supplier shipping, packaging, and other unit cost. It is not net profit. Payment fees, advertising, taxes, duties, returns, refunds, and unrecorded expenses must be considered separately.

Dashboard financial cards use confirmed `mode=live` payment data only. Test orders and browser analytics never become financial facts.

## Sensitive operations

- Do not mark a payment successful without verified provider evidence.
- Do not report a supplier purchase, shipment, delivery, cancellation, or refund before it is verified.
- Keep customer addresses, supplier details, cost data, and support notes private.
- Review audit events and low-stock alerts regularly.
- Test each new shipping rate, discount, and policy before publishing.
