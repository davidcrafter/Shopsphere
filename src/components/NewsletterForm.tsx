import { useState, type FormEvent } from 'react';
import { ArrowRight, CheckCircle2, LoaderCircle } from 'lucide-react';
import { Link } from 'react-router-dom';
import { subscribeToNewsletter } from '@/services/newsletter';

export function NewsletterForm() {
  const [email, setEmail] = useState(''); const [status, setStatus] = useState<'idle' | 'loading' | 'success' | 'error'>('idle'); const [message, setMessage] = useState('');
  const submit = async (event: FormEvent) => { event.preventDefault(); setStatus('loading'); try { const result = await subscribeToNewsletter(email); setMessage(result.message); setStatus('success'); setEmail(''); } catch (error) { setMessage(error instanceof Error ? error.message : 'Something went wrong.'); setStatus('error'); } };
  return <form className="newsletter-form" onSubmit={submit} noValidate><div className="newsletter-form__row"><label className="sr-only" htmlFor="newsletter-email">Email address</label><input id="newsletter-email" type="email" value={email} onChange={(event) => setEmail(event.target.value)} placeholder="you@example.com" required aria-describedby="newsletter-consent newsletter-status" /><button type="submit" disabled={status === 'loading'}>{status === 'loading' ? <LoaderCircle className="spin" size={18} /> : <>Subscribe <ArrowRight size={17} /></>}</button></div><small id="newsletter-consent">By subscribing, you agree to receive occasional emails. Unsubscribe anytime. See our <Link to="/privacy-policy">Privacy Policy</Link>.</small>{message && <p id="newsletter-status" className={`form-status form-status--${status}`} role="status">{status === 'success' && <CheckCircle2 size={16} />}{message}</p>}</form>;
}
