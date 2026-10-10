import { ShoppingBag } from 'lucide-react';
import { Link } from 'react-router-dom';
import { siteConfig } from '@/config/site';

export function BrandLogo({ inverse = false }: { inverse?: boolean }) {
  return <Link to="/" className={`brand-logo ${inverse ? 'brand-logo--inverse' : ''}`} aria-label={`${siteConfig.brand} home`}><span className="brand-logo__mark"><ShoppingBag size={20} strokeWidth={2.4} /></span><span>{siteConfig.brand}</span></Link>;
}
