import { apiClient } from '@/lib/api';
import {
  NavigationCategory,
  NavigationCategoryFormData,
  NavigationCategoryPublic,
  NavigationCategoryStats,
  BulkUpdateNavigationCategory,
  NavigationCategoryProduct,
  ProductBasic,
  BulkProductAssignment,
  ProductSearchParams
} from '@/types/navigation-category';

export class NavigationCategoriesService {
  private basePath = 'categories';

  // Public endpoint for frontend apps
  async getPublicNavigationCategories(): Promise<NavigationCategoryPublic[]> {
    try {
      const response = await apiClient.get<{
        success: boolean;
        count: number;
        categories: NavigationCategoryPublic[];
      }>(`${this.basePath}/navigation/`);
      return response.categories || [];
    } catch (error) {
      console.error('Error fetching public navigation categories:', error);
      return [];
    }
  }

  // Admin endpoints
  async getNavigationCategories(): Promise<NavigationCategory[]> {
    try {
      const response = await apiClient.get<{
        count: number;
        next: string | null;
        previous: string | null;
        results: NavigationCategory[];
      }>(`${this.basePath}/admin/categories/`);
      // Extract results from paginated response
      return response.results || [];
    } catch (error) {
      console.error('Error fetching navigation categories:', error);
      return [];
    }
  }

  async getNavigationCategory(id: number): Promise<NavigationCategory> {
    return apiClient.get<NavigationCategory>(`${this.basePath}/admin/categories/${id}/`);
  }

  async createNavigationCategory(data: NavigationCategoryFormData): Promise<NavigationCategory> {
    const formData = new FormData();
    
    // Add text fields
    Object.entries(data).forEach(([key, value]) => {
      if (key === 'image') return;
      
      if (value !== undefined && value !== null) {
        formData.append(key, String(value));
      }
    });

    // Add image if provided
    if (data.image) {
      formData.append('image', data.image);
    }

    const response = await apiClient.uploadFile<{
      success: boolean;
      message: string;
      category: NavigationCategory;
    }>(`${this.basePath}/admin/categories/`, formData);
    
    return response.category;
  }

  async updateNavigationCategory(id: number, data: Partial<NavigationCategoryFormData>): Promise<NavigationCategory> {
    const formData = new FormData();
    
    // Add text fields
    Object.entries(data).forEach(([key, value]) => {
      if (key === 'image') return;
      
      if (value !== undefined && value !== null) {
        formData.append(key, String(value));
      }
    });

    // Add image if provided
    if (data.image) {
      formData.append('image', data.image);
    }

    const response = await apiClient.uploadFile<{
      success: boolean;
      message: string;
      category: NavigationCategory;
    }>(`${this.basePath}/admin/categories/${id}/`, formData, {
      method: 'PATCH'
    });
    
    return response.category;
  }

  async deleteNavigationCategory(id: number): Promise<void> {
    await apiClient.delete<{
      success: boolean;
      message: string;
    }>(`${this.basePath}/admin/categories/${id}/`);
  }

  async bulkUpdateNavigationCategories(categories: BulkUpdateNavigationCategory[]): Promise<void> {
    await apiClient.post<{
      success: boolean;
      message: string;
    }>(`${this.basePath}/admin/categories/bulk-update/`, {
      categories
    });
  }

  async getNavigationCategoryStats(): Promise<NavigationCategoryStats> {
    try {
      const response = await apiClient.get<{
        success: boolean;
        statistics: NavigationCategoryStats;
      }>(`${this.basePath}/admin/categories/statistics/`);
      return response.statistics;
    } catch (error) {
      console.error('Error fetching navigation category stats:', error);
      return {
        total_categories: 0,
        active_categories: 0,
        inactive_categories: 0,
        categories_with_images: 0,
      };
    }
  }

  async getCategoryProducts(categoryId: number): Promise<NavigationCategoryProduct[]> {
    const response = await apiClient.get<{
      success: boolean;
      count: number;
      products: NavigationCategoryProduct[];
    }>(`${this.basePath}/admin/categories/${categoryId}/products/`);
    
    return response.products || [];
  }

  async addCategoryProducts(categoryId: number, data: Omit<BulkProductAssignment, 'navigation_category_id'>): Promise<{
    success: boolean;
    message: string;
    created_count: number;
    skipped_count: number;
  }> {
    const response = await apiClient.post<{
      success: boolean;
      message: string;
      created_count: number;
      skipped_count: number;
    }>(`${this.basePath}/admin/categories/${categoryId}/products/add/`, data);
    
    return response;
  }

  async removeCategoryProducts(categoryId: number, productIds: number[]): Promise<{
    success: boolean;
    message: string;
    deleted_count: number;
  }> {
    const response = await apiClient.delete<{
      success: boolean;
      message: string;
      deleted_count: number;
    }>(`${this.basePath}/admin/categories/${categoryId}/products/remove/`, {
      data: { product_ids: productIds }
    });
    
    return response;
  }

  async searchProducts(params: ProductSearchParams): Promise<ProductBasic[]> {
    const queryParams = new URLSearchParams();
    queryParams.append('search', params.search);
    
    if (params.exclude_category) {
      queryParams.append('exclude_category', params.exclude_category.toString());
    }

    const response = await apiClient.get<{
      success: boolean;
      count: number;
      products: ProductBasic[];
    }>(`${this.basePath}/admin/products/search/?${queryParams.toString()}`);
    
    return response.products || [];
  }
}

// Export service instance
export const navigationCategoriesService = new NavigationCategoriesService(); 