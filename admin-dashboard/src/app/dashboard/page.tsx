"use client";

import React from "react";
import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { useProducts, useProductStats } from "@/hooks/use-products";
import { formatCurrency, cn } from "@/lib/utils";
import {
  Package,
  TrendingUp,
  DollarSign,
  AlertTriangle,
  BarChart,
  ShoppingCart,
} from "lucide-react";
import Image from "next/image";
import Link from "next/link";
import { useToastContext } from "@/components/providers/ToastProvider";

export default function DashboardPage() {
  const { data: stats } = useProductStats();
  const { data: productsData } = useProducts({ page: 1, page_size: 50, ordering: "-created_at" });
  const products = productsData?.results || [];
  const lowStockProducts = products.filter((p) => p.is_low_stock);
  const { showComingSoon } = useToastContext();

  const summaryCards = [
    {
      title: "Total Products",
      value: stats?.total_products ?? 0,
      icon: Package,
      description: `${stats?.active_products ?? 0} active`,
      color: "bg-blue-500",
    },
    {
      title: "Featured Products",
      value: stats?.featured_products ?? 0,
      icon: TrendingUp,
      description: "Currently featured",
      color: "bg-green-500",
    },
    {
      title: "Low Stock Alert",
      value: stats?.low_stock_products ?? 0,
      icon: AlertTriangle,
      description: "≤ threshold units remaining",
      color: "bg-red-500",
    },
  ];

  // Calculate inventory value
  const inventoryValue = products.reduce((sum, product) => {
    const price = product.sale_price ?? product.price;
    return sum + price * product.stock_quantity;
  }, 0);

  summaryCards.splice(2, 0, {
    title: "Inventory Value",
    value: formatCurrency(inventoryValue),
    icon: DollarSign,
    description: "Total stock value",
    color: "bg-purple-500",
  });

  return (
    <DashboardLayout title="Dashboard">
      <div className="space-y-6">
        {/* Stats Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {summaryCards.map((stat, index) => (
            <Card key={index} className="card-hover">
              <CardContent className="p-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-slate-600">{stat.title}</p>
                    <p className="text-2xl font-bold text-slate-900">
                      {typeof stat.value === "number" ? stat.value.toLocaleString() : stat.value}
                    </p>
                    <p className="text-xs text-slate-500 mt-1">{stat.description}</p>
                  </div>
                  <div className={cn("p-3 rounded-full", stat.color)}>
                    <stat.icon className="h-6 w-6 text-white" />
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>

        {/* Recent & Low Stock Products */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <Card>
            <CardHeader>
              <CardTitle>Recent Products</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {products.length > 0 ? (
                  products.slice(0, 5).map((product) => (
                    <div
                      key={product.id}
                      className="flex items-center justify-between p-3 bg-slate-50 rounded-lg"
                    >
                      <div className="flex items-center space-x-3">
                        <div className="h-12 w-12 rounded-lg bg-slate-200 flex items-center justify-center overflow-hidden">
                          {product.featured_image ? (
                            <Image
                              src={product.featured_image}
                              alt={product.name}
                              width={48}
                              height={48}
                              className="object-cover"
                              onError={(e) => {
                                const target = e.target as HTMLImageElement;
                                if (!target.src.includes("placeholder-image.jpg")) {
                                  target.src = "/placeholder-image.jpg";
                                }
                              }}
                            />
                          ) : (
                            <span className="text-slate-400 text-xs">No Image</span>
                          )}
                        </div>
                        <div>
                          <h4 className="font-medium text-slate-900">{product.name}</h4>
                          <p className="text-sm text-slate-500">
                            {product.category?.name ?? "Uncategorized"}
                          </p>
                        </div>
                      </div>
                      <div className="text-right">
                        <p className="font-medium text-slate-900">
                          {formatCurrency(product.sale_price ?? product.price)}
                        </p>
                        <p className="text-sm text-slate-500">{product.stock_quantity} units</p>
                      </div>
                    </div>
                  ))
                ) : (
                  <p className="text-slate-500 text-center py-4">No recent products</p>
                )}
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Low Stock Alert</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {lowStockProducts.length > 0 ? (
                  lowStockProducts.slice(0, 5).map((product) => (
                    <div
                      key={product.id}
                      className="flex items-center justify-between p-3 bg-red-50 rounded-lg"
                    >
                      <div>
                        <h4 className="font-medium text-slate-900">{product.name}</h4>
                        <p className="text-sm text-slate-500">{product.sku}</p>
                      </div>
                      <div className="text-right">
                        <p className="font-medium text-red-600">
                          {product.stock_quantity} units
                        </p>
                        <p className="text-sm text-slate-500">Low stock</p>
                      </div>
                    </div>
                  ))
                ) : (
                  <p className="text-slate-500 text-center py-4">No low stock products</p>
                )}
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Quick Actions */}
        <Card>
          <CardHeader>
            <CardTitle>Quick Actions</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
              <Link
                href="/products/new"
                className="p-4 border border-slate-200 rounded-lg hover:bg-slate-50 transition-colors"
              >
                <Package className="h-8 w-8 text-primary mb-2" />
                <h3 className="font-medium text-slate-900">Add New Product</h3>
                <p className="text-sm text-slate-500">Create a new product listing</p>
              </Link>

              <Link
                href="/products"
                className="p-4 border border-slate-200 rounded-lg hover:bg-slate-50 transition-colors"
              >
                <TrendingUp className="h-8 w-8 text-primary mb-2" />
                <h3 className="font-medium text-slate-900">Manage Products</h3>
                <p className="text-sm text-slate-500">View and edit existing products</p>
              </Link>

              <Button
                variant="outline"
                onClick={showComingSoon}
                className="p-4 h-auto flex flex-col items-start text-left"
              >
                <BarChart className="h-8 w-8 text-primary mb-2" />
                <h3 className="font-medium text-slate-900">View Analytics</h3>
                <p className="text-sm text-slate-500">Performance insights</p>
              </Button>

              <Button
                variant="outline"
                onClick={showComingSoon}
                className="p-4 h-auto flex flex-col items-start text-left"
              >
                <ShoppingCart className="h-8 w-8 text-primary mb-2" />
                <h3 className="font-medium text-slate-900">Bulk Actions</h3>
                <p className="text-sm text-slate-500">Update multiple products</p>
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>
    </DashboardLayout>
  );
} 