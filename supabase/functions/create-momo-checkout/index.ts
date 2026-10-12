import { createClient } from 'npm:@supabase/supabase-js@2.57.4';
import { corsHeaders, json } from '../_shared/cors.ts';
import { paypackAuthenticate, paypackCashin, paypackEnvironment, RW_PHONE_RE } from '../_shared/payments/paypack.ts';

// Live mobile-money checkout. Creates a server-validated mode='live' order,
// then asks Paypack to collect the amount from the customer's MoMo/Airtel number.
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
    if (body.paymentMethod !== 'momo' || !Array.isArray(body.lines) || typeof body.shippingAddress !== 'object' || typeof body.shippingRateId !== 'string' || typeof body.idempotencyKey !== 'string' || typeof body.momoPhone !== 'string') {
      return json({ error: 'Invalid checkout request' }, 400);
    }
    const phone = body.momoPhone.trim();
    if (!RW_PHONE_RE.test(phone)) return json({ error: 'Enter a valid MTN or Airtel mobile money number (e.g. 078…).' }, 400);

    const authClient = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_ANON_KEY')!, { global: { headers: { Authorization: auth } } });
    const { data: { user }, error: userError } = await authClient.auth.getUser();
    if (userError || !user) return json({ error: 'Invalid session' }, 401);

    const admin = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);

    // 1) Create the live order + a pending payment, fully priced on the server.
    const { data: prep, error: prepError } = await admin.rpc('server_prepare_live_checkout', {
      p_user_id: user.id,
      p_lines: body.lines,
      p_address: body.shippingAddress,
      p_shipping_rate_id: body.shippingRateId,
      p_discount_code: typeof body.discountCode === 'string' ? body.discountCode : null,
      p_idempotency_key: body.idempotencyKey,
    });
    if (prepError) return json({ error: prepError.message }, 400);

    const amount = Number(prep.totalMinor);
    if (prep.currency !== 'RWF') return json({ error: 'Live mobile money payments support RWF only.' }, 400);
    if (!Number.isInteger(amount) || amount < 100) return json({ error: 'The minimum payable amount is 100 RWF.' }, 400);

    // 2) Ask Paypack to collect the money from the customer's phone.
    const environment = paypackEnvironment();
    let cashin;
    try {
      const token = await paypackAuthenticate(clientId, clientSecret);
      cashin = await paypackCashin({ token, amount, number: phone, environment });
    } catch (providerError) {
      return json({ error: providerError instanceof Error ? providerError.message : 'The payment request could not be started.', orderId: prep.orderId, orderNumber: prep.orderNumber }, 502);
    }

    // 3) Record the provider reference on the pending payment so the webhook/poller can match it.
    await admin.rpc('attach_live_payment_reference', { p_order_id: prep.orderId, p_provider_payment_id: cashin.ref, p_metadata: { phone, environment } });

    return json({
      orderId: prep.orderId,
      orderNumber: prep.orderNumber,
      totalMinor: prep.totalMinor,
      shippingMinor: prep.shippingMinor,
      discountMinor: prep.discountMinor,
      currency: prep.currency,
      ref: cashin.ref,
      paymentStatus: cashin.status,
    }, 201);
  } catch (error) {
    console.error('momo_checkout_error', error instanceof Error ? error.message : 'unknown');
    return json({ error: 'Checkout could not be created.' }, 500);
  }
});
