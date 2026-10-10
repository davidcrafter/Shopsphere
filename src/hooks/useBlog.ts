import { useEffect, useState } from 'react';
import { articles as fallback } from '@/data/articles';
import { getPublishedArticles } from '@/services/content';
import { isSupabaseConfigured } from '@/services/supabase';
import type { Article } from '@/types/catalog';
export function useBlog() { const [articles, setArticles] = useState<Article[]>(isSupabaseConfigured ? [] : fallback); const [loading, setLoading] = useState(isSupabaseConfigured); const [error, setError] = useState<string | null>(null); useEffect(() => { if (!isSupabaseConfigured) return; void getPublishedArticles().then(setArticles).catch((issue) => setError(issue instanceof Error ? issue.message : 'Articles could not be loaded.')).finally(() => setLoading(false)); }, []); return { articles, loading, error }; }
