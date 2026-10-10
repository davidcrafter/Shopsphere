import { Breadcrumbs } from '@/components/Breadcrumbs';
import { Seo } from '@/components/Seo';
const faqs = [
  ['Does ShopSphere sell products?', 'No. ShopSphere is a product-discovery and affiliate-publishing website. Checkout, payment, shipping, returns, and refunds are handled by the external seller.'],
  ['What is an affiliate link?', 'It is a seller-specific link that may allow the seller or affiliate network to credit ShopSphere with a commission after a qualifying purchase. It does not increase the price you pay.'],
  ['Are prices and ratings live?', 'Only information with a documented verification date is displayed. Demonstration listings intentionally omit prices and ratings. Always confirm current details on the seller’s website.'],
  ['Do you personally test every product?', 'No. Most content is research-led. Any hands-on testing will be clearly identified and will explain how the product was evaluated.'],
  ['Why is a seller button missing?', 'We show a seller button only when a valid, product-specific destination has been configured. We do not invent affiliate links.'],
  ['Can ShopSphere help with my order?', 'We cannot access seller orders or payments. Use your Amazon or AliExpress account and contact that seller’s support team.'],
];
export function FaqPage() { return <><Seo title="Frequently Asked Questions" description="Answers about ShopSphere affiliate links, product information, prices, testing, and orders." path="/faq" /><Breadcrumbs items={[{ label: 'FAQ' }]} /><header className="page-hero page-hero--compact"><div className="container"><span className="eyebrow">Good questions, clear answers</span><h1>Frequently Asked Questions</h1><p>How ShopSphere works, how we earn money, and what happens after you visit a seller.</p></div></header><section className="section"><div className="container faq-list">{faqs.map(([question, answer]) => <details key={question}><summary>{question}</summary><p>{answer}</p></details>)}</div></section></>; }
