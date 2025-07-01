"use client";

import React, { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Upload, X, Image as ImageIcon, Plus, Package, Search, Star } from "lucide-react";
import Image from "next/image";
import {
  NavigationCategory,
  NavigationCategoryFormData,
  ProductBasic,
} from "@/types/navigation-category";
import {
  useCreateNavigationCategory,
  useUpdateNavigationCategory,
  useCategoryProducts,
  useAddCategoryProducts,
  useRemoveCategoryProducts,
  useSearchProducts,
} from "@/hooks/use-navigation-categories";
import { useDebounce } from "@/hooks/use-debounce";

interface NavigationCategoryFormProps {
  category?: NavigationCategory;
  onSuccess?: () => void;
  onCancel?: () => void;
}

interface SelectedProduct {
  id: number;
  name: string;
  price: string;
  image_url?: string;
  sku?: string;
  is_featured?: boolean;
}

export const NavigationCategoryForm: React.FC<NavigationCategoryFormProps> = ({
  category,
  onSuccess,
  onCancel,
}) => {
  const [formData, setFormData] = useState<NavigationCategoryFormData>({
    name: "",
    order: 0,
    is_active: true,
  });
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [imagePreview, setImagePreview] = useState<string | null>(null);
  const [selectedProducts, setSelectedProducts] = useState<SelectedProduct[]>([]);
  
  // Product search state
  const [productSearchQuery, setProductSearchQuery] = useState("");
  const [availableProducts, setAvailableProducts] = useState<ProductBasic[]>([]);
  const [isSearching, setIsSearching] = useState(false);
  
  const debouncedSearchQuery = useDebounce(productSearchQuery, 300);

  const createMutation = useCreateNavigationCategory();
  const updateMutation = useUpdateNavigationCategory();

  // Product-related hooks for editing existing categories
  const { data: categoryProducts = [] } = useCategoryProducts(category?.id || 0);
  const addProductsMutation = useAddCategoryProducts();
  const removeProductsMutation = useRemoveCategoryProducts();
  
  // Product search hook
  const { data: searchResults = [], isLoading: searchLoading } = useSearchProducts({
    search: debouncedSearchQuery,
    exclude_category: category?.id,
  });

  const isEditing = !!category;
  const isLoading = createMutation.isPending || updateMutation.isPending;

  // Initialize form with category data if editing
  useEffect(() => {
    if (category) {
      setFormData({
        name: category.name,
        order: category.order,
        is_active: category.is_active,
      });
      
      // Set image preview if category has image
      if (category.image_url) {
        setImagePreview(category.image_url);
      }

      // Set selected products from category products
      if (categoryProducts.length > 0) {
        const products = categoryProducts.map(cp => ({
          id: cp.product.id,
          name: cp.product.name,
          price: cp.product.price,
          image_url: cp.product.image_url,
          sku: cp.product.sku,
          is_featured: cp.is_featured,
        }));
        setSelectedProducts(products);
      }
    }
  }, [category, categoryProducts]);

  // Update available products from search
  useEffect(() => {
    if (searchResults.length > 0) {
      setAvailableProducts(searchResults);
    }
  }, [searchResults]);

  const handleInputChange = (field: keyof NavigationCategoryFormData, value: any) => {
    setFormData(prev => ({ ...prev, [field]: value }));
  };

  const handleImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setImageFile(file);
      
      // Create preview
      const reader = new FileReader();
      reader.onload = (e) => {
        setImagePreview(e.target?.result as string);
      };
      reader.readAsDataURL(file);
    }
  };

  const removeImage = () => {
    setImageFile(null);
    setImagePreview(null);
  };

  const handleAddProduct = (product: ProductBasic) => {
    const isAlreadySelected = selectedProducts.some(p => p.id === product.id);
    if (!isAlreadySelected) {
      setSelectedProducts(prev => [...prev, {
        id: product.id,
        name: product.name,
        price: product.price,
        image_url: product.image_url,
        sku: product.sku,
        is_featured: false,
      }]);
      setProductSearchQuery("");
    }
  };

  const handleRemoveProduct = (productId: number) => {
    setSelectedProducts(prev => prev.filter(p => p.id !== productId));
    
    // If editing, also remove from backend
    if (isEditing && category) {
      removeProductsMutation.mutate({
        categoryId: category.id,
        productIds: [productId],
      });
    }
  };

  const handleToggleFeatured = (productId: number) => {
    setSelectedProducts(prev => prev.map(p => 
      p.id === productId ? { ...p, is_featured: !p.is_featured } : p
    ));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    const submitData: NavigationCategoryFormData = {
      ...formData,
      image: imageFile || undefined,
    };

    try {
      let categoryId: number;
      
      if (isEditing && category) {
        // Update existing category
        await updateMutation.mutateAsync({
          id: category.id,
          data: submitData,
        });
        categoryId = category.id;
      } else {
        // Create new category
        const newCategory = await createMutation.mutateAsync(submitData);
        categoryId = newCategory.id;
      }

      // Add products to category (for both new and existing categories)
      if (selectedProducts.length > 0) {
        await addProductsMutation.mutateAsync({
          categoryId,
          data: {
            product_ids: selectedProducts.map(p => p.id),
            clear_existing: true, // Replace all existing products
          },
        });
      }

      onSuccess?.();
    } catch (error) {
      console.error('Form submission error:', error);
    }
  };

  const formatPrice = (price: string) => {
    return `${parseInt(price).toLocaleString()} د.ع`;
  };

  return (
    <div className="space-y-6">
      <Tabs defaultValue="basic" className="w-full">
        <TabsList className="grid w-full grid-cols-2">
          <TabsTrigger value="basic">Basic Information</TabsTrigger>
          <TabsTrigger value="products">Products ({selectedProducts.length})</TabsTrigger>
        </TabsList>
        
        <form onSubmit={handleSubmit}>
          <TabsContent value="basic" className="space-y-6 mt-6">
            {/* Basic Information */}
            <Card>
              <CardHeader>
                <CardTitle>Category Details</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="name">Category Name *</Label>
                  <Input
                    id="name"
                    value={formData.name}
                    onChange={(e) => handleInputChange("name", e.target.value)}
                    placeholder="e.g., EYES, FACE, LIPS"
                    required
                  />
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="order">Display Order</Label>
                    <Input
                      id="order"
                      type="number"
                      value={formData.order}
                      onChange={(e) => handleInputChange("order", parseInt(e.target.value) || 0)}
                      placeholder="0"
                      min="0"
                    />
                    <p className="text-xs text-muted-foreground">
                      Lower numbers appear first
                    </p>
                  </div>

                  <div className="space-y-2">
                    <div className="flex items-center space-x-2">
                      <Switch
                        id="is_active"
                        checked={formData.is_active}
                        onCheckedChange={(checked) => handleInputChange("is_active", checked)}
                      />
                      <Label htmlFor="is_active">Active</Label>
                    </div>
                    <p className="text-xs text-muted-foreground">
                      Whether this category is visible in the navigation
                    </p>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Image Upload */}
            <Card>
              <CardHeader>
                <CardTitle>Category Image</CardTitle>
              </CardHeader>
              <CardContent>
                {imagePreview ? (
                  <div className="relative">
                    <div className="relative w-full h-48 rounded-lg overflow-hidden bg-gray-100">
                      <Image
                        src={imagePreview}
                        alt="Category preview"
                        fill
                        className="object-cover"
                      />
                    </div>
                    <Button
                      type="button"
                      variant="destructive"
                      size="icon"
                      className="absolute top-2 right-2"
                      onClick={removeImage}
                    >
                      <X className="h-4 w-4" />
                    </Button>
                  </div>
                ) : (
                  <div className="border-2 border-dashed border-gray-300 rounded-lg p-8 text-center">
                    <ImageIcon className="mx-auto h-12 w-12 text-gray-400" />
                    <div className="mt-4">
                      <Label htmlFor="image-upload" className="cursor-pointer">
                        <span className="mt-2 block text-sm font-medium text-gray-900">
                          Upload category image
                        </span>
                        <span className="mt-1 block text-xs text-gray-500">
                          PNG, JPG, GIF up to 10MB
                        </span>
                      </Label>
                      <Input
                        id="image-upload"
                        type="file"
                        accept="image/*"
                        onChange={handleImageChange}
                        className="hidden"
                      />
                    </div>
                  </div>
                )}
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="products" className="space-y-6 mt-6">
            {/* Product Search */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Search className="h-5 w-5" />
                  Add Products
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  <div className="relative">
                    <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-4 w-4" />
                    <Input
                      value={productSearchQuery}
                      onChange={(e) => setProductSearchQuery(e.target.value)}
                      placeholder="Search products by name or SKU..."
                      className="pl-10"
                    />
                  </div>

                  {/* Search Results */}
                  {debouncedSearchQuery && (
                    <Card className="border-2">
                      <CardContent className="p-0">
                        <ScrollArea className="h-64">
                          {searchLoading ? (
                            <div className="p-4 text-center text-muted-foreground">
                              Searching products...
                            </div>
                          ) : availableProducts.length === 0 ? (
                            <div className="p-4 text-center text-muted-foreground">
                              No products found for "{debouncedSearchQuery}"
                            </div>
                          ) : (
                            <div className="p-2">
                              {availableProducts.map((product) => {
                                const isSelected = selectedProducts.some(p => p.id === product.id);
                                return (
                                  <div
                                    key={product.id}
                                    className={`flex items-center justify-between p-3 rounded-lg border-2 mb-2 transition-colors ${
                                      isSelected 
                                        ? 'border-green-200 bg-green-50' 
                                        : 'border-transparent hover:border-gray-200'
                                    }`}
                                  >
                                    <div className="flex items-center space-x-3 flex-1">
                                      {product.image_url ? (
                                        <div className="relative w-12 h-12 rounded-lg overflow-hidden">
                                          <Image
                                            src={product.image_url}
                                            alt={product.name}
                                            fill
                                            className="object-cover"
                                          />
                                        </div>
                                      ) : (
                                        <div className="w-12 h-12 rounded-lg bg-muted flex items-center justify-center">
                                          <Package className="h-6 w-6 text-muted-foreground" />
                                        </div>
                                      )}
                                      
                                      <div className="flex-1">
                                        <h4 className="font-medium text-sm">{product.name}</h4>
                                        <div className="flex items-center space-x-2 mt-1">
                                          <Badge variant="secondary" className="text-xs">
                                            {formatPrice(product.price)}
                                          </Badge>
                                          {product.sku && (
                                            <span className="text-xs text-muted-foreground">
                                              SKU: {product.sku}
                                            </span>
                                          )}
                                        </div>
                                      </div>
                                    </div>
                                    
                                    <Button
                                      type="button"
                                      variant={isSelected ? "secondary" : "outline"}
                                      size="sm"
                                      onClick={() => handleAddProduct(product)}
                                      disabled={isSelected}
                                    >
                                      {isSelected ? "Added" : "Add"}
                                    </Button>
                                  </div>
                                );
                              })}
                            </div>
                          )}
                        </ScrollArea>
                      </CardContent>
                    </Card>
                  )}
                </div>
              </CardContent>
            </Card>

            {/* Selected Products */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center justify-between">
                  <span className="flex items-center gap-2">
                    <Package className="h-5 w-5" />
                    Selected Products ({selectedProducts.length})
                  </span>
                  {selectedProducts.length > 0 && (
                    <Badge variant="outline">
                      {selectedProducts.filter(p => p.is_featured).length} Featured
                    </Badge>
                  )}
                </CardTitle>
              </CardHeader>
              <CardContent>
                {selectedProducts.length === 0 ? (
                  <div className="text-center py-8">
                    <Package className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
                    <h3 className="text-lg font-medium text-muted-foreground mb-2">
                      No products selected
                    </h3>
                    <p className="text-sm text-muted-foreground mb-4">
                      Search and add products to this category
                    </p>
                  </div>
                ) : (
                  <ScrollArea className="h-96">
                    <div className="space-y-3">
                      {selectedProducts.map((product) => (
                        <div
                          key={product.id}
                          className="flex items-center justify-between p-4 rounded-lg border bg-card"
                        >
                          <div className="flex items-center space-x-3 flex-1">
                            {product.image_url ? (
                              <div className="relative w-12 h-12 rounded-lg overflow-hidden">
                                <Image
                                  src={product.image_url}
                                  alt={product.name}
                                  fill
                                  className="object-cover"
                                />
                              </div>
                            ) : (
                              <div className="w-12 h-12 rounded-lg bg-muted flex items-center justify-center">
                                <Package className="h-6 w-6 text-muted-foreground" />
                              </div>
                            )}
                            
                            <div className="flex-1">
                              <h4 className="font-medium text-sm">{product.name}</h4>
                              <div className="flex items-center space-x-2 mt-1">
                                <Badge variant="secondary" className="text-xs">
                                  {formatPrice(product.price)}
                                </Badge>
                                {product.sku && (
                                  <span className="text-xs text-muted-foreground">
                                    SKU: {product.sku}
                                  </span>
                                )}
                                {product.is_featured && (
                                  <Badge variant="default" className="text-xs">
                                    <Star className="h-3 w-3 mr-1" />
                                    Featured
                                  </Badge>
                                )}
                              </div>
                            </div>
                          </div>
                          
                          <div className="flex items-center space-x-2">
                            <Button
                              type="button"
                              variant={product.is_featured ? "default" : "outline"}
                              size="sm"
                              onClick={() => handleToggleFeatured(product.id)}
                            >
                              <Star className="h-4 w-4" />
                            </Button>
                            <Button
                              type="button"
                              variant="ghost"
                              size="icon"
                              onClick={() => handleRemoveProduct(product.id)}
                            >
                              <X className="h-4 w-4" />
                            </Button>
                          </div>
                        </div>
                      ))}
                    </div>
                  </ScrollArea>
                )}
              </CardContent>
            </Card>
          </TabsContent>

          {/* Form Actions */}
          <Separator className="my-6" />
          <div className="flex items-center justify-end space-x-2">
            <Button
              type="button"
              variant="outline"
              onClick={onCancel}
              disabled={isLoading}
            >
              Cancel
            </Button>
            <Button type="submit" disabled={isLoading}>
              {isLoading ? "Saving..." : isEditing ? "Update Category" : "Create Category"}
            </Button>
          </div>
        </form>
      </Tabs>
    </div>
  );
}; 