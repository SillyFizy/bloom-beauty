"use client";

import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import * as z from "zod";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { useCreateBrand, useUpdateBrand } from "@/hooks/use-categories";
import { Brand } from "@/types/product";
import { Loader2 } from "lucide-react";
import React from "react";

const schema = z.object({
  name: z.string().min(1, "Name is required"),
  description: z.string().optional(),
});

export type BrandFormData = z.infer<typeof schema>;

interface Props {
  brand?: Brand;
  onSuccess?: () => void;
  onCancel?: () => void;
}

export const BrandForm: React.FC<Props> = ({ brand, onSuccess, onCancel }) => {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<BrandFormData>({
    resolver: zodResolver(schema),
    defaultValues: {
      name: brand?.name ?? "",
      description: brand?.description ?? "",
    },
  });

  const createMutation = useCreateBrand();
  const updateMutation = useUpdateBrand();

  const onSubmit = async (data: BrandFormData) => {
    const payload = { ...data };
    if (brand) {
      await updateMutation.mutateAsync({ id: brand.id, data: payload });
    } else {
      await createMutation.mutateAsync(payload);
    }
    onSuccess?.();
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
      <div className="space-y-1">
        <label className="text-sm font-medium">Name</label>
        <Input placeholder="Brand name" {...register("name")} />
        {errors.name && <p className="text-xs text-destructive mt-1">{errors.name.message}</p>}
      </div>

      <div className="space-y-1">
        <label className="text-sm font-medium">Description</label>
        <Textarea rows={3} placeholder="Optional description" {...register("description")} />
      </div>

      <div className="flex justify-end gap-2 pt-4">
        {onCancel && (
          <Button type="button" variant="outline" onClick={onCancel} disabled={isSubmitting}>
            Cancel
          </Button>
        )}
        <Button type="submit" disabled={isSubmitting}>
          {isSubmitting && <Loader2 className="animate-spin h-4 w-4 mr-2" />}Save
        </Button>
      </div>
    </form>
  );
}; 