import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { shippingService } from '@/services/shipping';
import { 
  ShippingZone, 
  ShippingZoneFilters, 
  ShippingZonesResponse, 
  CreateShippingZoneRequest,
  UpdateShippingZoneRequest,
  ShippingSettings
} from '@/types/shipping';

export const SHIPPING_QUERY_KEYS = {
  shipping: ['shipping'] as const,
  zones: (filters: ShippingZoneFilters) => [...SHIPPING_QUERY_KEYS.shipping, 'zones', filters] as const,
  zone: (id: number) => [...SHIPPING_QUERY_KEYS.shipping, 'zone', id] as const,
  settings: () => [...SHIPPING_QUERY_KEYS.shipping, 'settings'] as const,
};

// Get shipping zones with filters
export function useShippingZones(filters: ShippingZoneFilters = {}) {
  return useQuery<ShippingZonesResponse, Error>({
    queryKey: SHIPPING_QUERY_KEYS.zones(filters),
    queryFn: () => shippingService.getShippingZones(filters),
    placeholderData: (previousData) => previousData,
  });
}

// Get shipping settings (organized by type)
export function useShippingSettings() {
  return useQuery<ShippingSettings, Error>({
    queryKey: SHIPPING_QUERY_KEYS.settings(),
    queryFn: () => shippingService.getShippingSettings(),
    staleTime: 5 * 60 * 1000, // 5 minutes
  });
}

// Get single shipping zone
export function useShippingZone(id: number) {
  return useQuery<ShippingZone, Error>({
    queryKey: SHIPPING_QUERY_KEYS.zone(id),
    queryFn: () => shippingService.getShippingZone(id),
    enabled: !!id,
  });
}

// Create shipping zone mutation
export function useCreateShippingZone() {
  const queryClient = useQueryClient();

  return useMutation<ShippingZone, Error, CreateShippingZoneRequest>({
    mutationFn: (data) => shippingService.createShippingZone(data),
    onSuccess: () => {
      // Invalidate all shipping related queries
      queryClient.invalidateQueries({ queryKey: SHIPPING_QUERY_KEYS.shipping });
    },
  });
}

// Update shipping zone mutation
export function useUpdateShippingZone() {
  const queryClient = useQueryClient();

  return useMutation<ShippingZone, Error, { id: number; data: UpdateShippingZoneRequest }>({
    mutationFn: ({ id, data }) => shippingService.updateShippingZone(id, data),
    onSuccess: (_, { id }) => {
      // Invalidate specific zone and all zones queries
      queryClient.invalidateQueries({ queryKey: SHIPPING_QUERY_KEYS.zone(id) });
      queryClient.invalidateQueries({ queryKey: SHIPPING_QUERY_KEYS.shipping });
    },
  });
}

// Delete shipping zone mutation
export function useDeleteShippingZone() {
  const queryClient = useQueryClient();

  return useMutation<void, Error, number>({
    mutationFn: (id) => shippingService.deleteShippingZone(id),
    onSuccess: () => {
      // Invalidate all shipping related queries
      queryClient.invalidateQueries({ queryKey: SHIPPING_QUERY_KEYS.shipping });
    },
  });
}

// Set same governorate mutation
export function useSetSameGovernorate() {
  const queryClient = useQueryClient();

  return useMutation<ShippingZone, Error, { governorateId: string; price: number }>({
    mutationFn: ({ governorateId, price }) => shippingService.setSameGovernorate(governorateId, price),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: SHIPPING_QUERY_KEYS.shipping });
    },
  });
}

// Update same governorate mutation
export function useUpdateSameGovernorate() {
  const queryClient = useQueryClient();

  return useMutation<ShippingZone, Error, number>({
    mutationFn: (price) => shippingService.updateSameGovernorate(price),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: SHIPPING_QUERY_KEYS.shipping });
    },
  });
}

// Remove same governorate mutation
export function useRemoveSameGovernorate() {
  const queryClient = useQueryClient();

  return useMutation<void, Error, void>({
    mutationFn: () => shippingService.removeSameGovernorate(),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: SHIPPING_QUERY_KEYS.shipping });
    },
  });
} 