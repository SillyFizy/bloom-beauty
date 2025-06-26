import { DashboardLayout } from '@/components/layout/dashboard-layout';

export default function ProductsLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <DashboardLayout title="Products">
      {children}
    </DashboardLayout>
  );
} 