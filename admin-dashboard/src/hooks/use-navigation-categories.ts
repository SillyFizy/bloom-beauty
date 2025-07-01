'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { NavigationCategoriesService } from '@/services/navigation-categories';
import {
  NavigationCategory,
  NavigationCategoryFormData,
  BulkUpdateNavigationCategory,
  BulkProductAssignment,
  ProductSearchParams
} from '@/types/navigation-category';
import { useToastContext } from '@/components/providers/ToastProvider';

// Create service instance
const navigationCategoriesService = new NavigationCategoriesService();

// Query keys
export const NAVIGATION_CATEGORY_QUERY_KEYS = {
  navigationCategories: ['navigationCategories'],
  navigationCategory: (id: number) => ['navigationCategories', id],
  navigationCategoryStats: ['navigationCategories', 'stats'],
  publicNavigationCategories: ['publicNavigationCategories'],
} as const;

// Queries
export function useNavigationCategories() {
      return useQuery({
      queryKey: NAVIGATION_CATEGORY_QUERY_KEYS.navigationCategories,
      queryFn: () => navigationCategoriesService.getNavigationCategories(),
      staleTime: 5 * 60 * 1000, // 5 minutes
    });
}

export const useNavigationCategory = (id: number) => {
  return useQuery({
    queryKey: NAVIGATION_CATEGORY_QUERY_KEYS.navigationCategory(id),
    queryFn: () => navigationCategoriesService.getNavigationCategory(id),
    enabled: !!id,
  });
};

export const usePublicNavigationCategories = () => {
  return useQuery({
    queryKey: NAVIGATION_CATEGORY_QUERY_KEYS.publicNavigationCategories,
    queryFn: () => navigationCategoriesService.getPublicNavigationCategories(),
    staleTime: 15 * 60 * 1000, // 15 minutes
  });
};

export const useNavigationCategoryStats = () => {
  return useQuery({
    queryKey: NAVIGATION_CATEGORY_QUERY_KEYS.navigationCategoryStats,
    queryFn: () => navigationCategoriesService.getNavigationCategoryStats(),
    staleTime: 10 * 60 * 1000, // 10 minutes
  });
};

// Mutations
export const useCreateNavigationCategory = () => {
  const queryClient = useQueryClient();
  const { showToast } = useToastContext();

  return useMutation({
    mutationFn: (data: NavigationCategoryFormData) => 
      navigationCategoriesService.createNavigationCategory(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ 
        queryKey: NAVIGATION_CATEGORY_QUERY_KEYS.navigationCategories 
      });
      queryClient.invalidateQueries({ 
        queryKey: NAVIGATION_CATEGORY_QUERY_KEYS.navigationCategoryStats 
      });
      showToast('Navigation category created successfully', 'success');
    },
    onError: (error: any) => {
      showToast(error?.message || 'Failed to create navigation category', 'error');
    },
  });
};

export const useUpdateNavigationCategory = () => {
  const queryClient = useQueryClient();
  const { showToast } = useToastContext();

  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: Partial<NavigationCategoryFormData> }) =>
      navigationCategoriesService.updateNavigationCategory(id, data),
    onSuccess: (updatedCategory, { id }) => {
      // Update the category in cache
      queryClient.setQueryData(
        NAVIGATION_CATEGORY_QUERY_KEYS.navigationCategory(id),
        updatedCategory
      );
      
      // Invalidate categories list to reflect changes
      queryClient.invalidateQueries({ 
        queryKey: NAVIGATION_CATEGORY_QUERY_KEYS.navigationCategories 
      });
      queryClient.invalidateQueries({ 
        queryKey: NAVIGATION_CATEGORY_QUERY_KEYS.navigationCategoryStats 
      });
      
      showToast('Navigation category updated successfully', 'success');
    },
    onError: (error: any) => {
      showToast(error?.message || 'Failed to update navigation category', 'error');
    },
  });
};

