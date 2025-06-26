"use client";

import React from "react";
import { useRouter } from "next/navigation";
import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { EditProductForm } from "@/components/products/edit-product-form";
import { useProduct } from "@/hooks/use-products";
import { Loader2 } from "lucide-react";
import { Button } from "@/components/ui/button";

interface EditProductPageProps {
  params: {
    id: string;
  };
}

export default function EditProductPage({ params }: EditProductPageProps) {
  const router = useRouter();
  const productId = Number(params.id);
  const { data: product, isLoading, error } = useProduct(productId);

  const handleSuccess = () => {
    router.push("/products");
  };

  const handleCancel = () => {
    router.push("/products");
  };

  if (isLoading) {
    return (
      <DashboardLayout title="Loading product...">
        <div className="flex items-center justify-center py-12">
          <Loader2 className="h-6 w-6 animate-spin text-slate-500" />
        </div>
      </DashboardLayout>
    );
  }

  if (error || !product) {
    return (
      <DashboardLayout title="Product Not Found">
        <div className="text-center py-12 space-y-4">
          <h2 className="text-2xl font-bold text-slate-900">Product Not Found</h2>
          <p className="text-slate-600">The product you are looking for does not exist.</p>
          <Button onClick={() => router.push("/products")}>Back to Products</Button>
        </div>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout title={`Edit ${product.name}`}>
      <div className="max-w-5xl mx-auto">
        <EditProductForm product={product} onSuccess={handleSuccess} onCancel={handleCancel} />
      </div>
    </DashboardLayout>
  );
} 