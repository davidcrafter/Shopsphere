-- IBYIZAMART manual-store operations expansion.
-- Apply after 001_initial.sql, 002_dropshipping_commerce.sql, and 003_ibyizamart_rebrand.sql.
-- This is forward-only: back up production data before applying.

begin;

-- Manual catalog only. Legacy source labels are normalized; new product writes are enforced as manual.
alter table public.products drop constraint if exists products_source_check;
update public.products set source = 'manual' where source is distinct from 'manual';
alter table public.products alter column source set default 'manual';
alter table public.products add constraint products_manual_source_check check (source = 'manual');
alter table public.products add column if not exists manual_entry_confirmed boolean not null default true;
alter table public.products add column if not exists product_type text not null default 'physical';
alter table public.products add column if not exists tags text[] not null default '{}';
alter table public.products add column if not exists seo_title text;
alter table public.products add column if not exists seo_description text;
alter table public.products add column if not exists canonical_url text;
alter table public.products add column if not exists social_image_url text;
alter table public.products add column if not exists noindex boolean not null default false;
alter table public.products add column if not exists allow_backorders boolean not null default false;
alter table public.products add column if not exists preorder boolean not null default false;
alter table public.products add column if not exists low_stock_threshold integer not null default 3 check (low_stock_threshold >= 0);
alter table public.products add column if not exists shipping_class text;
alter table public.products add column if not exists dimensions jsonb not null default '{}'::jsonb;

-- RWF is the operating default. Monetary columns store integer minor units; RWF uses zero decimal places in the client formatter.
alter table public.products drop constraint if exists products_currency_check;
alter table public.products add constraint products_currency_check check (currency is null or currency in ('RWF','USD','EUR','GBP','CAD','AUD'));
alter table public.product_variants drop constraint if exists product_variants_currency_check;
alter table public.product_variants add constraint product_variants_currency_check check (currency in ('RWF','USD','EUR','GBP','CAD','AUD'));
alter table public.product_variants alter column currency set default 'RWF';
alter table public.shipping_methods drop constraint if exists shipping_methods_currency_check;
alter table public.shipping_methods add constraint shipping_methods_currency_check check (currency in ('RWF','USD','EUR','GBP','CAD','AUD'));
alter table public.shipping_methods alter column currency set default 'RWF';
alter table public.orders drop constraint if exists orders_currency_check;
alter table public.orders add constraint orders_currency_check check (currency in ('RWF','USD','EUR','GBP','CAD','AUD'));
alter table public.payments drop constraint if exists payments_currency_check;
alter table public.payments add constraint payments_currency_check check (currency in ('RWF','USD','EUR','GBP','CAD','AUD'));
update public.shipping_methods set currency = 'RWF', fee_minor = 2000 where code = 'standard' and currency = 'USD';

-- Manual supplier records are private administration data, never supplier-import integration configuration.
alter table public.suppliers add column if not exists contact_name text;
alter table public.suppliers add column if not exists email text;
alter table public.suppliers add column if not exists phone text;
alter table public.suppliers add column if not exists website_url text;
alter table public.suppliers add column if not exists country_code char(2);
alter table public.suppliers add column if not exists currency char(3) not null default 'RWF';
alter table public.suppliers add column if not exists payment_terms text;
alter table public.suppliers add column if not exists processing_notes text;
alter table public.suppliers add column if not exists delivery_notes text;
alter table public.suppliers add column if not exists reliability_notes text;
alter table public.suppliers add column if not exists internal_notes text;
alter table public.suppliers add column if not exists archived_at timestamptz;
alter table public.product_private add column if not exists supplier_id uuid references public.suppliers(id) on delete set null;
alter table public.product_private add column if not exists supplier_contact_notes text;
alter table public.product_private add column if not exists other_unit_cost_minor bigint not null default 0 check (other_unit_cost_minor >= 0);

-- Preserve manual product imagery as first-class ordered records.
alter table public.product_images add column if not exists storage_path text;
alter table public.product_images add column if not exists created_at timestamptz not null default now();
alter table public.product_images add column if not exists updated_at timestamptz not null default now();
create index if not exists product_images_product_position_idx on public.product_images(product_id, position);

