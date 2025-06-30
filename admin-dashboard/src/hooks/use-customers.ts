import { useQuery } from '@tanstack/react-query';
import { CustomerFilters, CustomersResponse } from '@/types/customer';
import { customersService } from '@/services/customers';

export const QUERY_KEYS = {
  customers: ['customers'] as const,
  customerList: (filters: CustomerFilters) => [...QUERY_KEYS.customers, 'list', filters] as const,
};

export function useCustomers(filters: CustomerFilters = {}) {
  return useQuery<CustomersResponse, Error>({
    queryKey: QUERY_KEYS.customerList(filters),
    queryFn: () => customersService.getCustomers(filters),
    placeholderData: (previousData) => previousData,
  });
} 