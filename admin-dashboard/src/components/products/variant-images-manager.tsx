import React, { useState, useCallback, useRef } from 'react';
import { toast } from 'react-hot-toast';
import { productsService } from '@/services/products';
import type { VariantImage } from '@/types/variant';
import { 
  Upload, 
  X, 
  Star, 
  StarOff, 
  ImageIcon,
  AlertCircle,
  Loader2
} from 'lucide-react';
import { Button } from '@/components/ui/button';

interface VariantImagesManagerProps {
  variantId: number;
  images: VariantImage[];
  onImagesChange: (images: VariantImage[]) => void;
}

export const VariantImagesManager: React.FC<VariantImagesManagerProps> = ({
  variantId,
  images,
  onImagesChange,
}) => {
  const [uploading, setUploading] = useState(false);
  const [dragOver, setDragOver] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFileSelect = useCallback(async (files: File[]) => {
    if (files.length === 0) return;

    // Validate file sizes and types
    const maxSize = 10 * 1024 * 1024; // 10MB
    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
    
    const invalidFiles = files.filter(file => 
      file.size > maxSize || !allowedTypes.includes(file.type)
    );
    
    if (invalidFiles.length > 0) {
      toast.error(`Some files are too large (>10MB) or invalid format. Only JPG, PNG, WEBP allowed.`);
      return;
    }

    setUploading(true);
    try {
      const hasMainImage = images.some(img => img.is_main);
      
      const uploadPromises = files.map(async (file, index) => {
        // First image becomes main if no main image exists
        const shouldBeMain = !hasMainImage && index === 0;
        return productsService.uploadVariantImage(variantId, file, file.name, shouldBeMain);
      });

      const uploadedImages = await Promise.all(uploadPromises);
      const updatedImages = [...images, ...uploadedImages];
      onImagesChange(updatedImages);
      toast.success(`${files.length} image(s) uploaded successfully`);
    } catch (error: any) {
      console.error('Upload error:', error);
      const message = error?.message || 'Failed to upload images. Please check your authentication and try again.';
      toast.error(message);
    } finally {
      setUploading(false);
    }
  }, [variantId, images, onImagesChange]);

  const handleFileInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files || []);
    handleFileSelect(files);
    e.target.value = ''; // Reset input
  };

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setDragOver(false);
    const files = Array.from(e.dataTransfer.files).filter(file => 
      file.type.startsWith('image/')
    );
    handleFileSelect(files);
  }, [handleFileSelect]);

  const handleDragOver = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setDragOver(true);
  }, []);

  const handleDragLeave = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setDragOver(false);
  }, []);

  const handleSetMain = async (imageId: number) => {
    try {
      // Update the image to be main
      await productsService.updateVariantImage(imageId, { is_main: true });
      
      // Update local state
      const updatedImages = images.map(img => ({
        ...img,
        is_main: img.id === imageId
      }));
      onImagesChange(updatedImages);
      toast.success('Main image updated');
    } catch (error: any) {
      console.error('Set main image error:', error);
      const message = error?.message || 'Failed to update main image. Please check your authentication.';
      toast.error(message);
    }
  };

  const handleDelete = async (imageId: number) => {
    if (!confirm('Delete this image? This action cannot be undone.')) return;

    try {
      await productsService.deleteVariantImage(imageId);
      const updatedImages = images.filter(img => img.id !== imageId);
      onImagesChange(updatedImages);
      toast.success('Image deleted');
    } catch (error: any) {
      console.error('Delete image error:', error);
      const message = error?.message || 'Failed to delete image. Please check your authentication.';
      toast.error(message);
    }
  };

  const mainImage = images.find(img => img.is_main);
  const otherImages = images.filter(img => !img.is_main);

  return (
    <div className="space-y-6">
      {/* Upload Area */}
      <div
        className={`
          relative border-2 border-dashed rounded-xl p-8 text-center transition-all duration-200
          ${dragOver 
            ? 'border-blue-400 bg-blue-50 scale-[1.02]' 
            : 'border-slate-300 hover:border-slate-400 hover:bg-slate-50'
          }
          ${uploading ? 'pointer-events-none opacity-60' : 'cursor-pointer'}
        `}
        onDrop={handleDrop}
        onDragOver={handleDragOver}
        onDragLeave={handleDragLeave}
        onClick={() => fileInputRef.current?.click()}
      >
        <input
          type="file"
          ref={fileInputRef}
          onChange={handleFileInputChange}
          multiple
          accept="image/*"
          className="hidden"
        />
        
        {uploading ? (
          <div className="flex flex-col items-center gap-3">
            <Loader2 className="w-8 h-8 text-blue-500 animate-spin" />
            <p className="text-slate-600 font-medium">Uploading images...</p>
          </div>
        ) : (
          <div className="flex flex-col items-center gap-3">
            <div className="p-3 bg-blue-100 rounded-full">
              <Upload className="w-6 h-6 text-blue-600" />
            </div>
            <div>
              <p className="text-slate-700 font-medium">
                Drop images here or click to browse
              </p>
              <p className="text-sm text-slate-500 mt-1">
                PNG, JPG, WEBP up to 10MB each
              </p>
            </div>
          </div>
        )}
      </div>

      {/* Images Grid */}
      {images.length > 0 ? (
        <div className="space-y-6">
          {/* Main Image */}
          {mainImage && (
            <div>
              <h4 className="text-sm font-semibold text-slate-700 mb-3 flex items-center gap-2">
                <Star className="w-4 h-4 text-amber-500 fill-amber-500" />
                Main Image
              </h4>
              <div className="relative group">
                <div className="relative w-32 h-32 rounded-lg overflow-hidden border-2 border-amber-200 shadow-sm">
                  <img
                    src={mainImage.image}
                    alt={mainImage.alt_text || 'Main variant image'}
                    className="w-full h-full object-cover"
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-black/20 to-transparent" />
                  <div className="absolute top-2 right-2 opacity-0 group-hover:opacity-100 transition-opacity">
                    <Button
                      size="sm"
                      variant="destructive"
                      className="w-6 h-6 p-0 rounded-full"
                      onClick={() => handleDelete(mainImage.id)}
                    >
                      <X className="w-3 h-3" />
                    </Button>
                  </div>
                  <div className="absolute bottom-2 left-2">
                    <div className="flex items-center gap-1 px-2 py-1 bg-amber-500 text-white text-xs rounded-full font-medium">
                      <Star className="w-3 h-3 fill-white" />
                      Main
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* Other Images */}
          {otherImages.length > 0 && (
            <div>
              <h4 className="text-sm font-semibold text-slate-700 mb-3 flex items-center gap-2">
                <ImageIcon className="w-4 h-4 text-slate-500" />
                Additional Images ({otherImages.length})
              </h4>
              <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 gap-4">
                {otherImages.map((image) => (
                  <div key={image.id} className="relative group">
                    <div className="relative w-full aspect-square rounded-lg overflow-hidden border border-slate-200 shadow-sm hover:shadow-md transition-shadow">
                      <img
                        src={image.image}
                        alt={image.alt_text || 'Variant image'}
                        className="w-full h-full object-cover"
                      />
                      <div className="absolute inset-0 bg-gradient-to-t from-black/20 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />
                      
                      {/* Action buttons */}
                      <div className="absolute top-2 right-2 opacity-0 group-hover:opacity-100 transition-opacity space-y-1">
                        <Button
                          size="sm"
                          variant="secondary"
                          className="w-6 h-6 p-0 rounded-full bg-white/90 hover:bg-white"
                          onClick={() => handleSetMain(image.id)}
                          title="Set as main image"
                        >
                          <StarOff className="w-3 h-3" />
                        </Button>
                        <Button
                          size="sm"
                          variant="destructive"
                          className="w-6 h-6 p-0 rounded-full"
                          onClick={() => handleDelete(image.id)}
                          title="Delete image"
                        >
                          <X className="w-3 h-3" />
                        </Button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* No main image warning */}
          {!mainImage && images.length > 0 && (
            <div className="flex items-center gap-2 p-3 bg-amber-50 border border-amber-200 rounded-lg">
              <AlertCircle className="w-4 h-4 text-amber-600 flex-shrink-0" />
              <p className="text-sm text-amber-700">
                No main image selected. Click the star icon on any image to set it as the main image.
              </p>
            </div>
          )}
        </div>
      ) : (
        /* Empty State */
        <div className="text-center py-8 px-4 bg-slate-50 rounded-lg border-2 border-dashed border-slate-300">
          <ImageIcon className="w-12 h-12 text-slate-400 mx-auto mb-3" />
          <h3 className="font-medium text-slate-700 mb-2">No images yet</h3>
          <p className="text-slate-500 text-sm mb-4">
            Upload images for this variant. The first image will automatically become the main image.
          </p>
          <p className="text-xs text-slate-400">
            💡 Tip: You can drag & drop multiple images at once
          </p>
        </div>
      )}
    </div>
  );
}; 