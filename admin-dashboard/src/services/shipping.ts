import { apiClient, buildQueryString } from '@/lib/api';
import { 
  ShippingZone, 
  ShippingZonesResponse, 
  ShippingZoneFilters,
  CreateShippingZoneRequest,
  UpdateShippingZoneRequest,
  ShippingSettings
} from '@/types/shipping';

class ShippingService {
  private readonly baseUrl = 'shipping/zones';

  async getShippingZones(filters: ShippingZoneFilters = {}): Promise<ShippingZonesResponse> {
    const queryString = buildQueryString(filters);
    return apiClient.get<ShippingZonesResponse>(`${this.baseUrl}/${queryString}`);
  }

  async getShippingSettings(): Promise<ShippingSettings> {
    return apiClient.get<ShippingSettings>('shipping/settings/');
  }

  async getShippingZone(id: number): Promise<ShippingZone> {
    return apiClient.get<ShippingZone>(`${this.baseUrl}/${id}/`);
  }

  async createShippingZone(data: CreateShippingZoneRequest): Promise<ShippingZone> {
    return apiClient.post<ShippingZone>(`${this.baseUrl}/`, data);
  }

  async updateShippingZone(id: number, data: UpdateShippingZoneRequest): Promise<ShippingZone> {
    return apiClient.patch<ShippingZone>(`${this.baseUrl}/${id}/`, data);
  }

  async deleteShippingZone(id: number): Promise<void> {
    return apiClient.delete(`${this.baseUrl}/${id}/`);
  }

  async setSameGovernorate(governorateId: string, price: number): Promise<ShippingZone> {
    return apiClient.post<ShippingZone>('shipping/set-same-governorate/', {
      governorate_id: governorateId,
      price
    });
  }

  async updateSameGovernorate(price: number): Promise<ShippingZone> {
    return apiClient.patch<ShippingZone>('shipping/update-same-governorate/', {
      price
    });
  }

  async removeSameGovernorate(): Promise<void> {
    return apiClient.delete('shipping/remove-same-governorate/');
  }
}

export const shippingService = new ShippingService(); 