import { ArrowRight, BadgeCheck, ExternalLink, ShieldCheck, Sparkles } from 'lucide-react';
import { useState } from 'react';
import { Link } from 'react-router-dom';
import { articles } from '@/data/articles';
import { categories } from '@/data/categories';
import { useCatalog } from '@/hooks/useCatalog';
import { BlogCard } from '@/components/BlogCard';
import { CategoryCard } from '@/components/CategoryCard';
import { NewsletterForm } from '@/components/NewsletterForm';
import { ProductGrid } from '@/components/ProductGrid';
import { SearchBar } from '@/components/SearchBar';
import { SectionHeading } from '@/components/SectionHeading';
import { Seo } from '@/components/Seo';
import { ErrorState, LoadingSkeleton } from '@/components/States';

const filters = [['all', 'All'], ['electronics', 'Electronics'], ['fashion', 'Fashion'], ['home', 'Home'], ['beauty', 'Beauty'], ['sports', 'Sports']] as const;

export function HomePage() {
  const { products, loading, error, refresh } = useCatalog(); const [filter, setFilter] = useState('all');
  const trending = products.filter((product) => product.trending).slice(0, 5);
  const handpicked = products.filter((product) => product.featured && (filter === 'all' || product.category === filter)).slice(0, 5);
  return <>
    <Seo title="ShopSphere — Discover. Compare. Save." description="Explore carefully selected products, researched buying guides, and product-specific links to Amazon and AliExpress." path="/" jsonLd={{ '@context': 'https://schema.org', '@type': 'WebSite', name: 'ShopSphere', url: window.location.origin, potentialAction: { '@type': 'SearchAction', target: `${window.location.origin}/search?q={search_term_string}`, 'query-input': 'required name=search_term_string' } }} />
    <section className="hero"><div className="container hero-grid"><div className="hero-copy"><span className="eyebrow eyebrow--blue">Top picks from Amazon & AliExpress</span><h1>Discover Amazing Products at the Best Prices</h1><p>Find top-rated products, trending gadgets, fashion, home essentials, and more — all in one place. We bring you product recommendations from Amazon and AliExpress.</p><SearchBar prominent /><div className="hero-actions"><Link className="button button--primary button--large" to="/shop">Explore Products <ArrowRight size={18} /></Link><Link className="button button--secondary button--large" to="/deals">Browse Deals</Link></div><ul className="trust-list"><li><BadgeCheck />Carefully Selected Products</li><li><ShieldCheck />Shop Securely on the Seller's Website</li><li><Sparkles />Product Offers and Recommendations</li></ul></div><div className="hero-visual"><div className="hero-image-wrap"><img src="https://images.unsplash.com/photo-1496181133206-80ce9b88a853?auto=format&fit=crop&w=1400&q=90" alt="Laptop and useful everyday technology on a clean desk" width="1200" height="1000" fetchPriority="high" /><div className="floating-card floating-card--top"><span>Curated</span><strong>Useful finds</strong></div><div className="floating-card floating-card--bottom"><ShieldCheck /><span><strong>Independent</strong><small>Research-led guides</small></span></div></div></div></div></section>

    <section className="section"><div className="container"><SectionHeading title="Shop by Category" subtitle="Explore our most popular categories and find exactly what you need." /><div className="category-grid">{categories.map((category) => <CategoryCard category={category} key={category.slug} />)}</div></div></section>

    <section className="section section--soft"><div className="container"><SectionHeading eyebrow="Popular now" title="Trending Products" subtitle="Discover popular finds and products worth exploring." action={<Link className="text-link" to="/trending">View trending <ArrowRight size={16} /></Link>} />{error && <ErrorState message={error} retry={() => void refresh()} />}{loading && !trending.length ? <LoadingSkeleton /> : <ProductGrid products={trending} placement="homepage-trending" />}</div></section>

    <section className="section"><div className="container"><div className="promo-banner"><img src="https://images.unsplash.com/photo-1556740749-887f6717d7e4?auto=format&fit=crop&w=1800&q=85" alt="A shopper browsing products online" loading="lazy" width="1600" height="700" /><div className="promo-banner__overlay" /><div className="promo-banner__content"><span className="eyebrow">Curated recommendations</span><h2>Today's Best Deals</h2><p>Discover offers and save on products worth considering. Prices and availability are always confirmed on the seller’s website.</p><Link className="button button--light" to="/deals">Browse Deals <ArrowRight size={18} /></Link></div></div></div></section>

    <section className="section"><div className="container"><SectionHeading eyebrow="Picked with purpose" title="Handpicked for You" subtitle="Useful products across the categories you care about." action={<Link className="text-link" to="/shop">View all products <ArrowRight size={16} /></Link>} /><div className="filter-pills" role="group" aria-label="Filter recommended products">{filters.map(([value, label]) => <button className={filter === value ? 'active' : ''} onClick={() => setFilter(value)} aria-pressed={filter === value} key={value}>{label}</button>)}</div><ProductGrid products={handpicked} placement="homepage-handpicked" /></div></section>

    <section className="section section--soft"><div className="container"><SectionHeading eyebrow="Learn before you buy" title="Latest Blog & Buying Guides" subtitle="Clear, research-led guidance for more confident choices." action={<Link className="text-link" to="/blog">View all guides <ArrowRight size={16} /></Link>} /><div className="blog-grid">{articles.slice(0, 4).map((article) => <BlogCard article={article} key={article.slug} />)}</div></div></section>

    <section className="section newsletter-section"><div className="container"><div className="newsletter-banner"><div><span className="eyebrow">Smarter shopping, in your inbox</span><h2>Get the Best Deals & New Arrivals</h2><p>Receive useful product recommendations, buying guides, and occasional offers.</p></div><NewsletterForm /></div></div></section>

    <aside className="affiliate-strip"><div className="container"><ExternalLink size={18} /><p><strong>How ShopSphere works:</strong> We research and organize useful products. When available, seller buttons take you directly to Amazon or AliExpress to complete your purchase. We may earn a commission from qualifying purchases.</p><Link to="/affiliate-disclosure">Read our disclosure</Link></div></aside>
  </>;
}
