import { createClient } from 'npm:@supabase/supabase-js@2.57.4';
import { corsHeaders, json } from '../_shared/cors.ts';
import { paypackAuthenticate, paypackFind, paypackEnvironment } from '../_shared/payments/paypack.ts';

// Owner-polled confirmation. Re-verifies the transaction DIRECTLY against
// Paypack (never trusting the browser) and finalizes the order on success.
// This is the authoritative path and works even if the webhook is not configured.
Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (request.method !== 'POST') return json({ error: 'Method not allowed' }, 405);
  try {
    const clientId = Deno.env.get('PAYPACK_CLIENT_ID');
    const clientSecret = Deno.env.get('PAYPACK_CLIENT_SECRET');
    if (!clientId || !clientSecret) return json({ error: 'Live payments are not configured.' }, 503);

    const auth = request.headers.get('Authorization');
    if (!auth) return json({ error: 'Authentication required' }, 401);
    const body = await request.json();
    if (typeof body.orderId !== 'string') return json({ error: 'Invalid request' }, 400);

    const authClient = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_ANON_KEY')!, { global: { headers: { Authorization: auth } } });
    const { data: { user }, error: userError } = await authClient.auth.getUser();
    if (userError || !user) return json({ error: 'Invalid session' }, 401);

    const admin = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);

    // Owner-scoped lookup of the Paypack reference + expected amount.
    const { data: info, error: infoError } = await admin.rpc('live_payment_reference', { p_order_id: body.orderId, p_user_id: user.id });
    if (infoError) return json({ error: infoError.message }, 400);

    // Already settled — return the stored result.
    if (info.status === 'succeeded' || info.status === 'failed') {
      return json({ status: info.status, orderNumber: info.orderNumber });
    }
    if (!info.ref) return json({ status: 'pending', orderNumber: info.orderNumber });

    // Authoritative re-verification against Paypack.
    const token = await paypackAuthenticate(clientId, clientSecret);
    const found = await paypackFind({ token, ref: String(info.ref) });

    if (found.status === 'succeeded') {
      if (found.amount < Number(info.amountMinor)) {
        // Underpayment — do not mark paid.
        return json({ status: 'pending', orderNumber: info.orderNumber });
      }
      const { data: result } = await admin.rpc('finalize_live_payment', { p_provider_payment_id: String(info.ref), p_outcome: 'succeeded', p_amount_minor: found.amount, p_metadata: { verifiedBy: 'poll' } });
      return json({ status: 'succeeded', orderNumber: result?.orderNumber ?? info.orderNumber });
    }
    if (found.status === 'failed') {
      await admin.rpc('finalize_live_payment', { p_provider_payment_id: String(info.ref), p_outcome: 'failed', p_amount_minor: null, p_metadata: { verifiedBy: 'poll' } });
      return json({ status: 'failed', orderNumber: info.orderNumber });
    }
    return json({ status: 'pending', orderNumber: info.orderNumber });
  } catch (error) {
    console.error('momo_status_error', error instanceof Error ? error.message : 'unknown');
    return json({ error: 'Could not check payment status.' }, 500);
  }
});
