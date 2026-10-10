import { z } from 'zod';
import { supabase } from './supabase';
const schema = z.object({ orderNumber: z.string().trim().min(6).max(80), email: z.string().trim().email().max(254) });
export interface TrackingResult { orderNumber: string; status: string; paymentStatus: string; carrier: string | null; trackingNumber: string | null; createdAt: string; }
export async function trackOrder(raw: z.input<typeof schema>): Promise<TrackingResult> { if (!supabase) throw new Error('Tracking is not connected yet.'); const payload = schema.parse(raw); const { data, error } = await supabase.functions.invoke('track-order', { body: payload }); if (error) throw new Error(error.message || 'Order tracking is unavailable.'); if (!data?.orderNumber) throw new Error('We could not find an order with those details.'); return data as TrackingResult; }
