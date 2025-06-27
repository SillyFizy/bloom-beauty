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
  return useQuery({
    queryKey: [...CELEBRITY_QUERY_KEYS.celebrities, filters],
    queryFn: () => celebritiesService.getCelebrities(filters),
    placeholderData: (previousData) => previousData, // React Query v5 replacement for keepPreviousData
    staleTime: 5 * 60 * 1000, // 5 minutes
    retry: 3,
    retryDelay: (attemptIndex) => Math.min(1000 * 2 ** attemptIndex, 30000),
  });
}

export function useCelebrity(id: number) {
  return useQuery({
    queryKey: CELEBRITY_QUERY_KEYS.celebrity(id),
    queryFn: () => celebritiesService.getCelebrity(id),
    enabled: !!id && id > 0,
    staleTime: 2 * 60 * 1000, // 2 minutes
  });
}

export function useCelebrityStats() {
  return useQuery({
    queryKey: CELEBRITY_QUERY_KEYS.celebrityStats,
    queryFn: () => celebritiesService.getCelebrityStats(),
    staleTime: 10 * 60 * 1000, // 10 minutes
  });
}

// Celebrity promotions
export function useCelebrityPromotions(celebrityId: number, promotionType?: string) {
  return useQuery({
    queryKey: [...CELEBRITY_QUERY_KEYS.celebrityPromotions(celebrityId), promotionType],
    queryFn: () => celebritiesService.getCelebrityPromotions(celebrityId, promotionType),
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
    onSuccess: (newCelebrity) => {
      // Invalidate and refetch celebrities list
      queryClient.invalidateQueries({ queryKey: CELEBRITY_QUERY_KEYS.celebrities });
      queryClient.invalidateQueries({ queryKey: CELEBRITY_QUERY_KEYS.celebrityStats });
      
      toast.success(`Celebrity ${newCelebrity.full_name} created successfully!`);
    },
    onError: (error: any) => {
      toast.error(error.message || 'Failed to create celebrity');
    },
  });
}

export function useUpdateCelebrity() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: Partial<CelebrityFormData> }) =>
      celebritiesService.updateCelebrity(id, data),
    onSuccess: (updatedCelebrity, { id }) => {
      // Update the celebrity in cache
      queryClient.setQueryData(CELEBRITY_QUERY_KEYS.celebrity(id), updatedCelebrity);
      
      // Invalidate celebrities list to reflect changes
      queryClient.invalidateQueries({ queryKey: CELEBRITY_QUERY_KEYS.celebrities });
      queryClient.invalidateQueries({ queryKey: CELEBRITY_QUERY_KEYS.celebrityStats });
      
      toast.success(`Celebrity ${updatedCelebrity.full_name} updated successfully!`);
    },
    onError: (error: any) => {
      toast.error(error.message || 'Failed to update celebrity');
    },
  });
}

export function useDeleteCelebrity() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: number) => celebritiesService.deleteCelebrity(id),
    onSuccess: (_, deletedId) => {
      // Remove from cache
      queryClient.removeQueries({ queryKey: CELEBRITY_QUERY_KEYS.celebrity(deletedId) });
      
      // Invalidate celebrities list
      queryClient.invalidateQueries({ queryKey: CELEBRITY_QUERY_KEYS.celebrities });
      queryClient.invalidateQueries({ queryKey: CELEBRITY_QUERY_KEYS.celebrityStats });
      
      toast.success('Celebrity deleted successfully!');
    },
    onError: (error: any) => {
      toast.error(error.message || 'Failed to delete celebrity');
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

// Promotion mutations
export function useCreateCelebrityPromotion() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ celebrityId, data }: { celebrityId: number; data: ProductPromotionFormData }) =>
      celebritiesService.createCelebrityPromotion(celebrityId, data),
    onSuccess: (_, { celebrityId }) => {
      // Invalidate celebrity promotions
      queryClient.invalidateQueries({ 
        queryKey: CELEBRITY_QUERY_KEYS.celebrityPromotions(celebrityId) 
      });
      // Refresh celebrity details
      queryClient.invalidateQueries({ 
        queryKey: CELEBRITY_QUERY_KEYS.celebrity(celebrityId) 
      });
      
      toast.success('Product promotion added successfully!');
    },
    onError: (error: any) => {
      toast.error(error.message || 'Failed to add product promotion');
    },
  });
}

export function useDeleteCelebrityPromotion() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ promotionId, celebrityId }: { promotionId: number; celebrityId: number }) =>
      celebritiesService.deleteCelebrityPromotion(promotionId),
    onSuccess: (_, { celebrityId }) => {
      // Invalidate celebrity promotions
      queryClient.invalidateQueries({ 
        queryKey: CELEBRITY_QUERY_KEYS.celebrityPromotions(celebrityId) 
      });
      // Refresh celebrity details
      queryClient.invalidateQueries({ 
        queryKey: CELEBRITY_QUERY_KEYS.celebrity(celebrityId) 
      });
      
      toast.success('Product promotion removed successfully!');
    },
    onError: (error: any) => {
      toast.error(error.message || 'Failed to remove product promotion');
    },
  });
}

// Routine mutations
export function useCreateMorningRoutineItem() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: { celebrity_id: number; product_id: number; order: number; description?: string }) =>
      celebritiesService.addMorningRoutineItem(data),
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
      celebritiesService.addEveningRoutineItem(data),
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

// Search hook
export function useSearchCelebrities(query: string) {
  return useQuery({
    queryKey: ['celebrities', 'search', query],
    queryFn: () => celebritiesService.searchCelebrities(query),
    enabled: !!query && query.length > 2,
    staleTime: 2 * 60 * 1000, // 2 minutes
  });
} 