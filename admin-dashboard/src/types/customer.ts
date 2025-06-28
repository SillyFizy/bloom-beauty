export interface Customer {
  id: number;
  first_name: string;
  last_name: string;
  phone_number?: string;
  email?: string;
  total_orders: number;
  total_beauty_points: number;
  date_joined: string;
}

export interface CustomerFilters {
  search?: string;
  page?: number;
  page_size?: number;
  ordering?: string;
}

export interface CustomersResponse {
  results: Customer[];
  count: number;
  page: number;
  page_size: number;
  total_pages: number;
  has_next: boolean;
  has_previous: boolean;
} 