import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';
import { demoProducts } from '@/data/products';
import { isValidAffiliateUrl } from '@/services/affiliate';
import { isSupabaseConfigured, supabase } from '@/services/supabase';
import type { CurrencyCode, Product, ProductPrice, ProductRating, Seller } from '@/types/catalog';

interface CatalogState { products: Product[]; loading: boolean; error: string | null; refresh: () => Promise<void>; }
const CatalogContext = createContext<CatalogState | null>(null);
type DbRow = Record<string, unknown>;
const currencies = new Set<CurrencyCode>(['USD', 'EUR', 'GBP', 'CAD', 'AUD']);
function asString(value: unknown, fallback = '') { return typeof value === 'string' ? value : fallback; }
function mapPrice(amountValue: unknown, currencyValue: unknown, verifiedValue: unknown): ProductPrice | null { const amount = Number(amountValue); const currency = asString(currencyValue).toUpperCase() as CurrencyCode; if (!Number.isFinite(amount) || amount < 0 || !currencies.has(currency) || typeof verifiedValue !== 'string') return null; return { amount, currency, verifiedAt: verifiedValue }; }
function mapRating(value: unknown, countValue: unknown, verifiedValue: unknown): ProductRating | null { const rating = Number(value); const reviewCount = Number(countValue); if (!Number.isFinite(rating) || rating < 0 || rating > 5 || !Number.isInteger(reviewCount) || reviewCount < 0 || typeof verifiedValue !== 'string') return null; return { value: rating, reviewCount, verifiedAt: verifiedValue }; }
function mapSpecifications(value: unknown) { if (!value || typeof value !== 'object' || Array.isArray(value)) return {}; return Object.fromEntries(Object.entries(value).filter((entry): entry is [string, string] => typeof entry[1] === 'string')); }
function mapRow(row: DbRow): Product {
  const imageUrl = asString(row.image_url); const rawAmazon = asString(row.amazon_affiliate_url); const rawAli = asString(row.aliexpress_affiliate_url); const amazonUrl = isValidAffiliateUrl(rawAmazon, 'amazon') ? rawAmazon : undefined; const aliUrl = isValidAffiliateUrl(rawAli, 'aliexpress') ? rawAli : undefined;
  const availableSellers: Seller[] = [...(amazonUrl ? ['amazon' as const] : []), ...(aliUrl ? ['aliexpress' as const] : [])]; const price = mapPrice(row.price_amount, row.currency, row.price_verified_at); const previousPrice = mapPrice(row.previous_price_amount, row.currency, row.price_verified_at);
  return { id: asString(row.id), name: asString(row.name, 'Untitled product'), slug: asString(row.slug), description: asString(row.description), shortDescription: asString(row.short_description), category: asString(row.category_slug, 'uncategorized'), brand: typeof row.brand === 'string' ? row.brand : null, images: imageUrl ? [{ src: imageUrl, alt: asString(row.name, 'Product image') }] : [], affiliateUrls: { amazon: amazonUrl, aliexpress: aliUrl }, availableSellers, price, previousPrice, rating: mapRating(row.rating, row.review_count, row.rating_verified_at), featured: Boolean(row.featured), trending: Boolean(row.trending), deal: Boolean(row.deal), published: Boolean(row.published), publishedAt: asString(row.published_at, asString(row.created_at, new Date().toISOString())), lastPriceVerificationDate: price?.verifiedAt ?? null, specifications: mapSpecifications(row.specifications), research: null, relatedGuideSlugs: [], isDemo: false };
}

export function CatalogProvider({ children }: { children: ReactNode }) {
  const [remote, setRemote] = useState<Product[]>([]); const [loading, setLoading] = useState(isSupabaseConfigured); const [error, setError] = useState<string | null>(null);
  const refresh = async () => { if (!supabase) { setLoading(false); return; } setLoading(true); setError(null); const { data, error: queryError } = await supabase.from('products').select('*').eq('published', true).order('published_at', { ascending: false }); if (queryError) setError('The live catalog could not be loaded. Demonstration products are still available.'); else setRemote((data ?? []).map((row) => mapRow(row as DbRow)).filter((product) => product.id && product.slug)); setLoading(false); };
  useEffect(() => { void refresh(); }, []);
  const value = useMemo(() => { const remoteSlugs = new Set(remote.map((product) => product.slug)); return { products: [...remote, ...demoProducts.filter((product) => !remoteSlugs.has(product.slug))], loading, error, refresh }; }, [remote, loading, error]);
  return <CatalogContext.Provider value={value}>{children}</CatalogContext.Provider>;
}
export function useCatalog() { const value = useContext(CatalogContext); if (!value) throw new Error('useCatalog must be used within CatalogProvider'); return value; }
