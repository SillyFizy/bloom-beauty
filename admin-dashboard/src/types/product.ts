export interface Category {
  id: number;
  name: string;
  description?: string;
  parent?: number;
  image?: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
  subcategories?: Category[];
}

export interface Brand {
  id: number;
  name: string;
  description?: string;
  logo?: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface ProductAttribute {
  id: number;
  name: string;
}

export interface ProductAttributeValue {
  id: number;
  attribute: ProductAttribute;
  value: string;
}

export interface ProductImage {
  id: number;
  product: number;
  image: string;
  alt_text?: string;
  is_main: boolean;
  created_at: string;
}

export interface ProductVariant {
  id: number;
  product: number;
  name: string;
  sku: string;
  price_adjustment: number;
  stock: number;
  attributes: ProductAttributeValue[];
  is_active: boolean;
  created_at: string;
  updated_at: string;
  price: number;
}

export interface Product {
  id: number;
  name: string;
  description: string;
  price: number;
  sale_price?: number;
  category: Category;
  brand?: Brand;
  attributes: ProductAttributeValue[];
  featured_image?: string;
  stock: number;
  sku?: string;
  is_active: boolean;
  is_featured: boolean;
  meta_keywords?: string;
  meta_description?: string;
  low_stock_threshold: number;
  beauty_points: number;
  created_at: string;
  updated_at: string;
  
  // Computed properties from Django model
  is_on_sale: boolean;
  discount_percentage: number;
  is_low_stock: boolean;
  rating: number;
  review_count: number;
  has_reviews: boolean;
  is_celebrity_endorsed: boolean;
  
  // Related data
  images?: ProductImage[];
  variants?: ProductVariant[];
}

export interface ProductListItem {
  id: number;
  name: string;
  price: number;
  sale_price?: number;
  featured_image?: string;
  stock: number;
  stock_status: 'in_stock' | 'low_stock' | 'out_of_stock';
  stock_quantity: number;
  is_active: boolean;
  is_featured: boolean;
  is_on_sale: boolean;
  discount_percentage: number;
  is_low_stock: boolean;
  rating: number;
  review_count: number;
  category?: {
    id: number;
    name: string;
  };
  brand?: {
    id: number;
    name: string;
  };
  created_at: string;
  updated_at: string;
}

export interface ProductFormData {
  name: string;
  description: string;
  price: number;
  sale_price?: number;
  category: number;
  brand?: number;
  stock: number;
  sku?: string;
  is_active: boolean;
  is_featured: boolean;
  meta_keywords?: string;
  meta_description?: string;
  low_stock_threshold: number;
  beauty_points: number;
  featured_image?: File;
  images?: File[];
}

export interface ProductFilters {
  search?: string;
  category?: number;
  brand?: number;
  is_active?: boolean;
  is_featured?: boolean;
  is_on_sale?: boolean;
  is_low_stock?: boolean;
  price_min?: number;
  price_max?: number;
  ordering?: string;
  page?: number;
  page_size?: number;
}

export interface ProductsResponse {
  count: number;
  next?: string;
  previous?: string;
  results: ProductListItem[];
}

export interface InventoryLog {
  id: number;
  product: number;
  variant?: number;
  quantity: number;
  adjustment_type: 'stock_in' | 'stock_out' | 'adjustment' | 'returned';
  reference?: string;
  created_at: string;
  user?: {
    id: number;
    username: string;
  };
} 