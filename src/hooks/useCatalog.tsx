import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';
import { demoProducts } from '@/data/products';
import { categories as fallbackCategories } from '@/data/categories';
import { isSupabaseConfigured, supabase } from '@/services/supabase';
import type { Category, CurrencyCode, Product, ProductVariant } from '@/types/catalog';

interface CatalogState { products: Product[]; categories: Category[]; loading: boolean; error: string | null; refresh: () => Promise<void>; }
const CatalogContext = createContext<CatalogState | null>(null);
type Row = Record<string, unknown>;
const currencies = new Set<CurrencyCode>(['RWF', 'USD', 'EUR', 'GBP', 'CAD', 'AUD']);
const text = (value: unknown, fallback = '') => typeof value === 'string' ? value : fallback;
const bool = (value: unknown) => value === true;
const int = (value: unknown, fallback = 0) => Number.isFinite(Number(value)) ? Number(value) : fallback;

function mapVariant(raw: unknown): ProductVariant | null {
  if (!raw || typeof raw !== 'object') return null;
  const row = raw as Row; const price = int(row.price_minor, -1); const currency = text(row.currency, 'RWF') as CurrencyCode;
  if (!text(row.id) || !text(row.sku) || !Number.isInteger(price) || price < 0 || !currencies.has(currency)) return null;
  return { id: text(row.id), sku: text(row.sku), name: text(row.name, 'Standard'), optionValues: row.option_values && typeof row.option_values === 'object' ? row.option_values as Record<string, string> : {}, priceMinor: price, compareAtMinor: Number.isInteger(int(row.compare_at_minor, Number.NaN)) ? int(row.compare_at_minor) : null, currency, stockQuantity: row.stock_quantity === null ? null : int(row.stock_quantity), trackInventory: bool(row.track_inventory), available: bool(row.available), allowBackorders: bool(row.allow_backorders), preorder: bool(row.preorder), weightGrams: row.weight_grams === null ? null : int(row.weight_grams) };
}
function mapProduct(row: Row): Product | null {
  const variants = Array.isArray(row.variants) ? row.variants.map(mapVariant).filter((variant): variant is ProductVariant => Boolean(variant)) : [];
  if (!text(row.id) || !text(row.slug) || !variants.length) return null;
  const imageRows = Array.isArray(row.images) ? row.images.filter((value) => value && typeof value === 'object').map((value) => { const image = value as Row; return { id: text(image.id), src: text(image.src), alt: text(image.alt, text(row.name)), position: int(image.position), storagePath: typeof image.storage_path === 'string' ? image.storage_path : null }; }).filter((image) => image.src) : [];
  const images = imageRows.length ? imageRows : text(row.image_url) ? [{ src: text(row.image_url), alt: text(row.name), position: 0 }] : [];
  return { id: text(row.id), name: text(row.name), slug: text(row.slug), sku: text(row.sku), description: text(row.description), shortDescription: text(row.short_description), category: text(row.category_slug), brand: typeof row.brand === 'string' ? row.brand : null, images, variants, specifications: row.specifications && typeof row.specifications === 'object' ? row.specifications as Record<string, string> : {}, featured: bool(row.featured), bestSeller: bool(row.best_seller), promotion: bool(row.promotion), status: 'active', publishedAt: text(row.published_at), updatedAt: text(row.updated_at), processingEstimate: typeof row.processing_estimate === 'string' ? row.processing_estimate : null, deliveryEstimate: typeof row.delivery_estimate === 'string' ? row.delivery_estimate : null, rating: int(row.rating), reviewCount: int(row.review_count), productType: text(row.product_type, 'physical'), tags: Array.isArray(row.tags) ? row.tags.filter((tag): tag is string => typeof tag === 'string') : [], noindex: bool(row.noindex), allowBackorders: bool(row.allow_backorders), preorder: bool(row.preorder), isDemo: false };
}

export function CatalogProvider({ children }: { children: ReactNode }) {
  const demosEnabled = !isSupabaseConfigured && import.meta.env.VITE_ENABLE_DEMO_DATA !== 'false';
  const [remote, setRemote] = useState<Product[]>([]); const [remoteCategories, setRemoteCategories] = useState<Category[]>([]); const [loading, setLoading] = useState(isSupabaseConfigured); const [error, setError] = useState<string | null>(null);
  const refresh = async () => {
    if (!supabase) { setLoading(false); return; }
    setLoading(true); setError(null);
    const [productsResult, categoriesResult] = await Promise.all([supabase.from('storefront_products').select('*').order('published_at', { ascending: false }), supabase.from('categories').select('id,name,slug,description,image_url,parent_slug').eq('published', true).order('name')]);
    if (productsResult.error) setError('The live catalog could not be loaded. Please try again.'); else setRemote((productsResult.data ?? []).map((row) => mapProduct(row as Row)).filter((product): product is Product => Boolean(product)));
    if (!categoriesResult.error) setRemoteCategories((categoriesResult.data ?? []).map((row) => ({ id: text(row.id), name: text(row.name), slug: text(row.slug), description: text(row.description), image: text(row.image_url), parentSlug: typeof row.parent_slug === 'string' ? row.parent_slug : null })).filter((category) => category.slug && category.image));
    setLoading(false);
  };
  useEffect(() => { void refresh(); }, []);
  const value = useMemo(() => ({ products: remote.length || isSupabaseConfigured ? remote : demosEnabled ? demoProducts : [], categories: remoteCategories.length ? remoteCategories : fallbackCategories, loading, error, refresh }), [remote, remoteCategories, demosEnabled, loading, error]);
  return <CatalogContext.Provider value={value}>{children}</CatalogContext.Provider>;
}
export function useCatalog() { const value = useContext(CatalogContext); if (!value) throw new Error('useCatalog must be used inside CatalogProvider'); return value; }
