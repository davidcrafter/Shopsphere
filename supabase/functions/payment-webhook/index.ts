import{corsHeaders,json}from'../_shared/cors.ts';
Deno.serve(async req=>{if(req.method==='OPTIONS')return new Response('ok',{headers:corsHeaders});return json({error:'No live payment provider is configured. Add a provider adapter, verify its webhook signature, store provider event IDs idempotently, and enable the route only after test verification.'},501);});
