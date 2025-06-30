import { apiClient, buildQueryString } from '@/lib/api';
import {
  Product,
  ProductListItem,
  ProductsResponse,
  ProductFormData,
  ProductFilters,
  Category,
  Brand,
} from '@/types/product';
import type { Variant } from '@/types/variant';

export class ProductsService {
  private basePath = 'products';

  // Get paginated list of products with filtering
  async getProducts(filters: ProductFilters = {}): Promise<ProductsResponse> {
    const queryString = buildQueryString({
      search: filters.search,
      category: filters.category,
      brand: filters.brand,
      is_active: filters.is_active,
      is_featured: filters.is_featured,
      is_on_sale: filters.is_on_sale,
      is_low_stock: filters.is_low_stock,
      price_min: filters.price_min,
      price_max: filters.price_max,
      ordering: filters.ordering || '-created_at',
      page: filters.page || 1,
      page_size: filters.page_size || 20,
    });

    const apiUrl = `${this.basePath}/${queryString}`;
    console.log('🌐 API Call:', apiUrl);
    console.log('📋 Filters sent to API:', {
      search: filters.search,
      category: filters.category,
      brand: filters.brand,
      ordering: filters.ordering || '-created_at',
      page: filters.page || 1,
      page_size: filters.page_size || 20,
    });

    return apiClient.get<ProductsResponse>(apiUrl);
  }

  // Get single product by ID
  async getProduct(id: number): Promise<Product> {
    return apiClient.get<Product>(`${this.basePath}/${id}/`);
  }

  // Create new product
  async createProduct(data: ProductFormData): Promise<Product> {
    const formData = new FormData();
    
    // Add text fields
    Object.entries(data).forEach(([key, value]) => {
      if (key === 'featured_image' || key === 'images') return;
      
      if (value !== undefined && value !== null) {
        formData.append(key, String(value));
      }
    });

    // Add featured image
    if (data.featured_image) {
      formData.append('featured_image', data.featured_image);
    }

    // Add additional images
    if (data.images) {
      data.images.forEach((image, index) => {
        formData.append(`images[${index}]`, image);
      });
    }

    return apiClient.uploadFile<Product>(`${this.basePath}/`, formData);
  }

  // Update existing product
  async updateProduct(id: number, data: Partial<ProductFormData>): Promise<Product> {
    const formData = new FormData();
    
    // Add text fields
    Object.entries(data).forEach(([key, value]) => {
      if (key === 'featured_image' || key === 'images') return;
      
      if (value !== undefined && value !== null) {
        formData.append(key, String(value));
      }
    });

    // Add featured image if provided
    if (data.featured_image) {
      formData.append('featured_image', data.featured_image);
    }

    // Add additional images if provided
    if (data.images) {
      data.images.forEach((image, index) => {
        formData.append(`images[${index}]`, image);
      });
    }

    return apiClient.uploadFile<Product>(`${this.basePath}/${id}/`, formData);
  }

  // Delete product
  async deleteProduct(id: number): Promise<void> {
    return apiClient.delete<void>(`${this.basePath}/${id}/`);
  }

  // Bulk operations
  async bulkUpdateProducts(
    productIds: number[],
    updates: Partial<Pick<ProductFormData, 'is_active' | 'is_featured' | 'stock'>>
  ): Promise<{ updated: number; errors: string[] }> {
    return apiClient.post<{ updated: number; errors: string[] }>(
      `${this.basePath}/bulk_update/`,
      {
        product_ids: productIds,
        updates,
      }
    );
  }

  async bulkDeleteProducts(productIds: number[]): Promise<{ deleted: number; errors: string[] }> {
    return apiClient.post<{ deleted: number; errors: string[] }>(
      `${this.basePath}/bulk_delete/`,
      {
        product_ids: productIds,
      }
    );
  }

  // Stock management
  async updateStock(
    id: number,
    quantity: number,
    adjustmentType: 'stock_in' | 'stock_out' | 'adjustment',
    reference?: string
  ): Promise<Product> {
    return apiClient.post<Product>(`${this.basePath}/${id}/update_stock/`, {
      quantity,
      adjustment_type: adjustmentType,
      reference,
    });
  }

  // Product analytics and stats
  async getProductStats(): Promise<{
    total_products: number;
    active_products: number;
    featured_products: number;
    low_stock_products: number;
    on_sale_products: number;
  }> {
    // Fetch stats and low-stock list in parallel
    const [rawStats, lowStock] = await Promise.all([
      apiClient.get<any>(`${this.basePath}/stats/`),
      apiClient.get<any[]>(`${this.basePath}/low_stock/`).catch(() => []),
    ]);

    return {
      total_products: rawStats.total_products ?? 0,
      active_products: rawStats.total_products ?? 0, // stats endpoint already excludes inactive
      featured_products: rawStats.featured_count ?? 0,
      low_stock_products: lowStock.length,
      on_sale_products: rawStats.on_sale_count ?? 0,
    };
  }

  // Get featured products
  async getFeaturedProducts(limit = 10): Promise<ProductListItem[]> {
    return apiClient.get<ProductListItem[]>(`${this.basePath}/featured/?limit=${limit}`);
  }

  // Get low stock products
  async getLowStockProducts(): Promise<ProductListItem[]> {
    const response = await apiClient.get<ProductsResponse>(`${this.basePath}/low_stock/`);
    return response.results ?? [];
  }

  // Get products on sale
  async getOnSaleProducts(limit = 10): Promise<ProductListItem[]> {
    return apiClient.get<ProductListItem[]>(`${this.basePath}/on_sale/?limit=${limit}`);
  }

