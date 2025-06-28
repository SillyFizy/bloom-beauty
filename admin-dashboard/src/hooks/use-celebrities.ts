'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { toast } from 'react-hot-toast';
import { celebritiesService } from '@/services/celebrities';
import {
  Celebrity,
  CelebrityListItem,
  CelebrityFormData,
  CelebrityFilters,
  CelebritiesResponse,
  CelebrityStats,
  RoutineItemFormData,
  ProductPromotionFormData,
  CelebrityProductPromotion,
  CelebrityMorningRoutineItem,
  CelebrityEveningRoutineItem,
  PromotionFilters,
  PromotionsResponse,
  AvailableProductsFilters,
  AvailableProductsResponse,
  BulkPromotionData,
  BulkPromotionResponse,
} from '@/types/celebrity';

// Query keys for cache management
export const CELEBRITY_QUERY_KEYS = {
  celebrities: ['celebrities'],
  celebrity: (id: number) => ['celebrities', id],
  celebrityStats: ['celebrities', 'stats'],
  celebrityPromotions: (id: number) => ['celebrities', id, 'promotions'],
  morningRoutine: (id: number) => ['celebrities', id, 'morning-routine'],
  eveningRoutine: (id: number) => ['celebrities', id, 'evening-routine'],
  featuredPicks: ['celebrities', 'featured-picks'],
} as const;

// Celebrity queries
export function useCelebrities(filters: CelebrityFilters = {}) {
  return useQuery<CelebritiesResponse>({
    queryKey: ['celebrities', filters],
    queryFn: () => celebritiesService.getCelebrities(filters),
    staleTime: 5 * 60 * 1000, // 5 minutes
  });
}

export function useCelebrity(id: number) {
  return useQuery<Celebrity>({
    queryKey: ['celebrity', id],
    queryFn: () => celebritiesService.getCelebrityById(id),
    enabled: !!id,
  });
}

// Alias for useCelebrity for backward compatibility
export const useCelebrityById = useCelebrity;

export function useCelebrityStats() {
  return useQuery<CelebrityStats>({
    queryKey: ['celebrity-stats'],
    queryFn: () => celebritiesService.getCelebrityStats(),
    staleTime: 10 * 60 * 1000, // 10 minutes
  });
}

// Celebrity promotions
export function useCelebrityPromotions(celebrityId: number, promotionType?: string) {
  return useQuery({
    queryKey: [...CELEBRITY_QUERY_KEYS.celebrityPromotions(celebrityId), promotionType],
    queryFn: () => celebritiesService.getCelebrityPromotionsAdmin(celebrityId, { promotion_type: promotionType }),
    enabled: !!celebrityId && celebrityId > 0,
    staleTime: 5 * 60 * 1000,
  });
}

// Celebrity routines
export function useMorningRoutine(celebrityId: number) {
  return useQuery({
    queryKey: CELEBRITY_QUERY_KEYS.morningRoutine(celebrityId),
    queryFn: () => celebritiesService.getMorningRoutine(celebrityId),
    enabled: !!celebrityId && celebrityId > 0,
    staleTime: 5 * 60 * 1000,
  });
}

export function useEveningRoutine(celebrityId: number) {
  return useQuery({
    queryKey: CELEBRITY_QUERY_KEYS.eveningRoutine(celebrityId),
    queryFn: () => celebritiesService.getEveningRoutine(celebrityId),
    enabled: !!celebrityId && celebrityId > 0,
    staleTime: 5 * 60 * 1000,
  });
}

// Featured picks
export function useFeaturedCelebrityPicks(limit = 20) {
  return useQuery({
    queryKey: [...CELEBRITY_QUERY_KEYS.featuredPicks, limit],
    queryFn: () => celebritiesService.getFeaturedCelebrityPicks(limit),
    staleTime: 15 * 60 * 1000, // 15 minutes
  });
}

// Celebrity mutations
export function useCreateCelebrity() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: CelebrityFormData) => celebritiesService.createCelebrity(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['celebrities'] });
      queryClient.invalidateQueries({ queryKey: ['celebrity-stats'] });
      toast.success('Celebrity created successfully');
    },
    onError: (error: any) => {
      toast.error(error?.message || 'Failed to create celebrity');
    },
  });
}

