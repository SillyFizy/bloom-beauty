import React, { useState, useCallback } from 'react';
import { useDropzone } from 'react-dropzone';
import { X, Upload } from 'lucide-react';
import Image from 'next/image';
import { apiClient } from '@/lib/api';
import type { ProductImage } from '@/types/product';

interface ImageUploadProps {
  existingImages?: (string | ProductImage)[];
  onImagesChange: (files: File[]) => void;
  maxImages?: number;
}

export function ImageUpload({ existingImages = [], onImagesChange, maxImages = 5 }: ImageUploadProps) {
  const [selectedFiles, setSelectedFiles] = useState<File[]>([]);

  // Normalize existingImages into URL strings
  const normalizeUrl = (item: string | ProductImage): string => {
    if (typeof item === 'string') return item;
    return apiClient.getMediaUrl(item.image);
  };

  const [previewUrls, setPreviewUrls] = useState<string[]>(existingImages.map(normalizeUrl));

  const onDrop = useCallback((acceptedFiles: File[]) => {
    const remainingSlots = maxImages - previewUrls.length;
    const newFiles = acceptedFiles.slice(0, remainingSlots);

    setSelectedFiles(prev => [...prev, ...newFiles]);
    setPreviewUrls(prev => [
      ...prev,
      ...newFiles.map(file => URL.createObjectURL(file))
    ]);
    onImagesChange([...selectedFiles, ...newFiles]);
  }, [maxImages, previewUrls.length, selectedFiles, onImagesChange]);

  const removeImage = (index: number) => {
    setPreviewUrls(prev => prev.filter((_, i) => i !== index));
    setSelectedFiles(prev => prev.filter((_, i) => i !== index));
    onImagesChange(selectedFiles.filter((_, i) => i !== index));
  };

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: {
      'image/*': ['.jpeg', '.jpg', '.png', '.webp']
    },
    maxFiles: maxImages - previewUrls.length,
    disabled: previewUrls.length >= maxImages
  });

  return (
    <div className="space-y-4">
      <div
        {...getRootProps()}
        className={`border-2 border-dashed rounded-xl p-6 text-center cursor-pointer transition-colors
          ${isDragActive ? 'border-primary bg-primary/5' : 'border-slate-200 hover:border-primary'}
          ${previewUrls.length >= maxImages ? 'opacity-50 cursor-not-allowed' : ''}
        `}
      >
        <input {...getInputProps()} />
        <Upload className="h-10 w-10 mx-auto mb-4 text-slate-400" />
        <p className="text-sm text-slate-600">
          {isDragActive
            ? 'Drop the files here...'
            : previewUrls.length >= maxImages
            ? 'Maximum number of images reached'
            : 'Drag & drop images here, or click to select'}
        </p>
        <p className="text-xs text-slate-500 mt-1">
          {`${previewUrls.length}/${maxImages} images uploaded`}
        </p>
      </div>

      {previewUrls.length > 0 && (
        <div className="grid grid-cols-5 gap-4">
          {previewUrls.map((url, index) => (
            <div key={`${url}-${index}`} className="relative group">
              <div className="aspect-square relative rounded-lg overflow-hidden border border-slate-200">
                <Image
                  src={url}
                  alt={`Product image ${index + 1}`}
                  fill
                  className="object-cover"
                />
              </div>
              <button
                type="button"
                onClick={() => removeImage(index)}
                className="absolute -top-2 -right-2 bg-white rounded-full p-1 shadow-md opacity-0 group-hover:opacity-100 transition-opacity"
              >
                <X className="h-4 w-4 text-slate-500" />
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  );
} 