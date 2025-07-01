"use client";

import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { CategoryTable } from "@/components/categories/category-table";
import { NavigationCategoryTable } from "@/components/categories/navigation-category-table";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Package, Navigation } from "lucide-react";

export default function CategoriesPage() {
  return (
    <DashboardLayout title="Categories">
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-semibold tracking-tight">Categories Management</h1>
            <p className="text-muted-foreground">
              Manage product categories and navigation categories for your application
            </p>
          </div>
        </div>

        <Tabs defaultValue="products" className="space-y-6">
          <TabsList className="grid w-full grid-cols-2">
            <TabsTrigger value="products" className="flex items-center gap-2">
              <Package className="h-4 w-4" />
              Product Categories
            </TabsTrigger>
            <TabsTrigger value="navigation" className="flex items-center gap-2">
              <Navigation className="h-4 w-4" />
              Navigation Categories
            </TabsTrigger>
          </TabsList>

          <TabsContent value="products" className="space-y-4">
            <div className="space-y-4">
              <div>
                <h3 className="text-lg font-medium">Product Categories</h3>
                <p className="text-sm text-muted-foreground">
                  Manage categories used for organizing products in your catalog. 
                  These categories help customers find products easily and are used for filtering and search.
                </p>
              </div>
              <CategoryTable />
            </div>
          </TabsContent>

          <TabsContent value="navigation" className="space-y-4">
            <div className="space-y-4">
              <div>
                <h3 className="text-lg font-medium">Navigation Categories</h3>
                <p className="text-sm text-muted-foreground">
                  Manage navigation categories for the Flutter mobile app. 
                  These categories appear in the main navigation and help users browse by beauty areas (Eyes, Face, Lips, etc.).
                  Each category includes keywords for product filtering and display order.
                </p>
              </div>
              <NavigationCategoryTable />
            </div>
          </TabsContent>
        </Tabs>
      </div>
    </DashboardLayout>
  );
} 