export const siteConfig = {
  brand: 'ShopSphere',
  slogan: 'Discover. Compare. Save.',
  description: 'Independent product discovery, comparisons, and researched buying guides for thoughtful shoppers.',
  url: import.meta.env.VITE_SITE_URL || 'https://example.com',
  contactEmail: import.meta.env.VITE_CONTACT_EMAIL || 'hello@example.com',
  socialLinks: {} as Record<string, string>,
  nav: [
    { label: 'Home', to: '/' },
    { label: 'Shop', to: '/shop' },
    { label: 'Trending', to: '/trending' },
    { label: 'Deals', to: '/deals' },
    { label: 'Blog', to: '/blog' },
    { label: 'About', to: '/about' },
  ],
} as const;
