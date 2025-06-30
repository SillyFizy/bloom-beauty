import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { OrderFilters, OrdersResponse, OrderStatus } from '@/types/order';
import { ordersService } from '@/services/orders';

export const QUERY_KEYS = {
  orders: ['orders'] as const,
  orderList: (filters: OrderFilters) => [...QUERY_KEYS.orders, 'list', filters] as const,
};

export function useOrders(filters: OrderFilters = {}) {
  return useQuery<OrdersResponse, Error>({
    queryKey: QUERY_KEYS.orderList(filters),
    queryFn: () => ordersService.getOrders(filters),
    placeholderData: (previousData) => previousData,
  });
}

export function useUpdateOrderStatus() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ orderId, status }: { orderId: number; status: OrderStatus }) =>
      ordersService.updateOrderStatus(orderId, status),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: QUERY_KEYS.orders });
    },
  });
}

// Fetch single order detail
export function useOrder(orderId: number) {
  return useQuery({
    queryKey: ['order', orderId],
    queryFn: () => ordersService.getOrder(orderId),
    enabled: !!orderId,
  });
} 