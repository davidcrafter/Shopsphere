import { useEffect, useState } from 'react';
import { getCollections, getFaqEntries, getStorefrontContent } from '@/services/storefront';
import { siteConfig } from '@/config/site';
import type { Collection, StorefrontContent } from '@/types/catalog';

export function useStorefrontContent() { const [content, setContent] = useState<StorefrontContent>(siteConfig.homepageFallback); useEffect(() => { void getStorefrontContent().then(setContent).catch(() => setContent(siteConfig.homepageFallback)); }, []); return content; }
export function useCollections() { const [collections, setCollections] = useState<Collection[]>([]); const [loading, setLoading] = useState(true); useEffect(() => { void getCollections().then(setCollections).finally(() => setLoading(false)); }, []); return { collections, loading }; }
export function useFaqEntries() { const [entries, setEntries] = useState<{ id: string; category: string; question: string; answer: string; displayOrder: number }[]>([]); const [loading, setLoading] = useState(true); useEffect(() => { void getFaqEntries().then(setEntries).finally(() => setLoading(false)); }, []); return { entries, loading }; }
