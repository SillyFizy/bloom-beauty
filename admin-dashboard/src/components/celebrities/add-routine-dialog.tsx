'use client';

import React, { useState, useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import Image from 'next/image';
import { 
  Plus, 
  Search, 
  Package, 
  Sun, 
  Moon, 
  Loader2, 
  Check,
  X,
  ChevronDown,
  Star,
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
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent } from '@/components/ui/card';
import { Separator } from '@/components/ui/separator';
import { 
  useAddMorningRoutineItem, 
  useAddEveningRoutineItem,
} from '@/hooks/use-celebrities';
import { useProducts } from '@/hooks/use-products';
import { apiClient } from '@/lib/api';
import { Product } from '@/types/product';

// Form validation schema
const addRoutineItemSchema = z.object({
  product_id: z.number().min(1, 'Please select a product'),
  order: z.number().min(1, 'Order must be at least 1').max(20, 'Order cannot exceed 20'),
  description: z.string()
    .max(500, 'Description must be less than 500 characters')
    .optional()
    .or(z.literal('')),
});

type AddRoutineItemFormValues = z.infer<typeof addRoutineItemSchema>;

interface AddRoutineDialogProps {
  celebrityId: number;
  celebrityName: string;
  routineType: 'morning' | 'evening';
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function AddRoutineDialog({ 
  celebrityId, 
  celebrityName, 
  routineType, 
  open, 
  onOpenChange 
}: AddRoutineDialogProps) {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedProduct, setSelectedProduct] = useState<Product | null>(null);
  const [showProductList, setShowProductList] = useState(false);

  // API hooks
  const { data: productsData, isLoading: loadingProducts } = useProducts({ 
    search: searchQuery,
    page_size: 50,
    is_active: true 
  });
  const addMorningItem = useAddMorningRoutineItem();
  const addEveningItem = useAddEveningRoutineItem();

  const form = useForm<AddRoutineItemFormValues>({
    resolver: zodResolver(addRoutineItemSchema),
    defaultValues: {
      product_id: 0,
      order: 1,
      description: '',
    },
  });

  const products = (productsData as any)?.results || [];

  // Reset form when dialog opens/closes
  useEffect(() => {
    if (open) {
      form.reset({
        product_id: 0,
        order: 1,
        description: '',
      });
      setSelectedProduct(null);
      setSearchQuery('');
      setShowProductList(false);
    }
  }, [open, form]);

  const handleProductSelect = (product: Product) => {
    setSelectedProduct(product);
    form.setValue('product_id', product.id);
    setShowProductList(false);
    form.clearErrors('product_id');
    
    // Auto-generate description based on product
    if (!form.getValues('description')) {
      const defaultDesc = `Apply ${product.name}${product.brand ? ` by ${product.brand.name}` : ''} for best results.`;
      form.setValue('description', defaultDesc);
    }
  };

  const onSubmit = async (values: AddRoutineItemFormValues) => {
    try {
      const routineData = {
        celebrity_id: celebrityId,
        product_id: values.product_id,
        order: values.order,
        description: values.description || undefined,
      };

      if (routineType === 'morning') {
        await addMorningItem.mutateAsync(routineData);
      } else {
        await addEveningItem.mutateAsync(routineData);
      }
      
      handleClose();
    } catch (error) {
      console.error('Failed to add routine item:', error);
    }
  };

  const handleClose = () => {
    form.reset();
    setSelectedProduct(null);
    setSearchQuery('');
    setShowProductList(false);
    onOpenChange(false);
  };

  const isLoading = addMorningItem.isPending || addEveningItem.isPending;
  const routineIcon = routineType === 'morning' ? Sun : Moon;
  const routineColor = routineType === 'morning' ? 'text-orange-600' : 'text-blue-600';

  return (
    <Dialog open={open} onOpenChange={handleClose}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            {React.createElement(routineIcon, { className: `h-5 w-5 ${routineColor}` })}
            Add {routineType === 'morning' ? 'Morning' : 'Evening'} Routine Step
          </DialogTitle>
          <DialogDescription>
            Add a new step to {celebrityName}'s {routineType} routine. Select a product and specify the order and instructions.
          </DialogDescription>
        </DialogHeader>

        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
            {/* Product Selection */}
            <div className="space-y-4">
              <h3 className="text-lg font-medium">Product Selection</h3>
              
              {/* Selected Product Display */}
              {selectedProduct ? (
                <Card className="border-primary">
                  <CardContent className="p-4">
                    <div className="flex items-center gap-4">
                      <div className="relative w-16 h-16 rounded-lg overflow-hidden bg-muted">
                        {selectedProduct.featured_image ? (
                          <Image
                            src={apiClient.getMediaUrl(selectedProduct.featured_image)}
                            alt={selectedProduct.name}
                            fill
                            className="object-cover"
                          />
                        ) : (
                          <div className="w-full h-full bg-gradient-to-br from-primary/20 to-primary/5 flex items-center justify-center">
                            <Package className="h-6 w-6 text-primary/40" />
                          </div>
                        )}
                      </div>
                      
                      <div className="flex-1">
                        <h4 className="font-medium text-foreground">{selectedProduct.name}</h4>
                        {selectedProduct.brand && (
                          <p className="text-sm text-muted-foreground">by {selectedProduct.brand.name}</p>
                        )}
                        <div className="flex items-center gap-2 mt-1">
                          <Badge variant="secondary">{selectedProduct.category?.name || 'Unknown'}</Badge>
                          <span className="text-lg font-bold text-primary">
                            ${selectedProduct.sale_price ?? selectedProduct.price}
                          </span>
                        </div>
                      </div>
                      
                      <Button
                        type="button"
                        variant="ghost"
                        size="sm"
                        onClick={() => {
                          setSelectedProduct(null);
                          form.setValue('product_id', 0);
                          setShowProductList(true);
                        }}
                      >
                        <X className="h-4 w-4" />
                      </Button>
                    </div>
                  </CardContent>
                </Card>
              ) : (
                <div className="space-y-3">
                  {/* Search Input */}
                  <div className="relative">
                    <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                    <Input
                      placeholder="Search products by name, brand, or category..."
                      value={searchQuery}
                      onChange={(e) => {
                        setSearchQuery(e.target.value);
                        setShowProductList(true);
                      }}
                      onFocus={() => setShowProductList(true)}
                      className="pl-10"
                    />
                  </div>

                  {/* Product List */}
                  {showProductList && (
                    <Card className="max-h-64 overflow-y-auto">
                      <CardContent className="p-2">
                        {loadingProducts ? (
                          <div className="flex items-center justify-center py-4">
                            <Loader2 className="h-5 w-5 animate-spin mr-2" />
                            <span className="text-sm text-muted-foreground">Loading products...</span>
                          </div>
                        ) : products.length > 0 ? (
                          <div className="space-y-1">
                            {products.map((product: any) => (
                              <div
                                key={product.id}
                                className="flex items-center gap-3 p-2 rounded-lg hover:bg-muted cursor-pointer transition-colors"
                                onClick={() => handleProductSelect(product)}
                              >
                                <div className="relative w-10 h-10 rounded overflow-hidden bg-muted">
                                  {product.featured_image ? (
                                    <Image
                                      src={apiClient.getMediaUrl(product.featured_image)}
                                      alt={product.name}
                                      fill
                                      className="object-cover"
                                    />
                                  ) : (
                                    <div className="w-full h-full bg-gradient-to-br from-muted to-muted/50 flex items-center justify-center">
                                      <Package className="h-4 w-4 text-muted-foreground" />
                                    </div>
                                  )}
                                </div>
                                
                                <div className="flex-1">
                                  <h4 className="text-sm font-medium text-foreground">{product.name}</h4>
                                  <p className="text-xs text-muted-foreground">
                                    {product.brand?.name} • {product.category?.name}
                                  </p>
                                </div>
                                
                                <div className="text-sm font-medium text-primary">
                                  ${product.sale_price || product.price}
                                </div>
                              </div>
                            ))}
                          </div>
                        ) : (
                          <div className="text-center py-4 text-muted-foreground">
                            <Package className="h-8 w-8 mx-auto mb-2 opacity-50" />
                            <p className="text-sm">No products found</p>
                          </div>
                        )}
                      </CardContent>
                    </Card>
                  )}
                </div>
              )}

              {/* Hidden field for product_id */}
              <FormField
                control={form.control}
                name="product_id"
                render={({ field }) => (
                  <FormItem className="hidden">
                    <FormControl>
                      <Input type="hidden" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
            </div>

            <Separator />

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
                        className="min-h-[100px] resize-none transition-all focus:ring-2 focus:ring-primary/20"
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

            {/* Error Display */}
            {form.formState.errors.product_id && (
              <div className="p-4 bg-destructive/10 border border-destructive/20 rounded-lg">
                <p className="text-sm text-destructive">
                  Please select a product for this routine step.
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
                disabled={isLoading || !selectedProduct}
                className="min-w-[140px]"
              >
                {isLoading ? (
                  <>
                    <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                    Adding Step...
                  </>
                ) : (
                  <>
                    <Plus className="h-4 w-4 mr-2" />
                    Add to Routine
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