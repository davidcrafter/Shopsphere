# ShopSphere

A production-oriented affiliate product discovery website built with React, TypeScript, Vite, Tailwind CSS, React Router, Lucide, Zod, and optional Supabase. ShopSphere never takes payment: visitors complete purchases on the external seller's website.

## What is included

- Premium responsive homepage in the requested section order
- 18 required route types plus a protected AliExpress import route
- Typed product model supporting Amazon-only, AliExpress-only, both, or no configured seller
- Seller-domain validation and `sponsored nofollow noopener noreferrer` outbound links
- Working search, category/seller filters, sorting, pagination, and client-side recommendations filter
- Unique product, category, article, guide, static, legal, and 404 templates
- Clearly labeled demonstration catalog with no fabricated prices, ratings, discounts, reviews, or affiliate URLs
- Optional live Supabase catalog, newsletter storage, affiliate click events, admin auth, and Row Level Security
- AliExpress approved-export importer at `/admin/import`; imported items are unpublished drafts
- Consent-gated Plausible events and consent-gated Supabase click events
- Dynamic page title, description, canonical and Open Graph metadata; accurate article structured data
- Sitemap, robots rules, accessible focus styles, skip link, responsive images, and reduced-motion support
- Netlify and Vercel SPA deployment configuration

## Architecture

```text
src/
  components/       shared cards, forms, navigation, SEO, states, pagination
  components/layout site shell
  config/           brand and global site settings
  data/             clearly labeled local demo products, categories, guides
  hooks/            catalog provider and page-view behavior
  pages/            reusable route templates
  services/         Supabase, affiliate validation, analytics, newsletter, import
  types/            catalog domain model
  utils/            search, filtering, sorting, formatting
supabase/
  migrations/       tables, constraints, indexes, RLS policies
public/              crawl files and SPA fallback
```

Change the temporary brand, slogan, description, contact defaults, navigation, and social links in `src/config/site.ts`.

## Local setup

Requirements: Node.js 20.19+ or 22.12+ and npm.

```bash
cp .env.example .env.local
npm install
npm run dev
```

Production checks:

```bash
npm run typecheck
npm run lint
npm run build
npm run preview
```

Do not commit `.env.local`.

## Environment variables

| Variable | Required | Purpose |
|---|---:|---|
| `VITE_SITE_URL` | Before launch | Production origin used by canonical metadata; also replace `example.com` in `public/sitemap.xml` and `public/robots.txt` |
| `VITE_CONTACT_EMAIL` | Before launch | Public editorial/privacy email |
| `VITE_SUPABASE_URL` | For persistence/import | Supabase project URL; safe public project identifier |
| `VITE_SUPABASE_ANON_KEY` | For persistence/import | Supabase anon/publishable key protected by RLS |
| `VITE_ANALYTICS_PROVIDER` | Optional | Set to `plausible` to enable consent-gated analytics |
| `VITE_PLAUSIBLE_DOMAIN` | Optional | Site domain configured in Plausible |

Never put an Amazon secret key, AliExpress App Secret, Supabase service-role key, or any private credential in a `VITE_*` variable. Vite exposes these values to browsers.

## Supabase and newsletter setup

1. Create a Supabase project.
2. Apply `supabase/migrations/001_initial.sql` with the Supabase SQL editor or CLI.
3. Configure the public URL and anon key in `.env.local`.
4. Enable Email OTP in Supabase Auth and add `https://YOUR-DOMAIN/admin/import` as an allowed redirect.
5. Create an administrator and set `app_metadata.role` to `admin` using the Supabase dashboard or trusted server code. A browser must never assign its own role.
6. Test RLS with anonymous, ordinary authenticated, and admin users.

The newsletter form stores a real record only when Supabase is configured. Otherwise it displays a setup error and never shows fake success. Before a public launch, place signup behind a rate-limited Supabase Edge Function with CAPTCHA and implement confirmed opt-in if your jurisdiction or email provider requires it.

## Importing AliExpress products

The implemented workflow does not scrape AliExpress and does not need private API credentials in the browser:

1. Obtain approval for the AliExpress affiliate program and create product-specific promotion links in its approved affiliate portal/tools.
2. Export CSV or JSON with these fields: `product_id`, `product_title`, `promotion_link`, `image_url`, `category`, optional `product_description`, optional `target_sale_price`, and optional `target_sale_price_currency`.
3. Use a configured ShopSphere category slug (`electronics`, `fashion`, `home`, `beauty`, `sports`, `toys-hobbies`) or its full display name.
4. Sign in at `/admin/import`, paste the export, validate the preview, and import.
5. Imported products are always `published = false`. Review descriptions, usage rights for images, destination URLs, seller information, policy compliance, and current data before publishing.
6. Imported target prices are intentionally not displayed. Set `price_amount`, a supported `currency`, and `price_verified_at` only when your approved data source and affiliate agreement allow price display.

