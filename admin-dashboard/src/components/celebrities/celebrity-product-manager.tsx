'use client';

import React, { useState, useMemo } from 'react';
import Image from 'next/image';
import { 
  Search, 
  Plus, 
  Filter, 
  Star, 
  Trash2, 
  Edit, 
  Package, 
  Tag, 
  MoreVertical,
  ChevronLeft,
  ChevronRight,
  X,
  Check,
  AlertTriangle,
  Eye,
  Loader2,
  Heart,
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { 
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
  DropdownMenuSeparator,
} from '@/components/ui/dropdown-menu';
import { Checkbox } from '@/components/ui/checkbox';
import { Textarea } from '@/components/ui/textarea';
import { 
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Separator } from '@/components/ui/separator';
import { 
  useCelebrityPromotionsAdmin,
  useAvailableProductsForCelebrity,
  useCreateCelebrityPromotion,
  useUpdateCelebrityPromotion,
  useDeleteCelebrityPromotion,
  useBulkManageCelebrityPromotions,
} from '@/hooks/use-celebrities';
import { 
  Celebrity, 
  CelebrityProductPromotion,
  ProductBasic,
  PromotionFilters,
  AvailableProductsFilters,
  ProductPromotionFormData,
} from '@/types/celebrity';
import { formatCurrency, formatDate } from '@/lib/utils';

interface CelebrityProductManagerProps {
  celebrity: Celebrity;
}

export function CelebrityProductManager({ celebrity }: CelebrityProductManagerProps) {
  // State
  const [activeTab, setActiveTab] = useState('recommendations');
  const [selectedRecommendations, setSelectedRecommendations] = useState<number[]>([]);
  const [selectedProducts, setSelectedProducts] = useState<number[]>([]);
  const [showAddDialog, setShowAddDialog] = useState(false);
  const [showEditDialog, setShowEditDialog] = useState(false);
  const [showBulkAddDialog, setShowBulkAddDialog] = useState(false);
  const [editingRecommendation, setEditingRecommendation] = useState<CelebrityProductPromotion | null>(null);
  
  // Filters
  const [recommendationFilters, setRecommendationFilters] = useState<PromotionFilters>({
    page: 1,
    page_size: 12,
  });
  const [availableProductsFilters, setAvailableProductsFilters] = useState<AvailableProductsFilters>({
    page: 1,
    page_size: 12,
  });
  
  // Form state
  const [recommendationForm, setRecommendationForm] = useState<{
    product: number;
    testimonial: string;
  }>({
    product: 0,
    testimonial: '',
  });
  
  const [bulkRecommendationData, setBulkRecommendationData] = useState({
    testimonial: '',
  });

  // API hooks - always fetch featured recommendations only
  const { data: recommendationsData, isLoading: loadingRecommendations } = useCelebrityPromotionsAdmin(
    celebrity.id, 
    { ...recommendationFilters, is_featured: true }
  );
  const { data: availableProductsData, isLoading: loadingAvailableProducts } = useAvailableProductsForCelebrity(
    celebrity.id, 
    availableProductsFilters
  );
  
  const createRecommendation = useCreateCelebrityPromotion();
  const updateRecommendation = useUpdateCelebrityPromotion();
  const deleteRecommendation = useDeleteCelebrityPromotion();
  const bulkManageRecommendations = useBulkManageCelebrityPromotions();

  // Computed values
  const recommendations = recommendationsData?.results || [];
  const availableProducts = availableProductsData?.results || [];
  const hasSelectedRecommendations = selectedRecommendations.length > 0;
  const hasSelectedProducts = selectedProducts.length > 0;

  // Event handlers with debouncing for search
  const handleRecommendationFilterChange = (key: keyof PromotionFilters, value: any) => {
    setRecommendationFilters(prev => ({ ...prev, [key]: value, page: 1 }));
  };

  const handleAvailableProductsFilterChange = (key: keyof AvailableProductsFilters, value: any) => {
    setAvailableProductsFilters(prev => ({ ...prev, [key]: value, page: 1 }));
  };

  // Debounced search handlers
  const handleDebouncedRecommendationSearch = useMemo(
    () => {
      const timeoutRef = { current: null as NodeJS.Timeout | null };
      return (value: string) => {
        if (timeoutRef.current) clearTimeout(timeoutRef.current);
        timeoutRef.current = setTimeout(() => {
          handleRecommendationFilterChange('search', value);
        }, 300);
      };
    },
    [handleRecommendationFilterChange]
  );

  const handleDebouncedAvailableProductsSearch = useMemo(
    () => {
      const timeoutRef = { current: null as NodeJS.Timeout | null };
      return (value: string) => {
        if (timeoutRef.current) clearTimeout(timeoutRef.current);
        timeoutRef.current = setTimeout(() => {
          handleAvailableProductsFilterChange('search', value);
        }, 300);
      };
    },
    [handleAvailableProductsFilterChange]
  );

  const handleRecommendationSelect = (recommendationId: number, checked: boolean) => {
    if (checked) {
      setSelectedRecommendations(prev => [...prev, recommendationId]);
    } else {
      setSelectedRecommendations(prev => prev.filter(id => id !== recommendationId));
    }
  };

  const handleProductSelect = (productId: number, checked: boolean) => {
    if (checked) {
      setSelectedProducts(prev => [...prev, productId]);
    } else {
      setSelectedProducts(prev => prev.filter(id => id !== productId));
    }
  };

  const handleSelectAllRecommendations = (checked: boolean) => {
    if (checked) {
      setSelectedRecommendations(recommendations.map(r => r.id));
    } else {
      setSelectedRecommendations([]);
    }
  };

  const handleSelectAllProducts = (checked: boolean) => {
    if (checked) {
      setSelectedProducts(availableProducts.map(p => p.id));
    } else {
      setSelectedProducts([]);
    }
  };

  const handleCreateRecommendation = async () => {
    if (!recommendationForm.product) return;
    
    try {
      await createRecommendation.mutateAsync({
        celebrityId: celebrity.id,
        data: {
          product: recommendationForm.product,
          testimonial: recommendationForm.testimonial,
          promotion_type: 'general', // Always general for recommendations
          is_featured: true, // Always featured
        },
      });
      setShowAddDialog(false);
      resetRecommendationForm();
    } catch (error) {
      // Error handled by hook
    }
  };

  const handleUpdateRecommendation = async () => {
    if (!editingRecommendation) return;
    
    try {
      await updateRecommendation.mutateAsync({
        celebrityId: celebrity.id,
        promotionId: editingRecommendation.id,
        data: {
          testimonial: recommendationForm.testimonial,
        },
      });
      setShowEditDialog(false);
      setEditingRecommendation(null);
      resetRecommendationForm();
    } catch (error) {
      // Error handled by hook
    }
  };

  const handleDeleteRecommendations = async () => {
    if (!hasSelectedRecommendations) return;
    
    if (!confirm(`Are you sure you want to remove ${selectedRecommendations.length} recommendation(s)?`)) {
      return;
    }

    try {
      for (const recommendationId of selectedRecommendations) {
        await deleteRecommendation.mutateAsync({
          celebrityId: celebrity.id,
          promotionId: recommendationId,
        });
      }
      setSelectedRecommendations([]);
    } catch (error) {
      // Error handled by hook
    }
  };

  const handleBulkAddProducts = async () => {
    if (!hasSelectedProducts) return;
    
    try {
      await bulkManageRecommendations.mutateAsync({
        celebrityId: celebrity.id,
        data: {
          action: 'add',
          product_ids: selectedProducts,
          promotion_data: {
            testimonial: bulkRecommendationData.testimonial,
            promotion_type: 'general', // Always general
            is_featured: true, // Always featured
          },
        },
      });
      setShowBulkAddDialog(false);
      setSelectedProducts([]);
      setBulkRecommendationData({ testimonial: '' });
    } catch (error) {
      // Error handled by hook
    }
  };

  const handleEditRecommendation = (recommendation: CelebrityProductPromotion) => {
    setEditingRecommendation(recommendation);
    setRecommendationForm({
      product: recommendation.product.id,
      testimonial: recommendation.testimonial || '',
    });
    setShowEditDialog(true);
  };

  const resetRecommendationForm = () => {
    setRecommendationForm({
      product: 0,
      testimonial: '',
    });
  };

  return (
    <Card className="w-full">
      <CardHeader>
        <div className="flex items-center justify-between">
          <div>
            <CardTitle className="text-xl flex items-center gap-2">
              <Heart className="h-5 w-5 text-rose-500" />
              Featured Recommendations
            </CardTitle>
            <p className="text-sm text-muted-foreground mt-1">
              Manage {celebrity.full_name}'s featured product recommendations
            </p>
          </div>
          <div className="flex items-center gap-2">
            {hasSelectedRecommendations && activeTab === 'recommendations' && (
              <Button
                variant="destructive"
                size="sm"
                onClick={handleDeleteRecommendations}
                disabled={deleteRecommendation.isPending}
              >
                <Trash2 className="h-4 w-4 mr-2" />
                Remove ({selectedRecommendations.length})
              </Button>
            )}
            {hasSelectedProducts && activeTab === 'available' && (
              <Button
                size="sm"
                onClick={() => setShowBulkAddDialog(true)}
                className="bg-rose-500 hover:bg-rose-600"
              >
                <Heart className="h-4 w-4 mr-2" />
                Recommend ({selectedProducts.length})
              </Button>
            )}
          </div>
        </div>
      </CardHeader>

      <CardContent className="space-y-6">
        <Tabs value={activeTab} onValueChange={setActiveTab}>
          <TabsList className="grid w-full grid-cols-2">
            <TabsTrigger value="recommendations" className="flex items-center gap-2">
              <Heart className="h-4 w-4" />
              Current Recommendations ({recommendations.length})
            </TabsTrigger>
            <TabsTrigger value="available" className="flex items-center gap-2">
              <Plus className="h-4 w-4" />
              Add Products ({availableProducts.length})
            </TabsTrigger>
          </TabsList>

          {/* Current Recommendations Tab */}
          <TabsContent value="recommendations" className="space-y-4">
            <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
              <div className="flex items-center gap-2">
                <div className="relative">
                  <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                                      <Input
                      placeholder="Search recommendations..."
                      className="pl-9 w-64"
                      value={recommendationFilters.search || ''}
                      onChange={(e) => handleDebouncedRecommendationSearch(e.target.value)}
                    />
                </div>
              </div>
              
              <div className="flex items-center gap-2">
                {recommendations.length > 0 && (
                  <div className="flex items-center gap-2">
                    <Checkbox
                      checked={selectedRecommendations.length === recommendations.length}
                      onCheckedChange={handleSelectAllRecommendations}
                    />
                    <span className="text-sm text-muted-foreground">
                      Select All
                    </span>
                  </div>
                )}
              </div>
            </div>

            {loadingRecommendations ? (
              <div className="flex items-center justify-center py-12">
                <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
              </div>
            ) : recommendations.length === 0 ? (
              <div className="text-center py-12">
                <Heart className="h-12 w-12 text-rose-200 mx-auto mb-4" />
                <h3 className="text-lg font-semibold text-muted-foreground mb-2">
                  No recommendations yet
                </h3>
                <p className="text-sm text-muted-foreground mb-4">
                  {celebrity.full_name} hasn't recommended any products yet.
                </p>
                <Button 
                  onClick={() => setActiveTab('available')}
                  className="bg-rose-500 hover:bg-rose-600"
                >
                  <Heart className="h-4 w-4 mr-2" />
                  Add First Recommendation
                </Button>
              </div>
            ) : (
              <>
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                  {recommendations.map((recommendation) => (
                    <Card key={recommendation.id} className="group relative celebrity-product-card">
                      <CardContent className="p-4">
                        <div className="flex items-start gap-3">
                          <Checkbox
                            checked={selectedRecommendations.includes(recommendation.id)}
                            onCheckedChange={(checked) => 
                              handleRecommendationSelect(recommendation.id, checked as boolean)
                            }
                          />
                          
                          <div className="flex-1 min-w-0">
                            <div className="flex items-start justify-between mb-2">
                              <div className="flex items-center gap-2 min-w-0">
                                <div className="w-12 h-12 rounded-lg bg-muted flex-shrink-0 overflow-hidden">
                                  {recommendation.product.featured_image ? (
                                    <Image
                                      src={recommendation.product.featured_image}
                                      alt={recommendation.product.name}
                                      width={48}
                                      height={48}
                                      className="w-full h-full object-cover"
                                    />
                                  ) : (
                                    <div className="w-full h-full flex items-center justify-center">
                                      <Package className="h-6 w-6 text-muted-foreground" />
                                    </div>
                                  )}
                                </div>
                                <div className="min-w-0 flex-1">
                                  <h4 className="font-medium text-sm leading-tight truncate">
                                    {recommendation.product.name}
                                  </h4>
                                  <p className="text-xs text-muted-foreground">
                                    {formatCurrency(recommendation.product.sale_price || recommendation.product.price)}
                                  </p>
                                  {recommendation.product.brand && (
                                    <p className="text-xs text-muted-foreground">
                                      by {recommendation.product.brand.name}
                                    </p>
                                  )}
                                </div>
                              </div>
                              
                              <DropdownMenu>
                                <DropdownMenuTrigger asChild>
                                  <Button variant="ghost" size="sm" className="h-8 w-8 p-0">
                                    <MoreVertical className="h-4 w-4" />
                                  </Button>
                                </DropdownMenuTrigger>
                                <DropdownMenuContent align="end">
                                  <DropdownMenuItem onClick={() => handleEditRecommendation(recommendation)}>
                                    <Edit className="h-4 w-4 mr-2" />
                                    Edit Testimonial
                                  </DropdownMenuItem>
                                  <DropdownMenuSeparator />
                                  <DropdownMenuItem 
                                    className="text-destructive"
                                    onClick={() => {
                                      setSelectedRecommendations([recommendation.id]);
                                      handleDeleteRecommendations();
                                    }}
                                  >
                                    <Trash2 className="h-4 w-4 mr-2" />
                                    Remove
                                  </DropdownMenuItem>
                                </DropdownMenuContent>
                              </DropdownMenu>
                            </div>
                            
                            <div className="flex items-center gap-2 mb-2">
                              <Badge variant="default" className="text-xs bg-rose-500">
                                <Heart className="h-3 w-3 mr-1" />
                                Featured
                              </Badge>
                            </div>
                            
                            {recommendation.testimonial && (
                              <p className="text-xs text-muted-foreground line-clamp-2 mb-2">
                                "{recommendation.testimonial}"
                              </p>
                            )}
                            
                            <p className="text-xs text-muted-foreground">
                              Added {formatDate(recommendation.created_at)}
                            </p>
                          </div>
                        </div>
                      </CardContent>
                    </Card>
                  ))}
                </div>

                {/* Pagination for recommendations */}
                {recommendationsData && recommendationsData.total_pages > 1 && (
                  <div className="flex items-center justify-between">
                    <p className="text-sm text-muted-foreground">
                      Showing {recommendations.length} of {recommendationsData.count} recommendations
                    </p>
                    <div className="flex items-center gap-2">
                      <Button
                        variant="outline"
                        size="sm"
                        disabled={!recommendationsData.has_previous}
                        onClick={() => handleRecommendationFilterChange('page', recommendationFilters.page! - 1)}
                      >
                        <ChevronLeft className="h-4 w-4" />
                      </Button>
                      <span className="text-sm text-muted-foreground">
                        Page {recommendationsData.page} of {recommendationsData.total_pages}
                      </span>
                      <Button
                        variant="outline"
                        size="sm"
                        disabled={!recommendationsData.has_next}
                        onClick={() => handleRecommendationFilterChange('page', recommendationFilters.page! + 1)}
                      >
                        <ChevronRight className="h-4 w-4" />
                      </Button>
                    </div>
                  </div>
                )}
              </>
            )}
          </TabsContent>

          {/* Available Products Tab */}
          <TabsContent value="available" className="space-y-4">
            <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
              <div className="flex items-center gap-2">
                <div className="relative">
                  <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                                      <Input
                      placeholder="Search products..."
                      className="pl-9 w-64"
                      value={availableProductsFilters.search || ''}
                      onChange={(e) => handleDebouncedAvailableProductsSearch(e.target.value)}
                    />
                </div>
              </div>
              
              <div className="flex items-center gap-2">
                {availableProducts.length > 0 && (
                  <div className="flex items-center gap-2">
                    <Checkbox
                      checked={selectedProducts.length === availableProducts.length}
                      onCheckedChange={handleSelectAllProducts}
                    />
                    <span className="text-sm text-muted-foreground">
                      Select All
                    </span>
                  </div>
                )}
              </div>
            </div>

            {loadingAvailableProducts ? (
              <div className="flex items-center justify-center py-12">
                <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
              </div>
            ) : availableProducts.length === 0 ? (
              <div className="text-center py-12">
                <AlertTriangle className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
                <h3 className="text-lg font-semibold text-muted-foreground mb-2">
                  No available products
                </h3>
                <p className="text-sm text-muted-foreground">
                  All products are already recommended by {celebrity.full_name}.
                </p>
              </div>
            ) : (
              <>
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                  {availableProducts.map((product) => (
                    <Card key={product.id} className="group relative celebrity-product-card">
                      <CardContent className="p-4">
                        <div className="flex items-start gap-3">
                          <Checkbox
                            checked={selectedProducts.includes(product.id)}
                            onCheckedChange={(checked) => 
                              handleProductSelect(product.id, checked as boolean)
                            }
                          />
                          
                          <div className="flex-1 min-w-0">
                            <div className="flex items-start gap-3 mb-2">
                              <div className="w-12 h-12 rounded-lg bg-muted flex-shrink-0 overflow-hidden">
                                {product.featured_image ? (
                                  <Image
                                    src={product.featured_image}
                                    alt={product.name}
                                    width={48}
                                    height={48}
                                    className="w-full h-full object-cover"
                                  />
                                ) : (
                                  <div className="w-full h-full flex items-center justify-center">
                                    <Package className="h-6 w-6 text-muted-foreground" />
                                  </div>
                                )}
                              </div>
                              <div className="min-w-0 flex-1">
                                <h4 className="font-medium text-sm leading-tight truncate">
                                  {product.name}
                                </h4>
                                <p className="text-xs text-muted-foreground">
                                  {formatCurrency(product.sale_price || product.price)}
                                </p>
                                {product.category && (
                                  <p className="text-xs text-muted-foreground">
                                    {product.category.name}
                                  </p>
                                )}
                                {product.brand && (
                                  <p className="text-xs text-muted-foreground">
                                    by {product.brand.name}
                                  </p>
                                )}
                              </div>
                            </div>
                            
                            <div className="flex items-center justify-between">
                              <Badge variant="outline" className="text-xs">
                                Stock: {product.stock}
                              </Badge>
                              <Button
                                variant="ghost"
                                size="sm"
                                className="h-8 px-2 text-rose-500 hover:text-rose-600 hover:bg-rose-50"
                                onClick={() => {
                                  setRecommendationForm(prev => ({ ...prev, product: product.id }));
                                  setShowAddDialog(true);
                                }}
                              >
                                <Heart className="h-4 w-4" />
                              </Button>
                            </div>
                          </div>
                        </div>
                      </CardContent>
                    </Card>
                  ))}
                </div>

                {/* Pagination for available products */}
                {availableProductsData && availableProductsData.total_pages > 1 && (
                  <div className="flex items-center justify-between">
                    <p className="text-sm text-muted-foreground">
                      Showing {availableProducts.length} of {availableProductsData.count} products
                    </p>
                    <div className="flex items-center gap-2">
                      <Button
                        variant="outline"
                        size="sm"
                        disabled={!availableProductsData.has_previous}
                        onClick={() => handleAvailableProductsFilterChange('page', availableProductsFilters.page! - 1)}
                      >
                        <ChevronLeft className="h-4 w-4" />
                      </Button>
                      <span className="text-sm text-muted-foreground">
                        Page {availableProductsData.page} of {availableProductsData.total_pages}
                      </span>
                      <Button
                        variant="outline"
                        size="sm"
                        disabled={!availableProductsData.has_next}
                        onClick={() => handleAvailableProductsFilterChange('page', availableProductsFilters.page! + 1)}
                      >
                        <ChevronRight className="h-4 w-4" />
                      </Button>
                    </div>
                  </div>
                )}
              </>
            )}
          </TabsContent>
        </Tabs>
      </CardContent>

      {/* Add Single Product Dialog */}
      <Dialog open={showAddDialog} onOpenChange={setShowAddDialog}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <Heart className="h-5 w-5 text-rose-500" />
              Add Recommendation
            </DialogTitle>
            <DialogDescription>
              Add this product to {celebrity.full_name}'s featured recommendations.
            </DialogDescription>
          </DialogHeader>
          
          <div className="space-y-4">
            <div>
              <label className="text-sm font-medium mb-2 block">
                Testimonial (Optional)
              </label>
              <Textarea
                placeholder={`"I absolutely love this product! It's become an essential part of my routine." - ${celebrity.full_name}`}
                value={recommendationForm.testimonial}
                onChange={(e) => 
                  setRecommendationForm(prev => ({ ...prev, testimonial: e.target.value }))
                }
                rows={3}
              />
              <p className="text-xs text-muted-foreground mt-1">
                Add a personal testimonial from {celebrity.full_name} about this product.
              </p>
            </div>
          </div>
          
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowAddDialog(false)}>
              Cancel
            </Button>
            <Button 
              onClick={handleCreateRecommendation}
              disabled={createRecommendation.isPending || !recommendationForm.product}
              className="bg-rose-500 hover:bg-rose-600"
            >
              {createRecommendation.isPending && <Loader2 className="h-4 w-4 mr-2 animate-spin" />}
              <Heart className="h-4 w-4 mr-2" />
              Add Recommendation
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Edit Recommendation Dialog */}
      <Dialog open={showEditDialog} onOpenChange={setShowEditDialog}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle>Edit Recommendation</DialogTitle>
            <DialogDescription>
              Update the testimonial for this recommendation.
            </DialogDescription>
          </DialogHeader>
          
          <div className="space-y-4">
            <div>
              <label className="text-sm font-medium mb-2 block">
                Testimonial (Optional)
              </label>
              <Textarea
                placeholder={`"I absolutely love this product! It's become an essential part of my routine." - ${celebrity.full_name}`}
                value={recommendationForm.testimonial}
                onChange={(e) => 
                  setRecommendationForm(prev => ({ ...prev, testimonial: e.target.value }))
                }
                rows={3}
              />
            </div>
          </div>
          
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowEditDialog(false)}>
              Cancel
            </Button>
            <Button 
              onClick={handleUpdateRecommendation}
              disabled={updateRecommendation.isPending}
            >
              {updateRecommendation.isPending && <Loader2 className="h-4 w-4 mr-2 animate-spin" />}
              Update Recommendation
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Bulk Add Products Dialog */}
      <Dialog open={showBulkAddDialog} onOpenChange={setShowBulkAddDialog}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <Heart className="h-5 w-5 text-rose-500" />
              Bulk Add Recommendations
            </DialogTitle>
            <DialogDescription>
              Add {selectedProducts.length} product{selectedProducts.length > 1 ? 's' : ''} to {celebrity.full_name}'s recommendations.
            </DialogDescription>
          </DialogHeader>
          
          <div className="space-y-4">
            <div>
              <label className="text-sm font-medium mb-2 block">
                General Testimonial (Optional)
              </label>
              <Textarea
                placeholder={`"These products are amazing! I highly recommend them." - ${celebrity.full_name}`}
                value={bulkRecommendationData.testimonial}
                onChange={(e) => 
                  setBulkRecommendationData(prev => ({ ...prev, testimonial: e.target.value }))
                }
                rows={3}
              />
              <p className="text-xs text-muted-foreground mt-1">
                This testimonial will be applied to all selected products.
              </p>
            </div>
          </div>
          
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowBulkAddDialog(false)}>
              Cancel
            </Button>
            <Button 
              onClick={handleBulkAddProducts}
              disabled={bulkManageRecommendations.isPending}
              className="bg-rose-500 hover:bg-rose-600"
            >
              {bulkManageRecommendations.isPending && <Loader2 className="h-4 w-4 mr-2 animate-spin" />}
              <Heart className="h-4 w-4 mr-2" />
              Add Recommendations
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </Card>
  );
} 