import { z } from 'zod';
import { isSupabaseConfigured, supabase } from './supabase';

const emailSchema = z.string().trim().email('Enter a valid email address.').max(254);

export async function subscribeToNewsletter(rawEmail: string) {
  const email = emailSchema.parse(rawEmail).toLowerCase();
  if (!isSupabaseConfigured || !supabase) throw new Error('Subscriptions are not connected yet. Configure Supabase to enable this form.');
  const { error } = await supabase.from('newsletter_subscribers').insert({ email, consented_at: new Date().toISOString(), source: 'website' });
  if (error) {
    if (error.code === '23505') return { message: 'You are already subscribed.' };
    throw new Error('We could not save your subscription. Please try again.');
  }
  return { message: 'Thanks — please check your inbox for future updates.' };
}
