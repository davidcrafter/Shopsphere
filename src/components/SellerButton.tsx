import { ExternalLink } from 'lucide-react';
import { isValidAffiliateUrl } from '@/services/affiliate';
import { trackAffiliateClick } from '@/services/analytics';
import type { Seller } from '@/types/catalog';

export function SellerButton({ seller, url, productId, placement, compact = false }: { seller: Seller; url?: string; productId: string; placement: string; compact?: boolean }) {
  if (!isValidAffiliateUrl(url, seller)) return null;
  const label = seller === 'amazon' ? 'View on Amazon' : 'View on AliExpress';
  return <a className={`seller-button seller-button--${seller} ${compact ? 'seller-button--compact' : ''}`} href={url} target="_blank" rel="sponsored nofollow noopener noreferrer" onClick={() => trackAffiliateClick(productId, seller, placement)}>{label}<ExternalLink size={15} aria-hidden="true" /><span className="sr-only"> (opens in a new tab)</span></a>;
}
