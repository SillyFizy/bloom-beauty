"use client";

import React from "react";
import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { AddProductForm } from "@/components/products/add-product-form";
import { useRouter } from "next/navigation";

export default function NewProductPage() {
  const router = useRouter();

  return (
    <DashboardLayout title="Add New Product">
      <div className="max-w-5xl mx-auto">
        <AddProductForm
          onSuccess={() => router.push("/products")}
          onCancel={() => router.push("/products")}
        />
      </div>
    </DashboardLayout>
  );
} 