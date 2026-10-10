# Supplier integration and fulfillment

The active supplier adapter is manual. It never claims to submit an order. Paid **live** orders can be reviewed by an administrator, purchased through an authorized supplier channel, then updated with a verified supplier reference, carrier, and tracking number.

## AliExpress import

`/admin/suppliers` accepts an exact nine-column CSV header:

```text
supplier_product_id,product_title,supplier_url,image_url,category,supplier_cost,shipping_cost,selling_price,sku
```

Imports require an authenticated admin, authorized HTTPS AliExpress product URL, HTTPS image, existing database category slug, bounded costs/prices, and SKU. Each row is atomically upserted by supplier name + external ID as an unpublished draft. Imported supplier cost and URL are stored in `product_private`, never public catalog views. Selling price is explicit and is not overwritten by supplier cost changes.

Review image/data rights, variants, specifications, safety/compliance, inventory, shipping, and pricing before publication. A partially completed batch reports the exact number committed; reruns update matching supplier identities.

## Automated adapter

Implement the server interface in `supabase/functions/_shared/suppliers/types.ts` only after supplier/API approval. Credentials belong in Edge Function secrets. An adapter must normalize quote, submit, cancel, status, and tracking results; use idempotency keys; preserve supplier responses for audit; retry safely; and fall back to manual action without reporting false success.

Before enabling supplier submission, enforce that the order is `mode=live`, payment is verified, shipping address is valid, the variant mapping is current, and no supplier order already exists. Test orders are never eligible.
