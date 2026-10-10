export const siteConfig = {
  brand: 'IBYIZAMART', slogan: 'Discover. Compare. Save.', description: 'A modern online store for quality everyday products, clear pricing, and dependable order support.',
  url: import.meta.env.VITE_SITE_URL || 'https://example.com', contactEmail: import.meta.env.VITE_CONTACT_EMAIL || 'support@example.com', defaultCurrency: (import.meta.env.VITE_DEFAULT_CURRENCY || 'USD') as 'USD',
  socialLinks: {} as Record<string,string>,
  nav: [{label:'Home',to:'/'},{label:'Shop',to:'/shop'},{label:'New Arrivals',to:'/new-arrivals'},{label:'Best Sellers',to:'/best-sellers'},{label:'Deals',to:'/deals'},{label:'Contact',to:'/contact'}],
} as const;