-- Staff role registry complements the existing secure JWT app_metadata provisioning workflow.
create table if not exists public.user_roles(
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('admin','manager','support','content_editor')),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, role)
);
alter table public.user_roles enable row level security;
create policy "Users read own role" on public.user_roles for select using (user_id = auth.uid() or public.is_admin());
create policy "Admins manage roles" on public.user_roles for all using (public.is_admin()) with check (public.is_admin());
create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public
as $$
  select coalesce((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin', false);
$$;
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated;

-- Curated collections managed entirely by staff.
create table if not exists public.collections(
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  description text not null default '',
  banner_image_url text,
  active boolean not null default false,
  starts_at timestamptz,
  ends_at timestamptz,
  display_order integer not null default 0,
  seo_title text,
  seo_description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (ends_at is null or starts_at is null or ends_at > starts_at)
);
create table if not exists public.collection_products(
  collection_id uuid not null references public.collections(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  display_order integer not null default 0,
  primary key (collection_id, product_id)
);
create index if not exists collection_products_product_idx on public.collection_products(product_id);
alter table public.collections enable row level security;
alter table public.collection_products enable row level security;
create policy "Public active collections" on public.collections for select using ((active and (starts_at is null or starts_at <= now()) and (ends_at is null or ends_at > now())) or public.is_admin());
create policy "Admins manage collections" on public.collections for all using (public.is_admin()) with check (public.is_admin());
create policy "Public collection products" on public.collection_products for select using (exists(select 1 from public.collections c where c.id = collection_id and c.active and (c.starts_at is null or c.starts_at <= now()) and (c.ends_at is null or c.ends_at > now())) or public.is_admin());
create policy "Admins manage collection products" on public.collection_products for all using (public.is_admin()) with check (public.is_admin());

-- Customer wishlists: local guest wishlists can be merged after sign-in, while database records remain owner-only.
create table if not exists public.wishlists(
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.wishlist_items(
  id uuid primary key default gen_random_uuid(),
  wishlist_id uuid not null references public.wishlists(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(wishlist_id, product_id)
);
create index if not exists wishlist_items_product_idx on public.wishlist_items(product_id);
alter table public.wishlists enable row level security;
alter table public.wishlist_items enable row level security;
create policy "Owners manage wishlists" on public.wishlists for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "Owners manage wishlist items" on public.wishlist_items for all using (exists(select 1 from public.wishlists w where w.id = wishlist_id and w.user_id = auth.uid())) with check (exists(select 1 from public.wishlists w where w.id = wishlist_id and w.user_id = auth.uid()));
create or replace function public.ensure_my_wishlist()
returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  insert into public.wishlists(user_id) values(auth.uid()) on conflict(user_id) do update set updated_at = now() returning id into v_id;
  return v_id;
end $$;
revoke all on function public.ensure_my_wishlist() from public;
grant execute on function public.ensure_my_wishlist() to authenticated;

-- Moderated verified-purchase reviews. Legacy product rating values are not used as customer reviews.
create table if not exists public.product_reviews(
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  order_item_id uuid not null references public.order_items(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  rating integer not null check (rating between 1 and 5),
  title text,
  body text not null check (char_length(body) between 10 and 2000),
  status text not null default 'pending' check (status in ('pending','approved','rejected','hidden')),
  moderation_note text,
  moderated_by uuid references auth.users(id),
  moderated_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, order_item_id)
);
create index if not exists product_reviews_public_idx on public.product_reviews(product_id, status, created_at desc);
alter table public.product_reviews enable row level security;
create policy "Public approved reviews" on public.product_reviews for select using (status = 'approved' or user_id = auth.uid() or public.is_admin());
create policy "Users update own pending reviews" on public.product_reviews for update using (user_id = auth.uid() and status = 'pending') with check (user_id = auth.uid() and status = 'pending');
create policy "Admins manage reviews" on public.product_reviews for all using (public.is_admin()) with check (public.is_admin());
create or replace function public.submit_product_review(p_product_id uuid, p_rating integer, p_title text, p_body text)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_item uuid; v_review uuid;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if p_rating not between 1 and 5 or char_length(trim(coalesce(p_body,''))) not between 10 and 2000 then raise exception 'Invalid review'; end if;
  select oi.id into v_item
  from public.order_items oi join public.orders o on o.id = oi.order_id
  where oi.product_id = p_product_id and o.user_id = auth.uid() and o.payment_status = 'succeeded' and o.status = 'delivered'
  order by o.created_at desc limit 1;
  if v_item is null then raise exception 'A delivered purchase is required before reviewing this product'; end if;
  insert into public.product_reviews(product_id, order_item_id, user_id, rating, title, body)
  values(p_product_id, v_item, auth.uid(), p_rating, nullif(trim(p_title),''), trim(p_body))
  on conflict(user_id, order_item_id) do update set rating = excluded.rating, title = excluded.title, body = excluded.body, status = 'pending', moderation_note = null, moderated_by = null, moderated_at = null, updated_at = now()
  returning id into v_review;
  return v_review;
end $$;
revoke all on function public.submit_product_review(uuid, integer, text, text) from public;
grant execute on function public.submit_product_review(uuid, integer, text, text) to authenticated;
create or replace function public.admin_moderate_review(p_review_id uuid, p_status text, p_note text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'Administrator access required'; end if;
  if p_status not in ('approved','rejected','hidden') then raise exception 'Invalid review status'; end if;
  update public.product_reviews set status = p_status, moderation_note = nullif(trim(p_note),''), moderated_by = auth.uid(), moderated_at = now(), updated_at = now() where id = p_review_id;
  if not found then raise exception 'Review not found'; end if;
end $$;
revoke all on function public.admin_moderate_review(uuid, text, text) from public;
grant execute on function public.admin_moderate_review(uuid, text, text) to authenticated;

-- Support inbox. Public submission is available only through a rate-limited Edge Function using service credentials.
create table if not exists public.contact_messages(
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  name text not null check (char_length(name) between 2 and 120),
  email text not null check (char_length(email) between 5 and 254),
  order_number text,
  subject text not null check (char_length(subject) between 2 and 160),
  message text not null check (char_length(message) between 10 and 4000),
  status text not null default 'open' check (status in ('open','in_progress','resolved','closed')),
  internal_notes text,
  assigned_to uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.contact_rate_limits(
  rate_key text primary key,
  window_started_at timestamptz not null default now(),
  request_count integer not null default 0 check (request_count >= 0),
  updated_at timestamptz not null default now()
);
create index if not exists contact_messages_admin_idx on public.contact_messages(status, created_at desc);
alter table public.contact_messages enable row level security;
alter table public.contact_rate_limits enable row level security;
create policy "Owners read own contact messages" on public.contact_messages for select using (user_id = auth.uid() or public.is_admin());
create policy "Admins manage contact messages" on public.contact_messages for all using (public.is_admin()) with check (public.is_admin());

-- Editable FAQ, homepage, and policy content. Public views only reveal published/public blocks.
create table if not exists public.faq_entries(
  id uuid primary key default gen_random_uuid(),
  category text not null default 'General',
  question text not null check (char_length(question) between 5 and 250),
  answer text not null check (char_length(answer) between 10 and 4000),
  display_order integer not null default 0,
  published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.content_pages(
  id uuid primary key default gen_random_uuid(),
  slug text not null unique check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  title text not null,
  body text not null default '',
  seo_title text,
  seo_description text,
  published boolean not null default false,
  effective_at timestamptz,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.homepage_sections(
  id uuid primary key default gen_random_uuid(),
  section_key text not null unique,
  value jsonb not null default '{}'::jsonb,
  public boolean not null default true,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.faq_entries enable row level security;
alter table public.content_pages enable row level security;
alter table public.homepage_sections enable row level security;
create policy "Public published FAQ" on public.faq_entries for select using (published or public.is_admin());
create policy "Admins manage FAQ" on public.faq_entries for all using (public.is_admin()) with check (public.is_admin());
create policy "Public published pages" on public.content_pages for select using (published or public.is_admin());
create policy "Admins manage pages" on public.content_pages for all using (public.is_admin()) with check (public.is_admin());
create policy "Public homepage content" on public.homepage_sections for select using (public or public.is_admin());
create policy "Admins manage homepage content" on public.homepage_sections for all using (public.is_admin()) with check (public.is_admin());

-- Zone-based shipping and immutable checkout quote records.
create table if not exists public.shipping_zones(
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  active boolean not null default true,
  delivery_note text,
  display_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.shipping_zone_countries(
  zone_id uuid not null references public.shipping_zones(id) on delete cascade,
  country_code char(2) not null,
  primary key(zone_id, country_code)
);
create table if not exists public.shipping_rates(
  id uuid primary key default gen_random_uuid(),
  zone_id uuid not null references public.shipping_zones(id) on delete cascade,
  code text not null unique,
  name text not null,
  fee_minor bigint not null check (fee_minor >= 0),
  free_shipping_threshold_minor bigint check (free_shipping_threshold_minor is null or free_shipping_threshold_minor >= 0),
  currency char(3) not null default 'RWF' check (currency in ('RWF','USD','EUR','GBP','CAD','AUD')),
  min_delivery_days integer check (min_delivery_days is null or min_delivery_days >= 0),
  max_delivery_days integer check (max_delivery_days is null or max_delivery_days >= min_delivery_days),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.order_shipping_quotes(
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null unique references public.orders(id) on delete cascade,
  shipping_rate_id uuid references public.shipping_rates(id) on delete set null,
  method_name text not null,
  delivery_estimate text,
  fee_minor bigint not null check (fee_minor >= 0),
  currency char(3) not null,
  created_at timestamptz not null default now()
);
insert into public.shipping_zones(name, active, delivery_note) values ('Rwanda', true, 'Delivery estimates are shown at checkout and are not guaranteed.') on conflict(name) do nothing;
insert into public.shipping_zone_countries(zone_id, country_code) select id, 'RW' from public.shipping_zones where name = 'Rwanda' on conflict do nothing;
insert into public.shipping_rates(zone_id, code, name, fee_minor, currency, min_delivery_days, max_delivery_days, active)
select id, 'rwanda-standard', 'Rwanda standard delivery', 2000, 'RWF', 2, 7, true from public.shipping_zones where name = 'Rwanda' on conflict(code) do nothing;
alter table public.shipping_zones enable row level security;
alter table public.shipping_zone_countries enable row level security;
alter table public.shipping_rates enable row level security;
alter table public.order_shipping_quotes enable row level security;
create policy "Public active shipping zones" on public.shipping_zones for select using (active or public.is_admin());
create policy "Public shipping zone countries" on public.shipping_zone_countries for select using (exists(select 1 from public.shipping_zones z where z.id = zone_id and (z.active or public.is_admin())));
create policy "Public active shipping rates" on public.shipping_rates for select using (active or public.is_admin());
create policy "Admins manage shipping zones" on public.shipping_zones for all using (public.is_admin()) with check (public.is_admin());
create policy "Admins manage shipping countries" on public.shipping_zone_countries for all using (public.is_admin()) with check (public.is_admin());
create policy "Admins manage shipping rates" on public.shipping_rates for all using (public.is_admin()) with check (public.is_admin());
create policy "Owners read shipping quotes" on public.order_shipping_quotes for select using (exists(select 1 from public.orders o where o.id = order_id and (o.user_id = auth.uid() or public.is_admin())));

-- Discount lifecycle and immutable redemption records.
alter table public.discounts add column if not exists description text;
alter table public.discounts add column if not exists max_discount_minor bigint check (max_discount_minor is null or max_discount_minor >= 0);
alter table public.discounts add column if not exists per_customer_limit integer check (per_customer_limit is null or per_customer_limit > 0);
alter table public.discounts add column if not exists applies_to text not null default 'order' check (applies_to in ('order','product','category','shipping'));
alter table public.discounts add column if not exists product_ids uuid[] not null default '{}';
alter table public.discounts add column if not exists category_slugs text[] not null default '{}';
alter table public.discounts add constraint discounts_percentage_range_check check (kind <> 'percentage' or value between 1 and 100);
alter table public.discounts add constraint discounts_window_check check (ends_at is null or starts_at is null or ends_at > starts_at);
create unique index if not exists discounts_code_ci_idx on public.discounts(lower(code));
create table if not exists public.discount_redemptions(
  id uuid primary key default gen_random_uuid(),
  discount_id uuid not null references public.discounts(id) on delete restrict,
  order_id uuid not null unique references public.orders(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  code text not null,
  amount_minor bigint not null check (amount_minor >= 0),
  mode text not null check (mode in ('test','live')),
  created_at timestamptz not null default now()
);
create index if not exists discount_redemptions_user_idx on public.discount_redemptions(discount_id, user_id);
alter table public.discount_redemptions enable row level security;
create policy "Owners read own discount redemptions" on public.discount_redemptions for select using (user_id = auth.uid() or public.is_admin());
create policy "Admins manage discount redemptions" on public.discount_redemptions for all using (public.is_admin()) with check (public.is_admin());
alter table public.orders add column if not exists discount_code text;

-- Inventory ledger. Test checkout never reserves/decrements stock; verified live payment handling can use this ledger later.
create table if not exists public.inventory_movements(
  id uuid primary key default gen_random_uuid(),
  variant_id uuid not null references public.product_variants(id) on delete restrict,
  order_id uuid references public.orders(id) on delete set null,
  delta_quantity integer not null,
  quantity_after integer,
  reason text not null check (reason in ('opening_balance','manual_adjustment','payment_capture','reservation','reservation_release','refund_restock','return_received')),
  note text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);
create table if not exists public.inventory_reservations(
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  variant_id uuid not null references public.product_variants(id) on delete restrict,
  quantity integer not null check (quantity > 0),
  status text not null default 'active' check (status in ('active','committed','released','expired')),
  expires_at timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(order_id, variant_id)
);
create index if not exists inventory_reservations_active_idx on public.inventory_reservations(variant_id, status, expires_at);
alter table public.inventory_movements enable row level security;
alter table public.inventory_reservations enable row level security;
create policy "Admins manage inventory movements" on public.inventory_movements for all using (public.is_admin()) with check (public.is_admin());
create policy "Admins manage inventory reservations" on public.inventory_reservations for all using (public.is_admin()) with check (public.is_admin());
create or replace function public.admin_adjust_inventory(p_variant_id uuid, p_delta integer, p_reason text, p_note text)
returns integer language plpgsql security definer set search_path = public as $$
declare v_variant public.product_variants; v_quantity integer;
begin
  if not public.is_admin() then raise exception 'Administrator access required'; end if;
  if p_delta = 0 or p_reason not in ('opening_balance','manual_adjustment','refund_restock','return_received') then raise exception 'Invalid stock adjustment'; end if;
  select * into v_variant from public.product_variants where id = p_variant_id for update;
  if not found then raise exception 'Variant not found'; end if;
  if not v_variant.track_inventory then raise exception 'Inventory tracking is disabled for this variant'; end if;
  v_quantity := coalesce(v_variant.stock_quantity, 0) + p_delta;
  if v_quantity < 0 then raise exception 'Stock cannot become negative'; end if;
  update public.product_variants set stock_quantity = v_quantity, available = v_quantity > 0 where id = p_variant_id;
  insert into public.inventory_movements(variant_id, delta_quantity, quantity_after, reason, note, created_by) values(p_variant_id, p_delta, v_quantity, p_reason, nullif(trim(p_note),''), auth.uid());
  return v_quantity;
end $$;
revoke all on function public.admin_adjust_inventory(uuid, integer, text, text) from public;
grant execute on function public.admin_adjust_inventory(uuid, integer, text, text) to authenticated;

-- Returns/refunds, notifications, and immutable audit events for operations.
create table if not exists public.return_requests(
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete restrict,
  user_id uuid not null references auth.users(id) on delete restrict,
  reason text not null check (char_length(reason) between 10 and 1000),
  status text not null default 'requested' check (status in ('requested','approved','rejected','received','refunded','closed')),
  admin_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.return_request_items(
  return_request_id uuid not null references public.return_requests(id) on delete cascade,
  order_item_id uuid not null references public.order_items(id) on delete restrict,
  quantity integer not null check (quantity > 0),
  primary key(return_request_id, order_item_id)
);
alter table public.return_requests enable row level security;
alter table public.return_request_items enable row level security;
create policy "Owners read own return requests" on public.return_requests for select using (user_id = auth.uid() or public.is_admin());
create policy "Owners create own return requests" on public.return_requests for insert with check (user_id = auth.uid() and exists(select 1 from public.orders o where o.id = order_id and o.user_id = auth.uid()));
create policy "Admins manage return requests" on public.return_requests for all using (public.is_admin()) with check (public.is_admin());
create policy "Owners read return items" on public.return_request_items for select using (exists(select 1 from public.return_requests r where r.id = return_request_id and (r.user_id = auth.uid() or public.is_admin())));
create policy "Owners add return items" on public.return_request_items for insert with check (exists(select 1 from public.return_requests r join public.orders o on o.id = r.order_id join public.order_items oi on oi.id = order_item_id where r.id = return_request_id and r.user_id = auth.uid() and oi.order_id = o.id));
create policy "Admins manage return items" on public.return_request_items for all using (public.is_admin()) with check (public.is_admin());
create table if not exists public.notification_outbox(
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  email text,
  event_type text not null,
  payload jsonb not null default '{}'::jsonb,
  status text not null default 'pending' check (status in ('pending','sent','failed','disabled')),
  provider_message_id text,
  attempts integer not null default 0,
  last_error text,
  created_at timestamptz not null default now(),
  sent_at timestamptz
);
create table if not exists public.audit_events(
  id bigint generated always as identity primary key,
  actor_id uuid references auth.users(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id text,
  before_data jsonb,
  after_data jsonb,
  created_at timestamptz not null default now()
);
alter table public.notification_outbox enable row level security;
alter table public.audit_events enable row level security;
create policy "Admins manage notifications" on public.notification_outbox for all using (public.is_admin()) with check (public.is_admin());
create policy "Admins read audit events" on public.audit_events for select using (public.is_admin());

-- Consistent update timestamps.
create trigger user_roles_touch before update on public.user_roles for each row execute function public.touch_updated_at();
create trigger product_images_touch before update on public.product_images for each row execute function public.touch_updated_at();
create trigger wishlists_touch before update on public.wishlists for each row execute function public.touch_updated_at();
create trigger reviews_touch before update on public.product_reviews for each row execute function public.touch_updated_at();
create trigger contact_messages_touch before update on public.contact_messages for each row execute function public.touch_updated_at();
create trigger faq_entries_touch before update on public.faq_entries for each row execute function public.touch_updated_at();
create trigger content_pages_touch before update on public.content_pages for each row execute function public.touch_updated_at();
create trigger homepage_sections_touch before update on public.homepage_sections for each row execute function public.touch_updated_at();
create trigger shipping_zones_touch before update on public.shipping_zones for each row execute function public.touch_updated_at();
create trigger shipping_rates_touch before update on public.shipping_rates for each row execute function public.touch_updated_at();
create trigger inventory_reservations_touch before update on public.inventory_reservations for each row execute function public.touch_updated_at();
create trigger return_requests_touch before update on public.return_requests for each row execute function public.touch_updated_at();

-- Public projections are intentionally narrow and omit all supplier, cost, support, and staff data.
drop view if exists public.storefront_products;
drop view if exists public.admin_product_overview;
drop view if exists public.admin_dashboard_metrics;
create or replace view public.product_review_summary as
select p.id as product_id, coalesce(round(avg(r.rating)::numeric, 1), 0)::numeric as rating, count(r.id)::integer as review_count
from public.products p left join public.product_reviews r on r.product_id = p.id and r.status = 'approved'
group by p.id;
create or replace view public.storefront_product_reviews as
select r.id, r.product_id, r.rating, r.title, r.body, r.created_at, 'Verified customer'::text as author_name
from public.product_reviews r
where r.status = 'approved';
create or replace view public.storefront_collections as
select c.id, c.name, c.slug, c.description, c.banner_image_url, c.display_order,
coalesce((select jsonb_agg(jsonb_build_object('id', p.id, 'name', p.name, 'slug', p.slug, 'image_url', p.image_url) order by cp.display_order) from public.collection_products cp join public.products p on p.id = cp.product_id where cp.collection_id = c.id and p.published and p.status = 'active'), '[]'::jsonb) as products
from public.collections c where c.active and (c.starts_at is null or c.starts_at <= now()) and (c.ends_at is null or c.ends_at > now());
create or replace view public.storefront_faq_entries as select id, category, question, answer, display_order from public.faq_entries where published order by category, display_order, created_at;
create or replace view public.storefront_homepage_sections as select section_key, value from public.homepage_sections where public;
create or replace view public.storefront_shipping_rates as
select r.id, r.code, r.name, r.fee_minor, r.free_shipping_threshold_minor, r.currency, r.min_delivery_days, r.max_delivery_days,
coalesce(array_agg(zc.country_code) filter(where zc.country_code is not null), '{}') as country_codes
from public.shipping_rates r join public.shipping_zones z on z.id = r.zone_id left join public.shipping_zone_countries zc on zc.zone_id = z.id
where r.active and z.active group by r.id;
create or replace view public.storefront_products as
select p.id,p.name,p.slug,p.sku,p.description,p.short_description,p.category_slug,p.brand,p.image_url,p.specifications,p.featured,p.best_seller,p.promotion,p.published_at,p.updated_at,p.processing_estimate,p.delivery_estimate,p.product_type,p.tags,p.seo_title,p.seo_description,p.canonical_url,p.social_image_url,p.noindex,p.allow_backorders,p.preorder,p.low_stock_threshold,
coalesce(rs.rating, 0)::numeric as rating,coalesce(rs.review_count, 0)::integer as review_count,
coalesce((select jsonb_agg(jsonb_build_object('id',i.id,'src',i.src,'alt',i.alt,'position',i.position)order by i.position)from public.product_images i where i.product_id=p.id),'[]'::jsonb)images,
coalesce((select jsonb_agg(jsonb_build_object('id',v.id,'sku',v.sku,'name',v.name,'option_values',v.option_values,'price_minor',v.price_minor,'compare_at_minor',v.compare_at_minor,'currency',v.currency,'stock_quantity',v.stock_quantity,'track_inventory',v.track_inventory,'available',v.available)order by v.created_at)from public.product_variants v where v.product_id=p.id),'[]'::jsonb)variants
from public.products p left join public.product_review_summary rs on rs.product_id = p.id where p.published and p.status = 'active' and not exists(select 1 from public.product_variants v where v.product_id = p.id and v.currency <> 'RWF');
grant select on public.storefront_products, public.product_review_summary, public.storefront_product_reviews, public.storefront_collections, public.storefront_faq_entries, public.storefront_homepage_sections, public.storefront_shipping_rates to anon, authenticated;

-- Harden the test checkout boundary. The browser reaches only an Edge Function; direct old checkout RPC access is revoked.
revoke execute on function public.create_order_from_cart(jsonb, jsonb, text, uuid) from authenticated;
create or replace function public.server_prepare_test_checkout(
  p_user_id uuid,
  p_lines jsonb,
  p_address jsonb,
  p_shipping_rate_id uuid,
  p_discount_code text,
  p_idempotency_key uuid
) returns jsonb language plpgsql security definer set search_path = public as $$
declare v_order public.orders; v_subtotal bigint; v_shipping bigint; v_currency char(3); v_count integer; v_email text; v_fingerprint text; v_rate public.shipping_rates; v_discount public.discounts; v_discount_minor bigint := 0; v_eligible_subtotal bigint := 0; v_total bigint; v_estimate text;
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
  values(p_user_id, 'test', v_email, v_currency, v_subtotal, v_shipping, 0, v_discount_minor, v_total, p_address, v_rate.code, p_idempotency_key, v_fingerprint, case when v_discount.id is null then null else v_discount.code end) returning * into v_order;
  insert into public.order_items(order_id, product_id, variant_id, product_name, variant_name, sku, image_url, quantity, unit_price_minor, line_total_minor)
  select v_order.id, p.id, v.id, p.name, v.name, v.sku, p.image_url, x.quantity, v.price_minor, v.price_minor * x.quantity
  from (select (value->>'variantId')::uuid as variant_id, (value->>'quantity')::integer as quantity from jsonb_array_elements(p_lines)) x join public.product_variants v on v.id = x.variant_id join public.products p on p.id = v.product_id;
  insert into public.order_item_costs(order_item_id, supplier_product_cost_minor, supplier_shipping_cost_minor, packaging_cost_minor)
  select oi.id, coalesce(pp.supplier_cost_minor,0), coalesce(pp.supplier_shipping_minor,0), coalesce(pp.packaging_cost_minor + pp.other_unit_cost_minor,0)
  from public.order_items oi left join public.product_private pp on pp.product_id = oi.product_id where oi.order_id = v_order.id;
  insert into public.order_shipping_quotes(order_id, shipping_rate_id, method_name, delivery_estimate, fee_minor, currency) values(v_order.id, v_rate.id, v_rate.name, concat_ws('–', v_rate.min_delivery_days::text, v_rate.max_delivery_days::text, 'business days'), v_shipping, v_currency);
  if v_discount.id is not null then insert into public.discount_redemptions(discount_id, order_id, user_id, code, amount_minor, mode) values(v_discount.id, v_order.id, p_user_id, v_discount.code, v_discount_minor, 'test'); end if;
  insert into public.payments(order_id, provider, mode, status, amount_minor, currency, idempotency_key) values(v_order.id, 'test', 'test', 'pending', v_order.total_minor, v_order.currency, gen_random_uuid());
  insert into public.order_status_history(order_id, status, changed_by, note) values(v_order.id, 'pending_payment', p_user_id, 'Order created by server-validated test checkout');
  insert into public.audit_events(actor_id, action, entity_type, entity_id, after_data) values(p_user_id, 'checkout_created', 'order', v_order.id::text, jsonb_build_object('mode','test','total_minor',v_order.total_minor));
  return jsonb_build_object('orderId', v_order.id, 'orderNumber', v_order.order_number, 'totalMinor', v_order.total_minor, 'currency', v_order.currency, 'discountMinor', v_discount_minor, 'shippingMinor', v_shipping);
end $$;
revoke all on function public.server_prepare_test_checkout(uuid, jsonb, jsonb, uuid, text, uuid) from public;
grant execute on function public.server_prepare_test_checkout(uuid, jsonb, jsonb, uuid, text, uuid) to service_role;

-- Defense in depth for the existing test finalizer.
create or replace function public.finalize_test_payment(p_order_id uuid, p_user_id uuid, p_outcome text)
returns boolean language plpgsql security definer set search_path = public as $$
declare v_order public.orders; v_payment public.payments;
begin
  if p_outcome not in ('approve','decline') then raise exception 'Invalid test outcome'; end if;
  select * into v_order from public.orders where id = p_order_id and user_id = p_user_id for update;
  if not found or v_order.mode <> 'test' then raise exception 'Test order not found'; end if;
  select * into v_payment from public.payments where order_id = p_order_id and provider = 'test' and mode = 'test' order by created_at desc limit 1 for update;
  if not found then raise exception 'Test payment not found'; end if;
  if v_payment.status = 'succeeded' then return true; end if;
  if v_payment.status = 'failed' then return false; end if;
  if p_outcome = 'approve' then
    update public.payments set status = 'succeeded', updated_at = now() where id = v_payment.id;
    update public.orders set payment_status = 'succeeded', status = 'paid' where id = p_order_id;
    insert into public.notification_outbox(user_id, email, event_type, payload, status) values(p_user_id, v_order.customer_email, 'test_payment_succeeded', jsonb_build_object('orderNumber',v_order.order_number), 'disabled');
    return true;
  end if;
  update public.payments set status = 'failed', updated_at = now() where id = v_payment.id;
  update public.orders set payment_status = 'failed' where id = p_order_id;
  insert into public.notification_outbox(user_id, email, event_type, payload, status) values(p_user_id, v_order.customer_email, 'test_payment_failed', jsonb_build_object('orderNumber',v_order.order_number), 'disabled');
  return false;
end $$;
revoke all on function public.finalize_test_payment(uuid, uuid, text) from public;
grant execute on function public.finalize_test_payment(uuid, uuid, text) to service_role;

-- Manual product saves and safe archive rather than destructive catalog deletion.
create or replace function public.admin_save_product(p_product_id uuid, p_payload jsonb)
returns uuid language plpgsql security definer set search_path = public as $$
declare pid uuid := p_product_id; v jsonb; vid uuid; kept uuid[] := '{}'; published_value boolean := coalesce((p_payload->>'published')::boolean,false); v_currency char(3); v_image jsonb; v_position integer := 0;
begin
  v_currency := coalesce(nullif(p_payload->>'currency',''),'RWF');
  if not public.is_admin() then raise exception 'Administrator access required'; end if;
  if jsonb_typeof(p_payload->'variants') <> 'array' or jsonb_array_length(p_payload->'variants') < 1 then raise exception 'At least one variant is required'; end if;
  if (jsonb_typeof(p_payload->'images') <> 'array' or jsonb_array_length(p_payload->'images') < 1) and nullif(p_payload->>'imageUrl','') is null then raise exception 'At least one product image is required'; end if;
  if not exists(select 1 from public.categories where slug = p_payload->>'categorySlug') then raise exception 'Category is invalid'; end if;
  if v_currency <> 'RWF' then raise exception 'IBYIZAMART currently supports RWF manual products only'; end if;
  if pid is null then
    insert into public.products(name,slug,sku,category_slug,brand,description,short_description,image_url,source,status,published,featured,best_seller,promotion,processing_estimate,delivery_estimate,published_at,manual_entry_confirmed,product_type,tags,seo_title,seo_description,canonical_url,social_image_url,noindex,allow_backorders,preorder,low_stock_threshold,shipping_class,dimensions)
    values(p_payload->>'name',p_payload->>'slug',p_payload->>'sku',p_payload->>'categorySlug',nullif(p_payload->>'brand',''),p_payload->>'description',p_payload->>'shortDescription',nullif(p_payload->>'imageUrl',''),'manual',case when published_value then 'active' else 'draft' end,published_value,coalesce((p_payload->>'featured')::boolean,false),coalesce((p_payload->>'bestSeller')::boolean,false),coalesce((p_payload->>'promotion')::boolean,false),nullif(p_payload->>'processingEstimate',''),nullif(p_payload->>'deliveryEstimate',''),case when published_value then now() end,true,coalesce(nullif(p_payload->>'productType',''),'physical'),coalesce(array(select jsonb_array_elements_text(coalesce(p_payload->'tags','[]'::jsonb))), '{}'),nullif(p_payload->>'seoTitle',''),nullif(p_payload->>'seoDescription',''),nullif(p_payload->>'canonicalUrl',''),nullif(p_payload->>'socialImageUrl',''),coalesce((p_payload->>'noindex')::boolean,false),coalesce((p_payload->>'allowBackorders')::boolean,false),coalesce((p_payload->>'preorder')::boolean,false),greatest(coalesce((p_payload->>'lowStockThreshold')::integer,3),0),nullif(p_payload->>'shippingClass',''),coalesce(p_payload->'dimensions','{}'::jsonb)) returning id into pid;
  else
    update public.products set name=p_payload->>'name',slug=p_payload->>'slug',sku=p_payload->>'sku',category_slug=p_payload->>'categorySlug',brand=nullif(p_payload->>'brand',''),description=p_payload->>'description',short_description=p_payload->>'shortDescription',source='manual',status=case when published_value then 'active' else 'draft' end,published=published_value,featured=coalesce((p_payload->>'featured')::boolean,false),best_seller=coalesce((p_payload->>'bestSeller')::boolean,false),promotion=coalesce((p_payload->>'promotion')::boolean,false),processing_estimate=nullif(p_payload->>'processingEstimate',''),delivery_estimate=nullif(p_payload->>'deliveryEstimate',''),published_at=case when published_value then coalesce(published_at,now()) else published_at end,manual_entry_confirmed=true,product_type=coalesce(nullif(p_payload->>'productType',''),'physical'),tags=coalesce(array(select jsonb_array_elements_text(coalesce(p_payload->'tags','[]'::jsonb))), '{}'),seo_title=nullif(p_payload->>'seoTitle',''),seo_description=nullif(p_payload->>'seoDescription',''),canonical_url=nullif(p_payload->>'canonicalUrl',''),social_image_url=nullif(p_payload->>'socialImageUrl',''),noindex=coalesce((p_payload->>'noindex')::boolean,false),allow_backorders=coalesce((p_payload->>'allowBackorders')::boolean,false),preorder=coalesce((p_payload->>'preorder')::boolean,false),low_stock_threshold=greatest(coalesce((p_payload->>'lowStockThreshold')::integer,3),0),shipping_class=nullif(p_payload->>'shippingClass',''),dimensions=coalesce(p_payload->'dimensions','{}'::jsonb) where id=pid;
    if not found then raise exception 'Product not found'; end if;
  end if;
  for v in select value from jsonb_array_elements(p_payload->'variants') loop
    vid := nullif(v->>'id','')::uuid;
    if vid is null then select id into vid from public.product_variants where product_id = pid and sku = v->>'sku'; end if;
    if vid is not null and exists(select 1 from public.product_variants where id = vid and product_id = pid) then
      update public.product_variants set name=v->>'name',sku=v->>'sku',price_minor=(v->>'priceMinor')::bigint,compare_at_minor=nullif(v->>'compareAtMinor','')::bigint,currency=v_currency,stock_quantity=case when coalesce((v->>'trackInventory')::boolean,true) then greatest(coalesce((v->>'stockQuantity')::integer,0),0) else null end,track_inventory=coalesce((v->>'trackInventory')::boolean,true),available=case when coalesce((v->>'trackInventory')::boolean,true) then coalesce((p_payload->>'allowBackorders')::boolean,false) or coalesce((p_payload->>'preorder')::boolean,false) or coalesce((v->>'stockQuantity')::integer,0)>0 else true end,option_values=coalesce(v->'optionValues','{}'::jsonb),weight_grams=nullif(v->>'weightGrams','')::integer where id=vid;
    else
      insert into public.product_variants(product_id,name,sku,price_minor,compare_at_minor,currency,stock_quantity,track_inventory,available,option_values,weight_grams) values(pid,v->>'name',v->>'sku',(v->>'priceMinor')::bigint,nullif(v->>'compareAtMinor','')::bigint,v_currency,case when coalesce((v->>'trackInventory')::boolean,true) then greatest(coalesce((v->>'stockQuantity')::integer,0),0) else null end,coalesce((v->>'trackInventory')::boolean,true),case when coalesce((v->>'trackInventory')::boolean,true) then coalesce((p_payload->>'allowBackorders')::boolean,false) or coalesce((p_payload->>'preorder')::boolean,false) or coalesce((v->>'stockQuantity')::integer,0)>0 else true end,coalesce(v->'optionValues','{}'::jsonb),nullif(v->>'weightGrams','')::integer) returning id into vid;
    end if;
    kept := array_append(kept,vid);
  end loop;
  update public.product_variants set available = false where product_id = pid and not(id = any(kept));
  delete from public.product_images where product_id = pid;
  if jsonb_typeof(p_payload->'images') = 'array' and jsonb_array_length(p_payload->'images') > 0 then
    for v_image in select value from jsonb_array_elements(p_payload->'images') loop
      insert into public.product_images(product_id,src,alt,position,storage_path) values(pid,v_image->>'src',coalesce(nullif(v_image->>'alt',''),p_payload->>'name'),coalesce((v_image->>'position')::integer,v_position),nullif(v_image->>'storagePath',''));
      v_position := v_position + 1;
    end loop;
  elsif nullif(p_payload->>'imageUrl','') is not null then
    insert into public.product_images(product_id,src,alt,position) values(pid,p_payload->>'imageUrl',p_payload->>'name',0);
  end if;
  update public.products set image_url = (select src from public.product_images where product_id = pid order by position, created_at limit 1) where id = pid;
  insert into public.product_private(product_id,supplier_id,supplier_name,supplier_product_url,supplier_external_id,supplier_cost_minor,supplier_shipping_minor,packaging_cost_minor,other_unit_cost_minor,supplier_contact_notes)
  values(pid,nullif(p_payload->>'supplierId','')::uuid,nullif(p_payload->>'supplierName',''),nullif(p_payload->>'supplierWebsite',''),nullif(p_payload->>'supplierReference',''),greatest(coalesce((p_payload->>'supplierCostMinor')::bigint,0),0),greatest(coalesce((p_payload->>'supplierShippingMinor')::bigint,0),0),greatest(coalesce((p_payload->>'packagingCostMinor')::bigint,0),0),greatest(coalesce((p_payload->>'otherUnitCostMinor')::bigint,0),0),nullif(p_payload->>'supplierNotes',''))
  on conflict(product_id) do update set supplier_id=excluded.supplier_id,supplier_name=excluded.supplier_name,supplier_product_url=excluded.supplier_product_url,supplier_external_id=excluded.supplier_external_id,supplier_cost_minor=excluded.supplier_cost_minor,supplier_shipping_minor=excluded.supplier_shipping_minor,packaging_cost_minor=excluded.packaging_cost_minor,other_unit_cost_minor=excluded.other_unit_cost_minor,supplier_contact_notes=excluded.supplier_contact_notes,updated_at=now();
  insert into public.audit_events(actor_id,action,entity_type,entity_id,after_data) values(auth.uid(),'product_saved','product',pid::text,jsonb_build_object('published',published_value,'manual',true));
  return pid;
end $$;
revoke all on function public.admin_save_product(uuid, jsonb) from public;
grant execute on function public.admin_save_product(uuid, jsonb) to authenticated;
create or replace function public.admin_archive_product(p_product_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'Administrator access required'; end if;
  update public.products set status='archived', published=false where id=p_product_id;
  if not found then raise exception 'Product not found'; end if;
  insert into public.audit_events(actor_id,action,entity_type,entity_id) values(auth.uid(),'product_archived','product',p_product_id::text);
end $$;
revoke all on function public.admin_archive_product(uuid) from public;
grant execute on function public.admin_archive_product(uuid) to authenticated;


-- Public support/tracking endpoints use service-only functions after Edge Function validation and rate limiting.
create table if not exists public.tracking_rate_limits(
  rate_key text primary key,
  window_started_at timestamptz not null default now(),
  request_count integer not null default 0 check (request_count >= 0),
  updated_at timestamptz not null default now()
);
alter table public.tracking_rate_limits enable row level security;
create or replace function public.server_submit_contact_message(p_user_id uuid, p_name text, p_email text, p_order_number text, p_subject text, p_message text, p_rate_key text)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_limit public.contact_rate_limits; v_id uuid;
begin
  delete from public.contact_rate_limits where window_started_at < now() - interval '2 days';
  if char_length(trim(coalesce(p_name,''))) not between 2 and 120 or char_length(trim(coalesce(p_email,''))) not between 5 and 254 or char_length(trim(coalesce(p_subject,''))) not between 2 and 160 or char_length(trim(coalesce(p_message,''))) not between 10 and 4000 or char_length(coalesce(p_rate_key,'')) < 16 then raise exception 'Invalid support request'; end if;
  insert into public.contact_rate_limits(rate_key, request_count) values(p_rate_key, 0) on conflict(rate_key) do nothing;
  select * into v_limit from public.contact_rate_limits where rate_key = p_rate_key for update;
  if v_limit.window_started_at < now() - interval '1 hour' then update public.contact_rate_limits set window_started_at=now(),request_count=1,updated_at=now() where rate_key=p_rate_key;
  elsif v_limit.request_count >= 5 then raise exception 'Please wait before sending another message';
  else update public.contact_rate_limits set request_count=request_count+1,updated_at=now() where rate_key=p_rate_key; end if;
  insert into public.contact_messages(user_id,name,email,order_number,subject,message) values(p_user_id,trim(p_name),lower(trim(p_email)),nullif(trim(p_order_number),''),trim(p_subject),trim(p_message)) returning id into v_id;
  insert into public.notification_outbox(user_id,email,event_type,payload,status) values(p_user_id,lower(trim(p_email)),'support_message_received',jsonb_build_object('messageId',v_id),'disabled');
  return v_id;
end $$;
revoke all on function public.server_submit_contact_message(uuid,text,text,text,text,text,text) from public;
grant execute on function public.server_submit_contact_message(uuid,text,text,text,text,text,text) to service_role;
create or replace function public.server_track_order(p_order_number text, p_email text, p_rate_key text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_limit public.tracking_rate_limits; v_order public.orders; v_shipment public.shipments;
begin
  delete from public.tracking_rate_limits where window_started_at < now() - interval '2 days';
  if char_length(trim(coalesce(p_order_number,''))) < 6 or char_length(trim(coalesce(p_email,''))) < 5 or char_length(coalesce(p_rate_key,'')) < 16 then raise exception 'Invalid tracking request'; end if;
  insert into public.tracking_rate_limits(rate_key,request_count) values(p_rate_key,0) on conflict(rate_key) do nothing;
  select * into v_limit from public.tracking_rate_limits where rate_key=p_rate_key for update;
  if v_limit.window_started_at < now() - interval '1 hour' then update public.tracking_rate_limits set window_started_at=now(),request_count=1,updated_at=now() where rate_key=p_rate_key;
  elsif v_limit.request_count >= 10 then raise exception 'Please wait before trying again';
  else update public.tracking_rate_limits set request_count=request_count+1,updated_at=now() where rate_key=p_rate_key; end if;
  select * into v_order from public.orders where upper(order_number)=upper(trim(p_order_number)) and lower(customer_email)=lower(trim(p_email)) and mode='live' limit 1;
  if not found then raise exception 'Order not found'; end if;
  select * into v_shipment from public.shipments where order_id=v_order.id;
  return jsonb_build_object('orderNumber',v_order.order_number,'status',v_order.status,'paymentStatus',v_order.payment_status,'carrier',v_shipment.carrier,'trackingNumber',v_shipment.tracking_number,'createdAt',v_order.created_at);
end $$;
revoke all on function public.server_track_order(text,text,text) from public;
grant execute on function public.server_track_order(text,text,text) to service_role;

-- Expanded private admin projection for manual product editing; never grant this view to anonymous customers.
create or replace view public.admin_product_overview as
select p.*, pp.supplier_id, pp.supplier_name, pp.supplier_product_url, pp.supplier_external_id, pp.supplier_cost_minor, pp.supplier_shipping_minor, pp.packaging_cost_minor, pp.other_unit_cost_minor, pp.supplier_contact_notes,
coalesce(pp.supplier_cost_minor + pp.supplier_shipping_minor + pp.packaging_cost_minor + pp.other_unit_cost_minor, 0) as total_supplier_cost_minor,
coalesce((select min(v.currency) from public.product_variants v where v.product_id = p.id), 'RWF') as catalog_currency,
coalesce((select min(v.price_minor) from public.product_variants v where v.product_id = p.id), 0) as lowest_price_minor,
coalesce((select min(v.price_minor) from public.product_variants v where v.product_id = p.id), 0) - coalesce(pp.supplier_cost_minor + pp.supplier_shipping_minor + pp.packaging_cost_minor + pp.other_unit_cost_minor, 0) as estimated_gross_profit_minor,
coalesce((select jsonb_agg(jsonb_build_object('id',v.id,'name',v.name,'sku',v.sku,'price_minor',v.price_minor,'compare_at_minor',v.compare_at_minor,'currency',v.currency,'stock_quantity',v.stock_quantity,'track_inventory',v.track_inventory,'available',v.available,'option_values',v.option_values,'weight_grams',v.weight_grams) order by v.created_at) from public.product_variants v where v.product_id = p.id),'[]'::jsonb) as variants,
coalesce((select jsonb_agg(jsonb_build_object('id',i.id,'src',i.src,'alt',i.alt,'position',i.position,'storage_path',i.storage_path) order by i.position) from public.product_images i where i.product_id = p.id),'[]'::jsonb) as images
from public.products p left join public.product_private pp on pp.product_id = p.id where public.is_admin();
grant select on public.admin_product_overview to authenticated;

-- Admin-only reporting projections use verified live payment facts, never browser analytics events.
create or replace view public.admin_dashboard_metrics as
select
 count(*) filter(where mode = 'live')::bigint as total_orders,
 coalesce(sum(subtotal_minor) filter(where mode = 'live' and payment_status = 'succeeded'), 0)::bigint as gross_sales_minor,
 coalesce(sum(total_minor) filter(where mode = 'live' and payment_status = 'succeeded'), 0)::bigint as net_sales_minor,
 coalesce(avg(total_minor) filter(where mode = 'live' and payment_status = 'succeeded'), 0)::bigint as average_order_value_minor,
 coalesce(sum(total_minor - (select coalesce(sum(so.fulfillment_cost_minor), 0) from public.supplier_orders so where so.order_id = orders.id)) filter(where mode = 'live' and payment_status = 'succeeded'), 0)::bigint as gross_profit_minor,
 count(*) filter(where mode = 'live' and status in ('paid','awaiting_supplier_order'))::bigint as awaiting_fulfillment,
 count(*) filter(where mode = 'live' and payment_status = 'pending')::bigint as pending_payment,
 (select count(*) from public.product_variants v join public.products p on p.id = v.product_id where v.track_inventory and coalesce(v.stock_quantity,0) <= p.low_stock_threshold and p.status = 'active')::bigint as low_stock_products
from public.orders where public.is_admin();
create or replace view public.admin_sales_by_day as
select date_trunc('day', created_at)::date as day, count(*)::bigint as order_count, coalesce(sum(total_minor),0)::bigint as net_sales_minor
from public.orders where mode='live' and payment_status='succeeded' and public.is_admin() group by date_trunc('day', created_at) order by day;
create or replace view public.admin_low_stock as
select p.id as product_id,p.name,v.id as variant_id,v.name as variant_name,v.sku,v.stock_quantity,p.low_stock_threshold
from public.products p join public.product_variants v on v.product_id=p.id
where p.status='active' and v.track_inventory and coalesce(v.stock_quantity,0)<=p.low_stock_threshold and public.is_admin();
grant select on public.admin_dashboard_metrics, public.admin_sales_by_day, public.admin_low_stock to authenticated;

insert into public.categories(name, slug, description, image_url, published)
values ('Bags & Accessories', 'bags-accessories', 'Everyday carry and useful accessories.', 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?auto=format&fit=crop&w=900&q=80', true)
on conflict(slug) do nothing;

-- Category hierarchy and storefront ordering for manually managed navigation.
alter table public.categories add column if not exists parent_slug text references public.categories(slug) on delete set null;
alter table public.categories add column if not exists display_order integer not null default 0;
alter table public.categories add column if not exists seo_title text;
alter table public.categories add column if not exists seo_description text;
alter table public.categories add constraint categories_parent_not_self_check check (parent_slug is null or parent_slug <> slug);
create index if not exists categories_parent_display_idx on public.categories(parent_slug, display_order);

-- Reporting is intentionally limited to RWF until a reviewed exchange-rate/accounting system is configured.
create or replace view public.admin_dashboard_metrics as
select
 count(*) filter(where mode = 'live' and currency = 'RWF')::bigint as total_orders,
 coalesce(sum(subtotal_minor) filter(where mode = 'live' and payment_status = 'succeeded' and currency = 'RWF'), 0)::bigint as gross_sales_minor,
 coalesce(sum(total_minor) filter(where mode = 'live' and payment_status = 'succeeded' and currency = 'RWF'), 0)::bigint as net_sales_minor,
 coalesce(avg(total_minor) filter(where mode = 'live' and payment_status = 'succeeded' and currency = 'RWF'), 0)::bigint as average_order_value_minor,
 coalesce(sum(total_minor - (select coalesce(sum(so.fulfillment_cost_minor), 0) from public.supplier_orders so where so.order_id = orders.id)) filter(where mode = 'live' and payment_status = 'succeeded' and currency = 'RWF'), 0)::bigint as gross_profit_minor,
 count(*) filter(where mode = 'live' and status in ('paid','awaiting_supplier_order') and currency = 'RWF')::bigint as awaiting_fulfillment,
 count(*) filter(where mode = 'live' and payment_status = 'pending' and currency = 'RWF')::bigint as pending_payment,
 (select count(*) from public.product_variants v join public.products p on p.id = v.product_id where v.track_inventory and coalesce(v.stock_quantity,0) <= p.low_stock_threshold and p.status = 'active')::bigint as low_stock_products
from public.orders where public.is_admin();
create or replace view public.admin_sales_by_day as
select date_trunc('day', created_at)::date as day, count(*)::bigint as order_count, coalesce(sum(total_minor),0)::bigint as net_sales_minor
from public.orders where mode='live' and payment_status='succeeded' and currency='RWF' and public.is_admin() group by date_trunc('day', created_at) order by day;

-- Keep product-level backorder/preorder policy consistent when administrators adjust stock.
create or replace function public.admin_adjust_inventory(p_variant_id uuid, p_delta integer, p_reason text, p_note text)
returns integer language plpgsql security definer set search_path = public as $$
declare v_variant public.product_variants; v_product public.products; v_quantity integer;
begin
  if not public.is_admin() then raise exception 'Administrator access required'; end if;
  if p_delta = 0 or p_reason not in ('opening_balance','manual_adjustment','refund_restock','return_received') then raise exception 'Invalid stock adjustment'; end if;
  select * into v_variant from public.product_variants where id=p_variant_id for update;
  if not found then raise exception 'Variant not found'; end if;
  select * into v_product from public.products where id=v_variant.product_id;
  if not v_variant.track_inventory then raise exception 'Inventory tracking is disabled for this variant'; end if;
  v_quantity := coalesce(v_variant.stock_quantity, 0) + p_delta;
  if v_quantity < 0 then raise exception 'Stock cannot become negative'; end if;
  update public.product_variants set stock_quantity=v_quantity, available=(v_quantity > 0 or v_product.allow_backorders or v_product.preorder) where id=p_variant_id;
  insert into public.inventory_movements(variant_id,delta_quantity,quantity_after,reason,note,created_by) values(p_variant_id,p_delta,v_quantity,p_reason,nullif(trim(p_note),''),auth.uid());
  return v_quantity;
end $$;
revoke all on function public.admin_adjust_inventory(uuid, integer, text, text) from public;
grant execute on function public.admin_adjust_inventory(uuid, integer, text, text) to authenticated;

-- Base tables remain private; customer/public UI uses narrowly shaped views and controlled RPCs.
drop policy if exists "Public approved reviews" on public.product_reviews;
drop policy if exists "Users update own pending reviews" on public.product_reviews;
create policy "Owners read own reviews" on public.product_reviews for select using (user_id = auth.uid() or public.is_admin());
drop policy if exists "Owners read own contact messages" on public.contact_messages;
create or replace view public.customer_contact_messages as
select id, name, email, order_number, subject, message, status, created_at, updated_at
from public.contact_messages where user_id = auth.uid();
grant select on public.customer_contact_messages to authenticated;

commit;
