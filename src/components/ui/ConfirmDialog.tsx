import { AlertTriangle, X } from 'lucide-react';
import type { ReactNode } from 'react';

export function ConfirmDialog({ open, title, description, confirmLabel = 'Confirm', busy = false, onCancel, onConfirm }: { open: boolean; title: string; description: ReactNode; confirmLabel?: string; busy?: boolean; onCancel: () => void; onConfirm: () => void }) {
  if (!open) return null;
  return <div className="confirm-backdrop" role="presentation"><section className="confirm-dialog" role="dialog" aria-modal="true" aria-labelledby="confirm-title"><button className="confirm-dialog__close" aria-label="Close confirmation" disabled={busy} onClick={onCancel}><X size={18} /></button><AlertTriangle /><h2 id="confirm-title">{title}</h2><p>{description}</p><div><button className="button button--secondary" disabled={busy} onClick={onCancel}>Cancel</button><button className="button button--danger" disabled={busy} onClick={onConfirm}>{busy ? 'Working…' : confirmLabel}</button></div></section></div>;
}
