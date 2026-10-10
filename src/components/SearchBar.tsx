import { useState, type FormEvent } from 'react';
import { Search } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { trackEvent } from '@/services/analytics';

export function SearchBar({ prominent = false, initialValue = '', onSubmit }: { prominent?: boolean; initialValue?: string; onSubmit?: (query: string) => void }) {
  const [query, setQuery] = useState(initialValue); const navigate = useNavigate();
  const submit = (event: FormEvent) => { event.preventDefault(); const clean = query.trim(); if (!clean) return; trackEvent('Search', { query: clean }); if (onSubmit) onSubmit(clean); else navigate(`/search?q=${encodeURIComponent(clean)}`); };
  return <form className={`search-bar ${prominent ? 'search-bar--prominent' : ''}`} role="search" onSubmit={submit}><Search size={20} aria-hidden="true" /><label className="sr-only" htmlFor={prominent ? 'hero-search' : 'site-search'}>Search products</label><input id={prominent ? 'hero-search' : 'site-search'} value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search products, categories or brands..." autoComplete="off" /><button type="submit">Search</button></form>;
}