export const useDeleteNavigationCategory = () => {
  const queryClient = useQueryClient();
  const { showToast } = useToastContext();

  return useMutation({
    mutationFn: (id: number) => navigationCategoriesService.deleteNavigationCategory(id),
    onSuccess: (_, deletedId) => {
      // Remove from cache
      queryClient.removeQueries({ 
        queryKey: NAVIGATION_CATEGORY_QUERY_KEYS.navigationCategory(deletedId) 
      });
      
      // Invalidate categories list
      queryClient.invalidateQueries({ 
        queryKey: NAVIGATION_CATEGORY_QUERY_KEYS.navigationCategories 
      });
      queryClient.invalidateQueries({ 
        queryKey: NAVIGATION_CATEGORY_QUERY_KEYS.navigationCategoryStats 
      });
      
      showToast('Navigation category deleted successfully', 'success');
    },
    onError: (error: any) => {
      showToast(error?.message || 'Failed to delete navigation category', 'error');
    },
  });
};

export const useBulkUpdateNavigationCategories = () => {
  const queryClient = useQueryClient();
  const { showToast } = useToastContext();

  return useMutation({
    mutationFn: (categories: BulkUpdateNavigationCategory[]) =>
      navigationCategoriesService.bulkUpdateNavigationCategories(categories),
    onSuccess: () => {
      // Invalidate all queries
      queryClient.invalidateQueries({ 
        queryKey: NAVIGATION_CATEGORY_QUERY_KEYS.navigationCategories 
      });
      showToast('Categories updated successfully', 'success');
    },
    onError: (error: any) => {
      showToast(error?.message || 'Failed to update categories', 'error');
    },
  });
};

// Product management hooks
export const useCategoryProducts = (categoryId: number) => {
  return useQuery({
    queryKey: ['navigation-category-products', categoryId],
    queryFn: () => navigationCategoriesService.getCategoryProducts(categoryId),
    enabled: !!categoryId,
  });
};

export const useAddCategoryProducts = () => {
  const queryClient = useQueryClient();
  const { showToast } = useToastContext();
  
  return useMutation({
    mutationFn: ({ categoryId, data }: { 
      categoryId: number; 
      data: Omit<BulkProductAssignment, 'navigation_category_id'> 
    }) => navigationCategoriesService.addCategoryProducts(categoryId, data),
    onSuccess: (_, variables) => {
      // Invalidate category products
      queryClient.invalidateQueries({ 
        queryKey: ['navigation-category-products', variables.categoryId] 
      });
      // Invalidate navigation categories to update product counts
      queryClient.invalidateQueries({ 
        queryKey: ['navigation-categories'] 
      });
      
      showToast('Products added successfully', 'success');
    },
    onError: (error: any) => {
      showToast(error?.message || 'Failed to add products', 'error');
    },
  });
};

export const useRemoveCategoryProducts = () => {
  const queryClient = useQueryClient();
  const { showToast } = useToastContext();
  
  return useMutation({
    mutationFn: ({ categoryId, productIds }: { 
      categoryId: number; 
      productIds: number[] 
    }) => navigationCategoriesService.removeCategoryProducts(categoryId, productIds),
    onSuccess: (_, variables) => {
      // Invalidate category products
      queryClient.invalidateQueries({ 
        queryKey: ['navigation-category-products', variables.categoryId] 
      });
      // Invalidate navigation categories to update product counts
      queryClient.invalidateQueries({ 
        queryKey: ['navigation-categories'] 
      });
      
      showToast('Products removed successfully', 'success');
    },
    onError: (error: any) => {
      showToast(error?.message || 'Failed to remove products', 'error');
    },
  });
};

export const useSearchProducts = (params: ProductSearchParams) => {
  return useQuery({
    queryKey: ['product-search', params],
    queryFn: () => navigationCategoriesService.searchProducts(params),
    enabled: !!params.search && params.search.length >= 2,
    staleTime: 30000, // 30 seconds
  });
}; 