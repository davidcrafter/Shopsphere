// Paypack REST adapter (MTN MoMo + Airtel, Rwanda, RWF).
// Docs/SDK: https://docs.paypack.rw , https://github.com/quarksgroup/paypack-js
// RWF is a zero-decimal currency, so amount_minor equals the RWF amount.

const BASE_URL = 'https://payments.paypack.rw/api/';

// Rwandan MTN (078/079) and Airtel (073/072), plus 075.
export const RW_PHONE_RE = /^(\+?25)?(078|079|075|073|072)\d{7}$/;

export function paypackEnvironment(): string {
  // Controls which registered Paypack webhook receives events: 'development' | 'production'.
  return Deno.env.get('PAYPACK_ENVIRONMENT') === 'development' ? 'development' : 'production';
}

export function normalizeStatus(raw: unknown): 'pending' | 'succeeded' | 'failed' {
  const v = String(raw ?? '').toLowerCase();
  if (['successfull', 'successful', 'success', 'completed', 'complete', 'paid'].includes(v)) return 'succeeded';
  if (['failed', 'failure', 'rejected', 'declined', 'cancelled', 'canceled', 'timeout', 'expired'].includes(v)) return 'failed';
  return 'pending';
}

async function parse(res: Response): Promise<Record<string, unknown>> {
  try { return (await res.json()) as Record<string, unknown>; } catch { return {}; }
}

function pick(obj: Record<string, unknown>, key: string): unknown {
  if (obj == null) return undefined;
  if (key in obj) return obj[key];
  const data = obj.data as Record<string, unknown> | undefined;
  return data && key in data ? data[key] : undefined;
}

// Exchange client credentials for an access token.
export async function paypackAuthenticate(clientId: string, clientSecret: string): Promise<string> {
  const res = await fetch(BASE_URL + 'auth/agents/authorize', {
    method: 'POST',
    headers: { 'content-type': 'application/json', accept: 'application/json' },
    body: JSON.stringify({ client_id: clientId, client_secret: clientSecret }),
  });
  const body = await parse(res);
  if (!res.ok) throw new Error('Paypack authentication failed');
  const access = body.access as string | undefined;
  if (!access) throw new Error('Paypack did not return an access token');
  return access;
}

// Request a mobile-money payment from the customer (they approve on their phone).
export async function paypackCashin(input: { token: string; amount: number; number: string; environment: string }): Promise<{ ref: string; status: 'pending' | 'succeeded' | 'failed'; raw: Record<string, unknown> }> {
  const res = await fetch(BASE_URL + 'transactions/cashin', {
    method: 'POST',
    headers: { authorization: input.token, 'content-type': 'application/json', accept: 'application/json', 'X-Webhook-Mode': input.environment },
    body: JSON.stringify({ amount: input.amount, number: input.number }),
  });
  const raw = await parse(res);
  if (!res.ok) throw new Error((pick(raw, 'message') as string) || (raw.error as string) || 'Paypack cash-in request failed');
  const ref = pick(raw, 'ref') as string | undefined;
  if (!ref) throw new Error('Paypack did not return a transaction reference');
  return { ref, status: normalizeStatus(pick(raw, 'status')), raw };
}

// Authoritative server-side status check for a transaction reference.
export async function paypackFind(input: { token: string; ref: string }): Promise<{ status: 'pending' | 'succeeded' | 'failed'; amount: number; raw: Record<string, unknown> }> {
  const res = await fetch(BASE_URL + 'transactions/find/' + encodeURIComponent(input.ref), {
    headers: { authorization: input.token, accept: 'application/json' },
  });
  const raw = await parse(res);
  if (!res.ok) throw new Error((pick(raw, 'message') as string) || 'Paypack transaction lookup failed');
  return { status: normalizeStatus(pick(raw, 'status')), amount: Number(pick(raw, 'amount') ?? 0), raw };
}

// Send money back to the customer's number (refund = cash-out).
export async function paypackCashout(input: { token: string; amount: number; number: string; environment: string }): Promise<{ ref: string; status: 'pending' | 'succeeded' | 'failed'; raw: Record<string, unknown> }> {
  const res = await fetch(BASE_URL + 'transactions/cashout', {
    method: 'POST',
    headers: { authorization: input.token, 'content-type': 'application/json', accept: 'application/json', 'X-Webhook-Mode': input.environment },
    body: JSON.stringify({ amount: input.amount, number: input.number }),
  });
  const raw = await parse(res);
  if (!res.ok) throw new Error((pick(raw, 'message') as string) || (raw.error as string) || 'Paypack cash-out (refund) failed');
  const ref = pick(raw, 'ref') as string | undefined;
  if (!ref) throw new Error('Paypack did not return a refund reference');
  return { ref, status: normalizeStatus(pick(raw, 'status')), raw };
}

// Extract (ref, status) from a webhook payload regardless of nesting.
export function readWebhook(payload: Record<string, unknown>): { ref: string | null; status: 'pending' | 'succeeded' | 'failed' } {
  return { ref: (pick(payload, 'ref') as string) ?? null, status: normalizeStatus(pick(payload, 'status')) };
}
