import { MailCheck } from 'lucide-react';
import { Link } from 'react-router-dom';
import { Seo } from '@/components/Seo';
export function VerifyEmailPage() { return <><Seo title="Verify Your Email" description="Verify your IBYIZAMART account email." path="/verify-email" noindex /><section className="auth-page"><div className="auth-card"><MailCheck size={36} /><span className="eyebrow">Account verification</span><h1>Check your inbox</h1><p>Open the verification link sent by Supabase to activate email confirmation when it is enabled for this store.</p><Link className="button button--primary" to="/login">Go to sign in</Link></div></section></>; }