For fully automated AliExpress synchronization, build a server-side Supabase Edge Function using the current official Affiliate API documentation and your approved **App Key, App Secret, tracking ID, and affiliate account approval**. API details and signing must not be guessed or implemented until those credentials and the current account-specific documentation are available.

## Adding Amazon or manual products

Add rows through a secure Supabase admin workflow or dashboard. Each product has separate `amazon_affiliate_url` and `aliexpress_affiliate_url` fields. The UI renders only a seller button whose product-specific URL passes the corresponding domain validation.

For automated Amazon data, eligible publishers need Amazon Associates approval and Product Advertising API credentials: **Access Key, Secret Key, Partner/Associate Tag, marketplace, and API eligibility**. Keep API secrets server-side. Follow the current Product Advertising API license for images, price freshness, caching, availability, and attribution.

Never paste one generic affiliate URL onto every product. Never manufacture an ASIN, AliExpress product ID, promotion URL, price, discount, rating, review count, testing claim, or stock status.

## Product publishing checklist

- Replace demo content or leave the “Demo listing” label intact.
- Use an original useful description, key considerations, and research disclosure.
- Confirm each outbound URL resolves to the exact product and preserves the issued tracking parameters.
- Confirm you are permitted to use and cache each product image.
- Enter price/rating data only from an approved source with a verification timestamp.
- Confirm seller, shipping, return, warranty, and regional details on the destination page.
- Publish only after compliance review.

## Deployment

### Netlify

Connect the repository. Netlify reads `netlify.toml`, runs `npm run build`, publishes `dist`, and applies the SPA fallback and security headers.

### Vercel

Import the repository as a Vite project. Vercel reads `vercel.json`; use `npm run build` and output directory `dist`.

Set production environment variables in the host dashboard. After assigning the real domain, update `VITE_SITE_URL`, every `example.com` URL in `public/sitemap.xml` and `public/robots.txt`, Supabase Auth redirect URLs, and analytics configuration.

## Launch items requiring your credentials or approval

1. AliExpress affiliate approval and product-specific promotion links; App Key/App Secret/tracking ID only for a later server-side automated sync.
2. Amazon Associates tag and approved product links; Product Advertising API credentials only for approved server-side live data.
3. Supabase project URL and anon/publishable key; secure administrator assignment and Auth email configuration.
4. A production domain and public business/contact email.
5. Plausible account/domain if analytics is desired.
6. Transactional email/CAPTCHA provider if confirmed newsletter opt-in is required.
7. Your legal entity, address, jurisdiction, retention periods, processors, and qualified legal review.
8. Properly licensed product images. The included remote Unsplash images are development visuals; review their current license and replace them with your own or affiliate-program-approved assets before launch.

## Current scope and phase two

The public website, persistent data layer, newsletter, click-event storage, secure admin authentication, and AliExpress draft importer are included. A full visual CRUD dashboard for editing products/categories/articles and subscriber analytics is intentionally not faked; use the protected Supabase dashboard initially. A phase-two dashboard can be built against the supplied RLS-protected tables without changing the public templates.

## Verification performed in this workspace

| Check | Result |
|---|---|
| Workspace inspection | Passed — workspace was empty before scaffolding |
| TypeScript/TSX syntax transpilation | Passed for every source file |
| Static route inventory | Passed — all requested routes and custom 404 are registered |
| Internal navigation target audit | Passed — independent source audit found matching registered routes |
| Affiliate URL controls | Passed — 8 automated security and seller-domain cases |
| Sitemap XML syntax | Passed |
| Price range behavior | Implemented and conditionally displayed only when verified live prices exist |
| Catalog search/filter/sort logic | Passed — 6 automated query, category, seller, price, sort, and empty-result cases |
| Demo data compliance | Passed by source audit — no demo price, rating, review, discount, stock claim, or affiliate URL |
| Responsive/accessibility source review | Passed — responsive breakpoints, semantic landmarks, labels, skip link, focus and reduced-motion styles |
| `npm install` | Blocked by sandbox network policy (`403 Forbidden` from npm registry) |
| Full TypeScript typecheck/build/lint/runtime browser test | Not executable here because dependencies could not be downloaded; run the production checks above in a network-enabled environment before deployment |

The inability to install packages is reported rather than treating a syntax-only check as a successful production build.

## Legal and affiliate compliance

The legal pages are editable starter content and visibly marked for business-specific legal review. ShopSphere does not claim an official partnership with Amazon or AliExpress. Affiliate click events are not purchase conversions; only seller/network reports can confirm a qualifying purchase.
