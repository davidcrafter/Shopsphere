import type { Product } from '@/types/catalog';
import { ProductCard } from './ProductCard';
import { EmptyState } from './States';
export function ProductGrid({ products, placement }: { products: Product[]; placement?: string }) { if (!products.length) return <EmptyState />; return <div className="product-grid">{products.map((product) => <ProductCard key={product.id} product={product} placement={placement} />)}</div>; }
