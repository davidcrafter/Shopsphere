import type { Product, SortOption } from '@/types/catalog';

export function currencyMinorDigits(currency: string) { return currency === 'RWF' ? 0 : 2; }
export function minorToDisplay(minor: number, currency: string) { return minor / (10 ** currencyMinorDigits(currency)); }
export function displayToMinor(value: number, currency: string) { return Math.round(value * (10 ** currencyMinorDigits(currency))); }
export function formatDate(value: string) { return new Intl.DateTimeFormat('en', { month: 'short', day: 'numeric', year: 'numeric' }).format(new Date(value)); }
export function formatMoney(minor: number, currency: string) { const digits = currencyMinorDigits(currency); return new Intl.NumberFormat(currency === 'RWF' ? 'en-RW' : 'en', { style: 'currency', currency, minimumFractionDigits: digits, maximumFractionDigits: digits }).format(minorToDisplay(minor, currency)); }
export function lowestPrice(product: Product) { const prices = product.variants.map((variant) => variant.priceMinor); return prices.length ? Math.min(...prices) : 0; }
export function activeVariantCount(product: Product) { return product.variants.filter((variant) => variant.available).length; }
export function filterProducts(products: Product[], options: { query?: string; category?: string; availability?: 'all' | 'in-stock'; sort?: SortOption; minPrice?: number; maxPrice?: number }) {
  const query = options.query?.trim().toLowerCase() || '';
  const filtered = products.filter((product) => {
    const price = minorToDisplay(lowestPrice(product), product.variants[0]?.currency ?? 'RWF');
    const searchable = `${product.name} ${product.brand ?? ''} ${product.category} ${product.shortDescription} ${(product.tags ?? []).join(' ')}`.toLowerCase();
    return (!query || searchable.includes(query)) && (!options.category || options.category === 'all' || product.category === options.category) && (options.availability !== 'in-stock' || product.variants.some((variant) => variant.available)) && (options.minPrice === undefined || price >= options.minPrice) && (options.maxPrice === undefined || price <= options.maxPrice);
  });
  return [...filtered].sort((left, right) => {
    switch (options.sort) {
      case 'featured': return Number(right.featured) - Number(left.featured) || new Date(right.publishedAt).getTime() - new Date(left.publishedAt).getTime();
      case 'name-asc': return left.name.localeCompare(right.name);
      case 'name-desc': return right.name.localeCompare(left.name);
      case 'price-asc': return lowestPrice(left) - lowestPrice(right);
      case 'price-desc': return lowestPrice(right) - lowestPrice(left);
      case 'rating-desc': return right.rating - left.rating || right.reviewCount - left.reviewCount;
      default: return new Date(right.publishedAt).getTime() - new Date(left.publishedAt).getTime();
    }
  });
}
