import { RefreshCw, ServerCrash } from 'lucide-react';
import { Link } from 'react-router-dom';
import { Seo } from '@/components/Seo';
export function ServerErrorPage() { return <><Seo title="Something went wrong" description="A temporary store error occurred." path="/500" noindex /><section className="not-found container"><ServerCrash /><span className="eyebrow">Error 500</span><h1>We could not complete that request.</h1><p>Please try again. If the issue continues, contact customer support.</p><div><button className="button button--primary" onClick={() => window.location.reload()}><RefreshCw size={17} />Try again</button><Link className="button button--secondary" to="/contact">Contact support</Link></div></section></>; }
