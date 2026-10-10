import { BarChart3, Boxes, ClipboardList, FolderHeart, FolderTree, History, LayoutDashboard, Mail, MapPin, MessageSquare, PackageSearch, Percent, ReceiptText, RotateCcw, Settings, ShieldCheck, Star, Truck, Users } from 'lucide-react';
import { NavLink, Outlet } from 'react-router-dom';
import { siteConfig } from '@/config/site';
const groups = [
  { label: 'Overview', links: [['/admin', 'Dashboard', LayoutDashboard, true], ['/admin/analytics', 'Analytics', BarChart3, false]] },
  { label: 'Catalog', links: [['/admin/products', 'Products', Boxes, false], ['/admin/categories', 'Categories', FolderTree, false], ['/admin/collections', 'Collections', FolderHeart, false], ['/admin/inventory', 'Inventory', ClipboardList, false], ['/admin/reviews', 'Reviews', Star, false]] },
  { label: 'Sales', links: [['/admin/orders', 'Orders', PackageSearch, false], ['/admin/payments', 'Payments', ReceiptText, false], ['/admin/returns', 'Returns & Refunds', RotateCcw, false], ['/admin/discounts', 'Discounts', Percent, false], ['/admin/shipping', 'Shipping', MapPin, false]] },
  { label: 'Customers', links: [['/admin/customers', 'Customers', Users, false], ['/admin/contact-messages', 'Contact Messages', MessageSquare, false], ['/admin/newsletter', 'Newsletter', Mail, false]] },
  { label: 'Content & Operations', links: [['/admin/content', 'Homepage & Policies', FolderHeart, false], ['/admin/blog', 'Blog', FolderHeart, false], ['/admin/suppliers', 'Manual Suppliers', Truck, false], ['/admin/settings', 'Settings', Settings, false], ['/admin/audit-log', 'Audit Log', History, false]] },
] as const;
export function AdminLayout() { return <div className="admin-shell"><aside><strong>{siteConfig.brand} Admin</strong><nav>{groups.map((group) => <div className="admin-nav-group" key={group.label}><span>{group.label}</span>{group.links.map(([to, label, Icon, end]) => <NavLink end={end} to={to} key={to}><Icon size={18} />{label}</NavLink>)}</div>)}</nav><small><ShieldCheck size={14} />Manual catalog · private operations</small></aside><main><Outlet /></main></div>; }
