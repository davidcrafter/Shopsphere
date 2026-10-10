import { Link } from 'react-router-dom';
import { siteConfig } from '@/config/site';
import { BrandLogo } from '../BrandLogo';

const categoryLinks = [['Electronics', '/category/electronics'], ['Fashion', '/category/fashion'], ['Home & Living', '/category/home'], ['Beauty', '/category/beauty'], ['Sports', '/category/sports']];
const quickLinks = [['Home', '/'], ['Shop', '/shop'], ['Blog', '/blog'], ['About', '/about'], ['Contact', '/contact'], ['FAQ', '/faq']];
const legalLinks = [['Affiliate Disclosure', '/affiliate-disclosure'], ['Privacy Policy', '/privacy-policy'], ['Terms and Conditions', '/terms'], ['Cookie Preferences', '/cookies']];
function FooterLinks({ title, links }: { title: string; links: string[][] }) { return <div><h2>{title}</h2><ul>{links.map(([label, to]) => <li key={to}><Link to={to}>{label}</Link></li>)}</ul></div>; }
export function Footer() { return <footer className="site-footer"><div className="container footer-grid"><div className="footer-brand"><BrandLogo inverse /><strong>{siteConfig.slogan}</strong><p>{siteConfig.description}</p></div><FooterLinks title="Popular Categories" links={categoryLinks} /><FooterLinks title="Quick Links" links={quickLinks} /><FooterLinks title="Legal" links={legalLinks} /></div><div className="container footer-bottom"><p><strong>Affiliate disclosure:</strong> We may earn a commission from qualifying purchases made through seller links, at no extra cost to you. ShopSphere is independent and does not claim an official partnership with Amazon or AliExpress.</p><span>© {new Date().getFullYear()} {siteConfig.brand}. All rights reserved.</span></div></footer>; }
