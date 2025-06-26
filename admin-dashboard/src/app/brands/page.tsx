"use client";

import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { BrandTable } from "@/components/brands/brand-table";

export default function BrandsPage() {
  return (
    <DashboardLayout title="Brands">
      <BrandTable />
    </DashboardLayout>
  );
} 