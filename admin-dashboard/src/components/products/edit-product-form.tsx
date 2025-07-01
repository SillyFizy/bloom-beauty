import React, { useState, useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { CelebritySelector, SelectedCelebrity } from './celebrity-selector';
import { NavigationCategorySelector } from './navigation-category-selector';
import { celebritiesService } from '@/services/celebrities';

import { Product } from '@/types/product';
import { updateProduct } from '@/services/products';
import { categoriesService, brandsService } from '@/services/products';
import { toast } from 'react-hot-toast';
import { ProductImagesManager } from './product-images-manager';
import { VariantManager } from './variant-manager';
import type { Category, Brand } from '@/types/product';
import { useQueryClient } from '@tanstack/react-query';
import { QUERY_KEYS } from '@/hooks/use-products';
import { 
  useAddCategoryProducts,
  useRemoveCategoryProducts,
  useCategoryProducts
} from '@/hooks/use-navigation-categories';
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
  Grid3X3
} from 'lucide-react';

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

interface SelectedNavigationCategory {
  id: number;
  name: string;
  is_featured?: boolean;
}

interface EditProductFormProps {
  product: Product;
  onSuccess: () => void;
  onCancel: () => void;
}

export function EditProductForm({ product, onSuccess, onCancel }: EditProductFormProps) {
  const [isLoading, setIsLoading] = useState(false);
  const [categories, setCategories] = useState<Category[]>([]);
  const [brands, setBrands] = useState<Brand[]>([]);
  const [activeTab, setActiveTab] = useState<'basic' | 'images' | 'variants'>('basic');
  const [selectedCelebrities, setSelectedCelebrities] = useState<SelectedCelebrity[]>([]);
  const [originalCelebrities, setOriginalCelebrities] = useState<SelectedCelebrity[]>([]);
  const [selectedNavigationCategories, setSelectedNavigationCategories] = useState<SelectedNavigationCategory[]>([]);
  const [originalNavigationCategories, setOriginalNavigationCategories] = useState<SelectedNavigationCategory[]>([]);
  const queryClient = useQueryClient();

  // Navigation category hooks
  // const { data: productNavigationCategories = [], isLoading: loadingNavCategories } = useCategoryProducts(product.id);
  const addNavCategoryMutation = useAddCategoryProducts();
  const removeNavCategoryMutation = useRemoveCategoryProducts();

  // Helper function to check if navigation categories have changed
  const hasNavigationCategoriesChanged = () => {
    if (selectedNavigationCategories.length !== originalNavigationCategories.length) {
      return true;
    }
    
    const originalIds = new Set(originalNavigationCategories.map(cat => cat.id));
    const selectedIds = new Set(selectedNavigationCategories.map(cat => cat.id));
    
    // Check if any IDs are different
    const selectedIdsArray = Array.from(selectedIds);
    const originalIdsArray = Array.from(originalIds);
    
    if (selectedIdsArray.some(id => !originalIds.has(id))) return true;
    if (originalIdsArray.some(id => !selectedIds.has(id))) return true;
    
    // Check if featured status changed for any category
    const hasFeaturedChanges = selectedNavigationCategories.some(selected => {
      const original = originalNavigationCategories.find(cat => cat.id === selected.id);
      return original && original.is_featured !== selected.is_featured;
    });
    
    return hasFeaturedChanges;
  };

  // Helper function to check if celebrities have changed
  const hasCelebritiesChanged = () => {
    if (selectedCelebrities.length !== originalCelebrities.length) {
      return true;
    }
    
    const originalIds = new Set(originalCelebrities.map(cel => cel.id));
    const selectedIds = new Set(selectedCelebrities.map(cel => cel.id));
    
    // Check if any IDs are different
    const selectedIdsArray = Array.from(selectedIds);
    const originalIdsArray = Array.from(originalIds);
    
    if (selectedIdsArray.some(id => !originalIds.has(id))) return true;
    if (originalIdsArray.some(id => !selectedIds.has(id))) return true;
    
    // Check if testimonials changed for any celebrity
    const hasTestimonialChanges = selectedCelebrities.some(selected => {
      const original = originalCelebrities.find(cel => cel.id === selected.id);
      return original && original.testimonial !== selected.testimonial;
    });
    
    return hasTestimonialChanges;
  };

  // Generate unique SKU
  const generateSku = () => {
    const timestamp = Date.now().toString(36);
    const randomStr = Math.random().toString(36).substring(2, 8);
    return `BB-${timestamp.toUpperCase()}-${randomStr.toUpperCase()}`;
  };

  const {
    register,
    handleSubmit,
    formState: { errors, isDirty },
    reset,
    setValue,
    watch,
  } = useForm<ProductFormData>({
    resolver: zodResolver(productSchema),
    defaultValues: {
      name: product.name,
      description: product.description,
      price: product.price.toString(),
      stock: product.stock.toString(),
      sku: product.sku || '',
      category: product.category && (product.category as any).id ? (product.category as any).id.toString() : '',
      brand: product.brand && (product.brand as any).id ? (product.brand as any).id.toString() : '',
      beauty_points: product.beauty_points?.toString() || '0',
      is_featured: product.is_featured,
      is_active: product.is_active,
    },
  });

  // Watch form values for live preview
  const formValues = watch();

  // Combined dirty state - form fields OR navigation categories OR celebrities changed
  const hasAnyChanges = isDirty || hasNavigationCategoriesChanged() || hasCelebritiesChanged();

  // Reinitialize form when `product` prop changes (e.g., after full data fetch)
  useEffect(() => {
    reset({
      name: product.name,
      description: product.description,
      price: product.price.toString(),
      stock: product.stock.toString(),
      sku: product.sku || '',
      category: product.category && (product.category as any).id ? (product.category as any).id.toString() : '',
      brand: product.brand && (product.brand as any).id ? (product.brand as any).id.toString() : '',
      beauty_points: product.beauty_points?.toString() || '0',
      is_featured: product.is_featured,
      is_active: product.is_active,
    });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [product]);

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

        // Derive category/brand IDs from product if missing
        const deriveCategoryId = (): number | undefined => {
          if ((product as any).category?.id) return (product as any).category.id;
          if ((product as any).category_id) return (product as any).category_id;
          if (typeof (product as any).category === 'number') return (product as any).category;
          if ((product as any).category_name) {
            const found = normalizedCategories.find(
              (c: Category) => c.name.toLowerCase() === (product as any).category_name.toLowerCase()
            );
            return found?.id;
          }
          return undefined;
        };

        const deriveBrandId = (): number | undefined => {
          if ((product as any).brand?.id) return (product as any).brand.id;
          if ((product as any).brand_id) return (product as any).brand_id;
          if (typeof (product as any).brand === 'number') return (product as any).brand;
          if ((product as any).brand_name) {
            const found = normalizedBrands.find(
              (b: Brand) => b.name.toLowerCase() === (product as any).brand_name.toLowerCase()
            );
            return found?.id;
          }
          return undefined;
        };

        const catId = deriveCategoryId();
        const brId = deriveBrandId();

        // Update form with derived IDs when ready
        reset((prev) => ({
          ...prev,
          sku: product.sku || prev.sku,
          category: catId ? catId.toString() : prev.category,
          brand: brId ? brId.toString() : prev.brand,
        }));
      } catch (error) {
        toast.error('Failed to load form data');
      }
    };
    fetchData();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Load existing navigation categories for the product
  // useEffect(() => {
  //   if (productNavigationCategories.length > 0) {
  //     const navCategories = productNavigationCategories.map(categoryProduct => ({
  //       id: categoryProduct.product.id, // This should be the navigation category ID
  //       name: categoryProduct.product.name, // This should be the navigation category name
  //       is_featured: categoryProduct.is_featured,
  //     }));
  //     setSelectedNavigationCategories(navCategories);
  //     setOriginalNavigationCategories(navCategories);
  //   }
  // }, [productNavigationCategories]);

  const onSubmit = async (data: ProductFormData) => {
    try {
      setIsLoading(true);
      const formData = new FormData();
      
      // Append form fields
      Object.entries(data).forEach(([key, value]) => {
        if (value !== undefined) {
          formData.append(key, value.toString());
        }
      });

      await updateProduct(product.id, formData);

      // Handle celebrity promotions if product is featured
      if (data.is_featured && selectedCelebrities.length > 0) {
        for (const celebrity of selectedCelebrities) {
          try {
            await celebritiesService.createCelebrityPromotion(celebrity.id, {
              product: product.id,
              testimonial: celebrity.testimonial || '',
              promotion_type: 'general',
              is_featured: true,
            });
          } catch (error) {
            console.error(`Failed to create promotion for celebrity ${celebrity.name}:`, error);
            // Continue with other celebrities even if one fails
          }
        }
        
        if (selectedCelebrities.length > 0) {
          toast.success(`Product updated with ${selectedCelebrities.length} celebrity endorsement${selectedCelebrities.length > 1 ? 's' : ''}`);
        }
      } 

      // Handle navigation category changes
      const originalCategoryIds = new Set(originalNavigationCategories.map(cat => cat.id));
      const selectedCategoryIds = new Set(selectedNavigationCategories.map(cat => cat.id));
      
      // Categories to add
      const categoriesToAdd = selectedNavigationCategories.filter(cat => !originalCategoryIds.has(cat.id));
      
      // Categories to remove
      const categoriesToRemove = originalNavigationCategories.filter(cat => !selectedCategoryIds.has(cat.id));
      
      // Add new navigation categories
      for (const category of categoriesToAdd) {
        try {
          await addNavCategoryMutation.mutateAsync({
            categoryId: category.id,
            data: {
              product_ids: [product.id],
              clear_existing: false,
            },
          });
        } catch (error) {
          console.error(`Failed to add product to navigation category ${category.name}:`, error);
        }
      }
      
      // Remove navigation categories
      if (categoriesToRemove.length > 0) {
        for (const category of categoriesToRemove) {
          try {
            await removeNavCategoryMutation.mutateAsync({
              categoryId: category.id,
              productIds: [product.id],
            });
          } catch (error) {
            console.error(`Failed to remove product from navigation category ${category.name}:`, error);
          }
        }
      }

      if (!data.is_featured || (selectedCelebrities.length === 0 && categoriesToAdd.length === 0 && categoriesToRemove.length === 0)) {
        toast.success('Product updated successfully');
      }

      // Refresh caches (fire-and-forget)
      queryClient.invalidateQueries({ queryKey: QUERY_KEYS.products });
      queryClient.invalidateQueries({ queryKey: QUERY_KEYS.product(product.id) });
      queryClient.invalidateQueries({ queryKey: QUERY_KEYS.productStats });
      onSuccess();
    } catch (_) {
      /* Error toast already displayed by apiClient interceptor */
    } finally {
      setIsLoading(false);
    }
  };

  const tabs = [
    { id: 'basic' as const, label: 'Basic Info', icon: Package },
    { id: 'images' as const, label: 'Product Images', icon: ImageIcon },
    { id: 'variants' as const, label: 'Variants', icon: Settings },
  ];

  return (
    <div className="max-w-6xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between p-6 bg-white border border-slate-200 rounded-lg shadow-sm">
        <div className="flex items-center gap-4">
          <div className="p-3 bg-blue-100 rounded-lg">
            <Package className="w-6 h-6 text-blue-600" />
          </div>
          <div>
            <h2 className="text-2xl font-bold text-slate-800">Edit Product</h2>
            <p className="text-slate-500 mt-1">
              Update product details, manage images, and configure variants
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
          {hasAnyChanges && (
            <div className="flex items-center gap-1 px-2 py-1 bg-orange-100 text-orange-700 rounded-full text-sm">
              <AlertCircle className="w-3 h-3" />
              Unsaved
            </div>
          )}
        </div>
      </div>

      {/* Navigation Tabs */}
      <div className="bg-white border border-slate-200 rounded-lg">
        <div className="border-b border-slate-200">
          <nav className="flex">
            {tabs.map((tab) => {
              const Icon = tab.icon;
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={`
                    flex items-center gap-3 px-6 py-4 text-sm font-medium border-b-2 transition-colors
                    ${activeTab === tab.id
                      ? 'border-blue-500 text-blue-600 bg-blue-50'
                      : 'border-transparent text-slate-500 hover:text-slate-700 hover:bg-slate-50'
                    }
                  `}
                >
                  <Icon className="w-4 h-4" />
                  {tab.label}
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
                  <div className="p-2 bg-blue-100 rounded-lg">
                    <Package className="w-5 h-5 text-blue-600" />
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
                    <label className="text-sm font-medium text-slate-700">Price *</label>
                    <div className="relative">
                      <DollarSign className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-slate-400" />
                      <Input
                        {...register('price')}
                        type="number"
                        step="0.01"
                        placeholder="0.00"
                        className={`pl-10 ${errors.price ? 'border-red-500 focus:border-red-500' : ''}`}
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
                      className="w-4 h-4 text-blue-600 border-slate-300 rounded focus:ring-blue-500"
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
              <div className="flex justify-end gap-3 pt-6 border-t border-slate-200">
                <Button
                  type="button"
                  variant="outline"
                  onClick={onCancel}
                  disabled={isLoading}
                  className="flex items-center gap-2"
                >
                  <X className="w-4 h-4" />
                  Cancel
                </Button>
                <Button 
                  type="submit" 
                  disabled={isLoading || !hasAnyChanges}
                  className="flex items-center gap-2"
                >
                  {isLoading ? (
                    <Loader2 className="w-4 h-4 animate-spin" />
                  ) : (
                    <Save className="w-4 h-4" />
                  )}
                  {isLoading ? 'Saving...' : 'Save Changes'}
                </Button>
              </div>
            </form>
          )}

          {activeTab === 'images' && (
            <div className="space-y-6">
              <div className="flex items-center gap-3 mb-6">
                <div className="p-2 bg-blue-100 rounded-lg">
                  <ImageIcon className="w-5 h-5 text-blue-600" />
                </div>
                <div>
                  <h3 className="text-lg font-semibold text-slate-800">Product Images</h3>
                  <p className="text-sm text-slate-500">
                    Manage product images - set one as main and add additional gallery images
                  </p>
                </div>
              </div>
              <ProductImagesManager productId={product.id} />
            </div>
          )}

          {activeTab === 'variants' && (
            <div className="space-y-6">
              <VariantManager productId={product.id} />
            </div>
          )}
        </div>
      </div>
    </div>
  );
} 