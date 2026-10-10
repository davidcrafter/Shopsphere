import { ShoppingBag } from 'lucide-react';
import { useCart } from '@/providers/CartProvider';
import { useToast } from '@/providers/ToastProvider';
import type { Product, ProductVariant } from '@/types/catalog';
export function AddToCartButton({ product, variant, quantity = 1, large = false, onAdded }: { product: Product; variant: ProductVariant | undefined; quantity?: number; large?: boolean; onAdded?: () => void }) { const { addItem } = useCart(); const { notify } = useToast(); const unavailable = (!variant?.available && !product.allowBackorders && !product.preorder) || product.isDemo; return <button className={`button button--primary ${large ? 'button--large' : ''}`} disabled={unavailable} onClick={() => { if (!variant || product.isDemo) return; addItem(variant.id, quantity); notify(`${product.name} was added to your cart.`, 'success'); onAdded?.(); }}><ShoppingBag size={large ? 18 : 16} />{product.isDemo ? 'Demo only' : unavailable ? 'Unavailable' : 'Add to Cart'}</button>; }
