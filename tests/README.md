# Test suites

Run zero-dependency source/unit checks after installing project dependencies:

```bash
npm test
```

The included unit tests cover currency minor-unit handling and static security/manual-catalog contract assertions. They do **not** replace database integration tests.

Before launch, apply migrations to an isolated Supabase project and add/run tests for:

- anonymous, customer A, customer B, admin, and service-role RLS isolation;
- checkout coupon, shipping-rate, and idempotency behavior;
- test/live payment separation and signed live-provider webhooks;
- stock reservation/finalization once a live provider is configured;
- customer review eligibility and moderation;
- contact-message and tracking endpoint rate limits;
- manual supplier and archival workflows;
- browser checkout, wishlist, account, and admin route behavior.