export function useUpdateCelebrity() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: Partial<CelebrityFormData> }) =>
      celebritiesService.updateCelebrity(id, data),
    onSuccess: (_, { id }) => {
      queryClient.invalidateQueries({ queryKey: ['celebrities'] });
      queryClient.invalidateQueries({ queryKey: ['celebrity', id] });
      queryClient.invalidateQueries({ queryKey: ['celebrity-stats'] });
      toast.success('Celebrity updated successfully');
    },
    onError: (error: any) => {
      toast.error(error?.message || 'Failed to update celebrity');
    },
  });
}

export function useDeleteCelebrity() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: number) => celebritiesService.deleteCelebrity(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['celebrities'] });
      queryClient.invalidateQueries({ queryKey: ['celebrity-stats'] });
      toast.success('Celebrity deleted successfully');
    },
    onError: (error: any) => {
      toast.error(error?.message || 'Failed to delete celebrity');
    },
  });
}

// Bulk operations
export function useBulkUpdateCelebrities() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      celebrityIds,
      updates,
    }: {
      celebrityIds: number[];
      updates: Partial<Pick<CelebrityFormData, 'is_active'>>;
    }) => celebritiesService.bulkUpdateCelebrities(celebrityIds, updates),
    onSuccess: (result) => {
      // Invalidate celebrities list
      queryClient.invalidateQueries({ queryKey: CELEBRITY_QUERY_KEYS.celebrities });
      queryClient.invalidateQueries({ queryKey: CELEBRITY_QUERY_KEYS.celebrityStats });
      
      toast.success(`${result.updated} celebrities updated successfully!`);
      
      if (result.errors.length > 0) {
        result.errors.forEach(error => toast.error(error));
      }
    },
    onError: (error: any) => {
      toast.error(error.message || 'Failed to update celebrities');
    },
  });
}

export function useBulkDeleteCelebrities() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (celebrityIds: number[]) =>
      celebritiesService.bulkDeleteCelebrities(celebrityIds),
    onSuccess: (result) => {
      // Invalidate celebrities list
      queryClient.invalidateQueries({ queryKey: CELEBRITY_QUERY_KEYS.celebrities });
      queryClient.invalidateQueries({ queryKey: CELEBRITY_QUERY_KEYS.celebrityStats });
      
      toast.success(`${result.deleted} celebrities deleted successfully!`);
      
      if (result.errors.length > 0) {
        result.errors.forEach(error => toast.error(error));
      }
    },
    onError: (error: any) => {
      toast.error(error.message || 'Failed to delete celebrities');
    },
  });
}

// Celebrity product promotion hooks
export function useCelebrityPromotionsAdmin(celebrityId: number, filters: PromotionFilters = {}) {
  return useQuery<PromotionsResponse>({
    queryKey: ['celebrity-promotions-admin', celebrityId, filters],
    queryFn: () => celebritiesService.getCelebrityPromotionsAdmin(celebrityId, filters),
    enabled: !!celebrityId,
    staleTime: 5 * 60 * 1000,
  });
}

export function useCelebrityPromotionDetail(celebrityId: number, promotionId: number) {
  return useQuery<CelebrityProductPromotion>({
    queryKey: ['celebrity-promotion-detail', celebrityId, promotionId],
    queryFn: () => celebritiesService.getCelebrityPromotionDetail(celebrityId, promotionId),
    enabled: !!celebrityId && !!promotionId,
  });
}

export function useAvailableProductsForCelebrity(celebrityId: number, filters: AvailableProductsFilters = {}) {
  return useQuery<AvailableProductsResponse>({
    queryKey: ['available-products-for-celebrity', celebrityId, filters],
    queryFn: () => celebritiesService.getAvailableProductsForCelebrity(celebrityId, filters),
    enabled: !!celebrityId,
    staleTime: 2 * 60 * 1000, // 2 minutes
  });
}

export function useCreateCelebrityPromotion() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ celebrityId, data }: { celebrityId: number; data: ProductPromotionFormData }) =>
      celebritiesService.createCelebrityPromotion(celebrityId, data),
    onSuccess: (_, { celebrityId }) => {
      queryClient.invalidateQueries({ queryKey: ['celebrity-promotions-admin', celebrityId] });
      queryClient.invalidateQueries({ queryKey: ['available-products-for-celebrity', celebrityId] });
      queryClient.invalidateQueries({ queryKey: ['celebrity', celebrityId] });
      queryClient.invalidateQueries({ queryKey: ['celebrity-stats'] });
      toast.success('Product promotion created successfully');
    },
    onError: (error: any) => {
      toast.error(error?.message || 'Failed to create product promotion');
    },
  });
}

