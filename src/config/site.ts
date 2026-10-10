import type { CurrencyCode, StorefrontContent } from '@/types/catalog';

export const siteConfig = {
  brand: 'IBYIZAMART',
  slogan: 'Discover. Compare. Save.',
  description: 'A modern online store for quality everyday products, clear prices, and dependable order support.',
  url: import.meta.env.VITE_SITE_URL || 'https://example.com',
  contactEmail: import.meta.env.VITE_CONTACT_EMAIL || 'support@example.com',
  contactPhone: import.meta.env.VITE_CONTACT_PHONE || '',
  businessLocation: import.meta.env.VITE_BUSINESS_LOCATION || 'Kigali, Rwanda',
  defaultCurrency: 'RWF' as CurrencyCode,
  timezone: 'Africa/Kigali',
  socialLinks: {} as Record<string, string>,
  nav: [
    { label: 'Home', to: '/' }, { label: 'Shop', to: '/shop' }, { label: 'New Arrivals', to: '/new-arrivals' }, { label: 'Best Sellers', to: '/best-sellers' }, { label: 'Deals', to: '/deals' }, { label: 'Blog', to: '/blog' }, { label: 'Contact', to: '/contact' },
  ],
  homepageFallback: {
    announcement: "Discover great products at prices you'll love.", announcementEnabled: true,
    heroEyebrow: 'YOUR NEXT FAVORITE FIND', heroHeading: "Discover Products You'll Love.", heroText: 'Explore quality finds, everyday essentials, and fresh discoveries — all in one place.',
    heroImage: 'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?auto=format&fit=crop&w=1400&q=90', heroPrimaryLabel: 'Shop Now', heroPrimaryTo: '/shop', heroSecondaryLabel: 'Explore Categories', heroSecondaryTo: '/categories',
    promoHeading: 'Great Finds. Better Prices.', promoText: 'Explore carefully selected products at clear retail prices.', promoImage: 'https://images.unsplash.com/photo-1556740749-887f6717d7e4?auto=format&fit=crop&w=1800&q=85', promoTo: '/deals',
  } satisfies StorefrontContent,
} as const;
