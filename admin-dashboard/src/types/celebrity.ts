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
  product_promotions?: CelebrityProductPromotion[];
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
  celebrity: {
    id: number;
    full_name: string;
    image?: string;
  };
  product: {
    id: number;
    name: string;
    featured_image?: string;
    price: number;
    brand?: {
      id: number;
      name: string;
    };
  };
  testimonial?: string;
  promotion_type: 'general' | 'morning_routine' | 'evening_routine' | 'special_pick';
  is_featured: boolean;
  created_at: string;
  updated_at: string;
}

export interface CelebrityRoutineItem {
  id: number;
  product: {
    id: number;
    name: string;
    featured_image?: string;
    price: number;
    brand?: {
      id: number;
      name: string;
    };
  };
  order: number;
  description?: string;
  created_at: string;
}

export interface CelebrityMorningRoutineItem extends CelebrityRoutineItem {}

export interface CelebrityEveningRoutineItem extends CelebrityRoutineItem {}

export interface RoutineItemFormData {
  product_id: number;
  order: number;
  description?: string;
}

export interface ProductPromotionFormData {
  product_id: number;
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