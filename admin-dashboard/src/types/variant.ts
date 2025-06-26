export interface VariantImage {
  id: number;
  image: string;
  alt_text?: string;
  is_main: boolean;
  created_at: string;
}

export interface Variant {
  id: number;
  product: number;
  name: string;
  sku?: string;
  price_adjustment: string;
  stock: number;
  is_active: boolean;
  images: VariantImage[];
  main_image?: string;
  created_at: string;
  updated_at: string;
} 