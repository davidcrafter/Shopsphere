import { Mail, MessageCircle } from 'lucide-react';
import { Breadcrumbs } from '@/components/Breadcrumbs';
import { Seo } from '@/components/Seo';
import { siteConfig } from '@/config/site';

export function ContactPage() { return <><Seo title="Contact" description="Contact the ShopSphere editorial team about corrections, partnerships, and privacy requests." path="/contact" /><Breadcrumbs items={[{ label: 'Contact' }]} /><header className="page-hero page-hero--compact"><div className="container"><span className="eyebrow">We’re listening</span><h1>Contact ShopSphere</h1><p>Send corrections, product suggestions, business inquiries, or privacy requests to the appropriate address.</p></div></header><section className="section"><div className="container contact-grid"><div><Mail /><h2>Email us</h2><p>For general and editorial inquiries:</p><a className="button button--primary" href={`mailto:${siteConfig.contactEmail}`}>{siteConfig.contactEmail}</a></div><div><MessageCircle /><h2>Order support</h2><p>ShopSphere does not process orders. For delivery, payment, return, or refund help, contact the Amazon or AliExpress seller shown on your order confirmation.</p></div></div></section></>; }
