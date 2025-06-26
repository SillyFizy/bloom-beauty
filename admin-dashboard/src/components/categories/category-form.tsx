"use client";

import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import * as z from "zod";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { ImageUpload } from "@/components/ui/image-upload";
import { useCreateCategory, useUpdateCategory } from "@/hooks/use-categories";
import { Category } from "@/types/product";
import { Loader2 } from "lucide-react";
import React, { useState } from "react";

const schema = z.object({
  name: z.string().min(1, "Name is required"),
  description: z.string().optional(),
  image: z.any().optional(),
  is_active: z.boolean().default(true),
});

export type CategoryFormData = z.infer<typeof schema>;

interface Props {
  category?: Category; // if provided -> edit mode
  onSuccess?: () => void;
  onCancel?: () => void;
}

export const CategoryForm: React.FC<Props> = ({ category, onSuccess, onCancel }) => {
  const {
    register,
    handleSubmit,
    setValue,
    formState: { errors, isSubmitting },
  } = useForm<CategoryFormData>({
    resolver: zodResolver(schema),
    defaultValues: {
      name: category?.name ?? "",
      description: category?.description ?? "",
      is_active: category ? (category as any).is_active ?? true : true,
    },
  });

  const [imageFile, setImageFile] = useState<File | undefined>(category ? undefined : undefined);

  const createMutation = useCreateCategory();
  const updateMutation = useUpdateCategory();

  const onSubmit = async (data: CategoryFormData) => {
    if (!imageFile && !category) {
      alert("Image is required");
      return;
    }
    const payload = { ...data, image: imageFile, is_active: data.is_active };
    if (category) {
      await updateMutation.mutateAsync({ id: category.id, data: payload });
    } else {
      await createMutation.mutateAsync(payload);
    }
    onSuccess?.();
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
      <div className="space-y-1">
        <label className="text-sm font-medium">Name</label>
        <Input placeholder="Category name" {...register("name")} />
        {errors.name && <p className="text-xs text-destructive mt-1">{errors.name.message}</p>}
      </div>

      <div className="space-y-1">
        <label className="text-sm font-medium">Description</label>
        <Textarea rows={3} placeholder="Optional description" {...register("description")} />
      </div>

      <div className="space-y-1">
        <label className="text-sm font-medium">Image</label>
        <ImageUpload
          existingImages={category?.image ? [category.image] : []}
          onImagesChange={(files) => setImageFile(files[0])}
          maxImages={1}
        />
      </div>

      <div className="flex items-center space-x-2">
        <input type="checkbox" id="active" {...register("is_active")}
          defaultChecked={true}
          className="rounded border-slate-300" />
        <label htmlFor="active" className="text-sm">Active</label>
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