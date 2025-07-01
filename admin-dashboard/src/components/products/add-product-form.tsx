import React, { useState, useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';

import { categoriesService, brandsService, productsService } from '@/services/products';
import { toast } from 'react-hot-toast';
import type { Category, Brand } from '@/types/product';
import { useQueryClient } from '@tanstack/react-query';
import { QUERY_KEYS } from '@/hooks/use-products';
import { ProductImagesManager } from './product-images-manager';
import { VariantManager } from './variant-manager';
import { NavigationCategorySelector } from './navigation-category-selector';
import { 
  Package, 
  DollarSign, 
  Warehouse, 
  Tag, 
  Image as ImageIcon, 
  Settings,
  Star,
  Eye,
  Save,
  X,
  Loader2,
  AlertCircle,
  CheckCircle,
  Hash,
  Shuffle,
  Plus,
  Grid3X3
} from 'lucide-react';
import { ImageUpload } from '@/components/ui/image-upload';
import { CelebritySelector, SelectedCelebrity } from './celebrity-selector';
import { celebritiesService } from '@/services/celebrities';
import { useAddCategoryProducts } from '@/hooks/use-navigation-categories';

const productSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  description: z.string().min(1, 'Description is required'),
  price: z.string().min(1, 'Price is required'),
  stock: z.string().min(1, 'Stock is required'),
  sku: z.string().min(1, 'SKU is required'),
  category: z.string().min(1, 'Category is required'),
  brand: z.string().min(1, 'Brand is required'),
  beauty_points: z
    .string()
    .regex(/^\d+$/, 'Must be a positive integer')
    .optional(),
  is_featured: z.boolean().optional(),
  is_active: z.boolean().optional(),
});

type ProductFormData = z.infer<typeof productSchema>;

interface AddProductFormProps {
  onSuccess: () => void;
  onCancel: () => void;
}

interface DraftVariant {
  name: string;
  sku: string;
  price_adjustment: string;
  stock: string;
  images: File[];
}

interface SelectedNavigationCategory {
  id: number;
  name: string;
  is_featured?: boolean;
}

