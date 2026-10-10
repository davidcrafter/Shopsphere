-- Development-only IBYIZAMART seed content.
-- Apply only after migrations 001–004. This does not create orders, payments, reviews, or external catalog records.

insert into public.homepage_sections(section_key, value, public)
values
('announcement', '{"announcement":"Discover great products at prices you''ll love.","announcementEnabled":true}'::jsonb, true),
('hero', '{"heroEyebrow":"YOUR NEXT FAVORITE FIND","heroHeading":"Discover Products You''ll Love.","heroText":"Explore quality finds, everyday essentials, and fresh discoveries — all in one place.","heroPrimaryLabel":"Shop Now","heroPrimaryTo":"/shop","heroSecondaryLabel":"Explore Categories","heroSecondaryTo":"/categories"}'::jsonb, true),
('promo', '{"promoHeading":"Great Finds. Better Prices.","promoText":"Explore carefully selected products at clear retail prices.","promoTo":"/deals"}'::jsonb, true)
on conflict(section_key) do nothing;

insert into public.faq_entries(category, question, answer, display_order, published)
values
('Orders','How do I place an order?','Choose a product variant, add it to the cart, sign in, and complete checkout. Payment status is confirmed only after the configured service verifies it.',0,true),
('Delivery','How is shipping calculated?','The server validates the selected delivery rate for the destination and cart before it creates an order.',1,true),
('Returns','Can I request a return?','Use customer support with your order number. Eligibility depends on the published policy and the order state.',2,true)
on conflict do nothing;
