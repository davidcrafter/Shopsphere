/// <reference types="vite/client" />
interface ImportMetaEnv { readonly VITE_SITE_URL?: string; readonly VITE_CONTACT_EMAIL?: string; readonly VITE_CONTACT_PHONE?: string; readonly VITE_BUSINESS_LOCATION?: string; readonly VITE_DEFAULT_CURRENCY?: string; readonly VITE_SUPABASE_URL?: string; readonly VITE_SUPABASE_ANON_KEY?: string; readonly VITE_ANALYTICS_PROVIDER?: string; readonly VITE_PLAUSIBLE_DOMAIN?: string; readonly VITE_ENABLE_DEMO_DATA?: string; readonly VITE_ENABLE_TEST_CHECKOUT?: string; }
interface ImportMeta { readonly env: ImportMetaEnv }
