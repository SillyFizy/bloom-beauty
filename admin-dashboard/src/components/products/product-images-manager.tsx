import React, { useEffect, useState } from 'react';
import { ProductImage } from '@/types/product';
import { productsService } from '@/services/products';
import { Button } from '@/components/ui/button';
import { ImageUpload } from '@/components/ui/image-upload';
import { toast } from 'react-hot-toast';
import { cn } from '@/lib/utils';
import { Loader2, Trash, Star } from 'lucide-react';

interface ProductImagesManagerProps {
  productId: number;
}

export const ProductImagesManager: React.FC<ProductImagesManagerProps> = ({ productId }) => {
  const [images, setImages] = useState<ProductImage[]>([]);
  const [uploading, setUploading] = useState(false);
  const [mainId, setMainId] = useState<number | null>(null);

  const fetchImages = async () => {
    try {
      const imgs = await productsService.getProductImages(productId);
      setImages(imgs);
      const main = imgs.find((i: any) => i.is_main);
      setMainId(main?.id ?? null);
    } catch {
      toast.error('Failed to load images');
    }
  };

  useEffect(() => {
    fetchImages();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [productId]);

  const handleDelete = async (id: number) => {
    try {
      await productsService.deleteProductImage(id);
      setImages((prev) => prev.filter((img) => img.id !== id));
      if (mainId === id) setMainId(null);
      toast.success('Image deleted');
    } catch {
      toast.error('Failed to delete image');
    }
  };

  const handleSetMain = async (id: number) => {
    try {
      // Patch current main false, new main true
      const currentMain = images.find((img) => img.id === mainId);
      if (currentMain) {
        await productsService.updateProductImage(currentMain.id, { is_main: false });
      }
      await productsService.updateProductImage(id, { is_main: true });
      setMainId(id);
      toast.success('Main image updated');
    } catch {
      toast.error('Failed to set main image');
    }
  };

  const handleImagesChange = async (files: File[]) => {
    if (!files.length) return;
    setUploading(true);
    try {
      for (let idx = 0; idx < files.length; idx++) {
        const file = files[idx];
        await productsService.uploadProductImage(productId, file, undefined, mainId === null && idx === 0);
      }
      toast.success('Images uploaded');
      await fetchImages();
    } catch {
      toast.error('Failed to upload images');
    } finally {
      setUploading(false);
    }
  };

  return (
    <div className="space-y-4">
      <h3 className="text-lg font-medium text-slate-800">Images</h3>
      <div className="grid grid-cols-3 md:grid-cols-4 gap-4">
        {images.map((img) => (
          <div key={img.id} className="relative group border rounded-lg overflow-hidden">
            <img src={img.image} alt="" className="object-cover aspect-square w-full" />
            <button
              type="button"
              onClick={() => handleDelete(img.id)}
              className="absolute top-1 right-1 bg-red-600/80 text-white p-1 rounded-md opacity-0 group-hover:opacity-100 transition"
            >
              <Trash className="h-4 w-4" />
            </button>
            <button
              type="button"
              onClick={() => handleSetMain(img.id)}
              className={cn(
                'absolute bottom-1 right-1 bg-white/80 p-1 rounded-full border',
                img.id === mainId ? 'text-yellow-500' : 'text-slate-500'
              )}
            >
              <Star className="h-4 w-4 fill-current" />
            </button>
          </div>
        ))}
        <ImageUpload
          existingImages={[]}
          maxImages={5 - images.length}
          onImagesChange={handleImagesChange}
        />
      </div>
      {uploading && <p className="text-sm text-slate-500">Uploading...</p>}
    </div>
  );
}; 