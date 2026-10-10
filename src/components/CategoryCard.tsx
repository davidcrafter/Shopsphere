import { ArrowRight } from 'lucide-react';
import { Link } from 'react-router-dom';
import type { Category } from '@/types/catalog';

export function CategoryCard({ category }: { category: Category }) { return <Link className="category-card" to={`/category/${category.slug}`}><img src={category.image} alt="" loading="lazy" width="500" height="500" /><span className="category-card__shade" /><span className="category-card__content"><strong>{category.name}</strong><small>{category.description}</small><span>Shop now <ArrowRight size={14} /></span></span></Link>; }
