import type { ProductVariant } from '@/types/catalog';
import { formatMoney } from '@/utils/catalog';
export function ProductPrice({ variant, from = false }: { variant: ProductVariant; from?: boolean }) { return <div className="detail-price"><strong>{from && 'From '}{formatMoney(variant.priceMinor, variant.currency)}</strong>{variant.compareAtMinor && variant.compareAtMinor > variant.priceMinor && <><del>{formatMoney(variant.compareAtMinor, variant.currency)}</del><span className="sale-badge">Save {formatMoney(variant.compareAtMinor - variant.priceMinor, variant.currency)}</span></>}</div>; }
