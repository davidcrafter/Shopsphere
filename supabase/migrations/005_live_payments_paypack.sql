-- 005_live_payments_paypack.sql
-- Live mobile-money checkout via Paypack (MTN MoMo + Airtel), RWF.
-- Safe to run on an existing database: every statement is create-or-replace.
-- Run this once in the Supabase SQL Editor after full_setup.sql.

-- ============================================================
-- Live checkout: authoritative, idempotent order creation.
-- Mirrors server_prepare_test_checkout but records mode='live'
-- and a pending Paypack payment row. Browser totals are ignored.
-- ============================================================
create or replace function public.server_prepare_live_checkout(
  p_user_id uuid,
  p_lines jsonb,
  p_address jsonb,
  p_shipping_rate_id uuid,
  p_discount_code text,
  p_idempotency_key uuid
) returns jsonb language plpgsql security definer set search_path = public as $$
declare v_order public.orders; v_subtotal bigint; v_shipping bigint; v_currency char(3); v_count integer; v_email text; v_fingerprint text; v_rate public.shipping_rates; v_discount public.discounts; v_discount_minor bigint := 0; v_eligible_subtotal bigint := 0; v_total bigint;
begin
  if p_user_id is null then raise exception 'Authentication required'; end if;
  if jsonb_typeof(p_lines) <> 'array' or jsonb_array_length(p_lines) = 0 or jsonb_array_length(p_lines) > 50 then raise exception 'Invalid cart'; end if;
  if jsonb_typeof(p_address) <> 'object' or length(coalesce(p_address->>'fullName','')) < 2 or length(coalesce(p_address->>'email','')) < 5 or length(coalesce(p_address->>'line1','')) < 3 or length(coalesce(p_address->>'city','')) < 2 or length(coalesce(p_address->>'region','')) < 2 or length(coalesce(p_address->>'countryCode','')) <> 2 then raise exception 'Complete delivery details required'; end if;
  v_fingerprint := encode(digest(p_lines::text || p_address::text || coalesce(p_shipping_rate_id::text,'') || coalesce(upper(trim(p_discount_code)),''), 'sha256'), 'hex');
  perform pg_advisory_xact_lock(hashtextextended(p_user_id::text || p_idempotency_key::text, 0));
  select * into v_order from public.orders where user_id = p_user_id and idempotency_key = p_idempotency_key;
  if found then
    if v_order.request_fingerprint <> v_fingerprint then raise exception 'Idempotency key reused with different checkout data'; end if;
    return jsonb_build_object('orderId', v_order.id, 'orderNumber', v_order.order_number, 'totalMinor', v_order.total_minor, 'currency', v_order.currency, 'discountMinor', v_order.discount_minor, 'shippingMinor', v_order.shipping_minor);
  end if;
  perform 1 from public.product_variants v where v.id in (select distinct (value->>'variantId')::uuid from jsonb_array_elements(p_lines)) for update;
  select count(distinct x.variant_id), sum(v.price_minor * x.quantity), min(v.currency) into v_count, v_subtotal, v_currency
  from (select (value->>'variantId')::uuid as variant_id, (value->>'quantity')::integer as quantity from jsonb_array_elements(p_lines)) x
  join public.product_variants v on v.id = x.variant_id join public.products p on p.id = v.product_id
  where x.quantity between 1 and 99 and v.available and p.published and p.status = 'active'
    and (not v.track_inventory or p.allow_backorders or p.preorder or (v.stock_quantity is not null and v.stock_quantity >= x.quantity));
  if v_count <> jsonb_array_length(p_lines) or v_subtotal is null then raise exception 'A product, price, or quantity is no longer available'; end if;
  if exists(select 1 from (select distinct v.currency from jsonb_array_elements(p_lines) j join public.product_variants v on v.id = (j.value->>'variantId')::uuid) currencies having count(*) > 1) then raise exception 'Mixed-currency checkout is not supported'; end if;
  if v_currency <> 'RWF' then raise exception 'Live mobile money payments support RWF only'; end if;
  select r.* into v_rate from public.shipping_rates r join public.shipping_zones z on z.id = r.zone_id
  where r.id = p_shipping_rate_id and r.active and z.active and r.currency = v_currency
    and (not exists(select 1 from public.shipping_zone_countries c where c.zone_id = z.id) or exists(select 1 from public.shipping_zone_countries c where c.zone_id = z.id and c.country_code = upper(p_address->>'countryCode')));
  if not found then raise exception 'Selected delivery method is unavailable for this address'; end if;
  v_shipping := case when v_rate.free_shipping_threshold_minor is not null and v_subtotal >= v_rate.free_shipping_threshold_minor then 0 else v_rate.fee_minor end;
  if nullif(trim(coalesce(p_discount_code,'')),'') is not null then
    select * into v_discount from public.discounts where lower(code) = lower(trim(p_discount_code)) and active and (starts_at is null or starts_at <= now()) and (ends_at is null or ends_at > now()) for update;
    if not found then raise exception 'Discount code is invalid or inactive'; end if;
    if v_discount.currency is not null and v_discount.currency <> v_currency then raise exception 'Discount currency does not match your cart'; end if;
    if v_subtotal < v_discount.minimum_minor then raise exception 'Cart does not meet the discount minimum'; end if;
    if v_discount.usage_limit is not null and v_discount.used_count >= v_discount.usage_limit then raise exception 'Discount usage limit reached'; end if;
    if v_discount.per_customer_limit is not null and (select count(*) from public.discount_redemptions dr where dr.discount_id = v_discount.id and dr.user_id = p_user_id and dr.mode = 'live') >= v_discount.per_customer_limit then raise exception 'Customer discount limit reached'; end if;
    if v_discount.applies_to = 'shipping' then
      v_eligible_subtotal := v_shipping;
    elsif v_discount.applies_to = 'product' then
      select coalesce(sum(v.price_minor * x.quantity), 0) into v_eligible_subtotal from (select (value->>'variantId')::uuid as variant_id, (value->>'quantity')::integer as quantity from jsonb_array_elements(p_lines)) x join public.product_variants v on v.id=x.variant_id join public.products p on p.id=v.product_id where p.id = any(v_discount.product_ids);
    elsif v_discount.applies_to = 'category' then
      select coalesce(sum(v.price_minor * x.quantity), 0) into v_eligible_subtotal from (select (value->>'variantId')::uuid as variant_id, (value->>'quantity')::integer as quantity from jsonb_array_elements(p_lines)) x join public.product_variants v on v.id=x.variant_id join public.products p on p.id=v.product_id where p.category_slug = any(v_discount.category_slugs);
    else
      v_eligible_subtotal := v_subtotal;
    end if;
    if v_eligible_subtotal <= 0 then raise exception 'Discount does not apply to this cart'; end if;
    if v_discount.kind = 'percentage' then v_discount_minor := (v_eligible_subtotal * v_discount.value) / 100; else v_discount_minor := v_discount.value; end if;
    if v_discount.max_discount_minor is not null then v_discount_minor := least(v_discount_minor, v_discount.max_discount_minor); end if;
    v_discount_minor := least(v_discount_minor, v_eligible_subtotal);
  end if;
  v_total := greatest(0, v_subtotal + v_shipping - v_discount_minor);
  v_email := lower(trim(p_address->>'email'));
  insert into public.orders(user_id, mode, customer_email, currency, subtotal_minor, shipping_minor, tax_minor, discount_minor, total_minor, shipping_address, shipping_method_code, idempotency_key, request_fingerprint, discount_code)
  values(p_user_id, 'live', v_email, v_currency, v_subtotal, v_shipping, 0, v_discount_minor, v_total, p_address, v_rate.code, p_idempotency_key, v_fingerprint, case when v_discount.id is null then null else v_discount.code end) returning * into v_order;
  insert into public.order_items(order_id, product_id, variant_id, product_name, variant_name, sku, image_url, quantity, unit_price_minor, line_total_minor)
  select v_order.id, p.id, v.id, p.name, v.name, v.sku, p.image_url, x.quantity, v.price_minor, v.price_minor * x.quantity
  from (select (value->>'variantId')::uuid as variant_id, (value->>'quantity')::integer as quantity from jsonb_array_elements(p_lines)) x join public.product_variants v on v.id = x.variant_id join public.products p on p.id = v.product_id;
  insert into public.order_item_costs(order_item_id, supplier_product_cost_minor, supplier_shipping_cost_minor, packaging_cost_minor)
  select oi.id, coalesce(pp.supplier_cost_minor,0), coalesce(pp.supplier_shipping_minor,0), coalesce(pp.packaging_cost_minor + pp.other_unit_cost_minor,0)
  from public.order_items oi left join public.product_private pp on pp.product_id = oi.product_id where oi.order_id = v_order.id;
  insert into public.order_shipping_quotes(order_id, shipping_rate_id, method_name, delivery_estimate, fee_minor, currency) values(v_order.id, v_rate.id, v_rate.name, concat_ws('–', v_rate.min_delivery_days::text, v_rate.max_delivery_days::text, 'business days'), v_shipping, v_currency);
  if v_discount.id is not null then insert into public.discount_redemptions(discount_id, order_id, user_id, code, amount_minor, mode) values(v_discount.id, v_order.id, p_user_id, v_discount.code, v_discount_minor, 'live'); end if;
  insert into public.payments(order_id, provider, mode, status, amount_minor, currency, idempotency_key) values(v_order.id, 'paypack', 'live', 'pending', v_order.total_minor, v_order.currency, gen_random_uuid());
  insert into public.order_status_history(order_id, status, changed_by, note) values(v_order.id, 'pending_payment', p_user_id, 'Order created by server-validated live checkout');
  insert into public.audit_events(actor_id, action, entity_type, entity_id, after_data) values(p_user_id, 'checkout_created', 'order', v_order.id::text, jsonb_build_object('mode','live','provider','paypack','total_minor',v_order.total_minor));
  return jsonb_build_object('orderId', v_order.id, 'orderNumber', v_order.order_number, 'totalMinor', v_order.total_minor, 'currency', v_order.currency, 'discountMinor', v_discount_minor, 'shippingMinor', v_shipping);
