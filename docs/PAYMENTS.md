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

## Live provider: Paypack (MTN MoMo + Airtel, RWF)

A live mobile-money integration using [Paypack](https://docs.paypack.rw) ships in this repository. Paypack collects RWF payments from a customer's MTN MoMo or Airtel Money number. RWF is zero-decimal, so `amount_minor` equals the RWF amount.

### Pieces
- `supabase/functions/_shared/payments/paypack.ts` — REST adapter: authenticate, cash-in (collect), transaction lookup, cash-out (refund), status normalization.
- `supabase/functions/create-momo-checkout` — authenticates the user, creates a server-priced `mode='live'` order via `server_prepare_live_checkout`, then triggers a Paypack cash-in and stores the transaction reference.
- `supabase/functions/momo-payment-status` — owner-polled, re-verifies the transaction directly against Paypack and finalizes the order. Authoritative; works even without a webhook.
- `supabase/functions/payment-webhook` — verifies an optional HMAC signature, stores the event id idempotently, then re-verifies against Paypack before finalizing. Deploy with `--no-verify-jwt`.
- `supabase/migrations/005_live_payments_paypack.sql` — `server_prepare_live_checkout`, `attach_live_payment_reference`, `finalize_live_payment`, `live_payment_reference`, `record_webhook_event`, `record_live_refund`.

### Setup
1. Create an application at https://payments.paypack.rw and copy its `client_id` and `client_secret`.
2. Apply the migration: paste `supabase/migrations/005_live_payments_paypack.sql` into the Supabase SQL Editor and run it (safe to run on an existing database).
3. Set Edge Function secrets (never `VITE_*`):
   ```bash
   supabase secrets set \
     PAYPACK_CLIENT_ID=xxxx \
     PAYPACK_CLIENT_SECRET=xxxx \
     PAYPACK_ENVIRONMENT=production \
     ALLOWED_ORIGIN=https://your-domain.example
   ```
   Use `PAYPACK_ENVIRONMENT=development` while testing against Paypack's sandbox/test mode.
4. Deploy the functions:
   ```bash
   supabase functions deploy create-momo-checkout
   supabase functions deploy momo-payment-status
   supabase functions deploy payment-webhook --no-verify-jwt
   ```
5. (Optional) Register the `payment-webhook` URL in your Paypack dashboard for faster confirmation. If you enable signed webhooks, also `supabase secrets set PAYPACK_WEBHOOK_SECRET=...`.
6. In the app environment set `VITE_ENABLE_MOMO_CHECKOUT=true` and redeploy the frontend.

### Testing
Place an order, choose **Mobile Money**, enter a test MoMo/Airtel number, and approve the prompt. The checkout page polls `momo-payment-status` until the payment settles. Confirmation never depends on a browser redirect.

### How the live-adapter requirements are met
1. Keys live only in Edge Function secrets. ✔
2. `mode='live'` orders are created by a server transaction before any charge. ✔
3. Webhook signature verified when a secret is configured; and regardless, every confirmation is re-verified server-side. ✔
4. `payment_webhook_events` stores processed event ids; `record_webhook_event` makes duplicates no-ops. ✔
5. `momo-payment-status` and `payment-webhook` both call Paypack `transactions/find/{ref}` and check status + amount before `finalize_live_payment`. ✔
6. `finalize_live_payment` is idempotent and settles the order/payment exactly once. ✔ (Inventory follows the existing admin-managed model; add automatic decrement later if desired.)
7. `record_live_refund` records provider-confirmed refunds and updates order/payment state. ✔
8. No card numbers, CVV, or MoMo PINs are ever collected or stored — the customer authorizes on their own phone. ✔
