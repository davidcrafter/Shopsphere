# Payment configuration

ShopSphere ships with a **test-only adapter**, not a live payment gateway. Test orders are permanently marked `mode=test`, excluded from revenue/profit/fulfillment, do not decrement inventory, and cannot be submitted to suppliers.

## Enable test checkout

Use a non-production Supabase project:

```bash
supabase secrets set ALLOW_TEST_CHECKOUT=true ALLOWED_ORIGIN=http://localhost:5173
supabase functions deploy create-checkout
supabase functions deploy test-payment
```

Set `VITE_ENABLE_TEST_CHECKOUT=true` in local frontend configuration. Customers must authenticate. The server reloads active variants/prices, validates quantities/stock and shipping, ignores browser totals, and creates an idempotent test order. The UI can simulate approval or decline. No money moves.

## Add a live provider

Choose a provider only after confirming support for the merchant country, legal entity, settlement account, currencies, products, and customers. Implement `supabase/functions/_shared/payments/types.ts` server-side. A live implementation must:

1. Keep API and webhook secrets in Supabase Edge Function secrets—never `VITE_*`.
2. Recalculate all prices, discounts, tax, and shipping server-side.
3. Create immutable `mode=live` orders and payments.
4. Verify signed webhooks using the provider's current official SDK/documentation.
5. Insert each provider event ID into `payment_webhook_events`; duplicate IDs must return success without reprocessing.
6. Move an order to paid only from a verified event, never a browser redirect.
7. Implement inventory reservations with expiry/release for live payment sessions.
8. Implement provider-confirmed refund state transitions and reconciliation.
9. Never store raw card numbers, CVV, mobile-money PINs, or bank credentials.

`payment-webhook` currently fails closed with HTTP 501. This is intentional until a real provider is selected and tested.
