import { createClient } from 'npm:@supabase/supabase-js@2.57.4';
import { corsHeaders, json } from '../_shared/cors.ts';
import { paypackAuthenticate, paypackFind, readWebhook } from '../_shared/payments/paypack.ts';

// Deploy with:  supabase functions deploy payment-webhook --no-verify-jwt
// Paypack calls this endpoint; it carries no Supabase user JWT.
//
// Security model (see docs/PAYMENTS.md): the webhook is only a TRIGGER.
// We verify the signature when a secret is configured, store the event id
// idempotently, and then re-verify the transaction DIRECTLY against Paypack
// before marking any order paid. A forged webhook therefore cannot settle an
// order, because Paypack's own API is the source of truth.

async function hmacSha256Base64(secret: string, body: string): Promise<string> {
  const key = await crypto.subtle.importKey('raw', new TextEncoder().encode(secret), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  const sig = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(body));
  return btoa(String.fromCharCode(...new Uint8Array(sig)));
}

async function sha256Hex(body: string): Promise<string> {
  const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(body));
  return Array.from(new Uint8Array(digest)).map((b) => b.toString(16).padStart(2, '0')).join('');
}

function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (request.method !== 'POST') return json({ error: 'Method not allowed' }, 405);

  const clientId = Deno.env.get('PAYPACK_CLIENT_ID');
  const clientSecret = Deno.env.get('PAYPACK_CLIENT_SECRET');
  if (!clientId || !clientSecret) {
    // Fail closed when no provider is configured.
    return json({ error: 'No live payment provider is configured.' }, 501);
  }

  try {
    const rawBody = await request.text();

    // 1) Optional signature verification (when PAYPACK_WEBHOOK_SECRET is set).
    const webhookSecret = Deno.env.get('PAYPACK_WEBHOOK_SECRET');
    if (webhookSecret) {
      const provided = request.headers.get('X-Paypack-Signature') || request.headers.get('x-paypack-signature') || request.headers.get('X-Hub-Signature-256') || '';
      const expected = await hmacSha256Base64(webhookSecret, rawBody);
      if (!provided || !timingSafeEqual(provided.trim(), expected)) {
        return json({ error: 'Invalid signature' }, 401);
      }
    }

    const payload = JSON.parse(rawBody || '{}') as Record<string, unknown>;
    const { ref } = readWebhook(payload);
    if (!ref) return json({ received: true }, 200); // nothing actionable

    // 2) Idempotency: process each (provider,event) at most once.
    const payloadHash = await sha256Hex(rawBody);
    const eventId = `${ref}:${payloadHash.slice(0, 16)}`;
    const admin = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
    const { data: isNew } = await admin.rpc('record_webhook_event', { p_provider: 'paypack', p_event_id: eventId, p_payload_hash: payloadHash });
    if (isNew === false) return json({ received: true, duplicate: true }, 200);

    // 3) Authoritative verification against Paypack before changing anything.
    const token = await paypackAuthenticate(clientId, clientSecret);
    const found = await paypackFind({ token, ref: String(ref) });

    if (found.status === 'succeeded') {
      await admin.rpc('finalize_live_payment', { p_provider_payment_id: String(ref), p_outcome: 'succeeded', p_amount_minor: found.amount, p_metadata: { verifiedBy: 'webhook' } });
    } else if (found.status === 'failed') {
      await admin.rpc('finalize_live_payment', { p_provider_payment_id: String(ref), p_outcome: 'failed', p_amount_minor: null, p_metadata: { verifiedBy: 'webhook' } });
    }
    // pending → acknowledge and wait for a later event / poll.

    return json({ received: true }, 200);
  } catch (error) {
    console.error('payment_webhook_error', error instanceof Error ? error.message : 'unknown');
    return json({ error: 'Webhook processing failed' }, 500);
  }
});
