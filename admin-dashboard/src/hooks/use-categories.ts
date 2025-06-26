import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { toast } from 'react-hot-toast';
import { CategoriesService, BrandsService } from '@/services/products';
import type { Category, Brand } from '@/types/product';

const categoriesService = new CategoriesService();
const brandsService = new BrandsService();

const QUERY_KEYS = {
  categories: ['categories'],
  category: (id: number) => ['categories', id],
  brands: ['brands'],
  brand: (id: number) => ['brands', id],
} as const;

/* ------------------ Categories ------------------ */
export function useAllCategories() {
  return useQuery({
    queryKey: QUERY_KEYS.categories,
    queryFn: async () => {
      const res = await categoriesService.getCategories();
      // Some endpoints return paginated obj
      return Array.isArray(res) ? res : (res as any)?.results ?? [];
    },
  });
}

export function useCreateCategory() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: { name: string; description?: string; image?: File }) => {
      const formData = new FormData();
      formData.append('name', data.name);
      if (data.description) formData.append('description', data.description);
      if (data.image) {
        const file: File = data.image;
        const maxName = 90; // keep extension space
        let safeFile = file;
        if (file.name.length > 100) {
          const ext = file.name.split('.').pop() || '';
          const base = file.name.slice(0, maxName).replace(/[^a-zA-Z0-9_-]/g, '');
          safeFile = new File([file], `${base}.${ext}`, { type: file.type });
        }
        formData.append('image', safeFile);
      }
      formData.append('is_active', 'true');
      return categoriesService.createCategory(formData as any);
    },
    onSuccess: () => {
      toast.success('Category created');
      qc.invalidateQueries({ queryKey: QUERY_KEYS.categories });
    },
    onError: () => toast.error('Failed to create category'),
  });
}

export function useUpdateCategory() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: { name?: string; description?: string; image?: File } }) => {
      const formData = new FormData();
      if (data.name) formData.append('name', data.name);
      if (data.description) formData.append('description', data.description);
      if (data.image) {
        const file: File = data.image;
        const maxName = 90; // keep extension space
        let safeFile = file;
        if (file.name.length > 100) {
          const ext = file.name.split('.').pop() || '';
          const base = file.name.slice(0, maxName).replace(/[^a-zA-Z0-9_-]/g, '');
          safeFile = new File([file], `${base}.${ext}`, { type: file.type });
        }
        formData.append('image', safeFile);
      }
      return categoriesService.updateCategory(id, formData as any);
    },
    onSuccess: () => {
      toast.success('Category updated');
      qc.invalidateQueries({ queryKey: QUERY_KEYS.categories });
    },
    onError: () => toast.error('Failed to update category'),
  });
}

export function useDeleteCategory() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => categoriesService.deleteCategory(id),
    onSuccess: () => {
      toast.success('Category deleted');
      qc.invalidateQueries({ queryKey: QUERY_KEYS.categories });
    },
    onError: () => toast.error('Failed to delete category'),
  });
}

/* ------------------ Brands ------------------ */
export function useAllBrands() {
  return useQuery({
    queryKey: QUERY_KEYS.brands,
    queryFn: async () => {
      const res = await brandsService.getBrands();
      return Array.isArray(res) ? res : (res as any)?.results ?? [];
    },
  });
}

export function useCreateBrand() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: { name: string; description?: string; logo?: File }) => {
      const formData = new FormData();
      formData.append('name', data.name);
      if (data.description) formData.append('description', data.description);
      if (data.logo) formData.append('logo', data.logo);
      return brandsService.createBrand(formData as any);
    },
    onSuccess: () => {
      toast.success('Brand created');
      qc.invalidateQueries({ queryKey: QUERY_KEYS.brands });
    },
    onError: () => toast.error('Failed to create brand'),
  });
}

export function useUpdateBrand() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: { name?: string; description?: string; logo?: File } }) => {
      const formData = new FormData();
      if (data.name) formData.append('name', data.name);
      if (data.description) formData.append('description', data.description);
      if (data.logo) formData.append('logo', data.logo);
      return brandsService.updateBrand(id, formData as any);
    },
    onSuccess: () => {
      toast.success('Brand updated');
      qc.invalidateQueries({ queryKey: QUERY_KEYS.brands });
    },
    onError: () => toast.error('Failed to update brand'),
  });
}

export function useDeleteBrand() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => brandsService.deleteBrand(id),
    onSuccess: () => {
      toast.success('Brand deleted');
      qc.invalidateQueries({ queryKey: QUERY_KEYS.brands });
    },
    onError: () => toast.error('Failed to delete brand'),
  });
} 