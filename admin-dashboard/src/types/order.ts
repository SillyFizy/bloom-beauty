export type OrderStatus = 'pending' | 'confirmed' | 'processing' | 'packed' | 'shipped' | 'delivered' | 'cancelled' | 'returned';

export interface Order {
  id: number;
  customer_name: string;
  status: OrderStatus;
  total_amount: number;
  created_at: string;
}

export interface OrderFilters {
  search?: string;
  status?: string;
  page?: number;
  page_size?: number;
  ordering?: string;
}

export interface OrdersResponse {
  results: Order[];
  count: number;
  page: number;
  page_size: number;
  total_pages: number;
  has_next: boolean;
  has_previous: boolean;
} 