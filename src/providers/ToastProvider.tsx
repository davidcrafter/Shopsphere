import { createContext, useCallback, useContext, useMemo, useState, type ReactNode } from 'react';
import { CheckCircle2, Info, TriangleAlert, X } from 'lucide-react';

type ToastTone = 'success' | 'error' | 'info';
interface Toast { id: string; tone: ToastTone; message: string; }
interface ToastContextValue { notify: (message: string, tone?: ToastTone) => void; }
const ToastContext = createContext<ToastContextValue | null>(null);

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([]);
  const notify = useCallback((message: string, tone: ToastTone = 'info') => {
    const id = crypto.randomUUID(); setToasts((current) => [...current, { id, tone, message }]);
    window.setTimeout(() => setToasts((current) => current.filter((toast) => toast.id !== id)), 5000);
  }, []);
  const value = useMemo(() => ({ notify }), [notify]);
  return <ToastContext.Provider value={value}>{children}<div className="toast-viewport" aria-live="polite" aria-relevant="additions">{toasts.map((toast) => <div className={`toast toast--${toast.tone}`} key={toast.id}>{toast.tone === 'success' ? <CheckCircle2 /> : toast.tone === 'error' ? <TriangleAlert /> : <Info />}<span>{toast.message}</span><button aria-label="Dismiss notification" onClick={() => setToasts((current) => current.filter((item) => item.id !== toast.id))}><X size={16} /></button></div>)}</div></ToastContext.Provider>;
}
export function useToast() { const value = useContext(ToastContext); if (!value) throw new Error('useToast must be used inside ToastProvider'); return value; }
