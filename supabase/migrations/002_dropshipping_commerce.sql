-- IBYIZAMART commerce conversion. Apply after 001_initial.sql.
-- Money is stored as integer minor units; private costs never appear in public views.

alter table public.products add column if not exists sku text unique;
alter table public.products add column if not exists status text not null default 'draft' check(status in('draft','active','archived'));
alter table public.products add column if not exists best_seller boolean not null default false;
alter table public.products add column if not exists promotion boolean not null default false;
alter table public.products add column if not exists processing_estimate text;
alter table public.products add column if not exists delivery_estimate text;

create table public.product_variants(
 id uuid primary key default gen_random_uuid(), product_id uuid not null references public.products(id) on delete cascade,
 name text not null default 'Standard', sku text not null unique, option_values jsonb not null default '{}',
 price_minor bigint not null check(price_minor>=0), compare_at_minor bigint check(compare_at_minor is null or compare_at_minor>price_minor),
 currency char(3) not null default 'USD' check(currency in('USD','EUR','GBP','CAD','AUD')),
 stock_quantity integer check(stock_quantity is null or stock_quantity>=0), track_inventory boolean not null default true,
 available boolean not null default true, weight_grams integer check(weight_grams is null or weight_grams>=0),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index product_variants_product_idx on public.product_variants(product_id);

create table public.product_images(
 id uuid primary key default gen_random_uuid(), product_id uuid not null references public.products(id) on delete cascade,
 src text not null check(src~'^https://'), alt text not null default '', position integer not null default 0
);

create table public.product_private(
 product_id uuid primary key references public.products(id) on delete cascade,
 supplier_name text, supplier_product_url text, supplier_external_id text,
 supplier_cost_minor bigint not null default 0 check(supplier_cost_minor>=0), supplier_shipping_minor bigint not null default 0 check(supplier_shipping_minor>=0),
 packaging_cost_minor bigint not null default 0 check(packaging_cost_minor>=0), payment_fee_minor bigint not null default 0 check(payment_fee_minor>=0),
 advertising_cost_minor bigint not null default 0 check(advertising_cost_minor>=0), tax_duty_minor bigint not null default 0 check(tax_duty_minor>=0),
 updated_at timestamptz not null default now()
);

create table public.profiles(
 id uuid primary key references auth.users(id) on delete cascade, full_name text, phone text,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.addresses(
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
 label text not null default 'Shipping', full_name text not null, phone text, line1 text not null, line2 text, city text not null,
 region text not null, postal_code text not null, country_code char(2) not null, is_default boolean not null default false,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index addresses_user_idx on public.addresses(user_id);

create table public.carts(id uuid primary key default gen_random_uuid(),user_id uuid unique references auth.users(id) on delete cascade,created_at timestamptz not null default now(),updated_at timestamptz not null default now());
create table public.cart_items(id uuid primary key default gen_random_uuid(),cart_id uuid not null references public.carts(id) on delete cascade,variant_id uuid not null references public.product_variants(id) on delete cascade,quantity integer not null check(quantity between 1 and 99),unique(cart_id,variant_id));

create table public.shipping_methods(
 id uuid primary key default gen_random_uuid(), code text not null unique, name text not null, country_code char(2),
 fee_minor bigint not null check(fee_minor>=0), currency char(3) not null default 'USD', active boolean not null default true,
 min_delivery_days integer, max_delivery_days integer, created_at timestamptz not null default now()
);
insert into public.shipping_methods(code,name,fee_minor,currency,active,min_delivery_days,max_delivery_days) values('standard','Standard shipping',500,'USD',true,null,null) on conflict(code) do nothing;

create table public.discounts(
 id uuid primary key default gen_random_uuid(),code text not null unique,kind text not null check(kind in('fixed','percentage')),
 value integer not null check(value>0),currency char(3),minimum_minor bigint not null default 0,starts_at timestamptz,ends_at timestamptz,
 usage_limit integer,used_count integer not null default 0,active boolean not null default false,created_at timestamptz not null default now()
);

create sequence if not exists public.order_number_seq start 1001;
create table public.orders(
 id uuid primary key default gen_random_uuid(),order_number text not null unique default('SS-'||to_char(now(),'YYYYMMDD')||'-'||nextval('public.order_number_seq')),
 user_id uuid not null references auth.users(id),mode text not null default 'live' check(mode in('test','live')),customer_email text not null,status text not null default 'pending_payment' check(status in('pending_payment','paid','awaiting_supplier_order','supplier_order_placed','processing','shipped','delivered','cancelled','refund_pending','refunded')),
 payment_status text not null default 'pending' check(payment_status in('pending','succeeded','failed','cancelled','partially_refunded','refunded')),
 currency char(3) not null,subtotal_minor bigint not null check(subtotal_minor>=0),shipping_minor bigint not null check(shipping_minor>=0),tax_minor bigint not null check(tax_minor>=0),discount_minor bigint not null check(discount_minor>=0),total_minor bigint not null check(total_minor>=0),
 shipping_address jsonb not null,shipping_method_code text not null,idempotency_key uuid not null,request_fingerprint text not null,notes text,
 created_at timestamptz not null default now(),updated_at timestamptz not null default now(),unique(user_id,idempotency_key)
);
create index orders_user_created_idx on public.orders(user_id,created_at desc);create index orders_status_idx on public.orders(status,created_at desc);
create table public.order_items(
 id uuid primary key default gen_random_uuid(),order_id uuid not null references public.orders(id) on delete cascade,product_id uuid references public.products(id) on delete set null,variant_id uuid references public.product_variants(id) on delete set null,
 product_name text not null,variant_name text not null,sku text not null,image_url text,quantity integer not null check(quantity>0),unit_price_minor bigint not null check(unit_price_minor>=0),line_total_minor bigint not null check(line_total_minor>=0)
);
create index order_items_order_idx on public.order_items(order_id);
create table public.order_item_costs(order_item_id uuid primary key references public.order_items(id) on delete cascade,supplier_product_cost_minor bigint not null default 0,supplier_shipping_cost_minor bigint not null default 0,packaging_cost_minor bigint not null default 0);
create table public.payments(
 id uuid primary key default gen_random_uuid(),order_id uuid not null references public.orders(id) on delete cascade,provider text not null,mode text not null default 'live' check(mode in('test','live')),provider_payment_id text,status text not null check(status in('pending','succeeded','failed','cancelled','refunded')),amount_minor bigint not null,currency char(3) not null,idempotency_key uuid not null unique,provider_metadata jsonb not null default '{}',created_at timestamptz not null default now(),updated_at timestamptz not null default now()
);
create table public.payment_webhook_events(provider text not null,event_id text not null,payload_hash text not null,processed_at timestamptz not null default now(),primary key(provider,event_id));
create table public.refunds(id uuid primary key default gen_random_uuid(),order_id uuid not null references public.orders(id),payment_id uuid references public.payments(id),amount_minor bigint not null check(amount_minor>0),status text not null check(status in('pending','succeeded','failed')),reason text,created_at timestamptz not null default now());

create table public.shipments(id uuid primary key default gen_random_uuid(),order_id uuid not null unique references public.orders(id) on delete cascade,carrier text,tracking_number text,status text not null default 'processing' check(status in('processing','shipped','delivered','exception')),shipped_at timestamptz,delivered_at timestamptz,updated_at timestamptz not null default now());
create table public.suppliers(id uuid primary key default gen_random_uuid(),name text not null,adapter_key text not null default 'manual',mode text not null default 'manual' check(mode in('manual','api')),active boolean not null default true,created_at timestamptz not null default now());
create table public.supplier_products(id uuid primary key default gen_random_uuid(),supplier_id uuid not null references public.suppliers(id),product_id uuid not null references public.products(id) on delete cascade,variant_id uuid references public.product_variants(id) on delete cascade,external_product_id text,external_variant_id text,last_cost_minor bigint,currency char(3),last_availability boolean,last_checked_at timestamptz,unique(supplier_id,variant_id));
create table public.supplier_orders(id uuid primary key default gen_random_uuid(),order_id uuid not null unique references public.orders(id) on delete cascade,supplier_id uuid references public.suppliers(id),supplier_order_reference text,fulfillment_cost_minor bigint not null default 0,status text not null default 'awaiting_supplier_order',last_error text,created_at timestamptz not null default now(),updated_at timestamptz not null default now());
create table public.order_status_history(id bigint generated always as identity primary key,order_id uuid not null references public.orders(id) on delete cascade,status text not null,note text,changed_by uuid references auth.users(id),created_at timestamptz not null default now());
create index order_history_order_idx on public.order_status_history(order_id,created_at);
create table public.store_settings(key text primary key,value_text text,value_json jsonb,public boolean not null default false,updated_at timestamptz not null default now());

create or replace function public.touch_updated_at() returns trigger language plpgsql as $$begin new.updated_at=now();return new;end$$;
create trigger products_touch before update on public.products for each row execute function public.touch_updated_at();
create trigger variants_touch before update on public.product_variants for each row execute function public.touch_updated_at();
create trigger orders_touch before update on public.orders for each row execute function public.touch_updated_at();
create or replace function public.log_order_status() returns trigger language plpgsql security definer set search_path=public as $$begin if old.status is distinct from new.status then insert into order_status_history(order_id,status,changed_by)values(new.id,new.status,auth.uid());end if;return new;end$$;
create trigger orders_status_log after update on public.orders for each row execute function public.log_order_status();
create or replace function public.create_profile() returns trigger language plpgsql security definer set search_path=public as $$begin insert into profiles(id,full_name)values(new.id,new.raw_user_meta_data->>'full_name') on conflict do nothing;return new;end$$;
create trigger auth_user_profile after insert on auth.users for each row execute function public.create_profile();

-- RLS
alter table public.product_variants enable row level security;alter table public.product_images enable row level security;alter table public.product_private enable row level security;alter table public.profiles enable row level security;alter table public.addresses enable row level security;alter table public.carts enable row level security;alter table public.cart_items enable row level security;alter table public.shipping_methods enable row level security;alter table public.discounts enable row level security;alter table public.orders enable row level security;alter table public.order_items enable row level security;alter table public.order_item_costs enable row level security;alter table public.payments enable row level security;alter table public.payment_webhook_events enable row level security;alter table public.refunds enable row level security;alter table public.shipments enable row level security;alter table public.suppliers enable row level security;alter table public.supplier_products enable row level security;alter table public.supplier_orders enable row level security;alter table public.order_status_history enable row level security;alter table public.store_settings enable row level security;
create policy "Public active variants" on public.product_variants for select using((exists(select 1 from products p where p.id=product_id and p.published and p.status='active'))or is_admin());
create policy "Admins variants" on public.product_variants for all using(is_admin()) with check(is_admin());create policy "Public product images" on public.product_images for select using(exists(select 1 from products p where p.id=product_id and p.published and p.status='active')or is_admin());create policy "Admins images" on public.product_images for all using(is_admin()) with check(is_admin());create policy "Admins private products" on public.product_private for all using(is_admin()) with check(is_admin());
create policy "Own profile" on public.profiles for select using(id=auth.uid() or is_admin());create policy "Update own profile" on public.profiles for update using(id=auth.uid()) with check(id=auth.uid());create policy "Own addresses" on public.addresses for all using(user_id=auth.uid() or is_admin()) with check(user_id=auth.uid() or is_admin());
create policy "Own cart" on public.carts for all using(user_id=auth.uid()) with check(user_id=auth.uid());create policy "Own cart items" on public.cart_items for all using(exists(select 1 from carts c where c.id=cart_id and c.user_id=auth.uid())) with check(exists(select 1 from carts c where c.id=cart_id and c.user_id=auth.uid()));
create policy "Active shipping methods" on public.shipping_methods for select using(active or is_admin());create policy "Admin shipping methods" on public.shipping_methods for all using(is_admin()) with check(is_admin());create policy "Admin discounts" on public.discounts for all using(is_admin()) with check(is_admin());
create policy "Own orders" on public.orders for select using(user_id=auth.uid() or is_admin());create policy "Admins update orders" on public.orders for update using(is_admin()) with check(is_admin());create policy "Own order items" on public.order_items for select using(exists(select 1 from orders o where o.id=order_id and(o.user_id=auth.uid() or is_admin())));create policy "Admin order costs" on public.order_item_costs for all using(is_admin()) with check(is_admin());create policy "Own safe payments" on public.payments for select using(exists(select 1 from orders o where o.id=order_id and(o.user_id=auth.uid() or is_admin())));create policy "Admin webhook events" on public.payment_webhook_events for select using(is_admin());create policy "Own refunds" on public.refunds for select using(exists(select 1 from orders o where o.id=order_id and(o.user_id=auth.uid() or is_admin())));create policy "Own shipments" on public.shipments for select using(exists(select 1 from orders o where o.id=order_id and(o.user_id=auth.uid() or is_admin())));create policy "Admins shipments" on public.shipments for all using(is_admin()) with check(is_admin());create policy "Admin suppliers" on public.suppliers for all using(is_admin()) with check(is_admin());create policy "Admin supplier products" on public.supplier_products for all using(is_admin()) with check(is_admin());create policy "Admin supplier orders" on public.supplier_orders for all using(is_admin()) with check(is_admin());create policy "Own order history" on public.order_status_history for select using(exists(select 1 from orders o where o.id=order_id and(o.user_id=auth.uid() or is_admin())));create policy "Public settings" on public.store_settings for select using(public or is_admin());create policy "Admin settings" on public.store_settings for all using(is_admin()) with check(is_admin());

-- Public and role-filtered API projections. Private costs are absent from storefront views.
create or replace view public.storefront_products as select p.id,p.name,p.slug,p.sku,p.description,p.short_description,p.category_slug,p.brand,p.image_url,p.specifications,p.featured,p.best_seller,p.promotion,p.published_at,p.updated_at,p.processing_estimate,p.delivery_estimate,coalesce((select jsonb_agg(jsonb_build_object('id',i.id,'src',i.src,'alt',i.alt,'position',i.position)order by i.position)from product_images i where i.product_id=p.id),'[]')images,coalesce((select jsonb_agg(jsonb_build_object('id',v.id,'sku',v.sku,'name',v.name,'option_values',v.option_values,'price_minor',v.price_minor,'compare_at_minor',v.compare_at_minor,'currency',v.currency,'stock_quantity',v.stock_quantity,'track_inventory',v.track_inventory,'available',v.available)order by v.created_at)from product_variants v where v.product_id=p.id),'[]')variants from products p where p.published and p.status='active';
create or replace view public.customer_orders as select o.*,s.tracking_number,s.carrier from orders o left join shipments s on s.order_id=o.id where o.user_id=auth.uid();
create or replace view public.customer_order_details as select o.*,s.tracking_number,s.carrier,coalesce((select jsonb_agg(jsonb_build_object('id',i.id,'product_name',i.product_name,'variant_name',i.variant_name,'sku',i.sku,'quantity',i.quantity,'unit_price_minor',i.unit_price_minor,'line_total_minor',i.line_total_minor,'image_url',i.image_url))from order_items i where i.order_id=o.id),'[]')items from orders o left join shipments s on s.order_id=o.id where o.user_id=auth.uid();
create or replace view public.admin_product_overview as select p.*,pp.supplier_name,pp.supplier_product_url,pp.supplier_external_id,pp.supplier_cost_minor,pp.supplier_shipping_minor,pp.packaging_cost_minor,coalesce(pp.supplier_cost_minor+pp.supplier_shipping_minor+pp.packaging_cost_minor,0)total_supplier_cost_minor,coalesce((select min(v.price_minor)from product_variants v where v.product_id=p.id),0)lowest_price_minor,coalesce((select min(v.price_minor)from product_variants v where v.product_id=p.id),0)-coalesce(pp.supplier_cost_minor+pp.supplier_shipping_minor+pp.packaging_cost_minor,0)estimated_gross_profit_minor,coalesce((select jsonb_agg(to_jsonb(v))from product_variants v where v.product_id=p.id),'[]')variants from products p left join product_private pp on pp.product_id=p.id where is_admin();
create or replace view public.admin_order_overview as select o.*,s.tracking_number,s.carrier,so.supplier_order_reference,so.fulfillment_cost_minor from orders o left join shipments s on s.order_id=o.id left join supplier_orders so on so.order_id=o.id where is_admin();
create or replace view public.admin_customer_overview as select p.id,p.full_name,u.email,p.created_at,(select count(*)from orders o where o.user_id=p.id)order_count from profiles p join auth.users u on u.id=p.id where is_admin();
create or replace view public.admin_dashboard_metrics as select count(*)filter(where mode='live')::bigint total_orders,coalesce(sum(total_minor)filter(where mode='live' and payment_status='succeeded'),0)::bigint revenue_minor,coalesce(sum(total_minor-(select coalesce(sum(so.fulfillment_cost_minor),0)from supplier_orders so where so.order_id=orders.id))filter(where mode='live' and payment_status='succeeded'),0)::bigint gross_profit_minor,count(*)filter(where mode='live' and status in('paid','awaiting_supplier_order'))::bigint awaiting_fulfillment from orders where is_admin();
grant select on public.storefront_products to anon,authenticated;grant select on public.customer_orders,public.customer_order_details to authenticated;grant select on public.admin_product_overview,public.admin_order_overview,public.admin_customer_overview,public.admin_dashboard_metrics to authenticated;

-- Authoritative, idempotent checkout transaction. Browser totals are ignored.
create or replace function public.create_order_from_cart(p_lines jsonb,p_address jsonb,p_shipping_code text,p_idempotency_key uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_user uuid:=auth.uid();v_order orders;v_subtotal bigint;v_shipping bigint;v_currency char(3);v_count int;v_email text;v_fingerprint text;
begin
 if v_user is null then raise exception 'Authentication required';end if;
 if jsonb_typeof(p_lines)<>'array' or jsonb_array_length(p_lines)=0 or jsonb_array_length(p_lines)>50 then raise exception 'Invalid cart';end if;
 v_fingerprint:=encode(digest(p_lines::text||p_address::text||p_shipping_code,'sha256'),'hex');
 perform pg_advisory_xact_lock(hashtextextended(v_user::text||p_idempotency_key::text,0));
 select * into v_order from orders where user_id=v_user and idempotency_key=p_idempotency_key;if found then if v_order.request_fingerprint<>v_fingerprint then raise exception 'Idempotency key reused with different checkout data';end if;return jsonb_build_object('orderId',v_order.id,'orderNumber',v_order.order_number);end if;
 perform 1 from product_variants v where v.id in(select distinct(value->>'variantId')::uuid from jsonb_array_elements(p_lines)) for update;
 select count(distinct x.variant_id),sum(v.price_minor*x.quantity),min(v.currency) into v_count,v_subtotal,v_currency from(select(value->>'variantId')::uuid variant_id,(value->>'quantity')::int quantity from jsonb_array_elements(p_lines))x join product_variants v on v.id=x.variant_id join products p on p.id=v.product_id where x.quantity between 1 and 99 and v.available and p.published and p.status='active' and(not v.track_inventory or(v.stock_quantity is not null and v.stock_quantity>=x.quantity));
 if v_count<>jsonb_array_length(p_lines) or v_subtotal is null then raise exception 'A product, price, or quantity is no longer available';end if;
 if exists(select 1 from(select distinct v.currency from jsonb_array_elements(p_lines)j join product_variants v on v.id=(j.value->>'variantId')::uuid)x having count(*)>1)then raise exception 'Mixed-currency checkout is not supported';end if;
 select fee_minor into v_shipping from shipping_methods where code=p_shipping_code and active and currency=v_currency;if v_shipping is null then raise exception 'Shipping method unavailable';end if;
 if(length(coalesce(p_address->>'fullName',''))<2 or length(coalesce(p_address->>'line1',''))<3 or length(coalesce(p_address->>'city',''))<2 or length(coalesce(p_address->>'region',''))<2 or length(coalesce(p_address->>'postalCode',''))<2 or length(coalesce(p_address->>'countryCode',''))<>2)then raise exception 'Complete shipping address required';end if;
 v_email:=coalesce(p_address->>'email',(auth.jwt()->>'email'));if v_email is null then raise exception 'Email required';end if;
 insert into orders(user_id,mode,customer_email,currency,subtotal_minor,shipping_minor,tax_minor,discount_minor,total_minor,shipping_address,shipping_method_code,idempotency_key,request_fingerprint)values(v_user,'test',v_email,v_currency,v_subtotal,v_shipping,0,0,v_subtotal+v_shipping,p_address,p_shipping_code,p_idempotency_key,v_fingerprint)returning * into v_order;
 insert into order_items(order_id,product_id,variant_id,product_name,variant_name,sku,image_url,quantity,unit_price_minor,line_total_minor)select v_order.id,p.id,v.id,p.name,v.name,v.sku,p.image_url,x.quantity,v.price_minor,v.price_minor*x.quantity from(select(value->>'variantId')::uuid variant_id,(value->>'quantity')::int quantity from jsonb_array_elements(p_lines))x join product_variants v on v.id=x.variant_id join products p on p.id=v.product_id;
 insert into payments(order_id,provider,mode,status,amount_minor,currency,idempotency_key)values(v_order.id,'test','test','pending',v_order.total_minor,v_order.currency,gen_random_uuid());insert into order_status_history(order_id,status,changed_by,note)values(v_order.id,'pending_payment',v_user,'Order created by server-validated checkout');
 return jsonb_build_object('orderId',v_order.id,'orderNumber',v_order.order_number,'totalMinor',v_order.total_minor,'currency',v_order.currency);
end$$;
revoke all on function public.create_order_from_cart(jsonb,jsonb,text,uuid) from public;grant execute on function public.create_order_from_cart(jsonb,jsonb,text,uuid) to authenticated;

-- Storage bucket for admin product images.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)values('product-images','product-images',true,5242880,array['image/jpeg','image/png','image/webp'])on conflict(id)do nothing;
create policy "Public product images read" on storage.objects for select using(bucket_id='product-images');create policy "Admins upload product images" on storage.objects for insert to authenticated with check(bucket_id='product-images' and is_admin());create policy "Admins update product images" on storage.objects for update to authenticated using(bucket_id='product-images' and is_admin());create policy "Admins delete product images" on storage.objects for delete to authenticated using(bucket_id='product-images' and is_admin());

-- Test-only payment finalization called exclusively by the guarded Edge Function.
create or replace function public.finalize_test_payment(p_order_id uuid,p_user_id uuid,p_outcome text)
returns boolean language plpgsql security definer set search_path=public as $$
declare v_order orders;v_payment payments;
begin
 if p_outcome not in('approve','decline')then raise exception 'Invalid test outcome';end if;
 select * into v_order from orders where id=p_order_id and user_id=p_user_id for update;if not found then raise exception 'Order not found';end if;
 select * into v_payment from payments where order_id=p_order_id and provider='test' order by created_at desc limit 1 for update;if not found then raise exception 'Payment not found';end if;
 if v_payment.status='succeeded' then return true;end if;if v_payment.status='failed' then return false;end if;
 if p_outcome='approve' then update payments set status='succeeded',updated_at=now() where id=v_payment.id;update orders set payment_status='succeeded',status='paid' where id=p_order_id;return true;
 else update payments set status='failed',updated_at=now() where id=v_payment.id;update orders set payment_status='failed' where id=p_order_id;return false;end if;
end$$;
revoke all on function public.finalize_test_payment(uuid,uuid,text) from public;grant execute on function public.finalize_test_payment(uuid,uuid,text) to service_role;

-- Retire legacy affiliate-only fields and seed the initial store taxonomy.
drop table if exists public.affiliate_click_events;
alter table public.products drop constraint if exists amazon_https;
alter table public.products drop constraint if exists aliexpress_https;
alter table public.products drop column if exists amazon_affiliate_url;
alter table public.products drop column if exists aliexpress_affiliate_url;
insert into public.categories(name,slug,description,image_url,published) values
('Electronics & Gadgets','electronics','Smart technology for modern routines.','https://images.unsplash.com/photo-1498049794561-7780e7231661?auto=format&fit=crop&w=900&q=80',true),
('Fashion & Apparel','fashion','Versatile pieces for everyday style.','https://images.unsplash.com/photo-1445205170230-053b83016050?auto=format&fit=crop&w=900&q=80',true),
('Shoes','shoes','Footwear for movement and daily comfort.','https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=900&q=80',true),
('Home & Living','home','Useful upgrades for better spaces.','https://images.unsplash.com/photo-1484101403633-562f891dc89a?auto=format&fit=crop&w=900&q=80',true),
('Beauty & Personal Care','beauty','Daily care and thoughtful organization.','https://images.unsplash.com/photo-1596462502278-27bfdc403348?auto=format&fit=crop&w=900&q=80',true),
('Sports & Outdoors','sports','Practical gear to move and explore.','https://images.unsplash.com/photo-1517836357463-d25dfeac3438?auto=format&fit=crop&w=900&q=80',true),
('Toys & Hobbies','toys-hobbies','Creative finds for play and downtime.','https://images.unsplash.com/photo-1594787318286-3d835c1d207f?auto=format&fit=crop&w=900&q=80',true)
on conflict(slug)do nothing;
alter table public.products add constraint products_category_fk foreign key(category_slug) references public.categories(slug) not valid;

-- Customers consume curated views, never the legacy base product row (which may contain import metadata).
revoke select on public.products from anon,authenticated;
grant select(id) on public.products to authenticated;

-- Customer-safe payment projection; provider references and metadata remain private.
revoke select on public.payments from anon,authenticated;
create or replace view public.customer_payments as select p.id,p.order_id,p.status,p.amount_minor,p.currency,p.created_at,p.updated_at from payments p join orders o on o.id=p.order_id where o.user_id=auth.uid();
grant select on public.customer_payments to authenticated;

-- Atomic fulfillment state machine. Test orders and unverified payments cannot enter supplier operations.
create or replace function public.admin_update_fulfillment(p_order_id uuid,p_status text,p_tracking text,p_carrier text,p_supplier_reference text,p_fulfillment_cost_minor bigint)
returns void language plpgsql security definer set search_path=public as $$
declare o orders;
begin
 if not is_admin() then raise exception 'Administrator access required';end if;select * into o from orders where id=p_order_id for update;if not found then raise exception 'Order not found';end if;
 if o.mode<>'live' then raise exception 'Test orders cannot enter fulfillment';end if;
 if p_status in('paid','awaiting_supplier_order','supplier_order_placed','processing','shipped','delivered','refund_pending','refunded') and o.payment_status<>'succeeded' then raise exception 'Verified live payment required';end if;
 if not((o.status='pending_payment' and p_status='cancelled')or(o.status='paid' and p_status in('awaiting_supplier_order','cancelled','refund_pending'))or(o.status='awaiting_supplier_order' and p_status in('supplier_order_placed','cancelled','refund_pending'))or(o.status='supplier_order_placed' and p_status in('processing','shipped','refund_pending'))or(o.status='processing' and p_status in('shipped','refund_pending'))or(o.status='shipped' and p_status in('delivered','refund_pending'))or o.status=p_status)then raise exception 'Illegal order status transition';end if;
 if p_status in('shipped','delivered')and(length(coalesce(p_tracking,''))<3 or length(coalesce(p_carrier,''))<2)then raise exception 'Carrier and tracking are required';end if;
 update orders set status=p_status where id=p_order_id;
 insert into shipments(order_id,tracking_number,carrier,status,shipped_at,delivered_at)values(p_order_id,nullif(p_tracking,''),nullif(p_carrier,''),case when p_status in('shipped','delivered')then p_status else 'processing'end,case when p_status in('shipped','delivered')then now()end,case when p_status='delivered'then now()end)on conflict(order_id)do update set tracking_number=excluded.tracking_number,carrier=excluded.carrier,status=excluded.status,shipped_at=coalesce(shipments.shipped_at,excluded.shipped_at),delivered_at=coalesce(shipments.delivered_at,excluded.delivered_at),updated_at=now();
 insert into supplier_orders(order_id,supplier_order_reference,fulfillment_cost_minor,status)values(p_order_id,nullif(p_supplier_reference,''),greatest(p_fulfillment_cost_minor,0),p_status)on conflict(order_id)do update set supplier_order_reference=excluded.supplier_order_reference,fulfillment_cost_minor=excluded.fulfillment_cost_minor,status=excluded.status,updated_at=now();
end$$;
revoke all on function public.admin_update_fulfillment(uuid,text,text,text,text,bigint)from public;grant execute on function public.admin_update_fulfillment(uuid,text,text,text,text,bigint)to authenticated;

create unique index product_private_supplier_identity on public.product_private(supplier_name,supplier_external_id) where supplier_name is not null and supplier_external_id is not null;
-- Atomic product, stable-variant, and private-cost write used by the admin UI and imports.
create or replace function public.admin_save_product(p_product_id uuid,p_payload jsonb)
returns uuid language plpgsql security definer set search_path=public as $$
declare pid uuid:=p_product_id;v jsonb;vid uuid;kept uuid[]:='{}';published_value boolean:=coalesce((p_payload->>'published')::boolean,false);supplier_name_value text:=nullif(p_payload->>'supplierName','');supplier_id_value text:=nullif(p_payload->>'supplierExternalId','');
begin
 if not is_admin()then raise exception 'Administrator access required';end if;if jsonb_array_length(coalesce(p_payload->'variants','[]'))<1 then raise exception 'At least one variant required';end if;
 if pid is null and supplier_name_value is not null and supplier_id_value is not null then select product_id into pid from product_private where supplier_name=supplier_name_value and supplier_external_id=supplier_id_value;end if;
 if pid is null then insert into products(name,slug,sku,category_slug,brand,description,short_description,image_url,status,published,featured,best_seller,promotion,processing_estimate,delivery_estimate,published_at)values(p_payload->>'name',p_payload->>'slug',p_payload->>'sku',p_payload->>'categorySlug',nullif(p_payload->>'brand',''),p_payload->>'description',p_payload->>'shortDescription',nullif(p_payload->>'imageUrl',''),case when published_value then'active'else'draft'end,published_value,coalesce((p_payload->>'featured')::boolean,false),coalesce((p_payload->>'bestSeller')::boolean,false),coalesce((p_payload->>'promotion')::boolean,false),nullif(p_payload->>'processingEstimate',''),nullif(p_payload->>'deliveryEstimate',''),case when published_value then now()end)returning id into pid;
 else update products set name=p_payload->>'name',slug=p_payload->>'slug',sku=p_payload->>'sku',category_slug=p_payload->>'categorySlug',brand=nullif(p_payload->>'brand',''),description=p_payload->>'description',short_description=p_payload->>'shortDescription',image_url=nullif(p_payload->>'imageUrl',''),status=case when published_value then'active'else'draft'end,published=published_value,featured=coalesce((p_payload->>'featured')::boolean,false),best_seller=coalesce((p_payload->>'bestSeller')::boolean,false),promotion=coalesce((p_payload->>'promotion')::boolean,false),processing_estimate=nullif(p_payload->>'processingEstimate',''),delivery_estimate=nullif(p_payload->>'deliveryEstimate',''),published_at=case when published_value then coalesce(published_at,now())else published_at end where id=pid;if not found then raise exception 'Product not found';end if;end if;
 for v in select value from jsonb_array_elements(p_payload->'variants')loop vid:=nullif(v->>'id','')::uuid;if vid is null then select id into vid from product_variants where product_id=pid and sku=v->>'sku';end if;if vid is not null and exists(select 1 from product_variants where id=vid and product_id=pid)then update product_variants set name=v->>'name',sku=v->>'sku',price_minor=(v->>'priceMinor')::bigint,stock_quantity=(v->>'stockQuantity')::int,track_inventory=true,available=(v->>'stockQuantity')::int>0,option_values=coalesce(v->'optionValues','{}')where id=vid;else insert into product_variants(product_id,name,sku,price_minor,currency,stock_quantity,track_inventory,available,option_values)values(pid,v->>'name',v->>'sku',(v->>'priceMinor')::bigint,'USD',(v->>'stockQuantity')::int,true,(v->>'stockQuantity')::int>0,coalesce(v->'optionValues','{}'))returning id into vid;end if;kept:=array_append(kept,vid);end loop;
 update product_variants set available=false where product_id=pid and not(id=any(kept));
 insert into product_private(product_id,supplier_name,supplier_product_url,supplier_external_id,supplier_cost_minor,supplier_shipping_minor,packaging_cost_minor)values(pid,supplier_name_value,nullif(p_payload->>'supplierProductUrl',''),supplier_id_value,coalesce((p_payload->>'supplierCostMinor')::bigint,0),coalesce((p_payload->>'supplierShippingMinor')::bigint,0),coalesce((p_payload->>'packagingCostMinor')::bigint,0))on conflict(product_id)do update set supplier_name=excluded.supplier_name,supplier_product_url=excluded.supplier_product_url,supplier_external_id=excluded.supplier_external_id,supplier_cost_minor=excluded.supplier_cost_minor,supplier_shipping_minor=excluded.supplier_shipping_minor,packaging_cost_minor=excluded.packaging_cost_minor,updated_at=now();return pid;
end$$;
revoke all on function public.admin_save_product(uuid,jsonb)from public;grant execute on function public.admin_save_product(uuid,jsonb)to authenticated;
