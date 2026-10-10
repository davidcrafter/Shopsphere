# Administrator guide

## Secure first administrator

1. Apply migrations `001_initial.sql` then `002_dropshipping_commerce.sql`.
2. Enable Supabase Email authentication and create the user normally.
3. Assign `app_metadata.role = "admin"` using the Supabase dashboard or trusted server code.
4. Sign out/in to refresh the JWT. Never expose a browser field that assigns admin status.

## Dashboard

- Overview counts only `mode=live` orders and confirmed live revenue.
- Products supports manual create/edit/delete, images, variants, inventory, retail price, publication, supplier metadata, and cost/margin estimates.
- Categories supports create/edit/delete.
- Orders records legal fulfillment transitions, supplier references, costs, carrier, and tracking. Test orders are read-only for fulfillment.
- Customers is privacy-restricted and shows minimum account/order summary information.
- Suppliers supports authorized CSV draft import and documents the manual adapter.
- Marketing stores inactive discount drafts and reviews newsletter subscribers. Discounts are not applied until reviewed server checkout logic is added.
- Settings stores non-secret business values and standard shipping fees. Secrets never belong there.

## Profit figures

Estimated gross profit is retail price minus recorded product, supplier-shipping, and packaging costs. It is not net profit. Payment fees, advertising, taxes/duties, returns, refunds, and other operating expenses must be recorded and included before making net-profit decisions.

## Operational rules

Do not mark payment, supplier submission, shipment, delivery, cancellation, or refund complete without provider/supplier evidence. Do not paste secrets into product fields. Use least privilege, review RLS after every schema change, and limit access to customer addresses.
