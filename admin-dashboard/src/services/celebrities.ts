import { apiClient, buildQueryString } from '@/lib/api';
import {
  Celebrity,
  CelebrityListItem,
  CelebrityFormData,
  CelebrityFilters,
  CelebritiesResponse,
  CelebrityStats,
  CelebrityProductPromotion,
  CelebrityMorningRoutineItem,
  CelebrityEveningRoutineItem,
  RoutineItemFormData,
  ProductPromotionFormData,
  PromotionFilters,
  PromotionsResponse,
  AvailableProductsFilters,
  AvailableProductsResponse,
  BulkPromotionData,
  BulkPromotionResponse,
} from '@/types/celebrity';

class CelebritiesService {
  private readonly baseUrl = 'celebrities';

  // Celebrity CRUD operations
  async getCelebrities(filters: CelebrityFilters = {}): Promise<CelebritiesResponse> {
    const queryString = buildQueryString(filters);
    return apiClient.get<CelebritiesResponse>(`${this.baseUrl}/${queryString}`);
  }

  async getCelebrityById(id: number): Promise<Celebrity> {
    return apiClient.get<Celebrity>(`${this.baseUrl}/${id}/`);
  }

  async createCelebrity(data: CelebrityFormData): Promise<Celebrity> {
    const formData = this.createFormData(data);
    return apiClient.uploadFile<Celebrity>(`${this.baseUrl}/`, formData);
  }

  async updateCelebrity(id: number, data: Partial<CelebrityFormData>): Promise<Celebrity> {
    const formData = this.createFormData(data);
    return apiClient.uploadFile<Celebrity>(`${this.baseUrl}/${id}/`, formData, {
      method: 'PATCH',
    });
  }

  async deleteCelebrity(id: number): Promise<void> {
    return apiClient.delete(`${this.baseUrl}/${id}/`);
  }

  // Celebrity statistics
  async getCelebrityStats(): Promise<CelebrityStats> {
    return apiClient.get<CelebrityStats>(`${this.baseUrl}/stats/`);
  }

  // Celebrity product promotion management
  async getCelebrityPromotionsAdmin(
    celebrityId: number, 
    filters: PromotionFilters = {}
  ): Promise<PromotionsResponse> {
    const queryString = buildQueryString(filters);
    return apiClient.get<PromotionsResponse>(
      `${this.baseUrl}/${celebrityId}/admin/promotions/${queryString}`
    );
  }

  async createCelebrityPromotion(
    celebrityId: number, 
    data: ProductPromotionFormData
  ): Promise<CelebrityProductPromotion> {
    return apiClient.post<CelebrityProductPromotion>(
      `${this.baseUrl}/${celebrityId}/admin/promotions/`,
      data
    );
  }

  async getCelebrityPromotionDetail(
    celebrityId: number, 
    promotionId: number
  ): Promise<CelebrityProductPromotion> {
    return apiClient.get<CelebrityProductPromotion>(
      `${this.baseUrl}/${celebrityId}/admin/promotions/${promotionId}/`
    );
  }

  async updateCelebrityPromotion(
    celebrityId: number, 
    promotionId: number, 
    data: Partial<ProductPromotionFormData>
  ): Promise<CelebrityProductPromotion> {
    return apiClient.patch<CelebrityProductPromotion>(
      `${this.baseUrl}/${celebrityId}/admin/promotions/${promotionId}/`,
      data
    );
  }

  async deleteCelebrityPromotion(
    celebrityId: number, 
    promotionId: number
  ): Promise<void> {
    return apiClient.delete(`${this.baseUrl}/${celebrityId}/admin/promotions/${promotionId}/`);
  }

  async getAvailableProductsForCelebrity(
    celebrityId: number, 
    filters: AvailableProductsFilters = {}
  ): Promise<AvailableProductsResponse> {
    const queryString = buildQueryString(filters);
    return apiClient.get<AvailableProductsResponse>(
      `${this.baseUrl}/${celebrityId}/admin/available-products/${queryString}`
    );
  }

  async bulkManageCelebrityPromotions(
    celebrityId: number, 
    data: BulkPromotionData
  ): Promise<BulkPromotionResponse> {
    return apiClient.post<BulkPromotionResponse>(
      `${this.baseUrl}/${celebrityId}/admin/bulk-promotions/`,
      data
    );
  }

