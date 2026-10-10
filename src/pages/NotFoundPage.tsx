import { ArrowLeft, SearchX } from 'lucide-react';
import { Link } from 'react-router-dom';
import { Seo } from '@/components/Seo';
export function NotFoundPage() { return <><Seo title="Page not found" description="The page you requested could not be found." path="/404" noindex /><section className="not-found container"><SearchX /><span className="eyebrow">Error 404</span><h1>This page wandered off.</h1><p>The link may be outdated, or the product may no longer be published.</p><div><Link className="button button--primary" to="/"><ArrowLeft size={17} /> Back home</Link><Link className="button button--secondary" to="/shop">Browse products</Link></div></section></>; }
