# Manual supplier and fulfillment workflow

IBYIZAMART is a **manual-catalog store**. Products are created only by an authorized administrator in `/admin/products`. The application contains no external catalog ingestion, product scraping, synchronization, or automatic supplier-order submission.

## Manual supplier records

Use `/admin/suppliers` to create private records for suppliers you have independently approved. Records may contain a contact name, business website, country, currency, payment terms, realistic processing/delivery notes, reliability notes, and internal notes.

Supplier records are private. Customers cannot read supplier names, contact details, costs, internal notes, supplier references, or operational history.

## Manual product entry

When adding a product, the administrator manually enters:

- product content, images, variants, SKU, stock, retail price, and publication state;
- optional private supplier name/reference/website;
- supplier product and shipping costs, packaging cost, other unit cost, and notes;
- delivery estimates, inventory/backorder settings, and SEO fields.

A supplier cost update does not overwrite the product selling price.

## Manual fulfillment

After a verified **live** payment (once a real payment provider is configured):

1. Review the customer order and confirmed payment state.
2. Purchase/arrange fulfillment through your supplier outside IBYIZAMART.
3. Record the supplier reference, actual fulfillment cost, carrier, and tracking evidence in the admin order screen.
4. Move the order through valid fulfillment states.
5. Update the customer only after a status or tracking detail is verified.

Test orders cannot enter fulfillment. The application never claims that a supplier has been contacted or an order has been submitted automatically.

## Data and operational review

Before publishing a product, verify product safety/compliance, imagery rights, descriptions, variant identity, stock policy, realistic delivery estimates, customer return eligibility, and pricing. Retain supplier/order evidence according to your accounting and legal obligations.