end$$;
revoke all on function public.server_prepare_live_checkout(uuid,jsonb,jsonb,uuid,text,uuid) from public;
grant execute on function public.server_prepare_live_checkout(uuid,jsonb,jsonb,uuid,text,uuid) to service_role;

-- ============================================================
-- Attach the Paypack transaction reference to the pending payment,
-- immediately after the cashin request is initiated.
-- ============================================================
create or replace function public.attach_live_payment_reference(p_order_id uuid, p_provider_payment_id text, p_metadata jsonb)
returns void language plpgsql security definer set search_path = public as $$
begin
  update public.payments
    set provider_payment_id = p_provider_payment_id,
        provider_metadata = provider_metadata || coalesce(p_metadata, '{}'::jsonb),
        updated_at = now()
    where order_id = p_order_id and provider = 'paypack' and status = 'pending';
end$$;
revoke all on function public.attach_live_payment_reference(uuid,text,jsonb) from public;
grant execute on function public.attach_live_payment_reference(uuid,text,jsonb) to service_role;

-- ============================================================
-- Finalize a live payment after Paypack confirmation (via webhook
-- or server-side verification). Idempotent and keyed by the Paypack
-- transaction reference. The caller MUST have already verified the
-- transaction status and amount directly against Paypack.
-- ============================================================
create or replace function public.finalize_live_payment(p_provider_payment_id text, p_outcome text, p_amount_minor bigint, p_metadata jsonb)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_payment public.payments; v_order public.orders;
begin
  if p_outcome not in ('succeeded','failed') then raise exception 'Invalid outcome'; end if;
  select * into v_payment from public.payments where provider = 'paypack' and provider_payment_id = p_provider_payment_id order by created_at desc limit 1 for update;
  if not found then raise exception 'Payment not found for reference'; end if;
  select * into v_order from public.orders where id = v_payment.order_id for update;
  if v_payment.status in ('succeeded','failed','refunded','cancelled') then
    return jsonb_build_object('status', v_payment.status, 'orderId', v_order.id, 'orderNumber', v_order.order_number, 'alreadyProcessed', true);
  end if;
  if p_outcome = 'succeeded' then
    if p_amount_minor is not null and p_amount_minor < v_payment.amount_minor then raise exception 'Confirmed amount is less than the order total'; end if;
    update public.payments set status = 'succeeded', provider_metadata = provider_metadata || coalesce(p_metadata, '{}'::jsonb), updated_at = now() where id = v_payment.id;
    update public.orders set payment_status = 'succeeded', status = 'paid', updated_at = now() where id = v_order.id;
    insert into public.order_status_history(order_id, status, changed_by, note) values(v_order.id, 'paid', v_order.user_id, 'Live payment confirmed by Paypack');
    insert into public.audit_events(actor_id, action, entity_type, entity_id, after_data) values(v_order.user_id, 'payment_succeeded', 'order', v_order.id::text, jsonb_build_object('mode','live','provider','paypack','amount_minor', v_payment.amount_minor));
    return jsonb_build_object('status', 'succeeded', 'orderId', v_order.id, 'orderNumber', v_order.order_number);
  else
    update public.payments set status = 'failed', provider_metadata = provider_metadata || coalesce(p_metadata, '{}'::jsonb), updated_at = now() where id = v_payment.id;
    update public.orders set payment_status = 'failed', updated_at = now() where id = v_order.id;
    insert into public.order_status_history(order_id, status, changed_by, note) values(v_order.id, 'pending_payment', v_order.user_id, 'Live payment failed at Paypack');
    insert into public.audit_events(actor_id, action, entity_type, entity_id, after_data) values(v_order.user_id, 'payment_failed', 'order', v_order.id::text, jsonb_build_object('mode','live','provider','paypack'));
    return jsonb_build_object('status', 'failed', 'orderId', v_order.id, 'orderNumber', v_order.order_number);
  end if;
