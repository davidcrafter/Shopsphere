import { WifiOff } from 'lucide-react';
import { Link } from 'react-router-dom';
import { Seo } from '@/components/Seo';
export function OfflinePage() { return <><Seo title="Connection unavailable" description="IBYIZAMART needs a connection to load live store data." path="/offline" noindex /><section className="not-found container"><WifiOff /><span className="eyebrow">Connection unavailable</span><h1>Check your internet connection.</h1><p>Some saved browser features may remain available, but live products, orders, and support require a connection.</p><div><button className="button button--primary" onClick={() => window.location.reload()}>Try again</button><Link className="button button--secondary" to="/">Back home</Link></div></section></>; }
