import React, { useEffect, useState } from 'react';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { EditProductForm } from './edit-product-form';
import { Product } from '@/types/product';
import { productsService } from '@/services/products';
import { Loader2 } from 'lucide-react';
import { toast } from 'react-hot-toast';

interface EditProductDialogProps {
  product: Product | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onSuccess: () => void;
}

export function EditProductDialog({
  product,
  open,
  onOpenChange,
  onSuccess,
}: EditProductDialogProps) {
  const [currentProduct, setCurrentProduct] = useState<Product | null>(product);
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    if (!open || !product) return;

    // If description exists and category + brand included, we can skip fetch
    const needsFetch =
      !product.description || !product.category || !product.brand;

    if (!needsFetch) {
      setCurrentProduct(product);
      return;
    }

    const fetchFullProduct = async () => {
      try {
        setIsLoading(true);
        const full = await productsService.getProduct(product.id);
        setCurrentProduct(full);
      } catch (err) {
        toast.error('Failed to load product details');
        setCurrentProduct(product); // fallback to partial
      } finally {
        setIsLoading(false);
      }
    };

    fetchFullProduct();
  }, [open, product]);

  if (!product) return null;

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-7xl max-h-[95vh] overflow-y-auto w-[95vw]">
        <DialogHeader>
          <DialogTitle className="text-2xl font-semibold text-slate-900">
            Edit Product: {product.name}
          </DialogTitle>
        </DialogHeader>
        {isLoading || !currentProduct ? (
          <div className="flex items-center justify-center py-20">
            <Loader2 className="h-6 w-6 animate-spin text-slate-500" />
          </div>
        ) : (
          <EditProductForm
            product={currentProduct}
            onSuccess={() => {
              onSuccess();
              onOpenChange(false);
            }}
            onCancel={() => onOpenChange(false)}
          />
        )}
      </DialogContent>
    </Dialog>
  );
} 