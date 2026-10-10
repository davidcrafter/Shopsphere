import { ArrowUpRight } from 'lucide-react';
import { Link } from 'react-router-dom';
import { formatPrice } from '@/utils/catalog';
import { isValidAffiliateUrl } from '@/services/affiliate';
import type { Product } from '@/types/catalog';
import { SellerButton } from './SellerButton';

export function ProductCard({ product, placement = 'product-grid' }: { product: Product; placement?: string }) {
  const hasLink = isValidAffiliateUrl(product.affiliateUrls.amazon, 'amazon') || isValidAffiliateUrl(product.affiliateUrls.aliexpress, 'aliexpress');
  return <article className="product-card">
    <Link className="product-card__image" to={`/product/${product.slug}`}><img src={product.images[0]?.src || '/favicon.svg'} alt={product.images[0]?.alt || product.name} loading="lazy" width="640" height="640" />{product.isDemo && <span className="badge badge--demo">Demo listing</span>}</Link>
    <div className="product-card__body"><span className="eyebrow">{product.category.replace('-', ' ')}</span><h3><Link to={`/product/${product.slug}`}>{product.name}</Link></h3><p>{product.shortDescription}</p>
      <div className="product-card__price">{product.price && !product.price.isDemo ? <><strong>{formatPrice(product.price.amount, product.price.currency)}</strong><small>Verified {new Date(product.price.verifiedAt).toLocaleDateString()}</small></> : <span>Check seller for current price</span>}</div>
      <div className="product-card__actions"><SellerButton compact seller="amazon" url={product.affiliateUrls.amazon} productId={product.id} placement={placement} /><SellerButton compact seller="aliexpress" url={product.affiliateUrls.aliexpress} productId={product.id} placement={placement} />{!hasLink && <span className="link-pending">Seller link pending verification</span>}</div>
      <Link className="details-link" to={`/product/${product.slug}`}>View product details <ArrowUpRight size={16} /></Link>
    </div>
  </article>;
}