end$$;
revoke all on function public.finalize_live_payment(text,text,bigint,jsonb) from public;
grant execute on function public.finalize_live_payment(text,text,bigint,jsonb) to service_role;

-- ============================================================
-- Look up the pending Paypack reference + expected amount for an
-- order the authenticated owner is polling. Used by the status
-- Edge Function to re-verify against Paypack. Owner-scoped.
-- ============================================================
create or replace function public.live_payment_reference(p_order_id uuid, p_user_id uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_order public.orders; v_payment public.payments;
begin
  select * into v_order from public.orders where id = p_order_id and user_id = p_user_id and mode = 'live';
  if not found then raise exception 'Order not found'; end if;
  select * into v_payment from public.payments where order_id = p_order_id and provider = 'paypack' order by created_at desc limit 1;
  if not found then raise exception 'Payment not found'; end if;
  return jsonb_build_object('ref', v_payment.provider_payment_id, 'status', v_payment.status, 'amountMinor', v_payment.amount_minor, 'orderNumber', v_order.order_number);
end$$;
revoke all on function public.live_payment_reference(uuid,uuid) from public;
grant execute on function public.live_payment_reference(uuid,uuid) to service_role;

-- ============================================================
-- Record a processed provider webhook event exactly once.
-- Returns true only the first time an (provider,event_id) is seen.
-- ============================================================
create or replace function public.record_webhook_event(p_provider text, p_event_id text, p_payload_hash text)
returns boolean language plpgsql security definer set search_path = public as $$
begin
  insert into public.payment_webhook_events(provider, event_id, payload_hash) values(p_provider, p_event_id, p_payload_hash);
  return true;
exception when unique_violation then
  return false;
end$$;
revoke all on function public.record_webhook_event(text,text,text) from public;
grant execute on function public.record_webhook_event(text,text,text) to service_role;

-- ============================================================
-- Record a provider-confirmed refund against a paid live order.
-- Called by the admin refund Edge Function after Paypack confirms
-- the cash-out. Idempotent per (order, provider_payment_id).
-- ============================================================
create or replace function public.record_live_refund(p_order_id uuid, p_amount_minor bigint, p_status text, p_reason text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_order public.orders; v_payment public.payments; v_total_refunded bigint;
begin
  if p_status not in ('pending','succeeded','failed') then raise exception 'Invalid refund status'; end if;
  select * into v_order from public.orders where id = p_order_id for update;
  if not found then raise exception 'Order not found'; end if;
  select * into v_payment from public.payments where order_id = p_order_id and provider = 'paypack' and status in ('succeeded','refunded') order by created_at desc limit 1;
  if not found then raise exception 'No settled payment to refund'; end if;
  if p_amount_minor <= 0 or p_amount_minor > v_payment.amount_minor then raise exception 'Invalid refund amount'; end if;
  insert into public.refunds(order_id, payment_id, amount_minor, status, reason) values(p_order_id, v_payment.id, p_amount_minor, p_status, nullif(trim(p_reason),''));
  if p_status = 'succeeded' then
    select coalesce(sum(amount_minor),0) into v_total_refunded from public.refunds where order_id = p_order_id and status = 'succeeded';
    update public.payments set status = 'refunded', updated_at = now() where id = v_payment.id and v_total_refunded >= v_payment.amount_minor;
    update public.orders set payment_status = case when v_total_refunded >= v_order.total_minor then 'refunded' else 'partially_refunded' end,
      status = case when v_total_refunded >= v_order.total_minor then 'refunded' else status end, updated_at = now() where id = p_order_id;
    insert into public.audit_events(actor_id, action, entity_type, entity_id, after_data) values(v_order.user_id, 'refund_recorded', 'order', p_order_id::text, jsonb_build_object('amount_minor', p_amount_minor));
  end if;
  return jsonb_build_object('status', p_status, 'orderId', p_order_id);
end$$;
revoke all on function public.record_live_refund(uuid,bigint,text,text) from public;
grant execute on function public.record_live_refund(uuid,bigint,text,text) to service_role;
