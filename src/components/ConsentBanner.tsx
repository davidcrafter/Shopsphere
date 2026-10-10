import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { disableAnalytics, hasAnalyticsConsent, hasConsentChoice, initializeAnalytics, setAnalyticsConsent } from '@/services/analytics';

function syncAnalytics() { const enabled = hasAnalyticsConsent() && import.meta.env.VITE_ANALYTICS_PROVIDER === 'plausible' && Boolean(import.meta.env.VITE_PLAUSIBLE_DOMAIN); if (!enabled) { disableAnalytics(); return; } initializeAnalytics(); if (document.getElementById('plausible-script')) return; const script = document.createElement('script'); script.id = 'plausible-script'; script.defer = true; script.dataset.domain = import.meta.env.VITE_PLAUSIBLE_DOMAIN; script.src = 'https://plausible.io/js/script.js'; document.head.appendChild(script); }
export function ConsentBanner() {
  const [visible, setVisible] = useState(!hasConsentChoice());
  useEffect(() => { const update = () => { setVisible(!hasConsentChoice()); syncAnalytics(); }; update(); window.addEventListener('shopsphere-consent-change', update); return () => window.removeEventListener('shopsphere-consent-change', update); }, []);
  if (!visible) return null;
  const decide = (granted: boolean) => { setAnalyticsConsent(granted); setVisible(false); };
  return <aside className="consent-banner" aria-label="Cookie preferences"><p><strong>Your privacy, your choice.</strong> We use optional privacy-friendly analytics only with your consent. Affiliate links work either way. <Link to="/cookies">Learn more</Link>.</p><div><button className="button button--ghost" onClick={() => decide(false)}>Decline analytics</button><button className="button button--primary" onClick={() => decide(true)}>Allow analytics</button></div></aside>;
}
