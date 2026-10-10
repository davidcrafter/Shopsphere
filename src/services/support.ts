import { z } from 'zod';
import { supabase } from './supabase';
import type { ContactMessageInput } from '@/types/catalog';
const schema = z.object({ name: z.string().trim().min(2).max(120), email: z.string().trim().email().max(254), orderNumber: z.string().trim().max(80).optional(), subject: z.string().trim().min(2).max(160), message: z.string().trim().min(10).max(4000) });
export async function submitContactMessage(input: ContactMessageInput) { if (!supabase) throw new Error('Support messages are not connected yet. Configure Supabase to enable this form.'); const payload = schema.parse(input); const { data, error } = await supabase.functions.invoke('create-contact-message', { body: payload }); if (error) throw new Error(error.message || 'We could not send your message.'); if (!data?.id) throw new Error('The support service returned an invalid response.'); return String(data.id); }
