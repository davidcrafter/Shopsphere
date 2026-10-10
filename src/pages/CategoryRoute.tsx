import { Navigate, useParams } from 'react-router-dom';
import { categories } from '@/data/categories';
import { CatalogPage } from './CatalogPage';
export function CategoryRoute() { const { slug } = useParams(); if (!slug || !categories.some((item) => item.slug === slug)) return <Navigate to="/404" replace />; return <CatalogPage mode="category" categorySlug={slug} />; }
