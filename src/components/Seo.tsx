import { useEffect } from 'react';
import { siteConfig } from '@/config/site';

interface SeoProps { title: string; description: string; path?: string; image?: string; type?: 'website' | 'article'; noindex?: boolean; jsonLd?: object; }
function upsertMeta(selector: string, attributes: Record<string, string>) { let element = document.head.querySelector<HTMLMetaElement>(selector); if (!element) { element = document.createElement('meta'); document.head.appendChild(element); } Object.entries(attributes).forEach(([key, value]) => element!.setAttribute(key, value)); }

export function Seo({ title, description, path = '/', image, type = 'website', noindex = false, jsonLd }: SeoProps) {
  useEffect(() => {
    const fullTitle = title.includes(siteConfig.brand) ? title : `${title} | ${siteConfig.brand}`;
    const url = new URL(path, siteConfig.url).toString();
    document.title = fullTitle;
    upsertMeta('meta[name="description"]', { name: 'description', content: description });
    upsertMeta('meta[property="og:title"]', { property: 'og:title', content: fullTitle });
    upsertMeta('meta[property="og:description"]', { property: 'og:description', content: description });
    upsertMeta('meta[property="og:type"]', { property: 'og:type', content: type });
    upsertMeta('meta[property="og:url"]', { property: 'og:url', content: url });
    upsertMeta('meta[name="twitter:card"]', { name: 'twitter:card', content: image ? 'summary_large_image' : 'summary' });
    const oldOgImage = document.head.querySelector('meta[property="og:image"]'); const oldTwitterImage = document.head.querySelector('meta[name="twitter:image"]');
    if (image) { upsertMeta('meta[property="og:image"]', { property: 'og:image', content: image }); upsertMeta('meta[name="twitter:image"]', { name: 'twitter:image', content: image }); } else { oldOgImage?.remove(); oldTwitterImage?.remove(); }
    upsertMeta('meta[name="robots"]', { name: 'robots', content: noindex ? 'noindex, nofollow' : 'index, follow' });
    let canonical = document.head.querySelector<HTMLLinkElement>('link[rel="canonical"]'); if (!canonical) { canonical = document.createElement('link'); canonical.rel = 'canonical'; document.head.appendChild(canonical); } canonical.href = url;
    document.getElementById('page-jsonld')?.remove();
    if (jsonLd) { const script = document.createElement('script'); script.id = 'page-jsonld'; script.type = 'application/ld+json'; script.text = JSON.stringify(jsonLd); document.head.appendChild(script); }
  }, [title, description, path, image, type, noindex, jsonLd]);
  return null;
}
