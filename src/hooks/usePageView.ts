import { useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import { trackEvent } from '@/services/analytics';

export function usePageView() {
  const location = useLocation();
  useEffect(() => { trackEvent('Page View', { path: `${location.pathname}${location.search}` }); window.scrollTo({ top: 0, behavior: 'instant' }); }, [location.pathname, location.search]);
}
