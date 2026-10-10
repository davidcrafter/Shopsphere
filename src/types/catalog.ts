export type Seller = 'amazon' | 'aliexpress';
export type CurrencyCode = 'USD' | 'EUR' | 'GBP' | 'CAD' | 'AUD';

export interface ProductImage { src: string; alt: string; }
export interface ProductPrice { amount: number; currency: CurrencyCode; verifiedAt: string; isDemo?: boolean; }
export interface ProductRating { value: number; reviewCount: number; verifiedAt: string; isDemo?: boolean; }
export interface ProductProsCons { pros: string[]; cons: string[]; sourceNote: string; }
export interface Product {
  id: string;
  name: string;
  slug: string;
  description: string;
  shortDescription: string;
  category: string;
  brand: string | null;
  images: ProductImage[];
  affiliateUrls: Partial<Record<Seller, string>>;
  availableSellers: Seller[];
  price: ProductPrice | null;
  previousPrice: ProductPrice | null;
  rating: ProductRating | null;
  featured: boolean;
  trending: boolean;
  deal: boolean;
  published: boolean;
  publishedAt: string;
  lastPriceVerificationDate: string | null;
  specifications: Record<string, string>;
  research: ProductProsCons | null;
  relatedGuideSlugs: string[];
  isDemo: boolean;
}

export interface Category { name: string; slug: string; description: string; image: string; }
export interface Article { slug: string; title: string; excerpt: string; category: string; image: string; publishedAt: string; readMinutes: number; sections: { heading: string; body: string }[]; researchedGuide: boolean; }
export type SortOption = 'latest' | 'name-asc' | 'name-desc' | 'price-asc' | 'price-desc';
