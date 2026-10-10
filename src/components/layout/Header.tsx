import { ChevronDown, Menu, Search, X } from 'lucide-react';
import { useEffect, useRef, useState } from 'react';
import { NavLink, useLocation } from 'react-router-dom';
import { categories } from '@/data/categories';
import { siteConfig } from '@/config/site';
import { BrandLogo } from '../BrandLogo';
import { SearchBar } from '../SearchBar';

export function Header() {
  const [menuOpen, setMenuOpen] = useState(false); const [searchOpen, setSearchOpen] = useState(false); const [categoriesOpen, setCategoriesOpen] = useState(false); const location = useLocation(); const categoryRef = useRef<HTMLDivElement>(null);
  useEffect(() => { setMenuOpen(false); setSearchOpen(false); setCategoriesOpen(false); }, [location.pathname, location.search]);
  useEffect(() => { const close = (event: MouseEvent) => { if (categoryRef.current && !categoryRef.current.contains(event.target as Node)) setCategoriesOpen(false); }; document.addEventListener('click', close); return () => document.removeEventListener('click', close); }, []);
  return <header className="site-header"><div className="container header-inner"><BrandLogo /><nav className={`main-nav ${menuOpen ? 'main-nav--open' : ''}`} aria-label="Primary navigation">{siteConfig.nav.slice(0, 2).map((item) => <NavLink key={item.to} to={item.to}>{item.label}</NavLink>)}<div className="nav-dropdown" ref={categoryRef}><button aria-expanded={categoriesOpen} onClick={() => setCategoriesOpen((open) => !open)}>Categories <ChevronDown size={15} /></button>{categoriesOpen && <div className="nav-dropdown__menu">{categories.map((category) => <NavLink key={category.slug} to={`/category/${category.slug}`}>{category.name}</NavLink>)}</div>}</div>{siteConfig.nav.slice(2).map((item) => <NavLink key={item.to} to={item.to}>{item.label}</NavLink>)}</nav><div className="header-actions"><button className="icon-button desktop-only" aria-label="Open search" aria-expanded={searchOpen} onClick={() => setSearchOpen((open) => !open)}><Search size={20} /></button><button className="icon-button menu-toggle" aria-label={menuOpen ? 'Close menu' : 'Open menu'} aria-expanded={menuOpen} onClick={() => setMenuOpen((open) => !open)}>{menuOpen ? <X size={22} /> : <Menu size={22} />}</button></div></div>{searchOpen && <div className="header-search"><div className="container"><SearchBar /></div></div>}</header>;
}