export function useUpdateCelebrityPromotion() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ 
      celebrityId, 
      promotionId, 
      data 
    }: { 
      celebrityId: number; 
      promotionId: number; 
      data: Partial<ProductPromotionFormData> 
    }) =>
      celebritiesService.updateCelebrityPromotion(celebrityId, promotionId, data),
    onSuccess: (_, { celebrityId, promotionId }) => {
      queryClient.invalidateQueries({ queryKey: ['celebrity-promotions-admin', celebrityId] });
      queryClient.invalidateQueries({ queryKey: ['celebrity-promotion-detail', celebrityId, promotionId] });
      queryClient.invalidateQueries({ queryKey: ['celebrity', celebrityId] });
      toast.success('Product promotion updated successfully');
    },
    onError: (error: any) => {
      toast.error(error?.message || 'Failed to update product promotion');
    },
  });
}

export function useDeleteCelebrityPromotion() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ celebrityId, promotionId }: { celebrityId: number; promotionId: number }) =>
      celebritiesService.deleteCelebrityPromotion(celebrityId, promotionId),
    onSuccess: (_, { celebrityId }) => {
      queryClient.invalidateQueries({ queryKey: ['celebrity-promotions-admin', celebrityId] });
      queryClient.invalidateQueries({ queryKey: ['available-products-for-celebrity', celebrityId] });
      queryClient.invalidateQueries({ queryKey: ['celebrity', celebrityId] });
      queryClient.invalidateQueries({ queryKey: ['celebrity-stats'] });
      toast.success('Product promotion deleted successfully');
    },
    onError: (error: any) => {
      toast.error(error?.message || 'Failed to delete product promotion');
    },
  });
}

export function useBulkManageCelebrityPromotions() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ celebrityId, data }: { celebrityId: number; data: BulkPromotionData }) =>
      celebritiesService.bulkManageCelebrityPromotions(celebrityId, data),
    onSuccess: (result: BulkPromotionResponse, { celebrityId, data }) => {
      queryClient.invalidateQueries({ queryKey: ['celebrity-promotions-admin', celebrityId] });
      queryClient.invalidateQueries({ queryKey: ['available-products-for-celebrity', celebrityId] });
      queryClient.invalidateQueries({ queryKey: ['celebrity', celebrityId] });
      queryClient.invalidateQueries({ queryKey: ['celebrity-stats'] });
      
      if (data.action === 'add') {
        const successCount = result.created_count || 0;
        const errorCount = result.error_count || 0;
        
        if (successCount > 0) {
          toast.success(`${successCount} product${successCount > 1 ? 's' : ''} added successfully`);
        }
        if (errorCount > 0) {
          toast.error(`${errorCount} product${errorCount > 1 ? 's' : ''} failed to add`);
        }
      } else {
        const removedCount = result.removed_count || 0;
        const errorCount = result.error_count || 0;
        
        if (removedCount > 0) {
          toast.success(`${removedCount} promotion${removedCount > 1 ? 's' : ''} removed successfully`);
        }
        if (errorCount > 0) {
          toast.error(`${errorCount} promotion${errorCount > 1 ? 's' : ''} failed to remove`);
        }
      }
    },
    onError: (error: any) => {
      toast.error(error?.message || 'Failed to manage promotions');
    },
  });
}

// Routine mutations
export function useCreateMorningRoutineItem() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: { celebrity_id: number; product_id: number; order: number; description?: string }) =>
      celebritiesService.addMorningRoutineItem({ ...data, product: data.product_id }),
    onSuccess: (_, { celebrity_id }) => {
      // Invalidate morning routine
      queryClient.invalidateQueries({ 
        queryKey: CELEBRITY_QUERY_KEYS.morningRoutine(celebrity_id) 
      });
      // Refresh celebrity details
      queryClient.invalidateQueries({ 
        queryKey: CELEBRITY_QUERY_KEYS.celebrity(celebrity_id) 
      });
      
      toast.success('Morning routine item added successfully!');
    },
    onError: (error: any) => {
      toast.error(error.message || 'Failed to add morning routine item');
    },
  });
}