export function AddProductForm({ onSuccess, onCancel }: AddProductFormProps) {
  const [isLoading, setIsLoading] = useState(false);
  const [categories, setCategories] = useState<Category[]>([]);
  const [brands, setBrands] = useState<Brand[]>([]);
  const [activeTab, setActiveTab] = useState<'basic' | 'images' | 'variants'>('basic');
  const [createdProductId, setCreatedProductId] = useState<number | null>(null);
  const [draftImages, setDraftImages] = useState<File[]>([]);
  const [draftVariants, setDraftVariants] = useState<DraftVariant[]>([]);
  const [variantForm, setVariantForm] = useState<{ name: string; sku: string; price_adjustment: string; stock: string; images: File[] }>({ name: '', sku: '', price_adjustment: '', stock: '', images: [] });
  const [draftCreating, setDraftCreating] = useState(false);
  const [selectedCelebrities, setSelectedCelebrities] = useState<SelectedCelebrity[]>([]);
  const [selectedNavigationCategories, setSelectedNavigationCategories] = useState<SelectedNavigationCategory[]>([]);
  const queryClient = useQueryClient();
  
  // Navigation category mutation
  const addCategoryProductsMutation = useAddCategoryProducts();

  // Generate unique SKU
  const generateSku = () => {
    const timestamp = Date.now().toString(36);
    const randomStr = Math.random().toString(36).substring(2, 8);
    return `BB-${timestamp.toUpperCase()}-${randomStr.toUpperCase()}`;
  };

  const {
    register,
    handleSubmit,
    formState: { errors, isDirty, isValid },
    reset,
    setValue,
    watch,
  } = useForm<ProductFormData>({
    resolver: zodResolver(productSchema),
    mode: 'onChange',
    defaultValues: {
      name: '',
      description: '',
      price: '',
      stock: '',
      sku: '',
      category: '',
      brand: '',
      beauty_points: '0',
      is_featured: false,
      is_active: true,
    },
  });

  // Watch form values for live preview
  const formValues = watch();

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [categoriesData, brandsData] = await Promise.all([
          categoriesService.getCategories(),
          brandsService.getBrands(),
        ]);

        // Normalize potential paginated responses
        const normalizedCategories = Array.isArray(categoriesData)
          ? categoriesData
          : (categoriesData as any)?.results ?? [];
        const normalizedBrands = Array.isArray(brandsData)
          ? brandsData
          : (brandsData as any)?.results ?? [];

        setCategories(normalizedCategories);
        setBrands(normalizedBrands);
      } catch (error) {
        toast.error('Failed to load form data');
      }
    };
    fetchData();
  }, []);

  const onSubmit = async (data: ProductFormData) => {
    // Simply move to next tab without saving
    setActiveTab('images');
  };

  const handleCreateProductFinal = async () => {
    if (isLoading || createdProductId) return;

    // Basic form validation already handled, but ensure still valid
    if (!isValid) {
      toast.error('Please complete required fields in Basic Info');
      setActiveTab('basic');
      return;
    }

    try {
      setIsLoading(true);

      const newProduct = await productsService.createProduct({
        name: formValues.name,
        description: formValues.description,
        price: Number(formValues.price),
        stock: Number(formValues.stock),
        sku: formValues.sku,
        category: Number(formValues.category),
        brand: Number(formValues.brand),
        beauty_points: Number(formValues.beauty_points || 0),
        is_featured: formValues.is_featured || false,
        is_active: formValues.is_active ?? true,
        low_stock_threshold: 10,
        images: draftImages,
        featured_image: draftImages[0],
      });

      setCreatedProductId(newProduct.id);

      // Upload variants if any
      for (const variant of draftVariants) {
        try {
          const createdVar = await productsService.createVariant(newProduct.id, {
            name: variant.name,
            sku: variant.sku,
            price_adjustment: variant.price_adjustment || '0',
            stock: Number(variant.stock),
          });
          if (variant.images.length) {
            for (let i = 0; i < variant.images.length; i++) {
              await productsService.uploadVariantImage(createdVar.id, variant.images[i], undefined, i === 0);
            }
          }
        } catch {
          // continue
        }
      }

      // Create celebrity promotions if product is featured and celebrities are selected
      if (formValues.is_featured && selectedCelebrities.length > 0) {
        for (const celebrity of selectedCelebrities) {
          try {
            await celebritiesService.createCelebrityPromotion(celebrity.id, {
              product: newProduct.id,
              testimonial: celebrity.testimonial || '',
              promotion_type: 'general', // Default to general promotion
              is_featured: true,
            });
          } catch (error) {
            console.error(`Failed to create promotion for celebrity ${celebrity.name}:`, error);
            // Continue with other celebrities even if one fails
          }
        }
        
        if (selectedCelebrities.length > 0) {
          toast.success(`Product created with ${selectedCelebrities.length} celebrity endorsement${selectedCelebrities.length > 1 ? 's' : ''}`);
        }
      }

      // Associate product with navigation categories
      if (selectedNavigationCategories.length > 0) {
        for (const navCategory of selectedNavigationCategories) {
          try {
            await addCategoryProductsMutation.mutateAsync({
              categoryId: navCategory.id,
              data: {
                product_ids: [newProduct.id],
                clear_existing: false,
              },
            });
          } catch (error) {
            console.error(`Failed to associate product with navigation category ${navCategory.name}:`, error);
            // Continue with other categories even if one fails
          }
        }
        
        if (selectedNavigationCategories.length > 0) {
          toast.success(`Product associated with ${selectedNavigationCategories.length} navigation categor${selectedNavigationCategories.length > 1 ? 'ies' : 'y'}`);
        }
      }

      // refresh queries
      queryClient.invalidateQueries({ queryKey: QUERY_KEYS.products });
      queryClient.invalidateQueries({ queryKey: QUERY_KEYS.productStats });

      if (!formValues.is_featured || (selectedCelebrities.length === 0 && selectedNavigationCategories.length === 0)) {
        toast.success('Product created successfully');
      }
      handleFinalSave();
    } catch (_) {
      /* handled */
    } finally {
      setIsLoading(false);
    }
  };

  const handleFinalSave = () => {
    onSuccess();
  };

  const tabs = [
    { id: 'basic' as const, label: 'Basic Info', icon: Package, disabled: false },
    { id: 'images' as const, label: 'Product Images', icon: ImageIcon, disabled: false },
    { id: 'variants' as const, label: 'Variants', icon: Settings, disabled: false },
  ];

  return (
    <div className="w-full space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between p-6 bg-gradient-to-r from-green-50 to-emerald-50 border border-green-200 rounded-xl shadow-sm">
        <div className="flex items-center gap-4">
          <div className="p-3 bg-green-100 rounded-lg">
            <Plus className="w-6 h-6 text-green-600" />
          </div>
          <div>
            <h2 className="text-2xl font-bold text-slate-800">Add New Product</h2>
            <p className="text-slate-500 mt-1">
              Create a new product, add images, and configure variants
            </p>
          </div>
        </div>
        
        {/* Status Indicators */}
        <div className="flex items-center gap-3">
          {formValues.is_active && (
            <div className="flex items-center gap-1 px-2 py-1 bg-green-100 text-green-700 rounded-full text-sm">
              <CheckCircle className="w-3 h-3" />
              Active
            </div>
          )}
          {formValues.is_featured && (
            <div className="flex items-center gap-1 px-2 py-1 bg-amber-100 text-amber-700 rounded-full text-sm">
              <Star className="w-3 h-3 fill-amber-700" />
              Featured
            </div>
          )}
          {isDirty && !createdProductId && (
            <div className="flex items-center gap-1 px-2 py-1 bg-orange-100 text-orange-700 rounded-full text-sm">
              <AlertCircle className="w-3 h-3" />
              Unsaved
            </div>
          )}
          {createdProductId && (
            <div className="flex items-center gap-1 px-2 py-1 bg-blue-100 text-blue-700 rounded-full text-sm">
              <CheckCircle className="w-3 h-3" />
              Created
            </div>
          )}
        </div>
      </div>

      {/* Navigation Tabs */}
      <div className="bg-white border border-slate-200 rounded-xl shadow-sm overflow-hidden">
        <div className="border-b border-slate-200 bg-slate-50/50">
          <nav className="flex">
            {tabs.map((tab) => {
              const Icon = tab.icon;
              const isDisabled = tab.disabled;
              return (
                <button
                  key={tab.id}
                  onClick={() => !isDisabled && setActiveTab(tab.id)}
                  disabled={isDisabled}
                  className={`
                    flex items-center gap-3 px-6 py-4 text-sm font-medium border-b-2 transition-colors
                    ${isDisabled
                      ? 'border-transparent text-slate-300 cursor-not-allowed'
                      : activeTab === tab.id
                        ? 'border-green-500 text-green-600 bg-green-50'
                        : 'border-transparent text-slate-500 hover:text-slate-700 hover:bg-slate-50'
                    }
                  `}
                >
                  <Icon className="w-4 h-4" />
                  {tab.label}
                  {isDisabled && <span className="text-xs">(Create product first)</span>}
                </button>
              );
            })}
          </nav>
        </div>

        {/* Tab Content */}
        <div className="p-6">
          {activeTab === 'basic' && (
            <form onSubmit={handleSubmit(onSubmit)} className="space-y-8">
              {/* Product Information */}
              <div className="space-y-6">
                <div className="flex items-center gap-3 mb-4">
                  <div className="p-2 bg-green-100 rounded-lg">
                    <Package className="w-5 h-5 text-green-600" />
                  </div>
                  <h3 className="text-lg font-semibold text-slate-800">Product Information</h3>
                </div>

                <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                  <div className="space-y-2">
                    <label className="text-sm font-medium text-slate-700">Product Name *</label>
                    <Input
                      {...register('name')}
                      placeholder="Enter product name"
                      className={`${errors.name ? 'border-red-500 focus:border-red-500' : ''}`}
                    />
                    {errors.name && (
                      <p className="text-sm text-red-500 flex items-center gap-1">
                        <AlertCircle className="w-3 h-3" />
                        {errors.name.message}
                      </p>
                    )}
                  </div>

                  <div className="space-y-2">
                    <label className="text-sm font-medium text-slate-700">Beauty Points</label>
                    <Input
                      {...register('beauty_points')}
                      type="number"
                      min="0"
                      placeholder="0"
                      className={`${errors.beauty_points ? 'border-red-500 focus:border-red-500' : ''}`}
                    />
                    {errors.beauty_points && (
                      <p className="text-sm text-red-500 flex items-center gap-1">
                        <AlertCircle className="w-3 h-3" />
                        {errors.beauty_points.message}
                      </p>
                    )}
                  </div>
                </div>

                <div className="space-y-2">
                  <label className="text-sm font-medium text-slate-700">SKU (Stock Keeping Unit) *</label>
                  <div className="flex gap-2">
                    <div className="relative flex-1">
                      <Hash className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-slate-400" />
                      <Input
                        {...register('sku')}
                        placeholder="Enter SKU or generate one"
                        className={`pl-10 ${errors.sku ? 'border-red-500 focus:border-red-500' : ''}`}
                      />
                    </div>
                    <Button
                      type="button"
                      variant="outline"
                      onClick={() => {
                        const newSku = generateSku();
                        setValue('sku', newSku, { shouldDirty: true });
                      }}
                      className="px-3"
                      title="Generate random SKU"
                    >
                      <Shuffle className="w-4 h-4" />
                    </Button>
                  </div>
                  {errors.sku && (
                    <p className="text-sm text-red-500 flex items-center gap-1">
                      <AlertCircle className="w-3 h-3" />
                      {errors.sku.message}
                    </p>
                  )}
                  <p className="text-xs text-slate-500">
                    Unique identifier for inventory tracking. Click the shuffle button to generate a random SKU.
                  </p>
                </div>

                <div className="space-y-2">
                  <label className="text-sm font-medium text-slate-700">Description *</label>
                  <Textarea
                    {...register('description')}
                    placeholder="Detailed product description"
                    className={`min-h-[120px] ${errors.description ? 'border-red-500 focus:border-red-500' : ''}`}
                  />
                  {errors.description && (
                    <p className="text-sm text-red-500 flex items-center gap-1">
                      <AlertCircle className="w-3 h-3" />
                      {errors.description.message}
                    </p>
                  )}
                </div>
              </div>

              {/* Pricing & Inventory */}
              <div className="space-y-6">
                <div className="flex items-center gap-3 mb-4">
                  <div className="p-2 bg-green-100 rounded-lg">
                    <DollarSign className="w-5 h-5 text-green-600" />
                  </div>
                  <h3 className="text-lg font-semibold text-slate-800">Pricing & Inventory</h3>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div className="space-y-2">
                    <label className="text-sm font-medium text-slate-700">Price (IQD) *</label>
                    <div className="relative">
                      <span className="absolute left-3 top-1/2 transform -translate-y-1/2 text-xs font-medium text-slate-500">IQD</span>
                      <Input
                        {...register('price')}
                        type="number"
                        step="0.01"
                        placeholder="0"
                        className={`pl-12 ${errors.price ? 'border-red-500 focus:border-red-500' : ''}`}
                      />
                    </div>
                    {errors.price && (
                      <p className="text-sm text-red-500 flex items-center gap-1">
                        <AlertCircle className="w-3 h-3" />
                        {errors.price.message}
                      </p>
                    )}
                  </div>

                  <div className="space-y-2">
                    <label className="text-sm font-medium text-slate-700">Stock Quantity *</label>
                    <div className="relative">
                      <Warehouse className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-slate-400" />
                      <Input
                        {...register('stock')}
                        type="number"
                        placeholder="0"
                        className={`pl-10 ${errors.stock ? 'border-red-500 focus:border-red-500' : ''}`}
                      />
                    </div>
                    {errors.stock && (
                      <p className="text-sm text-red-500 flex items-center gap-1">
                        <AlertCircle className="w-3 h-3" />
                        {errors.stock.message}
                      </p>
                    )}
                  </div>
                </div>
              </div>

              {/* Categories & Classification */}
              <div className="space-y-6">
                <div className="flex items-center gap-3 mb-4">
                  <div className="p-2 bg-purple-100 rounded-lg">
                    <Tag className="w-5 h-5 text-purple-600" />
                  </div>
                  <h3 className="text-lg font-semibold text-slate-800">Categories & Classification</h3>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div className="space-y-2">
                    <label className="text-sm font-medium text-slate-700">Category *</label>
                    <select
                      {...register('category')}
                      className={`w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 ${errors.category ? 'border-red-500 focus:border-red-500' : ''}`}
                    >
                      <option value="">Select category</option>
                      {categories.map((category) => (
                        <option key={category.id} value={category.id}>
                          {category.name}
                        </option>
                      ))}
                    </select>
                    {errors.category && (
                      <p className="text-sm text-red-500 flex items-center gap-1">
                        <AlertCircle className="w-3 h-3" />
                        {errors.category.message}
                      </p>
                    )}
                  </div>

                  <div className="space-y-2">
                    <label className="text-sm font-medium text-slate-700">Brand *</label>
                    <select
                      {...register('brand')}
                      className={`w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 ${errors.brand ? 'border-red-500 focus:border-red-500' : ''}`}
                    >
                      <option value="">Select brand</option>
                      {brands.map((brand) => (
                        <option key={brand.id} value={brand.id}>
                          {brand.name}
                        </option>
                      ))}
                    </select>
                    {errors.brand && (
                      <p className="text-sm text-red-500 flex items-center gap-1">
                        <AlertCircle className="w-3 h-3" />
                        {errors.brand.message}
                      </p>
                    )}
                  </div>
                </div>
              </div>

              {/* Product Status */}
              <div className="space-y-6">
                <div className="flex items-center gap-3 mb-4">
                  <div className="p-2 bg-indigo-100 rounded-lg">
                    <Eye className="w-5 h-5 text-indigo-600" />
                  </div>
                  <h3 className="text-lg font-semibold text-slate-800">Product Status</h3>
                </div>

                <div className="flex flex-col sm:flex-row gap-4">
                  <label className="flex items-center gap-3 p-4 border border-slate-200 rounded-lg hover:bg-slate-50 cursor-pointer">
                    <input
                      type="checkbox"
                      {...register('is_active')}
                      className="w-4 h-4 text-green-600 border-slate-300 rounded focus:ring-green-500"
                    />
                    <div>
                      <span className="font-medium text-slate-700">Active Product</span>
                      <p className="text-sm text-slate-500">Product will be visible to customers</p>
                    </div>
                  </label>

                  <label className="flex items-center gap-3 p-4 border border-slate-200 rounded-lg hover:bg-slate-50 cursor-pointer">
                    <input
                      type="checkbox"
                      {...register('is_featured')}
                      className="w-4 h-4 text-amber-600 border-slate-300 rounded focus:ring-amber-500"
                    />
                    <div>
                      <span className="font-medium text-slate-700">Featured Product</span>
                      <p className="text-sm text-slate-500">Show in featured sections</p>
                    </div>
                  </label>
                </div>
              </div>

              {/* Celebrity Endorsements - shown only when is_featured is checked */}
              {formValues.is_featured && (
                <div className="space-y-6">
                  <div className="flex items-center gap-3 mb-4">
                    <div className="p-2 bg-rose-100 rounded-lg">
                      <Star className="w-5 h-5 text-rose-600" />
                    </div>
                    <h3 className="text-lg font-semibold text-slate-800">Featured Product Endorsements</h3>
                  </div>

                  <CelebritySelector
                    selectedCelebrities={selectedCelebrities}
                    onCelebritiesChange={setSelectedCelebrities}
                    productName={formValues.name || 'this product'}
                  />
                </div>
              )}

              {/* Navigation Category Selector */}
              <div className="space-y-6">
                <div className="flex items-center gap-3 mb-4">
                  <div className="p-2 bg-purple-100 rounded-lg">
                    <Grid3X3 className="w-5 h-5 text-purple-600" />
                  </div>
                  <h3 className="text-lg font-semibold text-slate-800">Navigation Categories</h3>
                </div>

                <NavigationCategorySelector
                  selectedCategories={selectedNavigationCategories}
                  onCategoriesChange={(categories) => setSelectedNavigationCategories(categories)}
                  productName={formValues.name || 'this product'}
                />
              </div>

              {/* Form Actions */}
              <div className="sticky bottom-0 bg-white border-t border-slate-200 -mx-6 px-6 py-4 mt-8">
                <div className="flex justify-end gap-4">
                  <Button
                    type="button"
                    variant="outline"
                    onClick={onCancel}
                    disabled={isLoading}
                    className="flex items-center gap-2 px-6 py-3 border-slate-300 text-slate-600 hover:bg-slate-50"
                  >
                    <X className="w-4 h-4" />
                    Cancel
                  </Button>
                  <Button 
                    type="submit" 
                    disabled={!isValid}
                    className="flex items-center gap-2 px-8 py-3 bg-green-600 hover:bg-green-700 text-white shadow-lg hover:shadow-xl transition-all duration-200"
                  >
                    Next
                  </Button>
                </div>
              </div>
            </form>
          )}

          {activeTab === 'images' && (
            createdProductId ? (
              <div className="space-y-6">
                <div className="flex items-center justify-between mb-6">
                  <div className="flex items-center gap-3">
                    <div className="p-2 bg-blue-100 rounded-lg">
                      <ImageIcon className="w-5 h-5 text-blue-600" />
                    </div>
                    <div>
                      <h3 className="text-lg font-semibold text-slate-800">Product Images</h3>
                      <p className="text-sm text-slate-500">
                        Add images for your product - set one as main and add additional gallery images
                      </p>
                    </div>
                  </div>
                  <Button onClick={handleFinalSave} className="flex items-center gap-2">
                    <CheckCircle className="w-4 h-4" />
                    Finish & Save
                  </Button>
                </div>
                <ProductImagesManager productId={createdProductId} />
              </div>
            ) : (
              <div className="space-y-6">
                <div className="flex items-center justify-between mb-6">
                  <div className="flex items-center gap-3">
                    <div className="p-2 bg-blue-100 rounded-lg">
                      <ImageIcon className="w-5 h-5 text-blue-600" />
                    </div>
                    <div>
                      <h3 className="text-lg font-semibold text-slate-800">Product Images</h3>
                      <p className="text-sm text-slate-500">
                        Upload images now – they will be saved once the product is created
                      </p>
                    </div>
                  </div>
                </div>
                <ImageUpload
                  existingImages={draftImages.map(file => URL.createObjectURL(file))}
                  maxImages={5}
                  onImagesChange={(files) => setDraftImages(files)}
                />

                {/* Action buttons */}
                <div className="flex justify-end gap-4 mt-6">
                  <Button variant="outline" onClick={() => setActiveTab('basic')}>Back</Button>
                  <Button onClick={handleCreateProductFinal} disabled={isLoading} className="flex items-center gap-2 bg-green-600 hover:bg-green-700 text-white">
                    {isLoading ? <Loader2 className="w-4 h-4 animate-spin" /> : <Save className="w-4 h-4" />}
                    {isLoading ? 'Saving...' : 'Create Product'}
                  </Button>
                </div>
              </div>
            )
          )}

          {activeTab === 'variants' && (
            createdProductId ? (
              <div className="space-y-6">
                <div className="flex items-center justify-between mb-6">
                  <div className="flex items-center gap-3">
                    <div className="p-2 bg-purple-100 rounded-lg">
                      <Settings className="w-5 h-5 text-purple-600" />
                    </div>
                    <div>
                      <h3 className="text-lg font-semibold text-slate-800">Product Variants</h3>
                      <p className="text-sm text-slate-500">
                        Create different variations of your product (colors, sizes, etc.)
                      </p>
                    </div>
                  </div>
                  <Button onClick={handleFinalSave} className="flex items-center gap-2">
                    <CheckCircle className="w-4 h-4" />
                    Finish & Save
                  </Button>
                </div>
                <VariantManager productId={createdProductId} />
              </div>
            ) : (
              <div className="space-y-6">
                <div className="flex items-center justify-between mb-6">
                  <div className="flex items-center gap-3">
                    <div className="p-2 bg-purple-100 rounded-lg">
                      <Settings className="w-5 h-5 text-purple-600" />
                    </div>
                    <div>
                      <h3 className="text-lg font-semibold text-slate-800">Product Variants</h3>
                      <p className="text-sm text-slate-500">
                        Define variants now – they will be saved once the product is created
                      </p>
                    </div>
                  </div>
                </div>
                <Button 
                  onClick={() => setDraftCreating(v => !v)}
                  className="flex items-center gap-2"
                  variant={draftCreating ? 'outline' : 'default'}
                >
                  <Plus className="w-4 h-4" />
                  {draftCreating ? 'Cancel' : 'Add Variant'}
                </Button>

                {/* Draft variants list */}
                {draftVariants.length > 0 && (
                  <div className="space-y-3 mb-6">
                    {draftVariants.map((variant, idx) => (
                      <div key={idx} className="grid grid-cols-5 gap-3 items-center border border-slate-200 rounded-lg p-3">
                        <p className="text-sm font-medium text-slate-700 truncate">{variant.name}</p>
                        <p className="text-sm text-slate-600 truncate">{variant.sku}</p>
                        <p className="text-sm text-slate-600">{variant.stock}</p>
                        <p className="text-sm text-slate-600">{variant.images.length} img</p>
                        <Button size="icon" variant="outline" onClick={() => setDraftVariants(draftVariants.filter((_, i) => i !== idx))}>
                          <X className="w-4 h-4" />
                        </Button>
                      </div>
                    ))}
                  </div>
                )}

                {/* Draft variant form */}
                {draftCreating && (
                  <div className="space-y-4">
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4 items-end">
                      <Input
                        placeholder="Name"
                        value={variantForm.name}
                        onChange={(e) => setVariantForm({ ...variantForm, name: e.target.value })}
                      />
                      <div className="flex gap-2">
                        <Input
                          placeholder="SKU"
                          value={variantForm.sku}
                          onChange={(e) => setVariantForm({ ...variantForm, sku: e.target.value })}
                        />
                        <Button
                          type="button"
                          variant="outline"
                          size="sm"
                          onClick={() => {
                            const ts = Date.now().toString(36);
                            const rand = Math.random().toString(36).substring(2,6);
                            setVariantForm({ ...variantForm, sku: `VAR-${ts.toUpperCase()}-${rand.toUpperCase()}` });
                          }}
                        >Gen</Button>
                      </div>
                      <Input
                        placeholder="Stock"
                        type="number"
                        value={variantForm.stock}
                        onChange={(e) => setVariantForm({ ...variantForm, stock: e.target.value })}
                      />
                      <Button
                        type="button"
                        onClick={() => {
                          if (!variantForm.name || !variantForm.sku || !variantForm.stock) return;
                          setDraftVariants([...draftVariants, variantForm]);
                          setVariantForm({ name: '', sku: '', price_adjustment: '', stock: '', images: [] });
                          setDraftCreating(false);
                        }}
                        disabled={!variantForm.name || !variantForm.sku || !variantForm.stock}
                        className="self-end"
                      >
                        Add
                      </Button>
                      <div className="space-y-2 md:col-span-2 lg:col-span-5">
                        <label className="text-sm font-medium text-slate-700">Images</label>
                        <ImageUpload
                          existingImages={variantForm.images.map(f=>URL.createObjectURL(f))}
                          maxImages={5}
                          onImagesChange={(files)=> setVariantForm({ ...variantForm, images: files })}
                        />
                      </div>
                    </div>
                  </div>
                )}

                {/* Action buttons */}
                <div className="flex justify-end gap-4 mt-6">
                  <Button variant="outline" onClick={() => setActiveTab('images')}>Back</Button>
                  <Button onClick={handleCreateProductFinal} disabled={isLoading} className="flex items-center gap-2 bg-green-600 hover:bg-green-700 text-white">
                    {isLoading ? <Loader2 className="w-4 h-4 animate-spin" /> : <Save className="w-4 h-4" />}
                    {isLoading ? 'Saving...' : 'Create Product'}
                  </Button>
                </div>
              </div>
            )
          )}
        </div>
      </div>
    </div>
  );
} 