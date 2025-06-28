import { apiClient, buildQueryString } from '@/lib/api';
import { OrdersResponse, OrderFilters, OrderStatus } from '@/types/order';

class OrdersService {
  private readonly baseUrl = 'orders/admin/orders';

  async getOrders(filters: OrderFilters = {}): Promise<OrdersResponse> {
    const queryString = buildQueryString(filters);
    return apiClient.get<OrdersResponse>(`${this.baseUrl}/${queryString}`);
  }

  async updateOrderStatus(orderId: number, status: OrderStatus) {
    return apiClient.patch(`${this.baseUrl}/${orderId}/`, { status });
  }
}

export const ordersService = new OrdersService(); 