  // Search products with advanced filtering
  async searchProducts(query: string, filters: Omit<ProductFilters, 'search'> = {}): Promise<ProductsResponse> {
    return this.getProducts({ ...filters, search: query });
  }

  // Get product images
  async getProductImages(productId: number): Promise<any[]> {
    const res = await apiClient.get<any>(`products/images/?product=${productId}`);
    return Array.isArray(res) ? res : (res?.results ?? []);
  }

  // Upload product image
  async uploadProductImage(
    productId: number,
    image: File,
    altText?: string,
    isMain = false
  ): Promise<any> {
    const formData = new FormData();
    formData.append('product', String(productId));
    formData.append('image', image);
    if (altText) formData.append('alt_text', altText);
    formData.append('is_main', String(isMain));

    return apiClient.uploadFile<any>('products/images/', formData);
  }

  // Delete product image
  async deleteProductImage(imageId: number): Promise<void> {
    return apiClient.delete<void>(`products/images/${imageId}/`);
  }

  // Patch product image (e.g., toggle is_main)
  async updateProductImage(imageId: number, data: Partial<{ is_main: boolean; alt_text: string }> ) : Promise<any> {
    return apiClient.patch<any>(`products/images/${imageId}/`, data);
  }

  /* ---------------- Variants ---------------- */
  async getVariants(productId: number): Promise<Variant[]> {
    const res = await apiClient.get<any>(`products/variants/?product=${productId}`);
    return Array.isArray(res) ? res : res?.results ?? [];
  }

  async createVariant(productId: number, payload: { name: string; sku: string; price_adjustment: string; stock: number }): Promise<Variant> {
    return apiClient.post<Variant>('products/variants/', { ...payload, product: productId });
  }

  async updateVariant(id: number, data: Partial<Variant>): Promise<Variant> {
    return apiClient.patch<Variant>(`products/variants/${id}/`, data);
  }

  async deleteVariant(id: number): Promise<void> {
    return apiClient.delete<void>(`products/variants/${id}/`);
  }

  // Variant images
  async getVariantImages(variantId: number): Promise<any[]> {
    const res = await apiClient.get<any>(`products/variant-images/?variant=${variantId}`);
    return Array.isArray(res) ? res : (res?.results ?? []);
  }

  async uploadVariantImage(variantId: number, image: File, altText?: string, isMain = false): Promise<any> {
    const fd = new FormData();
    fd.append('variant', String(variantId));
    fd.append('image', image);
    if (altText) fd.append('alt_text', altText);
    fd.append('is_main', String(isMain));
    return apiClient.uploadFile('products/variant-images/', fd);
  }

  async updateVariantImage(imageId: number, data: Partial<{ is_main: boolean; alt_text: string }>): Promise<any> {
    return apiClient.patch<any>(`products/variant-images/${imageId}/`, data);
  }

  async deleteVariantImage(id: number): Promise<void> {
    return apiClient.delete<void>(`products/variant-images/${id}/`);
  }
}

export class CategoriesService {
  private basePath = 'products/categories';

  async getCategories(): Promise<Category[]> {
    return apiClient.get<Category[]>(`${this.basePath}/`);
  }

  async getCategory(id: number): Promise<Category> {
    return apiClient.get<Category>(`${this.basePath}/${id}/`);
  }

  async createCategory(data: any): Promise<Category> {
    if (data instanceof FormData) {
      return apiClient.uploadFile<Category>(`${this.basePath}/`, data);
    }
    return apiClient.post<Category>(`${this.basePath}/`, data);
  }

  async updateCategory(id: number, data: any): Promise<Category> {
    if (data instanceof FormData) {
      return apiClient.patch<Category>(`${this.basePath}/${id}/`, data, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });
    }
    return apiClient.patch<Category>(`${this.basePath}/${id}/`, data);
  }

  async deleteCategory(id: number): Promise<void> {
    return apiClient.delete<void>(`${this.basePath}/${id}/`);
  }

  async getCategoryTree(): Promise<Category[]> {
    return apiClient.get<Category[]>(`${this.basePath}/tree/`);
  }
}

export class BrandsService {
  private basePath = 'products/brands';

  async getBrands(): Promise<Brand[]> {
    return apiClient.get<Brand[]>(`${this.basePath}/`);
  }

  async getBrand(id: number): Promise<Brand> {
    return apiClient.get<Brand>(`${this.basePath}/${id}/`);
  }

  async createBrand(data: any): Promise<Brand> {
    if (data instanceof FormData) {
      return apiClient.uploadFile<Brand>(`${this.basePath}/`, data);
    }
    return apiClient.post<Brand>(`${this.basePath}/`, data);
  }

  async updateBrand(id: number, data: any): Promise<Brand> {
    if (data instanceof FormData) {
      return apiClient.patch<Brand>(`${this.basePath}/${id}/`, data, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });
    }
    return apiClient.patch<Brand>(`${this.basePath}/${id}/`, data);
  }

  async deleteBrand(id: number): Promise<void> {
    return apiClient.delete<void>(`${this.basePath}/${id}/`);
  }
}

// Export service instances
export const productsService = new ProductsService();
export const categoriesService = new CategoriesService();
export const brandsService = new BrandsService();

export async function updateProduct(productId: number, data: FormData): Promise<Product> {
  return apiClient.patch<Product>(`products/${productId}/`, data, {
    headers: {
      'Content-Type': 'multipart/form-data',
    },
  });
} 