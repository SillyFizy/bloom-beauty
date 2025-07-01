"use client";

import React, { useState } from "react";
import { NavigationCategory } from "@/types/navigation-category";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Switch } from "@/components/ui/switch";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import Image from "next/image";
import { 
  Edit, 
  Trash2, 
  Plus, 
  Search, 
  Eye, 
  EyeOff,
  ArrowUpDown,
  ImageIcon
} from "lucide-react";
import {
  useNavigationCategories,
  useDeleteNavigationCategory,
  useBulkUpdateNavigationCategories,
} from "@/hooks/use-navigation-categories";
import { NavigationCategoryForm } from "./navigation-category-form";

export const NavigationCategoryTable: React.FC = () => {
  const { data: categoriesData = [], isLoading, error } = useNavigationCategories();
  const deleteMutation = useDeleteNavigationCategory();
  const bulkUpdateMutation = useBulkUpdateNavigationCategories();

  // Ensure categories is always an array
  const categories = Array.isArray(categoriesData) ? categoriesData : [];

  const [selected, setSelected] = useState<NavigationCategory | null>(null);
  const [showDialog, setShowDialog] = useState(false);
  const [searchTerm, setSearchTerm] = useState("");
  const [showInactive, setShowInactive] = useState(false);

  // Filter categories based on search and active status
  const filteredCategories = categories.filter((category) => {
    const matchesSearch = !searchTerm || 
      category.name.toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesStatus = showInactive || category.is_active;
    
    return matchesSearch && matchesStatus;
  });

  // Sort categories by order, then by name
  const sortedCategories = [...filteredCategories].sort((a, b) => {
    if (a.order !== b.order) {
      return a.order - b.order;
    }
    return a.name.localeCompare(b.name);
  });

  const handleEdit = (category: NavigationCategory) => {
    setSelected(category);
    setShowDialog(true);
  };

  const handleAdd = () => {
    setSelected(null);
    setShowDialog(true);
  };

  const handleDelete = async (id: number, name: string) => {
    if (confirm(`Are you sure you want to delete "${name}"? This action cannot be undone.`)) {
      await deleteMutation.mutateAsync(id);
    }
  };

  const handleToggleActive = async (category: NavigationCategory) => {
    await bulkUpdateMutation.mutateAsync([{
      id: category.id,
      is_active: !category.is_active,
    }]);
  };

  if (error) {
    return (
      <Card>
        <CardContent className="p-6">
          <div className="text-center text-destructive">
            Failed to load navigation categories. Please try again.
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <>
      <Card>
        <CardHeader>
          <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
            <div>
              <CardTitle>Navigation Categories</CardTitle>
              <p className="text-sm text-muted-foreground mt-1">
                Manage categories for the Flutter app navigation
              </p>
            </div>
            <Button onClick={handleAdd} size="sm">
              <Plus className="h-4 w-4 mr-2" />
              Add Category
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          {/* Filters */}
          <div className="flex flex-col sm:flex-row gap-4 mb-6">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Search categories..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-10"
              />
            </div>
            <div className="flex items-center space-x-2">
              <Switch
                id="show-inactive"
                checked={showInactive}
                onCheckedChange={setShowInactive}
              />
              <label htmlFor="show-inactive" className="text-sm font-medium">
                Show inactive
              </label>
            </div>
          </div>

          {/* Statistics Cards */}
          <div className="grid grid-cols-1 sm:grid-cols-5 gap-4 mb-6">
            <div className="bg-muted/50 rounded-lg p-3">
              <div className="text-2xl font-bold">{categories.length}</div>
              <div className="text-xs text-muted-foreground">Total Categories</div>
            </div>
            <div className="bg-green-50 dark:bg-green-950 rounded-lg p-3">
              <div className="text-2xl font-bold text-green-600 dark:text-green-400">
                {categories.filter(c => c.is_active).length}
              </div>
              <div className="text-xs text-muted-foreground">Active</div>
            </div>
            <div className="bg-red-50 dark:bg-red-950 rounded-lg p-3">
              <div className="text-2xl font-bold text-red-600 dark:text-red-400">
                {categories.filter(c => !c.is_active).length}
              </div>
              <div className="text-xs text-muted-foreground">Inactive</div>
            </div>
            <div className="bg-blue-50 dark:bg-blue-950 rounded-lg p-3">
              <div className="text-2xl font-bold text-blue-600 dark:text-blue-400">
                {categories.filter(c => c.image_url).length}
              </div>
              <div className="text-xs text-muted-foreground">With Images</div>
            </div>
            <div className="bg-purple-50 dark:bg-purple-950 rounded-lg p-3">
              <div className="text-2xl font-bold text-purple-600 dark:text-purple-400">
                {categories.reduce((total, c) => total + (c.product_count || 0), 0)}
              </div>
              <div className="text-xs text-muted-foreground">Total Products</div>
            </div>
          </div>

          {/* Table */}
          <div className="rounded-lg border">
            <table className="w-full">
              <thead>
                <tr className="border-b text-left">
                  <th className="pb-3 font-medium text-foreground">Image</th>
                  <th className="pb-3 font-medium text-foreground">
                    <Button variant="ghost" size="sm" className="h-auto p-0 font-medium">
                      Name <ArrowUpDown className="ml-1 h-3 w-3" />
                    </Button>
                  </th>
                  <th className="pb-3 font-medium text-foreground">
                    <Button variant="ghost" size="sm" className="h-auto p-0 font-medium">
                      Order <ArrowUpDown className="ml-1 h-3 w-3" />
                    </Button>
                  </th>
                  <th className="pb-3 font-medium text-foreground">Products</th>
                  <th className="pb-3 font-medium text-foreground">Status</th>
                  <th className="pb-3 font-medium text-foreground">Actions</th>
                </tr>
              </thead>
              <tbody>
                {isLoading ? (
                  <tr>
                    <td colSpan={6} className="py-6 text-center text-muted-foreground">
                      Loading categories...
                    </td>
                  </tr>
                ) : sortedCategories.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="py-6 text-center text-muted-foreground">
                      {searchTerm || !showInactive ? 'No categories found' : 'No categories yet'}
                    </td>
                  </tr>
                ) : (
                  sortedCategories.map((category) => (
                    <tr key={category.id} className="border-b hover:bg-muted/50">
                      <td className="py-3">
                        {category.image_url ? (
                          <div className="relative w-10 h-10 rounded-lg overflow-hidden">
                            <Image
                              src={category.image_url}
                              alt={category.name}
                              fill
                              className="object-cover"
                            />
                          </div>
                        ) : (
                          <div className="w-10 h-10 rounded-lg bg-muted flex items-center justify-center">
                            <ImageIcon className="h-4 w-4 text-muted-foreground" />
                          </div>
                        )}
                      </td>
                      <td className="py-3">
                        <div className="font-medium">{category.name}</div>
                      </td>
                      <td className="py-3">
                        <Badge variant="outline">{category.order}</Badge>
                      </td>
                      <td className="py-3">
                        <Badge variant={category.product_count > 0 ? "default" : "secondary"}>
                          {category.product_count || 0}
                        </Badge>
                      </td>
                      <td className="py-3">
                        <Badge variant={category.is_active ? "default" : "secondary"}>
                          {category.is_active ? "Active" : "Inactive"}
                        </Badge>
                      </td>
                      <td className="py-3">
                        <div className="flex items-center space-x-2">
                          <Button
                            variant="ghost"
                            size="icon"
                            className="h-8 w-8"
                            onClick={() => handleEdit(category)}
                          >
                            <Edit className="h-4 w-4" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="icon"
                            className="h-8 w-8"
                            onClick={() => handleToggleActive(category)}
                          >
                            {category.is_active ? (
                              <Eye className="h-4 w-4" />
                            ) : (
                              <EyeOff className="h-4 w-4" />
                            )}
                          </Button>
                          <Button
                            variant="ghost"
                            size="icon"
                            className="h-8 w-8 text-destructive hover:text-destructive"
                            onClick={() => handleDelete(category.id, category.name)}
                          >
                            <Trash2 className="h-4 w-4" />
                          </Button>
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>

      {/* Dialog */}
      <Dialog open={showDialog} onOpenChange={setShowDialog}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>
              {selected ? "Edit Navigation Category" : "Add Navigation Category"}
            </DialogTitle>
          </DialogHeader>
          <NavigationCategoryForm
            category={selected || undefined}
            onSuccess={() => setShowDialog(false)}
            onCancel={() => setShowDialog(false)}
          />
        </DialogContent>
      </Dialog>
    </>
  );
}; 