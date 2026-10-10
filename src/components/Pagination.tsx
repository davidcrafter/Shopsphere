import { ChevronLeft, ChevronRight } from 'lucide-react';

export function Pagination({ page, totalPages, onPage }: { page: number; totalPages: number; onPage: (page: number) => void }) {
  if (totalPages <= 1) return null;
  return <nav className="pagination" aria-label="Product pages"><button disabled={page === 1} onClick={() => onPage(page - 1)}><ChevronLeft size={16} /> Previous</button><span>Page {page} of {totalPages}</span><button disabled={page === totalPages} onClick={() => onPage(page + 1)}>Next <ChevronRight size={16} /></button></nav>;
}
