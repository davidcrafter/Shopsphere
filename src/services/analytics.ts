import type { Seller } from '@/types/catalog';
import { supabase } from './supabase';

type EventProperties = Record<string, string | number | boolean | undefined>;
type Plausible = ((event: string, options?: { props?: EventProperties }) => void) & { q?: unknown[][] };
const consentKey = 'shopsphere-analytics-consent';

export function hasAnalyticsConsent() { return localStorage.getItem(consentKey) === 'granted'; }
export function setAnalyticsConsent(granted: boolean) { localStorage.setItem(consentKey, granted ? 'granted' : 'denied'); window.dispatchEvent(new Event('shopsphere-consent-change')); }
export function hasConsentChoice() { return localStorage.getItem(consentKey) !== null; }
export function initializeAnalytics() { const target = window as Window & { plausible?: Plausible }; if (target.plausible) return; const queue: Plausible = ((...args: unknown[]) => { queue.q = queue.q || []; queue.q.push(args); }) as Plausible; target.plausible = queue; }
export function disableAnalytics() { document.getElementById('plausible-script')?.remove(); delete (window as Window & { plausible?: Plausible }).plausible; }
export function trackEvent(name: string, properties: EventProperties = {}) { if (!hasAnalyticsConsent() || import.meta.env.VITE_ANALYTICS_PROVIDER !== 'plausible') return; (window as Window & { plausible?: Plausible }).plausible?.(name, { props: properties }); }
export function trackAffiliateClick(productId: string, seller: Seller, placement: string) { if (!hasAnalyticsConsent()) return; const occurredAt = new Date().toISOString(); trackEvent('Affiliate Link Click', { productId, seller, placement, timestamp: occurredAt }); if (supabase) void supabase.from('affiliate_click_events').insert({ product_id: productId, seller, placement, occurred_at: occurredAt }); }
