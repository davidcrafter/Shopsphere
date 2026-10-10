-- ShopSphere initial data layer. Apply with the Supabase CLI or SQL editor.
create extension if not exists pgcrypto;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public
as $$ select coalesce((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin', false); $$;

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  description text not null default '',
  image_url text,
  published boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.products (
  id uuid primary key default gen_random_uuid(),
  external_id text unique,
  name text not null check (char_length(name) between 2 and 240),
  slug text not null unique check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  description text not null default '',
  short_description text not null default '',
  category_slug text not null,
  brand text,
  image_url text,
  gallery_urls jsonb not null default '[]'::jsonb,
  amazon_affiliate_url text,
  aliexpress_affiliate_url text,
  source text not null default 'manual' check (source in ('manual','amazon','aliexpress')),
  price_amount numeric(12,2) check (price_amount is null or price_amount >= 0),
  currency char(3) check (currency is null or currency in ('USD','EUR','GBP','CAD','AUD')),
  previous_price_amount numeric(12,2),
  price_verified_at timestamptz,
  rating numeric(2,1) check (rating is null or rating between 0 and 5),
  review_count integer check (review_count is null or review_count >= 0),
  rating_verified_at timestamptz,
  specifications jsonb not null default '{}'::jsonb,
  research_notes jsonb,
  featured boolean not null default false,
  trending boolean not null default false,
  deal boolean not null default false,
  published boolean not null default false,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint verified_price_requires_date check (price_amount is null or price_verified_at is not null),
  constraint verified_rating_requires_date check (rating is null or rating_verified_at is not null),
  constraint amazon_https check (amazon_affiliate_url is null or amazon_affiliate_url ~ '^https://'),
  constraint aliexpress_https check (aliexpress_affiliate_url is null or aliexpress_affiliate_url ~ '^https://')
);
create index products_public_catalog_idx on public.products (published, published_at desc);
create index products_category_idx on public.products (category_slug) where published = true;

create table public.blog_articles (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  slug text not null unique,
  excerpt text not null default '',
  category text not null,
  featured_image_url text,
  body jsonb not null default '[]'::jsonb,
  researched_guide boolean not null default true,
  published boolean not null default false,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.newsletter_subscribers (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  consented_at timestamptz not null,
  source text not null default 'website',
  status text not null default 'subscribed' check (status in ('subscribed','unsubscribed','pending')),
  created_at timestamptz not null default now()
);
create unique index newsletter_email_unique on public.newsletter_subscribers (lower(email));

create table public.affiliate_click_events (
  id bigint generated always as identity primary key,
  product_id text not null check (char_length(product_id) <= 100),
  seller text not null check (seller in ('amazon','aliexpress')),
  placement text not null check (char_length(placement) <= 100),
  occurred_at timestamptz not null default now()
);
create index affiliate_click_events_time_idx on public.affiliate_click_events (occurred_at desc);

alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.blog_articles enable row level security;
alter table public.newsletter_subscribers enable row level security;
alter table public.affiliate_click_events enable row level security;

create policy "Published categories are public" on public.categories for select using (published = true or public.is_admin());
create policy "Admins manage categories" on public.categories for all using (public.is_admin()) with check (public.is_admin());
create policy "Published products are public" on public.products for select using (published = true or public.is_admin());
create policy "Admins manage products" on public.products for all using (public.is_admin()) with check (public.is_admin());
create policy "Published articles are public" on public.blog_articles for select using (published = true or public.is_admin());
create policy "Admins manage articles" on public.blog_articles for all using (public.is_admin()) with check (public.is_admin());
create policy "Anyone may subscribe" on public.newsletter_subscribers for insert to anon, authenticated with check (char_length(email) <= 254 and consented_at <= now());
create policy "Admins review subscribers" on public.newsletter_subscribers for select using (public.is_admin());
create policy "Admins update subscribers" on public.newsletter_subscribers for update using (public.is_admin()) with check (public.is_admin());
create policy "Admins delete subscribers" on public.newsletter_subscribers for delete using (public.is_admin());
create policy "Consent-based client may record clicks" on public.affiliate_click_events for insert to anon, authenticated with check (occurred_at <= now());
create policy "Admins review click events" on public.affiliate_click_events for select using (public.is_admin());

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated;
