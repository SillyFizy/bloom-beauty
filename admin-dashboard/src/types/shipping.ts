export interface Governorate {
  id: string;
  name: string;
  nameArabic: string;
}

export interface ShippingZone {
  id: number;
  governorate: Governorate;
  price: number;
  type: 'same' | 'nearby' | 'other';
  created_at: string;
  updated_at: string;
}

export interface ShippingSettings {
  same_governorate?: ShippingZone;
  nearby_governorates: ShippingZone[];
  other_governorates: ShippingZone[];
}

export interface CreateShippingZoneRequest {
  governorate_id: string;
  price: number;
  type: 'same' | 'nearby' | 'other';
}

export interface UpdateShippingZoneRequest {
  price: number;
}

export interface ShippingZoneFilters {
  type?: 'same' | 'nearby' | 'other';
  search?: string;
  page?: number;
  page_size?: number;
}

export interface ShippingZonesResponse {
  results: ShippingZone[];
  count: number;
  page: number;
  page_size: number;
  total_pages: number;
  has_next: boolean;
  has_previous: boolean;
}

// Iraqi Governorates List
export const IRAQI_GOVERNORATES: Governorate[] = [
  { id: 'baghdad', name: 'Baghdad', nameArabic: 'بغداد' },
  { id: 'basra', name: 'Basra', nameArabic: 'البصرة' },
  { id: 'maysan', name: 'Maysan', nameArabic: 'ميسان' },
  { id: 'dhi_qar', name: 'Dhi Qar', nameArabic: 'ذي قار' },
  { id: 'muthanna', name: 'Al Muthanna', nameArabic: 'المثنى' },
  { id: 'qadisiyyah', name: 'Al-Qadisiyyah', nameArabic: 'القادسية' },
  { id: 'babylon', name: 'Babylon', nameArabic: 'بابل' },
  { id: 'karbala', name: 'Karbala', nameArabic: 'كربلاء' },
  { id: 'najaf', name: 'Najaf', nameArabic: 'النجف' },
  { id: 'wasit', name: 'Wasit', nameArabic: 'واسط' },
  { id: 'anbar', name: 'Al Anbar', nameArabic: 'الأنبار' },
  { id: 'ninawa', name: 'Ninawa', nameArabic: 'نينوى' },
  { id: 'salah_al_din', name: 'Salah al-Din', nameArabic: 'صلاح الدين' },
  { id: 'kirkuk', name: 'Kirkuk', nameArabic: 'كركوك' },
  { id: 'diyala', name: 'Diyala', nameArabic: 'ديالى' },
  { id: 'erbil', name: 'Erbil', nameArabic: 'أربيل' },
  { id: 'sulaymaniyah', name: 'Sulaymaniyah', nameArabic: 'السليمانية' },
  { id: 'duhok', name: 'Duhok', nameArabic: 'دهوك' },
  { id: 'halabja', name: 'Halabja', nameArabic: 'حلبجة' },
]; 