import React, { useEffect, useState } from 'react';
import { productsService } from '@/services/products';
import type { Variant } from '@/types/variant';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { toast } from 'react-hot-toast';
import { Loader2, Trash2, Edit3, Package, ImageIcon, Plus, ChevronDown, ChevronUp } from 'lucide-react';
import { VariantImagesManager } from './variant-images-manager';
import { ImageUpload } from '@/components/ui/image-upload';

interface VariantManagerProps {
  productId: number;
}

export const VariantManager: React.FC<VariantManagerProps> = ({ productId }) => {
  const [variants, setVariants] = useState<Variant[]>([]);
  const [creating, setCreating] = useState(false);
  const [editingId, setEditingId] = useState<number | null>(null);
  const [expandedVariants, setExpandedVariants] = useState<Set<number>>(new Set());
  const [form, setForm] = useState({ name: '', sku: '', price_adjustment: '', stock: '' });
  const [formImages, setFormImages] = useState<File[]>([]);
  const [editForm, setEditForm] = useState({ name: '', sku: '', price_adjustment: '', stock: '' });
  const [loading, setLoading] = useState(false);

  const fetchVariants = async () => {
    try {
      const data = await productsService.getVariants(productId);
      setVariants(data);
    } catch {
      toast.error('Failed to load variants');
    }
  };

  useEffect(() => {
    fetchVariants();
  }, [productId]);

  const handleCreate = async () => {
    if (!form.name || !form.sku || !form.stock) return;
    setLoading(true);
    try {
      const newVariant = await productsService.createVariant(productId, {
        name: form.name,
        sku: form.sku,
        price_adjustment: form.price_adjustment || '0',
        stock: Number(form.stock),
      });

      // Upload images if any
      if (formImages.length) {
        for (let i = 0; i < formImages.length; i++) {
          await productsService.uploadVariantImage(newVariant.id, formImages[i], undefined, i === 0);
        }
      }

      setVariants(prev => [...prev, newVariant]);
      toast.success('Variant created');
      setForm({ name: '', sku: '', price_adjustment: '', stock: '' });
      setFormImages([]);
      setCreating(false);
    } catch {
      toast.error('Failed to create variant');
    } finally {
      setLoading(false);
    }
  };

  const handleEdit = (variant: Variant) => {
    setEditingId(variant.id);
    setEditForm({
      name: variant.name,
      sku: variant.sku || '',
      price_adjustment: variant.price_adjustment,
      stock: variant.stock.toString(),
    });
  };

  const handleSaveEdit = async (variantId: number) => {
    setLoading(true);
    try {
      const updatedVariant = await productsService.updateVariant(variantId, {
        name: editForm.name,
        sku: editForm.sku,
        price_adjustment: editForm.price_adjustment,
        stock: Number(editForm.stock),
      });
      setVariants(prev => prev.map(v => v.id === variantId ? { ...v, ...updatedVariant } : v));
      toast.success('Variant updated');
      setEditingId(null);
    } catch {
      toast.error('Failed to update variant');
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id: number) => {
    if (!confirm('Delete this variant? This will also delete all associated images.')) return;
    try {
      await productsService.deleteVariant(id);
      toast.success('Variant deleted');
      setVariants(prev => prev.filter(v => v.id !== id));
    } catch {
      toast.error('Failed to delete variant');
    }
  };

  const toggleExpandVariant = (variantId: number) => {
    setExpandedVariants(prev => {
      const newSet = new Set(prev);
      if (newSet.has(variantId)) {
        newSet.delete(variantId);
      } else {
        newSet.add(variantId);
      }
      return newSet;
    });
  };

  const handleVariantImagesChange = (variantId: number, images: any[]) => {
    setVariants(prev => prev.map(v => 
      v.id === variantId ? { ...v, images } : v
    ));
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="p-2 bg-blue-100 rounded-lg">
            <Package className="w-5 h-5 text-blue-600" />
          </div>
          <div>
            <h3 className="text-lg font-semibold text-slate-800">Product Variants</h3>
            <p className="text-sm text-slate-500">
              Manage different variations of this product
            </p>
          </div>
        </div>
        <Button 
          onClick={() => setCreating(v => !v)}
          className="flex items-center gap-2"
          variant={creating ? "outline" : "default"}
        >
          <Plus className="w-4 h-4" />
          {creating ? 'Cancel' : 'Add Variant'}
        </Button>
      </div>

      {/* Create Form */}
      {creating && (
        <div className="p-6 bg-gradient-to-r from-blue-50 to-indigo-50 border border-blue-200 rounded-xl space-y-4">
          <h4 className="font-medium text-slate-800 flex items-center gap-2">
            <Plus className="w-4 h-4" />
            Create New Variant
          </h4>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <div className="space-y-2">
              <label className="text-sm font-medium text-slate-700">Name</label>
              <Input
                placeholder="e.g. Red, Large, etc."
                value={form.name}
                onChange={(e) => setForm({ ...form, name: e.target.value })}
                className="bg-white"
              />
            </div>
            <div className="space-y-2">
              <label className="text-sm font-medium text-slate-700">SKU</label>
              <div className="flex gap-2">
                <Input
                  placeholder="Enter SKU"
                  value={form.sku}
                  onChange={(e) => setForm({ ...form, sku: e.target.value })}
                  className="bg-white"
                />
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  onClick={() => {
                    const timestamp = Date.now().toString(36);
                    const randomStr = Math.random().toString(36).substring(2, 6);
                    setForm({ ...form, sku: `VAR-${timestamp.toUpperCase()}-${randomStr.toUpperCase()}` });
                  }}
                  title="Generate random SKU"
                  className="px-2"
                >
                  Gen
                </Button>
              </div>
            </div>
            <div className="space-y-2">
              <label className="text-sm font-medium text-slate-700">Price Adjustment</label>
              <Input
                placeholder="0.00"
                type="number"
                step="0.01"
                value={form.price_adjustment}
                onChange={(e) => setForm({ ...form, price_adjustment: e.target.value })}
                className="bg-white"
              />
            </div>
            <div className="space-y-2">
              <label className="text-sm font-medium text-slate-700">Stock</label>
              <Input
                placeholder="0"
                type="number"
                value={form.stock}
                onChange={(e) => setForm({ ...form, stock: e.target.value })}
                className="bg-white"
              />
            </div>
            <div className="space-y-2 col-span-full">
              <label className="text-sm font-medium text-slate-700">Images</label>
              <ImageUpload
                existingImages={formImages.map(f=>URL.createObjectURL(f))}
                maxImages={5}
                onImagesChange={setFormImages}
              />
            </div>
          </div>
          <div className="flex justify-end gap-2">
            <Button variant="outline" onClick={() => setCreating(false)}>
              Cancel
            </Button>
            <Button 
              onClick={handleCreate} 
              disabled={loading || !form.name || !form.sku || !form.stock}
              className="flex items-center gap-2"
            >
              {loading ? <Loader2 className="w-4 h-4 animate-spin" /> : <Plus className="w-4 h-4" />}
              Create Variant
            </Button>
          </div>
        </div>
      )}

      {/* Variants List */}
      {variants.length > 0 ? (
        <div className="space-y-4">
          {variants.map((variant) => {
            const isExpanded = expandedVariants.has(variant.id);
            const isEditing = editingId === variant.id;
            
            return (
              <div key={variant.id} className="border border-slate-200 rounded-lg bg-white shadow-sm">
                {/* Variant Header */}
                <div className="p-4">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-4 flex-1">
                      {/* Variant Info */}
                      {isEditing ? (
                        <div className="grid grid-cols-4 gap-3 flex-1 max-w-2xl">
                          <Input
                            placeholder="Name"
                            value={editForm.name}
                            onChange={(e) => setEditForm({ ...editForm, name: e.target.value })}
                            className="text-sm"
                          />
                          <Input
                            placeholder="SKU"
                            value={editForm.sku}
                            onChange={(e) => setEditForm({ ...editForm, sku: e.target.value })}
                            className="text-sm"
                          />
                          <Input
                            placeholder="Price Adjustment"
                            type="number"
                            step="0.01"
                            value={editForm.price_adjustment}
                            onChange={(e) => setEditForm({ ...editForm, price_adjustment: e.target.value })}
                            className="text-sm"
                          />
                          <Input
                            placeholder="Stock"
                            type="number"
                            value={editForm.stock}
                            onChange={(e) => setEditForm({ ...editForm, stock: e.target.value })}
                            className="text-sm"
                          />
                        </div>
                      ) : (
                        <div className="flex items-center gap-6">
                          <div>
                            <h4 className="font-medium text-slate-800">{variant.name}</h4>
                            <div className="flex items-center gap-4 text-sm text-slate-500 mt-1">
                              <span>SKU: {variant.sku || 'N/A'}</span>
                              <span>Price: ${variant.price_adjustment}</span>
                              <span>Stock: {variant.stock}</span>
                              <span>Images: {variant.images?.length || 0}</span>
                            </div>
                          </div>
                          {variant.main_image && (
                            <img 
                              src={variant.main_image} 
                              alt={variant.name}
                              className="w-12 h-12 rounded-lg object-cover border border-slate-200"
                            />
                          )}
                        </div>
                      )}
                    </div>

                    {/* Actions */}
                    <div className="flex items-center gap-2">
                      {isEditing ? (
                        <>
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => setEditingId(null)}
                          >
                            Cancel
                          </Button>
                          <Button
                            size="sm"
                            onClick={() => handleSaveEdit(variant.id)}
                            disabled={loading}
                            className="flex items-center gap-1"
                          >
                            {loading ? <Loader2 className="w-3 h-3 animate-spin" /> : 'Save'}
                          </Button>
                        </>
                      ) : (
                        <>
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => handleEdit(variant)}
                            className="flex items-center gap-1"
                          >
                            <Edit3 className="w-3 h-3" />
                          </Button>
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => toggleExpandVariant(variant.id)}
                            className="flex items-center gap-1"
                            title={isExpanded ? "Hide images" : "Manage images"}
                          >
                            <ImageIcon className="w-3 h-3" />
                            <span className="text-xs">Images</span>
                            {isExpanded ? <ChevronUp className="w-3 h-3" /> : <ChevronDown className="w-3 h-3" />}
                          </Button>
                          <Button
                            size="sm"
                            variant="destructive"
                            onClick={() => handleDelete(variant.id)}
                            className="flex items-center gap-1"
                          >
                            <Trash2 className="w-3 h-3" />
                          </Button>
                        </>
                      )}
                    </div>
                  </div>
                </div>

                {/* Expanded Section - Images */}
                {isExpanded && (
                  <div className="border-t border-slate-200 p-4 bg-slate-50">
                    <div className="flex items-center gap-2 mb-4">
                      <ImageIcon className="w-4 h-4 text-slate-600" />
                      <span className="font-medium text-slate-700">Variant Images</span>
                    </div>
                    <VariantImagesManager
                      variantId={variant.id}
                      images={variant.images || []}
                      onImagesChange={(images) => handleVariantImagesChange(variant.id, images)}
                    />
                  </div>
                )}
              </div>
            );
          })}
        </div>
      ) : null}
    </div>
  );
}; 