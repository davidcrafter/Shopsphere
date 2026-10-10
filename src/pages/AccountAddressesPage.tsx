import { Breadcrumbs } from '@/components/Breadcrumbs';
import { Seo } from '@/components/Seo';
import { AddressBook } from '@/components/account/AddressBook';
export function AccountAddressesPage() { return <><Seo title="Saved Addresses" description="Manage your saved delivery addresses." path="/account/addresses" noindex /><Breadcrumbs items={[{ label: 'Account', to: '/account' }, { label: 'Addresses' }]} /><section className="section"><div className="container account-page"><span className="eyebrow">Delivery details</span><h1>Saved addresses</h1><AddressBook /></div></section></>; }