export function useCreateEveningRoutineItem() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: { celebrity_id: number; product_id: number; order: number; description?: string }) =>
      celebritiesService.addEveningRoutineItem({ ...data, product: data.product_id }),
    onSuccess: (_, { celebrity_id }) => {
      // Invalidate evening routine
      queryClient.invalidateQueries({ 
        queryKey: CELEBRITY_QUERY_KEYS.eveningRoutine(celebrity_id) 
      });
      // Refresh celebrity details
      queryClient.invalidateQueries({ 
        queryKey: CELEBRITY_QUERY_KEYS.celebrity(celebrity_id) 
      });
      
      toast.success('Evening routine item added successfully!');
    },
    onError: (error: any) => {
      toast.error(error.message || 'Failed to add evening routine item');
    },
  });
}

export function useDeleteMorningRoutineItem() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ itemId, celebrityId }: { itemId: number; celebrityId: number }) =>
      celebritiesService.deleteMorningRoutineItem(itemId),
    onSuccess: (_, { celebrityId }) => {
      // Invalidate morning routine
      queryClient.invalidateQueries({ 
        queryKey: CELEBRITY_QUERY_KEYS.morningRoutine(celebrityId) 
      });
      // Refresh celebrity details
      queryClient.invalidateQueries({ 
        queryKey: CELEBRITY_QUERY_KEYS.celebrity(celebrityId) 
      });
      
      toast.success('Morning routine item removed successfully!');
    },
    onError: (error: any) => {
      toast.error(error.message || 'Failed to remove morning routine item');
    },
  });
}

export function useDeleteEveningRoutineItem() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ itemId, celebrityId }: { itemId: number; celebrityId: number }) =>
      celebritiesService.deleteEveningRoutineItem(itemId),
    onSuccess: (_, { celebrityId }) => {
      // Invalidate evening routine
      queryClient.invalidateQueries({ 
        queryKey: CELEBRITY_QUERY_KEYS.eveningRoutine(celebrityId) 
      });
      // Refresh celebrity details
      queryClient.invalidateQueries({ 
        queryKey: CELEBRITY_QUERY_KEYS.celebrity(celebrityId) 
      });
      
      toast.success('Evening routine item removed successfully!');
    },
    onError: (error: any) => {
      toast.error(error.message || 'Failed to remove evening routine item');
    },
  });
}

// Update routine item hooks
export function useUpdateMorningRoutineItem() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: { order?: number; description?: string } }) =>
      celebritiesService.updateMorningRoutineItem(id, data),
    onSuccess: () => {
      // Invalidate all morning routine queries
      queryClient.invalidateQueries({ 
        queryKey: ['celebrities', 'morning-routine'] 
      });
      toast.success('Morning routine step updated successfully!');
    },
    onError: (error: any) => {
      toast.error(error.message || 'Failed to update morning routine step');
    },
  });
}

export function useUpdateEveningRoutineItem() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: { order?: number; description?: string } }) =>
      celebritiesService.updateEveningRoutineItem(id, data),
    onSuccess: () => {
      // Invalidate all evening routine queries
      queryClient.invalidateQueries({ 
        queryKey: ['celebrities', 'evening-routine'] 
      });
      toast.success('Evening routine step updated successfully!');
    },
    onError: (error: any) => {
      toast.error(error.message || 'Failed to update evening routine step');
    },
  });
}

// Convenience aliases for the add hooks
export const useAddMorningRoutineItem = useCreateMorningRoutineItem;
export const useAddEveningRoutineItem = useCreateEveningRoutineItem;

// Additional aliases for backward compatibility
export const useCelebrityMorningRoutine = useMorningRoutine;
export const useCelebrityEveningRoutine = useEveningRoutine;
export const useDeleteCelebrityRoutineItem = ({ celebrityId, routineType, itemId }: { celebrityId: number; routineType: 'morning' | 'evening'; itemId: number }) => {
  const deleteMorning = useDeleteMorningRoutineItem();
  const deleteEvening = useDeleteEveningRoutineItem();
  
  return {
    mutateAsync: async () => {
      if (routineType === 'morning') {
        return deleteMorning.mutateAsync({ itemId, celebrityId });
      } else {
        return deleteEvening.mutateAsync({ itemId, celebrityId });
      }
    },
    isPending: deleteMorning.isPending || deleteEvening.isPending,
  };
};

// Search hook
export function useSearchCelebrities(query: string) {
  return useQuery({
    queryKey: ['celebrities', 'search', query],
    queryFn: () => celebritiesService.searchCelebrities(query),
    enabled: !!query && query.length > 2,
    staleTime: 2 * 60 * 1000, // 2 minutes
  });
} 