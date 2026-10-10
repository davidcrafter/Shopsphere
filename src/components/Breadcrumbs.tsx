import { ChevronRight, Home } from 'lucide-react';
import { Link } from 'react-router-dom';

export interface Crumb { label: string; to?: string; }
export function Breadcrumbs({ items }: { items: Crumb[] }) {
  return <nav className="breadcrumbs container" aria-label="Breadcrumb"><ol><li><Link to="/" aria-label="Home"><Home size={15} /></Link></li>{items.map((item) => <li key={item.label}><ChevronRight size={14} aria-hidden="true" />{item.to ? <Link to={item.to}>{item.label}</Link> : <span aria-current="page">{item.label}</span>}</li>)}</ol></nav>;
}
