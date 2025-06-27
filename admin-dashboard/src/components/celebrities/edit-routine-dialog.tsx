'use client';

import React, { useState, useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import Image from 'next/image';
import { 
  Edit, 
  Package, 
  Sun, 
  Moon, 
  Loader2, 
  Save,
  X,
  GripVertical,
} from 'lucide-react';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import {
  Form,
  FormControl,
  FormDescription,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from '@/components/ui/form';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent } from '@/components/ui/card';
import { 
  useUpdateMorningRoutineItem, 
  useUpdateEveningRoutineItem,
} from '@/hooks/use-celebrities';
import { apiClient } from '@/lib/api';
import { CelebrityMorningRoutineItem, CelebrityEveningRoutineItem } from '@/types/celebrity';

// Form validation schema
const editRoutineItemSchema = z.object({
  order: z.number().min(1, 'Order must be at least 1').max(20, 'Order cannot exceed 20'),
  description: z.string()
    .max(500, 'Description must be less than 500 characters')
    .optional()
    .or(z.literal('')),
});

type EditRoutineItemFormValues = z.infer<typeof editRoutineItemSchema>;

interface EditRoutineDialogProps {
  routineItem: CelebrityMorningRoutineItem | CelebrityEveningRoutineItem;
  routineType: 'morning' | 'evening';
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function EditRoutineDialog({ 
  routineItem, 
  routineType, 
  open, 
  onOpenChange 
}: EditRoutineDialogProps) {
  // API hooks
  const updateMorningItem = useUpdateMorningRoutineItem();
  const updateEveningItem = useUpdateEveningRoutineItem();

  const form = useForm<EditRoutineItemFormValues>({
    resolver: zodResolver(editRoutineItemSchema),
    defaultValues: {
      order: routineItem.order,
      description: routineItem.description || '',
    },
  });

  // Reset form when dialog opens or routine item changes
  useEffect(() => {
    if (open && routineItem) {
      form.reset({
        order: routineItem.order,
        description: routineItem.description || '',
      });
    }
  }, [open, routineItem, form]);

  const onSubmit = async (values: EditRoutineItemFormValues) => {
    try {
      const updateData = {
        order: values.order,
        description: values.description || undefined,
      };

      if (routineType === 'morning') {
        await updateMorningItem.mutateAsync({
          id: routineItem.id,
          data: updateData,
        });
      } else {
        await updateEveningItem.mutateAsync({
          id: routineItem.id,
          data: updateData,
        });
      }
      
      handleClose();
    } catch (error) {
      console.error('Failed to update routine item:', error);
    }
  };

  const handleClose = () => {
    form.reset();
    onOpenChange(false);
  };

  const isLoading = updateMorningItem.isPending || updateEveningItem.isPending;
  const routineIcon = routineType === 'morning' ? Sun : Moon;
  const routineColor = routineType === 'morning' ? 'text-orange-600' : 'text-blue-600';
  const product = routineItem.product;

  return (
    <Dialog open={open} onOpenChange={handleClose}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            {React.createElement(routineIcon, { className: `h-5 w-5 ${routineColor}` })}
            Edit {routineType === 'morning' ? 'Morning' : 'Evening'} Routine Step
          </DialogTitle>
          <DialogDescription>
            Modify the order and instructions for this routine step.
          </DialogDescription>
        </DialogHeader>

        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
            {/* Product Display */}
            <div className="space-y-4">
              <h3 className="text-lg font-medium">Product</h3>
              
              <Card className="border-muted">
                <CardContent className="p-4">
                  <div className="flex items-center gap-4">
                    <div className="relative w-16 h-16 rounded-lg overflow-hidden bg-muted">
                      {product.featured_image ? (
                        <Image
                          src={apiClient.getMediaUrl(product.featured_image)}
                          alt={product.name}
                          fill
                          className="object-cover"
                        />
                      ) : (
                        <div className="w-full h-full bg-gradient-to-br from-muted to-muted/50 flex items-center justify-center">
                          <Package className="h-6 w-6 text-muted-foreground" />
                        </div>
                      )}
                    </div>
                    
                    <div className="flex-1">
                      <h4 className="font-medium text-foreground">{product.name}</h4>
                      {(product as any).brand && (
                        <p className="text-sm text-muted-foreground">by {(product as any).brand.name}</p>
                      )}
                      <div className="flex items-center gap-2 mt-1">
                        <Badge variant="secondary">{(product as any).category?.name || 'Unknown'}</Badge>
                                                  <span className="text-lg font-bold text-primary">
                            ${(product as any).sale_price || product.price}
                          </span>
                      </div>
                    </div>
                    
                    <div className="flex items-center gap-2 text-muted-foreground">
                      <GripVertical className="h-5 w-5" />
                      <span className="text-sm">Step #{routineItem.order}</span>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </div>

            {/* Routine Details */}
            <div className="space-y-4">
              <h3 className="text-lg font-medium">Routine Details</h3>
              
              <FormField
                control={form.control}
                name="order"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Step Order *</FormLabel>
                    <FormControl>
                      <Input
                        type="number"
                        min={1}
                        max={20}
                        placeholder="1"
                        {...field}
                        onChange={(e) => field.onChange(parseInt(e.target.value) || 1)}
                        className="transition-all focus:ring-2 focus:ring-primary/20"
                      />
                    </FormControl>
                    <FormDescription>
                      The order of this step in the {routineType} routine (1-20)
                    </FormDescription>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="description"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Instructions</FormLabel>
                    <FormControl>
                      <Textarea
                        placeholder="How to use this product in the routine. Include application tips, amount to use, and any special instructions..."
                        className="min-h-[120px] resize-none transition-all focus:ring-2 focus:ring-primary/20"
                        {...field}
                      />
                    </FormControl>
                    <FormDescription>
                      {form.watch('description')?.length || 0}/500 characters
                    </FormDescription>
                    <FormMessage />
                  </FormItem>
                )}
              />
            </div>

            {/* Current vs New Order Comparison */}
            {form.watch('order') !== routineItem.order && (
              <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
                <div className="flex items-center gap-2 text-blue-700">
                  <Edit className="h-4 w-4" />
                  <span className="text-sm font-medium">Order Change</span>
                </div>
                <p className="text-sm text-blue-600 mt-1">
                  Step order will change from #{routineItem.order} to #{form.watch('order')}
                </p>
              </div>
            )}

            <DialogFooter className="gap-2">
              <Button
                type="button"
                variant="outline"
                onClick={handleClose}
                disabled={isLoading}
              >
                Cancel
              </Button>
              <Button
                type="submit"
                disabled={isLoading}
                className="min-w-[120px]"
              >
                {isLoading ? (
                  <>
                    <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                    Saving...
                  </>
                ) : (
                  <>
                    <Save className="h-4 w-4 mr-2" />
                    Save Changes
                  </>
                )}
              </Button>
            </DialogFooter>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  );
}