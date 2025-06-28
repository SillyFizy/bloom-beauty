import { apiClient, buildQueryString } from '@/lib/api';
import { CustomersResponse, CustomerFilters } from '@/types/customer';

class CustomersService {
  private readonly baseUrl = 'users/admin/customers';

  async getCustomers(filters: CustomerFilters = {}): Promise<CustomersResponse> {
    const queryString = buildQueryString(filters);
    return apiClient.get<CustomersResponse>(`${this.baseUrl}/${queryString}`);
  }
}

export const customersService = new CustomersService(); 