  // Morning routine management
  async getMorningRoutine(celebrityId: number): Promise<{
    celebrity: string;
    morning_routine: CelebrityMorningRoutineItem[];
  }> {
    return apiClient.get(`${this.baseUrl}/${celebrityId}/morning-routine/`);
  }

  async createMorningRoutineItem(
    celebrityId: number,
    data: RoutineItemFormData
  ): Promise<CelebrityMorningRoutineItem> {
    return apiClient.post(`${this.baseUrl}/${celebrityId}/morning-routine/`, data);
  }

  // Add convenience method for the new hook structure
  async addMorningRoutineItem(data: {
    celebrity_id: number;
    product: number;
    order: number;
    description?: string;
  }): Promise<CelebrityMorningRoutineItem> {
    return this.createMorningRoutineItem(data.celebrity_id, {
      product: data.product,
      order: data.order,
      description: data.description,
    });
  }

  async updateMorningRoutineItem(
    itemId: number,
    data: Partial<RoutineItemFormData>
  ): Promise<CelebrityMorningRoutineItem> {
    return apiClient.patch(`morning-routine/${itemId}/`, data);
  }

  async deleteMorningRoutineItem(itemId: number): Promise<void> {
    return apiClient.delete(`morning-routine/${itemId}/`);
  }

  // Evening routine management
  async getEveningRoutine(celebrityId: number): Promise<{
    celebrity: string;
    evening_routine: CelebrityEveningRoutineItem[];
  }> {
    return apiClient.get(`${this.baseUrl}/${celebrityId}/evening-routine/`);
  }

  async createEveningRoutineItem(
    celebrityId: number,
    data: RoutineItemFormData
  ): Promise<CelebrityEveningRoutineItem> {
    return apiClient.post(`${this.baseUrl}/${celebrityId}/evening-routine/`, data);
  }

  // Add convenience method for the new hook structure
  async addEveningRoutineItem(data: {
    celebrity_id: number;
    product: number;
    order: number;
    description?: string;
  }): Promise<CelebrityEveningRoutineItem> {
    return this.createEveningRoutineItem(data.celebrity_id, {
      product: data.product,
      order: data.order,
      description: data.description,
    });
  }

  async updateEveningRoutineItem(
    itemId: number,
    data: Partial<RoutineItemFormData>
  ): Promise<CelebrityEveningRoutineItem> {
    return apiClient.patch(`evening-routine/${itemId}/`, data);
  }

  async deleteEveningRoutineItem(itemId: number): Promise<void> {
    return apiClient.delete(`evening-routine/${itemId}/`);
  }

  // Utility methods
  private createFormData(data: Partial<CelebrityFormData>): FormData {
    const formData = new FormData();

    Object.entries(data).forEach(([key, value]) => {
      if (value !== undefined && value !== null) {
        if (key === 'image' && value instanceof File) {
          formData.append(key, value);
        } else if (typeof value === 'boolean') {
          formData.append(key, value.toString());
        } else if (typeof value === 'string' || typeof value === 'number') {
          formData.append(key, value.toString());
        }
      }
    });

    return formData;
  }

  // Bulk operations
  async bulkUpdateCelebrities(
    celebrityIds: number[],
    updates: Partial<Pick<CelebrityFormData, 'is_active'>>
  ): Promise<{ updated: number; errors: string[] }> {
    return apiClient.post(`${this.baseUrl}/bulk-update/`, {
      celebrity_ids: celebrityIds,
      updates,
    });
  }

  async bulkDeleteCelebrities(celebrityIds: number[]): Promise<{ deleted: number; errors: string[] }> {
    return apiClient.post(`${this.baseUrl}/bulk-delete/`, {
      celebrity_ids: celebrityIds,
    });
  }

  // Search and filter utilities
  async searchCelebrities(query: string): Promise<CelebrityListItem[]> {
    const queryString = buildQueryString({ search: query });
    return apiClient.get(`${this.baseUrl}/search/${queryString}`);
  }

  // Featured celebrity picks
  async getFeaturedCelebrityPicks(limit = 20): Promise<{
    celebrity_picks: Array<{
      celebrity: {
        id: number;
        name: string;
        image?: string;
      };
      product: any;
      testimonial?: string;
      promotion_type: string;
    }>;
  }> {
    const queryString = buildQueryString({ limit });
    return apiClient.get(`${this.baseUrl}/picks/featured/${queryString}`);
  }
}

export const celebritiesService = new CelebritiesService(); 