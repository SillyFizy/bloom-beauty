"use client";

import React, { useState } from "react";
import { Category } from "@/types/product";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import Image from "next/image";
import { Edit, Trash2, Plus } from "lucide-react";
import { CategoryForm } from "./category-form";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { useAllCategories, useDeleteCategory } from "@/hooks/use-categories";

export const CategoryTable: React.FC = () => {
  const { data: categories = [], isLoading } = useAllCategories();
  const deleteMutation = useDeleteCategory();

  const [selected, setSelected] = useState<Category | null>(null);
  const [showDialog, setShowDialog] = useState(false);

  const handleEdit = (cat: Category) => {
    setSelected(cat);
    setShowDialog(true);
  };

  const handleAdd = () => {
    setSelected(null);
    setShowDialog(true);
  };

  const handleDelete = async (id: number) => {
    if (confirm("Delete this category?")) {
      await deleteMutation.mutateAsync(id);
    }
  };

  return (
    <>
      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle>Categories ({categories.length})</CardTitle>
          <Button size="sm" onClick={handleAdd}>
            <Plus className="h-4 w-4 mr-2" /> New Category
          </Button>
        </CardHeader>
        <CardContent>
          <div className="overflow-x-auto">
            <table className="w-full table-auto">
              <thead>
                <tr className="border-b text-left">
                  <th className="pb-3 font-medium text-foreground">Image</th>
                  <th className="pb-3 font-medium text-foreground">Name</th>
                  <th className="pb-3 font-medium text-foreground">Description</th>
                  <th className="pb-3 font-medium text-foreground">Actions</th>
                </tr>
              </thead>
              <tbody>
                {categories.map((cat: any) => (
                  <tr key={cat.id} className="border-b hover:bg-muted/50">
                    <td className="py-3">
                      {cat.image ? (
                        <Image src={cat.image} alt={cat.name} width={40} height={40} className="rounded" />
                      ) : (
                        <span className="text-xs text-muted-foreground">No image</span>
                      )}
                    </td>
                    <td className="py-3">{cat.name}</td>
                    <td className="py-3 text-sm text-muted-foreground truncate max-w-xs">{cat.description}</td>
                    <td className="py-3">
                      <div className="flex gap-2">
                        <Button variant="ghost" size="icon" onClick={() => handleEdit(cat)}>
                          <Edit className="h-4 w-4" />
                        </Button>
                        <Button variant="ghost" size="icon" className="text-destructive" onClick={() => handleDelete(cat.id)}>
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </div>
                    </td>
                  </tr>
                ))}
                {categories.length === 0 && !isLoading && (
                  <tr>
                    <td colSpan={4} className="py-6 text-center text-muted-foreground">
                      No categories yet
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>

      {/* Dialog */}
      <Dialog open={showDialog} onOpenChange={setShowDialog}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>{selected ? "Edit Category" : "New Category"}</DialogTitle>
          </DialogHeader>
          <CategoryForm
            category={selected || undefined}
            onSuccess={() => setShowDialog(false)}
            onCancel={() => setShowDialog(false)}
          />
        </DialogContent>
      </Dialog>
    </>
  );
}; 