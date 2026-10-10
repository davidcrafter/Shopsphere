import { Outlet } from 'react-router-dom';
import { usePageView } from '@/hooks/usePageView';
import { ConsentBanner } from '../ConsentBanner';
import { Footer } from './Footer';
import { Header } from './Header';

export function Layout() { usePageView(); return <><Header /><main id="main-content"><Outlet /></main><Footer /><ConsentBanner /></>; }
