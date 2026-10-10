import { AlertCircle, PackageOpen, RefreshCw } from 'lucide-react';

export function LoadingSkeleton({ count = 5 }: { count?: number }) { return <div className="product-grid" aria-label="Loading products" aria-busy="true">{Array.from({ length: count }, (_, index) => <div className="skeleton-card" key={index}><div /><span /><span /><span /></div>)}</div>; }
export function EmptyState({ title = 'No products found', message = 'Try changing your search or filters.' }: { title?: string; message?: string }) { return <div className="state-card"><PackageOpen size={36} /><h2>{title}</h2><p>{message}</p></div>; }
export function ErrorState({ message, retry }: { message: string; retry?: () => void }) { return <div className="error-notice" role="alert"><AlertCircle size={20} /><span>{message}</span>{retry && <button onClick={retry}><RefreshCw size={15} /> Retry</button>}</div>; }
