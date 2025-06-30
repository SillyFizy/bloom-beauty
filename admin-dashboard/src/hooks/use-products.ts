'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { toast } from 'react-hot-toast';
import {
  productsService,
  categoriesService,
  brandsService,
} from '@/services/products';
import {
  ProductsResponse,
  Product,
  ProductFilters,
  ProductFormData,
  Category,
  Brand,
} from '@/types/product';

// Query keys
export const QUERY_KEYS = {
  products: ['products'],
  product: (id: number) => ['products', id],
  categories: ['categories'],
  brands: ['brands'],
  productStats: ['products', 'stats'],
  lowStock: ['products', 'lowStock'],
} as const;

// Products queries
export function useProducts(filters: ProductFilters = {}) {
  return useQuery({
    queryKey: [...QUERY_KEYS.products, filters],
    queryFn: () => productsService.getProducts(filters),
    placeholderData: (previousData) => previousData, // React Query v5 replacement for keepPreviousData
    staleTime: 5 * 60 * 1000, // 5 minutes
  });
}

export function useProduct(id: number) {
  return useQuery({
    queryKey: QUERY_KEYS.product(id),
    queryFn: () => productsService.getProduct(id),
    enabled: !!id,
  });
}

export function useProductStats() {
  return useQuery({
    queryKey: QUERY_KEYS.productStats,
    queryFn: () => productsService.getProductStats(),
    staleTime: 10 * 60 * 1000, // 10 minutes
  });
}

// Categories and brands
export function useCategories() {
  return useQuery({
    queryKey: QUERY_KEYS.categories,
    queryFn: async () => {
      try {
        const result = await categoriesService.getCategories();
        // Ensure we always return an array
        return Array.isArray(result) ? result : [];
      } catch (error) {
        console.error('Failed to fetch categories:', error);
        // Return empty array on error to prevent map() issues
        return [];
      }
    },
    staleTime: 15 * 60 * 1000, // 15 minutes
    retry: 3,
    retryDelay: (attemptIndex) => Math.min(1000 * 2 ** attemptIndex, 30000),
  });
}

export function useBrands() {
  return useQuery({
    queryKey: QUERY_KEYS.brands,
    queryFn: async () => {
      try {
        const result = await brandsService.getBrands();
        // Ensure we always return an array
        return Array.isArray(result) ? result : [];
      } catch (error) {
        console.error('Failed to fetch brands:', error);
        // Return empty array on error to prevent map() issues
        return [];
      }
    },
    staleTime: 15 * 60 * 1000, // 15 minutes
    retry: 3,
    retryDelay: (attemptIndex) => Math.min(1000 * 2 ** attemptIndex, 30000),
  });
}

// Product mutations
export function useCreateProduct() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: ProductFormData) => productsService.createProduct(data),
    onSuccess: (newProduct) => {
      // Invalidate and refetch products list
      queryClient.invalidateQueries({ queryKey: QUERY_KEYS.products });
      queryClient.invalidateQueries({ queryKey: QUERY_KEYS.productStats });
      
      toast.success('Product created successfully!');
    },
    onError: (error: any) => {
      toast.error(error.message || 'Failed to create product');
    },
  });
}

export function useUpdateProduct() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: Partial<ProductFormData> }) =>
      productsService.updateProduct(id, data),
    onSuccess: (updatedProduct, { id }) => {
      // Update the product in cache
      queryClient.setQueryData(QUERY_KEYS.product(id), updatedProduct);
      
      // Invalidate products list to reflect changes
      queryClient.invalidateQueries({ queryKey: QUERY_KEYS.products });
      queryClient.invalidateQueries({ queryKey: QUERY_KEYS.productStats });
      
      toast.success('Product updated successfully!');
    },
    onError: (error: any) => {
      toast.error(error.message || 'Failed to update product');
    },
  });
}

export function useDeleteProduct() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: number) => productsService.deleteProduct(id),
    onSuccess: (_, deletedId) => {
      // Remove from cache
      queryClient.removeQueries({ queryKey: QUERY_KEYS.product(deletedId) });
      
      // Invalidate products list
      queryClient.invalidateQueries({ queryKey: QUERY_KEYS.products });
      queryClient.invalidateQueries({ queryKey: QUERY_KEYS.productStats });
      
      toast.success('Product deleted successfully!');
    },
    onError: (error: any) => {
      toast.error(error.message || 'Failed to delete product');
    },
  });
}

export function useBulkUpdateProducts() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      productIds,
      updates,
    }: {
      productIds: number[];
      updates: Partial<Pick<ProductFormData, 'is_active' | 'is_featured' | 'stock'>>;
    }) => productsService.bulkUpdateProducts(productIds, updates),
    onSuccess: (result) => {
      // Invalidate products list
      queryClient.invalidateQueries({ queryKey: QUERY_KEYS.products });
      queryClient.invalidateQueries({ queryKey: QUERY_KEYS.productStats });
      
      toast.success(`${result.updated} products updated successfully!`);
      
      if (result.errors.length > 0) {
        result.errors.forEach(error => toast.error(error));
      }
    },
    onError: (error: any) => {
      toast.error(error.message || 'Failed to update products');
    },
  });
}

export function useBulkDeleteProducts() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (productIds: number[]) =>
      productsService.bulkDeleteProducts(productIds),
    onSuccess: (result) => {
      // Invalidate products list
      queryClient.invalidateQueries({ queryKey: QUERY_KEYS.products });
      queryClient.invalidateQueries({ queryKey: QUERY_KEYS.productStats });
      
      toast.success(`${result.deleted} products deleted successfully!`);
      
      if (result.errors.length > 0) {
        result.errors.forEach(error => toast.error(error));
      }
    },
    onError: (error: any) => {
      toast.error(error.message || 'Failed to delete products');
    },
  });
}

export function useUpdateStock() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      id,
      quantity,
      adjustmentType,
      reference,
    }: {
      id: number;
      quantity: number;
      adjustmentType: 'stock_in' | 'stock_out' | 'adjustment';
      reference?: string;
    }) => productsService.updateStock(id, quantity, adjustmentType, reference),
    onSuccess: (updatedProduct, { id }) => {
      // Update the product in cache
      queryClient.setQueryData(QUERY_KEYS.product(id), updatedProduct);
      
      // Invalidate products list
      queryClient.invalidateQueries({ queryKey: QUERY_KEYS.products });
      queryClient.invalidateQueries({ queryKey: QUERY_KEYS.productStats });
      
      toast.success('Stock updated successfully!');
    },
    onError: (error: any) => {
      toast.error(error.message || 'Failed to update stock');
    },
  });
}

export function useLowStockProducts() {
  return useQuery({
    queryKey: QUERY_KEYS.lowStock,
    queryFn: () => productsService.getLowStockProducts(),
    staleTime: 5 * 60 * 1000,
  });
} 