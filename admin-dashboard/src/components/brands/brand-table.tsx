"use client";

import React, { useState } from "react";
import { Brand } from "@/types/product";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import Image from "next/image";
import { Edit, Trash2, Plus } from "lucide-react";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { BrandForm } from "./brand-form";
import { useAllBrands, useDeleteBrand } from "@/hooks/use-categories";

export const BrandTable: React.FC = () => {
  const { data: brands = [], isLoading } = useAllBrands();
  const deleteMutation = useDeleteBrand();

  const [selected, setSelected] = useState<Brand | null>(null);
  const [showDialog, setShowDialog] = useState(false);

  const handleAdd = () => {
    setSelected(null);
    setShowDialog(true);
  };

  const handleEdit = (brand: Brand) => {
    setSelected(brand);
    setShowDialog(true);
  };

  const handleDelete = async (id: number) => {
    if (confirm("Delete this brand?")) {
      await deleteMutation.mutateAsync(id);
    }
  };

  return (
    <>
      <Card>
        <CardHeader>
          <CardTitle>Brands ({brands.length})</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex justify-end mb-4">
            <Button size="sm" onClick={handleAdd}>
              <Plus className="h-4 w-4 mr-2" /> New Brand
            </Button>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full table-auto">
              <thead>
                <tr className="border-b text-left">
                  <th className="pb-3 font-medium text-foreground">Logo</th>
                  <th className="pb-3 font-medium text-foreground">Name</th>
                  <th className="pb-3 font-medium text-foreground">Description</th>
                  <th className="pb-3 font-medium text-foreground">Actions</th>
                </tr>
              </thead>
              <tbody>
                {brands.map((b) => (
                  <tr key={b.id} className="border-b hover:bg-muted/50">
                    <td className="py-3">
                      {b.logo ? (
                        <Image src={b.logo} alt={b.name} width={40} height={40} className="rounded" />
                      ) : (
                        <span className="text-xs text-muted-foreground">No logo</span>
                      )}
                    </td>
                    <td className="py-3">{b.name}</td>
                    <td className="py-3 text-sm text-muted-foreground truncate max-w-xs">{b.description}</td>
                    <td className="py-3">
                      <div className="flex gap-2">
                        <Button variant="ghost" size="icon" onClick={() => handleEdit(b)}>
                          <Edit className="h-4 w-4" />
                        </Button>
                        <Button variant="ghost" size="icon" className="text-destructive" onClick={() => handleDelete(b.id)}>
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </div>
                    </td>
                  </tr>
                ))}
                {brands.length === 0 && !isLoading && (
                  <tr>
                    <td colSpan={4} className="py-6 text-center text-muted-foreground">
                      No brands yet
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>

      <Dialog open={showDialog} onOpenChange={setShowDialog}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>{selected ? "Edit Brand" : "New Brand"}</DialogTitle>
          </DialogHeader>
          <BrandForm
            brand={selected || undefined}
            onSuccess={() => setShowDialog(false)}
            onCancel={() => setShowDialog(false)}
          />
        </DialogContent>
      </Dialog>
    </>
  );
}; 