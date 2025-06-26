"use client";

import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { CategoryTable } from "@/components/categories/category-table";

export default function CategoriesPage() {
  return (
    <DashboardLayout title="Categories">
      <CategoryTable />
    </DashboardLayout>
  );
} 