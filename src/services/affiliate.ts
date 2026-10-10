import type { Seller } from '@/types/catalog';

const amazonHosts = new Set(['amazon.com', 'www.amazon.com', 'amazon.co.uk', 'www.amazon.co.uk', 'amazon.ca', 'www.amazon.ca', 'amazon.de', 'www.amazon.de', 'amazon.fr', 'www.amazon.fr', 'amazon.es', 'www.amazon.es', 'amazon.it', 'www.amazon.it', 'amazon.com.au', 'www.amazon.com.au', 'amazon.co.jp', 'www.amazon.co.jp', 'amzn.to']);
const aliExpressHosts = new Set(['aliexpress.com', 'www.aliexpress.com', 'aliexpress.us', 'www.aliexpress.us', 's.click.aliexpress.com']);

export function isValidAffiliateUrl(url: string | undefined, seller: Seller): url is string {
  if (!url) return false;
  try {
    const parsed = new URL(url);
    const hosts = seller === 'amazon' ? amazonHosts : aliExpressHosts;
    return parsed.protocol === 'https:' && !parsed.username && !parsed.password && hosts.has(parsed.hostname.toLowerCase());
  } catch { return false; }
}
