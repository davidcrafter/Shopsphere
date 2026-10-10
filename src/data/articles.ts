import type { Article } from '@/types/catalog';

export const articles: Article[] = [
  { slug: 'choose-right-running-shoes', title: 'How to Choose the Right Running Shoes', excerpt: 'A practical framework for matching fit, cushioning, and terrain to the way you run.', category: 'Fitness guide', image: 'https://images.unsplash.com/photo-1460353581641-37baddab0fa2?auto=format&fit=crop&w=1200&q=85', publishedAt: '2026-09-24', readMinutes: 7, researchedGuide: true, sections: [
    { heading: 'Start with where and how you run', body: 'Road, trail, and track shoes solve different problems. Begin with your usual surface, weekly distance, and whether the shoe is for easy miles, faster sessions, or a mix.' },
    { heading: 'Prioritize fit over labels', body: 'Allow comfortable toe room and look for a secure heel without pressure points. Sizing differs by brand, so use the seller’s current chart and choose a seller with a suitable return policy.' },
    { heading: 'Treat cushioning as a preference', body: 'More cushioning is not automatically better. Compare stack height, firmness, flexibility, and heel-to-toe drop, then choose the combination that feels stable and natural for you.' },
  ] },
  { slug: 'best-budget-gadgets-everyday-use', title: 'Best Budget Gadgets for Everyday Use: What Matters', excerpt: 'How to identify useful, dependable tech without paying for features you will not use.', category: 'Tech guide', image: 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?auto=format&fit=crop&w=1200&q=85', publishedAt: '2026-09-17', readMinutes: 6, researchedGuide: true, sections: [
    { heading: 'Solve a frequent problem', body: 'A low price is only good value when the item earns a place in your routine. Focus on charging, organization, lighting, or another task you do often.' },
    { heading: 'Check compatibility first', body: 'Confirm ports, power standards, operating-system support, dimensions, and regional plugs before comparing optional features.' },
    { heading: 'Look beyond the headline specification', body: 'Safety certifications, warranty terms, software support, and clear documentation often matter more than a single impressive number.' },
  ] },
  { slug: 'what-to-look-for-home-essentials', title: 'What to Look for When Buying Home Essentials', excerpt: 'A room-by-room approach to choosing durable items that fit your space and routine.', category: 'Home guide', image: 'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?auto=format&fit=crop&w=1200&q=85', publishedAt: '2026-09-09', readMinutes: 8, researchedGuide: true, sections: [
    { heading: 'Measure the space and the task', body: 'Record the available dimensions, nearby outlets, storage constraints, and how often the item will be used. This prevents attractive but impractical purchases.' },
    { heading: 'Favor maintainable materials', body: 'Review cleaning instructions, replaceable parts, surface durability, and whether common wear points can be repaired.' },
    { heading: 'Verify safety and return terms', body: 'For electrical, heat-producing, or load-bearing products, look for applicable certifications and clear usage limits. Review return costs before ordering bulky items.' },
  ] },
  { slug: 'compare-products-before-buying-online', title: 'How to Compare Products Before Buying Online', excerpt: 'A repeatable checklist for separating meaningful differences from marketing noise.', category: 'Smart shopping', image: 'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?auto=format&fit=crop&w=1200&q=85', publishedAt: '2026-08-31', readMinutes: 5, researchedGuide: true, sections: [
    { heading: 'Define your non-negotiables', body: 'Write down the three requirements that determine whether a product works for you. Use those to eliminate poor fits before looking at extras.' },
    { heading: 'Compare equivalent information', body: 'Make sure dimensions use the same units and that prices include the same accessories. Distinguish manufacturer claims from independently verifiable facts.' },
    { heading: 'Evaluate the seller as well as the product', body: 'Check ShopSphere’s fulfillment estimate, warranty responsibility, return eligibility, and any return shipping costs before ordering.' },
  ] },
];
