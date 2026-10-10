import { z } from 'zod';
import { categories } from '@/data/categories';
import { isValidAffiliateUrl } from './affiliate';

const supportedCategoryValues = new Set(categories.flatMap((category) => [category.slug, category.name.toLowerCase()]));
function resolveCategory(value: string) { const normalized = value.trim().toLowerCase(); return categories.find((category) => category.slug === normalized || category.name.toLowerCase() === normalized)?.slug; }
const rowSchema = z.object({
  product_id: z.coerce.string().min(1),
  product_title: z.string().min(2),
  promotion_link: z.string().url().refine((url) => isValidAffiliateUrl(url, 'aliexpress'), 'Use an HTTPS URL from an approved AliExpress host.'),
  image_url: z.string().url().refine((url) => new URL(url).protocol === 'https:', 'Product images must use HTTPS.'),
  category: z.string().min(1).refine((value) => supportedCategoryValues.has(value.trim().toLowerCase()), 'Use one of the configured ShopSphere category names or slugs.'),
  product_description: z.string().default(''),
  target_sale_price: z.coerce.number().positive().optional(),
  target_sale_price_currency: z.string().length(3).default('USD'),
});
export type AliExpressImportRow = z.infer<typeof rowSchema>;

function parseCsvLine(line: string) { const result: string[] = []; let value = ''; let quoted = false; for (let i = 0; i < line.length; i += 1) { const char = line[i]; if (char === '"' && line[i + 1] === '"') { value += '"'; i += 1; } else if (char === '"') quoted = !quoted; else if (char === ',' && !quoted) { result.push(value.trim()); value = ''; } else value += char; } if (quoted) throw new Error('Multiline quoted CSV fields are not supported. Export JSON or remove line breaks inside fields.'); result.push(value.trim()); return result; }
function slugify(value: string) { return value.toLowerCase().normalize('NFKD').replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '').slice(0, 90); }

export function parseAliExpressImport(input: string): AliExpressImportRow[] {
  const trimmed = input.trim(); if (!trimmed) throw new Error('Paste an approved AliExpress export first.'); let rows: unknown[];
  if (trimmed.startsWith('[')) rows = JSON.parse(trimmed) as unknown[];
  else { const lines = trimmed.split(/\r?\n/).filter(Boolean); const headers = parseCsvLine(lines[0]); rows = lines.slice(1).map((line) => { const values = parseCsvLine(line); return Object.fromEntries(headers.map((header, index) => [header.trim(), values[index] ?? ''])); }); }
  return z.array(rowSchema).min(1).max(500).parse(rows);
}

export function toProductRows(rows: AliExpressImportRow[]) { return rows.map((row) => ({ external_id: `aliexpress:${row.product_id}`, name: row.product_title, slug: `${slugify(row.product_title)}-${row.product_id}`, description: row.product_description || 'Product information imported from an approved AliExpress affiliate export. Verify all details before publishing.', short_description: row.product_description?.slice(0, 180) || 'Imported draft — verify product details before publishing.', category_slug: resolveCategory(row.category)!, image_url: row.image_url, aliexpress_affiliate_url: row.promotion_link, currency: row.target_sale_price_currency.toUpperCase(), price_amount: null, price_verified_at: null, source: 'aliexpress', published: false, featured: false, trending: false, deal: false })); }
