import { z } from 'zod';
import { supabase } from './supabase';
const reviewSchema = z.object({ productId: z.string().uuid(), rating: z.number().int().min(1).max(5), title: z.string().trim().max(160).optional(), body: z.string().trim().min(10, 'Write at least 10 characters.').max(2000) });
export async function submitReview(input: z.input<typeof reviewSchema>) { if (!supabase) throw new Error('Reviews require a configured customer account.'); const value = reviewSchema.parse(input); const { data, error } = await supabase.rpc('submit_product_review', { p_product_id: value.productId, p_rating: value.rating, p_title: value.title ?? '', p_body: value.body }); if (error) throw new Error(error.message); return String(data); }
