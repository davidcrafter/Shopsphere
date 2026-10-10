import { ArrowUpRight } from 'lucide-react';
import { Link } from 'react-router-dom';
import type { Article } from '@/types/catalog';
import { formatDate } from '@/utils/catalog';

export function BlogCard({ article }: { article: Article }) { return <article className="blog-card"><Link to={`/blog/${article.slug}`}><img src={article.image} alt="" loading="lazy" width="800" height="520" /></Link><div><span className="eyebrow">{article.category}</span><h3><Link to={`/blog/${article.slug}`}>{article.title}</Link></h3><p>{article.excerpt}</p><div className="blog-card__meta"><time dateTime={article.publishedAt}>{formatDate(article.publishedAt)}</time><span>{article.readMinutes} min read</span></div><Link className="details-link" to={`/blog/${article.slug}`}>Read more <ArrowUpRight size={16} /></Link></div></article>; }
