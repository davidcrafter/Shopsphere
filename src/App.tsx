import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { Layout } from '@/components/layout/Layout';
import { CatalogProvider } from '@/hooks/useCatalog';
import { AboutPage } from '@/pages/AboutPage';
import { AdminImportPage } from '@/pages/AdminImportPage';
import { ArticlePage } from '@/pages/ArticlePage';
import { BlogPage } from '@/pages/BlogPage';
import { CatalogPage } from '@/pages/CatalogPage';
import { CategoryRoute } from '@/pages/CategoryRoute';
import { ContactPage } from '@/pages/ContactPage';
import { FaqPage } from '@/pages/FaqPage';
import { HomePage } from '@/pages/HomePage';
import { LegalPage } from '@/pages/LegalPage';
import { NotFoundPage } from '@/pages/NotFoundPage';
import { ProductPage } from '@/pages/ProductPage';

export default function App() { return <BrowserRouter><CatalogProvider><Routes><Route element={<Layout />}><Route path="/" element={<HomePage />} /><Route path="/shop" element={<CatalogPage mode="shop" />} /><Route path="/product/:slug" element={<ProductPage />} /><Route path="/category/:slug" element={<CategoryRoute />} /><Route path="/search" element={<CatalogPage mode="search" />} /><Route path="/trending" element={<CatalogPage mode="trending" />} /><Route path="/deals" element={<CatalogPage mode="deals" />} /><Route path="/blog" element={<BlogPage />} /><Route path="/blog/:slug" element={<ArticlePage />} /><Route path="/guides" element={<BlogPage guidesOnly />} /><Route path="/about" element={<AboutPage />} /><Route path="/contact" element={<ContactPage />} /><Route path="/faq" element={<FaqPage />} /><Route path="/affiliate-disclosure" element={<LegalPage kind="affiliate-disclosure" />} /><Route path="/privacy-policy" element={<LegalPage kind="privacy-policy" />} /><Route path="/terms" element={<LegalPage kind="terms" />} /><Route path="/cookies" element={<LegalPage kind="cookies" />} /><Route path="/admin/import" element={<AdminImportPage />} /><Route path="/404" element={<NotFoundPage />} /><Route path="*" element={<Navigate to="/404" replace />} /></Route></Routes></CatalogProvider></BrowserRouter>; }
