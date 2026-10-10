/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_SITE_URL?: string;
  readonly VITE_CONTACT_EMAIL?: string;
  readonly VITE_SUPABASE_URL?: string;
  readonly VITE_SUPABASE_ANON_KEY?: string;
  readonly VITE_ANALYTICS_PROVIDER?: string;
  readonly VITE_PLAUSIBLE_DOMAIN?: string;
}
interface ImportMeta { readonly env: ImportMetaEnv }
