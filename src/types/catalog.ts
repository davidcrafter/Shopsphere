export type CurrencyCode = 'USD' | 'EUR' | 'GBP' | 'CAD' | 'AUD';
export type ProductStatus = 'draft' | 'active' | 'archived';
export interface ProductImage { id?: string; src: string; alt: string; position?: number; }
export interface ProductVariant { id: string; sku: string; name: string; optionValues: Record<string, string>; priceMinor: number; compareAtMinor: number | null; currency: CurrencyCode; stockQuantity: number | null; trackInventory: boolean; available: boolean; }
export interface Product { id: string; name: string; slug: string; sku: string; description: string; shortDescription: string; category: string; brand: string | null; images: ProductImage[]; variants: ProductVariant[]; specifications: Record<string, string>; featured: boolean; bestSeller: boolean; promotion: boolean; status: ProductStatus; publishedAt: string; updatedAt: string; processingEstimate: string | null; deliveryEstimate: string | null; isDemo: boolean; }
export interface Category { name: string; slug: string; description: string; image: string; }
export interface Article { slug: string; title: string; excerpt: string; category: string; image: string; publishedAt: string; readMinutes: number; sections: { heading: string; body: string }[]; researchedGuide: boolean; }
export type SortOption = 'latest' | 'name-asc' | 'name-desc' | 'price-asc' | 'price-desc';
export interface CartLine { variantId: string; quantity: number; }
export interface CartDisplayLine extends CartLine { product: Product; variant: ProductVariant; lineTotalMinor: number; }
export interface AddressInput { fullName: string; email: string; phone?: string; line1: string; line2?: string; city: string; region: string; postalCode: string; countryCode: string; deliveryInstructions?: string; }
export type OrderStatus = 'pending_payment' | 'paid' | 'awaiting_supplier_order' | 'supplier_order_placed' | 'processing' | 'shipped' | 'delivered' | 'cancelled' | 'refund_pending' | 'refunded';
export interface CustomerOrder { id: string; orderNumber: string; mode: 'test'|'live'; status: OrderStatus; paymentStatus: string; currency: CurrencyCode; subtotalMinor: number; shippingMinor: number; taxMinor: number; discountMinor: number; totalMinor: number; createdAt: string; trackingNumber?: string | null; carrier?: string | null; items?: { id: string; productName: string; variantName: string; sku: string; quantity: number; unitPriceMinor: number; lineTotalMinor: number; imageUrl?: string | null }[]; }
