import type { Product, Seller, SortOption } from '@/types/catalog';

export function formatDate(value: string) { return new Intl.DateTimeFormat('en', { month: 'short', day: 'numeric', year: 'numeric' }).format(new Date(value)); }
export function formatPrice(amount: number, currency: string) { return new Intl.NumberFormat('en', { style: 'currency', currency }).format(amount); }
export function filterProducts(products: Product[], options: { query?: string; category?: string; seller?: Seller | 'all'; sort?: SortOption; minPrice?: number; maxPrice?: number }) {
  const query = options.query?.trim().toLowerCase() || '';
  const filtered = products.filter((product) => {
    const haystack = `${product.name} ${product.brand ?? ''} ${product.category} ${product.shortDescription}`.toLowerCase(); const price = product.price && !product.price.isDemo ? product.price.amount : null; const priceMatches = options.minPrice === undefined && options.maxPrice === undefined ? true : price !== null && (options.minPrice === undefined || price >= options.minPrice) && (options.maxPrice === undefined || price <= options.maxPrice);
    return (!query || haystack.includes(query)) && (!options.category || options.category === 'all' || product.category === options.category) && (!options.seller || options.seller === 'all' || product.availableSellers.includes(options.seller)) && priceMatches;
  });
  return filtered.sort((a, b) => { switch (options.sort) { case 'name-asc': return a.name.localeCompare(b.name); case 'name-desc': return b.name.localeCompare(a.name); case 'price-asc': return (a.price?.amount ?? Number.POSITIVE_INFINITY) - (b.price?.amount ?? Number.POSITIVE_INFINITY); case 'price-desc': return (b.price?.amount ?? -1) - (a.price?.amount ?? -1); default: return new Date(b.publishedAt).getTime() - new Date(a.publishedAt).getTime(); } });
}
