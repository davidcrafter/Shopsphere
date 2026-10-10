import { Eye, Star } from 'lucide-react';
import { useState } from 'react';
import { Link } from 'react-router-dom';
import type { Product } from '@/types/catalog';
import { activeVariantCount, lowestPrice } from '@/utils/catalog';
import { AddToCartButton } from './product/AddToCartButton';
import { ProductPrice } from './product/ProductPrice';
import { QuickViewModal } from './product/QuickViewModal';
import { WishlistButton } from './product/WishlistButton';

export function ProductCard({ product }: { product: Product }) {
  const [quickView, setQuickView] = useState(false); const available = product.variants.filter((variant) => variant.available || product.allowBackorders || product.preorder); const single = available.length === 1 ? available[0] : null; const priceVariant = product.variants.find((variant) => variant.priceMinor === lowestPrice(product)) ?? product.variants[0];
  return <article className="product-card"><div className="product-card__image"><Link to={`/product/${product.slug}`}><img src={product.images[0]?.src || '/favicon.svg'} alt={product.images[0]?.alt || product.name} loading="lazy" width="640" height="640" /></Link>{product.isDemo && <span className="badge badge--demo">Demo product</span>}{!available.length && <span className="badge badge--sold">Unavailable</span>}<WishlistButton productId={product.id} /><button className="quick-view-trigger" aria-label={`Quick view ${product.name}`} onClick={() => setQuickView(true)}><Eye size={17} /></button></div><div className="product-card__body"><span className="eyebrow">{product.category.replace('-', ' ')}</span><h3><Link to={`/product/${product.slug}`}>{product.name}</Link></h3><p>{product.shortDescription}</p>{priceVariant && <ProductPrice variant={priceVariant} from={product.variants.length > 1} />}{product.reviewCount > 0 && <div className="product-rating" aria-label={`${product.rating} out of 5 from ${product.reviewCount} reviews`}><Star size={14} fill="currentColor" /><span>{product.rating.toFixed(1)} ({product.reviewCount})</span></div>}<div className="product-card__actions">{single ? <AddToCartButton product={product} variant={single} /> : <Link className="button button--primary" to={`/product/${product.slug}`}>{activeVariantCount(product) ? 'Choose options' : 'View product'}</Link>}<button className="button button--secondary" onClick={() => setQuickView(true)}>Quick view</button></div></div><QuickViewModal product={product} open={quickView} onClose={() => setQuickView(false)} /></article>;
}
