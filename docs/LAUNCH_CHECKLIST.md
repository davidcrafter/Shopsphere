# IBYIZAMART launch checklist

## Infrastructure and security

- [ ] Configure a production domain and HTTPS.
- [ ] Set production `VITE_SITE_URL`, contact details, RWF default currency, and exact Supabase Auth redirects.
- [ ] Apply migrations through `004_manual_store_operations.sql` in staging first, then production.
- [ ] Provision the initial administrator securely and test anonymous/customer/admin RLS paths.
- [ ] Keep service-role, payment, email, and webhook secrets only in Edge Function secret storage.
- [ ] Deploy required Edge Functions: `create-checkout`, `test-payment` only in a non-production project, `create-contact-message`, and `track-order`.
- [ ] Disable demo data in production: `VITE_ENABLE_DEMO_DATA=false`.
- [ ] Add trusted edge/WAF rate limiting and bot protection for anonymous support and tracking endpoints; database rate buckets are only a second line of defense.
- [ ] Review storage object limits, MIME rules, public image rights, backup policy, monitoring, and error alerts.

## Store operations

- [ ] Create every product manually with owned/licensed imagery, descriptions, variants, stock policy, retail price, and accurate delivery estimate.
- [ ] Record private supplier/cost information and verify no private fields are visible in public catalog responses.
- [ ] Configure Rwanda delivery zones/rates and test destination matching.
- [ ] Keep the operating currency as RWF. Do not publish another currency until currency conversion, per-currency delivery, checkout, and accounting rules are designed and tested.
- [ ] Publish legally reviewed shipping, returns, privacy, and terms pages.
- [ ] Configure contact email, support workflow, and retention procedures.
- [ ] Create/publish FAQs, homepage content, collections, and blog posts.
- [ ] Test discount codes and shipping methods against server-side checkout rules.

## Payments, legal, and compliance

- [ ] Confirm Rwanda business registration, tax, consumer-protection, privacy, and import obligations with qualified professionals.
- [ ] Complete payment-provider eligibility/onboarding, settlement, currency, and webhook verification before enabling live payment.
- [ ] Configure email delivery and confirm order/status notification templates before claiming notifications are delivered.
- [ ] Do not deploy test payment functions or `ALLOW_TEST_CHECKOUT=true` in production.

## Verification

- [ ] Run `npm run typecheck`, `npm run lint`, `npm test`, and `npm run build` in a network-enabled environment.
- [ ] Test 320px, 375px, 430px, 768px, 1024px, and desktop layouts.
- [ ] Test product creation, image gallery, category, collection, cart, wishlist, coupon, checkout, support, review, tracking, order privacy, and admin authorization.
- [ ] Test anonymous, customer A, customer B, admin, and service-role data access separately.
