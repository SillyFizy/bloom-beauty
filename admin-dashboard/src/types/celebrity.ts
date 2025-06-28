export interface Celebrity {
  id: number;
  first_name: string;
  last_name: string;
  full_name: string;
  image?: string;
  bio?: string;
  instagram_url?: string;
  facebook_url?: string;
  snapchat_url?: string;
  social_media_links: Record<string, string>;
  is_active: boolean;
  created_at: string;
  updated_at: string;
  
  // Computed fields from serializer
  total_promotions: number;
  featured_promotions_count: number;
  morning_routine_count: number;
  evening_routine_count: number;
  
  // Related data (when fetching details)
  morning_routine_items?: CelebrityMorningRoutineItem[];
  evening_routine_items?: CelebrityEveningRoutineItem[];
  product_promotions: CelebrityProductPromotion[];
}

export interface CelebrityListItem {
  id: number;
  first_name: string;
  last_name: string;
  full_name: string;
  image?: string;
  bio?: string;
  social_media_links: Record<string, string>;
  is_active: boolean;
  created_at: string;
  total_promotions: number;
  featured_promotions_count: number;
}

export interface CelebrityFormData {
  first_name: string;
  last_name: string;
  bio?: string;
  instagram_url?: string;
  facebook_url?: string;
  snapchat_url?: string;
  is_active: boolean;
  image?: File;
}

export interface CelebrityProductPromotion {
  id: number;
  celebrity: CelebrityBasic;
  product: ProductBasic;
  testimonial?: string;
  promotion_type: 'general' | 'morning_routine' | 'evening_routine' | 'special_pick';
  is_featured: boolean;
  created_at: string;
  updated_at: string;
}

export interface CelebrityBasic {
  id: number;
  first_name: string;
  last_name: string;
  full_name: string;
  image?: string;
  is_active: boolean;
}

export interface ProductBasic {
  id: number;
  name: string;
  price: number;
  sale_price?: number;
  featured_image?: string;
  category?: {
    id: number;
    name: string;
  };
  brand?: {
    id: number;
    name: string;
  };
  is_active: boolean;
  stock: number;
}

export interface CelebrityMorningRoutineItem {
  id: number;
  celebrity: CelebrityBasic;
  product: ProductBasic;
  order: number;
  description?: string;
  created_at: string;
  updated_at: string;
}

export interface CelebrityEveningRoutineItem {
  id: number;
  celebrity: CelebrityBasic;
  product: ProductBasic;
  order: number;
  description?: string;
  created_at: string;
  updated_at: string;
}

export interface RoutineItemFormData {
  product: number;
  order: number;
  description?: string;
}

export interface ProductPromotionFormData {
  product: number;
  testimonial?: string;
  promotion_type: 'general' | 'morning_routine' | 'evening_routine' | 'special_pick';
  is_featured: boolean;
}

export interface CelebrityFilters {
  search?: string;
  is_active?: boolean;
  ordering?: string;
  page?: number;
  page_size?: number;
}

export interface CelebritiesResponse {
  count: number;
  next?: string;
  previous?: string;
  results: CelebrityListItem[];
}

export interface CelebrityStats {
  total_celebrities: number;
  active_celebrities: number;
  total_promotions: number;
  featured_promotions: number;
  total_routine_items: number;
}

export interface PromotionFilters {
  page?: number;
  page_size?: number;
  promotion_type?: string;
  is_featured?: boolean;
  search?: string;
}

export interface AvailableProductsFilters {
  page?: number;
  page_size?: number;
  category_id?: number;
  brand_id?: number;
  search?: string;
}

export interface PromotionsResponse {
  results: CelebrityProductPromotion[];
  count: number;
  page: number;
  page_size: number;
  total_pages: number;
  has_next: boolean;
  has_previous: boolean;
}

export interface AvailableProductsResponse {
  results: ProductBasic[];
  count: number;
  page: number;
  page_size: number;
  total_pages: number;
  has_next: boolean;
  has_previous: boolean;
}

export interface BulkPromotionData {
  action: 'add' | 'remove';
  product_ids: number[];
  promotion_data?: {
    testimonial?: string;
    promotion_type: 'general' | 'morning_routine' | 'evening_routine' | 'special_pick';
    is_featured: boolean;
  };
}

export interface BulkPromotionResponse {
  created?: CelebrityProductPromotion[];
  removed_count?: number;
  errors: string[];
  created_count?: number;
  error_count: number;
} 