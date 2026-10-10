-- IBYIZAMART rebrand: new orders receive the IBY- order-number prefix.
-- Existing order numbers are intentionally left unchanged.
alter table public.orders
  alter column order_number set default ('IBY-' || to_char(now(), 'YYYYMMDD') || '-' || nextval('public.order_number_seq'));
