export interface NavigationCategory {
  id: number;
  name: string;
  image?: string;
  image_url?: string;
  order: number;
  is_active: boolean;
  product_count: number;
  products?: NavigationCategoryProduct[];
  created_at: string;
  updated_at: string;
}

export interface NavigationCategoryProduct {
  id: number;
  product: ProductBasic;
  order: number;
  is_featured: boolean;
  created_at: string;
}

export interface ProductBasic {
  id: number;
  name: string;
  price: string;
  sale_price?: string;
  image_url?: string;
  sku?: string;
  is_active: boolean;
}

export interface NavigationCategoryFormData {
  name: string;
  image?: File;
  order: number;
  is_active: boolean;
}

export interface NavigationCategoryPublic {
  id: number;
  name: string;
  image_url?: string;
  order: number;
}

export interface NavigationCategoryFilters {
  is_active?: boolean;
  search?: string;
}

export interface NavigationCategoryStats {
  total_categories: number;
  active_categories: number;
  inactive_categories: number;
  categories_with_images: number;
}

export interface BulkProductAssignment {
  navigation_category_id: number;
  product_ids: number[];
  clear_existing?: boolean;
}

export interface ProductSearchParams {
  search: string;
  exclude_category?: number;
}

export interface BulkUpdateNavigationCategory {
  id: number;
  order?: number;
  is_active?: boolean;
} 