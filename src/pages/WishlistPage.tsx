import { Heart } from 'lucide-react';
import { Link } from 'react-router-dom';
import { Breadcrumbs } from '@/components/Breadcrumbs';
import { ProductGrid } from '@/components/ProductGrid';
import { Seo } from '@/components/Seo';
import { useCatalog } from '@/hooks/useCatalog';
import { useWishlist } from '@/providers/WishlistProvider';
import { useAuth } from '@/providers/AuthProvider';
export function WishlistPage() { const { products } = useCatalog(); const { productIds } = useWishlist(); const { user } = useAuth(); const saved = products.filter((product) => productIds.has(product.id)); return <><Seo title="Your Wishlist" description="Saved IBYIZAMART products." path="/wishlist" noindex /><Breadcrumbs items={[{ label: 'Wishlist' }]} /><header className="page-hero page-hero--compact"><div className="container"><span className="eyebrow">Saved for later</span><h1>Your Wishlist</h1><p>{user ? 'Your saved products are available across your signed-in sessions.' : 'Your wishlist is saved in this browser. Sign in to sync it to your account.'}</p></div></header><section className="section"><div className="container">{saved.length ? <ProductGrid products={saved} /> : <div className="state-card"><Heart size={38} /><h2>Your wishlist is empty</h2><p>Save products you want to compare or return to later.</p><Link className="button button--primary" to="/shop">Browse products</Link></div>}</div></section></>; }
