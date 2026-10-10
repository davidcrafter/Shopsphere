# Payment configuration

IBYIZAMART ships with a **test-only** checkout path, not a live payment gateway. Test orders are permanently `mode=test`, excluded from live revenue/profit, cannot enter supplier fulfillment, and do not change live inventory.

## Isolated test checkout

Use a non-production Supabase project only:

```bash
supabase secrets set ALLOW_TEST_CHECKOUT=true ALLOWED_ORIGIN=http://localhost:5173
supabase functions deploy create-checkout
supabase functions deploy test-payment
```

Set `VITE_ENABLE_TEST_CHECKOUT=true` locally. The server validates account identity, cart lines, active products, variants, server prices, stock policy, selected shipping rate, coupon eligibility, address fields, and idempotency before it creates a test order. Browser totals are never authoritative.

## Live provider integration

No live payment provider is operational in this repository. `payment-webhook` fails closed until a provider is chosen, approved, implemented, and tested. Flutterwave or any other provider must be confirmed to support the business entity, Rwanda settlement account, intended currencies, payment methods, and customer markets before implementation.

A live adapter must:

1. Keep keys/webhook secrets only in Supabase Edge Function secrets—never `VITE_*` or a browser response.
2. Create `mode=live` payment attempts after a server-side quote/order transaction.
3. Verify raw signed webhook requests before parsing or updating an order.
4. Store provider event IDs in `payment_webhook_events` and make duplicate events idempotent.
5. Verify provider transaction reference, order association, currency, and amount before payment success.
6. Reserve/commit/release inventory exactly once through a live-payment state machine.
7. Record provider-confirmed refunds and reconciliation information.
8. Never store raw card numbers, CVV, mobile-money PINs, or bank credentials.

Do not activate a provider based only on a browser redirect. A provider webhook or server-side provider verification is required before marking a live order paid.
