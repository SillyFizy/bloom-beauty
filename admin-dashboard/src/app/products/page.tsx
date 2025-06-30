'use client';

import { useState, useMemo } from 'react';
import Image from 'next/image';
import { 
  Plus, 
  Search, 
  Filter, 
  MoreHorizontal, 
  Edit, 
  Trash2, 
  Eye,
  Star,
  AlertTriangle,
  Package,
  DollarSign,
  TrendingUp,
  Users,
  Pencil,
  Gem,
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { useProducts, useProductStats, useCategories, useBrands, useDeleteProduct, useLowStockProducts, QUERY_KEYS } from '@/hooks/use-products';
import { useQueryClient } from '@tanstack/react-query';
import { ProductFilters, ProductListItem } from '@/types/product';
import { formatCurrency, formatDate, cn, debounce } from '@/lib/utils';
import { apiClient } from '@/lib/api';
import { EditProductDialog } from '@/components/products/edit-product-dialog';
import { AddProductDialog } from '@/components/products/add-product-dialog';
import type { Category, Brand, Product } from '@/types/product';

function ProductsPageInner() {
  const [filters, setFilters] = useState<ProductFilters>({
    page: 1,
    page_size: 20,
    ordering: '-created_at',
  });
  const [selectedProducts, setSelectedProducts] = useState<number[]>([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [editingProduct, setEditingProduct] = useState<Product | null>(null);
  const [showAddProduct, setShowAddProduct] = useState(false);
  
  const queryClient = useQueryClient();

  // Debounced search function
  const debouncedSearch = useMemo(
    () => debounce((query: string) => {
      setFilters(prev => ({ ...prev, search: query, page: 1 }));
    }, 300),
    []
  );

  // Handle search input
  const handleSearch = (value: string) => {
    setSearchQuery(value);
    debouncedSearch(value);
  };

  // Queries
  const { data: productsData, isLoading, error } = useProducts(filters);
  const { data: stats } = useProductStats();
  const { data: categories = [] } = useCategories();
  const { data: brands = [] } = useBrands();
  const { data: lowStockProducts = [] } = useLowStockProducts();
  
  // Debug logging
  console.log('🔍 Debug Info:');
  console.log('Current filters:', filters);
  console.log('Categories data:', categories);
  console.log('Brands data:', brands);
  console.log('Products data:', productsData);
  
  // Mutations
  const deleteProduct = useDeleteProduct();

  const products = (productsData as any)?.results || [];
  const totalCount = (productsData as any)?.count || 0;
  const totalPages = Math.ceil(totalCount / (filters.page_size || 20));

  // Calculate inventory value like in dashboard
  const { data: allProductsData } = useProducts({ page: 1, page_size: 1000, ordering: "-created_at" });
  const allProducts = (allProductsData as any)?.results || [];
  const inventoryValue = allProducts.reduce((sum: number, product: any) => {
    const price = product.sale_price ?? product.price ?? 0;
    const qty = product.stock_quantity ?? product.stock ?? 0;
    return sum + price * qty;
  }, 0);

  const summaryCards = [
    {
      title: "Total Products",
      value: stats?.total_products ?? 0,
      icon: Package,
      description: `${stats?.active_products ?? 0} active`,
      color: "bg-blue-500",
    },
    {
      title: "Featured Products",
      value: stats?.featured_products ?? 0,
      icon: TrendingUp,
      description: "Currently featured",
      color: "bg-green-500",
    },
    {
      title: "Inventory Value",
      value: formatCurrency(inventoryValue) as any,
      icon: DollarSign,
      description: "Total stock value",
      color: "bg-purple-500",
    },
    {
      title: "Low Stock Alert",
      value: lowStockProducts.length,
      icon: AlertTriangle,
      description: "≤ threshold units remaining",
      color: "bg-red-500",
    },
  ];

  // Handle pagination
  const handlePageChange = (page: number) => {
    setFilters(prev => ({ ...prev, page }));
  };

  // Handle selection
  const handleSelectProduct = (productId: number) => {
    setSelectedProducts(prev => 
      prev.includes(productId)
        ? prev.filter(id => id !== productId)
        : [...prev, productId]
    );
  };

  const handleSelectAll = () => {
    if (selectedProducts.length === products.length) {
      setSelectedProducts([]);
    } else {
      setSelectedProducts(products.map((p: any) => p.id));
    }
  };

  // Handle delete
  const handleDelete = async (productId: number) => {
    if (window.confirm('Are you sure you want to delete this product?')) {
      deleteProduct.mutate(productId);
    }
  };

  const handleEdit = (product: Product) => {
    setEditingProduct(product);
  };

  const handleAddProduct = () => {
    setShowAddProduct(true);
  };

  const handleAddProductSuccess = () => {
    // Refresh the products list after successful creation
    queryClient.invalidateQueries({ queryKey: QUERY_KEYS.products });
    queryClient.invalidateQueries({ queryKey: QUERY_KEYS.productStats });
  };

  if (error) {
    return (
      <div className="flex-1 flex items-center justify-center">
        <div className="text-center">
          <AlertTriangle className="h-12 w-12 text-destructive mx-auto mb-4" />
          <h2 className="text-lg font-semibold mb-2">Failed to load products</h2>
          <p className="text-slate-700 mb-4">
            Please check your connection and try again.
          </p>
          <Button onClick={() => window.location.reload()}>
            Retry
          </Button>
        </div>
      </div>
    );
  }

  return (
    <>
      <div className="flex-1 space-y-6 p-6 bg-background">
        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {summaryCards.map((stat, index) => (
            <Card key={index} className="card-hover">
              <CardContent className="p-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-slate-600">{stat.title}</p>
                    <p className="text-2xl font-bold text-slate-900">
                      {typeof stat.value === "number" ? stat.value.toLocaleString() : stat.value}
                    </p>
                    <p className="text-xs text-slate-500 mt-1">{stat.description}</p>
                  </div>
                  <div className={cn("p-3 rounded-full", stat.color)}>
                    <stat.icon className="h-6 w-6 text-white" />
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>

        {/* Header and Actions */}
        <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-6">
          <div className="flex-1">
            <h2 className="text-3xl font-bold text-slate-900">Products</h2>
            <p className="text-sm font-medium text-slate-600 mt-1">
              Manage your product catalog ({totalCount.toLocaleString()} products)
            </p>
          </div>
          
          <div className="flex items-center gap-3">
            <Button 
              size="sm" 
              onClick={handleAddProduct}
              className="h-12 rounded-xl bg-green-600 text-white border border-green-600 hover:bg-green-700 hover:border-green-700 transition-all duration-200 shadow-sm hover:shadow-md"
            >
              <Plus className="h-4 w-4 mr-2" />
              Add Product
            </Button>
          </div>
        </div>

        {/* Search and Filters */}
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-500" />
            <input
              type="search"
              placeholder="Search products by name, SKU, or description..."
              value={searchQuery}
              onChange={(e) => handleSearch(e.target.value)}
              className="w-full h-12 rounded-xl border border-slate-200 bg-white pl-9 pr-3 text-slate-700 placeholder:text-slate-500 focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/10 shadow-sm hover:shadow-md transition-all duration-200"
            />
          </div>
          
          <select
            value={filters.category || ''}
            onChange={(e) => {
              const newCategoryFilter = e.target.value ? Number(e.target.value) : undefined;
              console.log('📂 Category filter changed:', e.target.value, '→', newCategoryFilter);
              setFilters(prev => ({ 
                ...prev, 
                category: newCategoryFilter,
                page: 1 
              }));
            }}
            className="h-12 rounded-xl border border-slate-200 bg-white px-3 text-slate-700 focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/10 shadow-sm hover:shadow-md transition-all duration-200"
          >
            <option value="">All Categories</option>
            {categories.map(category => (
              <option key={category.id} value={category.id}>
                {category.name}
              </option>
            ))}
          </select>

          <select
            value={filters.brand || ''}
            onChange={(e) => {
              const newBrandFilter = e.target.value ? Number(e.target.value) : undefined;
              console.log('🏷️ Brand filter changed:', e.target.value, '→', newBrandFilter);
              setFilters(prev => ({ 
                ...prev, 
                brand: newBrandFilter,
                page: 1 
              }));
            }}
            className="h-12 rounded-xl border border-slate-200 bg-white px-3 text-slate-700 focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/10 shadow-sm hover:shadow-md transition-all duration-200"
          >
            <option value="">All Brands</option>
            {brands.map(brand => (
              <option key={brand.id} value={brand.id}>
                {brand.name}
              </option>
            ))}
          </select>
        </div>

        {/* Products Table */}
        <div className="bg-white rounded-2xl border border-slate-200 overflow-hidden shadow-lg">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-slate-50 border-b border-slate-200">
                <tr>
                  <th className="text-left p-6 font-semibold text-slate-700 text-sm uppercase tracking-wide">
                    <input
                      type="checkbox"
                      checked={selectedProducts.length === products.length && products.length > 0}
                      onChange={handleSelectAll}
                      className="rounded-lg border-slate-300 text-primary focus:ring-primary"
                    />
                  </th>
                  <th className="text-left p-6 font-semibold text-slate-700 text-sm uppercase tracking-wide">Product</th>
                  <th className="text-left p-6 font-semibold text-slate-700 text-sm uppercase tracking-wide">Category</th>
                  <th className="text-left p-6 font-semibold text-slate-700 text-sm uppercase tracking-wide">Price</th>
                  <th className="text-left p-6 font-semibold text-slate-700 text-sm uppercase tracking-wide">Stock</th>
                  <th className="text-left p-6 font-semibold text-slate-700 text-sm uppercase tracking-wide">Beauty Pts</th>
                  <th className="text-left p-6 font-semibold text-slate-700 text-sm uppercase tracking-wide">Rating</th>
                  <th className="text-left p-6 font-semibold text-slate-700 text-sm uppercase tracking-wide">Brand</th>
                  <th className="text-left p-6 font-semibold text-slate-700 text-sm uppercase tracking-wide">Created</th>
                  <th className="text-left p-6 font-semibold text-slate-700 text-sm uppercase tracking-wide">Actions</th>
                </tr>
              </thead>
              <tbody>
                {isLoading ? (
                  // Loading skeleton
                  Array.from({ length: 10 }).map((_, i) => (
                    <tr key={i} className="border-b border-slate-200">
                      <td className="p-4">
                        <div className="w-4 h-4 bg-slate-100 rounded animate-pulse" />
                      </td>
                      <td className="p-4">
                        <div className="flex items-center space-x-3">
                          <div className="w-12 h-12 bg-slate-100 rounded-lg animate-pulse" />
                          <div className="space-y-2">
                            <div className="w-32 h-4 bg-slate-100 rounded animate-pulse" />
                            <div className="w-24 h-3 bg-slate-100 rounded animate-pulse" />
                          </div>
                        </div>
                      </td>
                      <td className="p-4">
                        <div className="w-20 h-4 bg-slate-100 rounded animate-pulse" />
                      </td>
                      <td className="p-4">
                        <div className="w-16 h-4 bg-slate-100 rounded animate-pulse" />
                      </td>
                      <td className="p-4">
                        <div className="w-12 h-4 bg-slate-100 rounded animate-pulse" />
                      </td>
                      <td className="p-4">
                        <div className="w-12 h-4 bg-slate-100 rounded animate-pulse" />
                      </td>
                      <td className="p-4">
                        <div className="w-12 h-4 bg-slate-100 rounded animate-pulse" />
                      </td>
                      <td className="p-4">
                        <div className="w-12 h-4 bg-slate-100 rounded animate-pulse" />
                      </td>
                      <td className="p-4">
                        <div className="w-16 h-4 bg-slate-100 rounded animate-pulse" />
                      </td>
                      <td className="p-4">
                        <div className="w-8 h-8 bg-slate-100 rounded animate-pulse" />
                      </td>
                    </tr>
                  ))
                ) : products.length === 0 ? (
                  <tr>
                    <td colSpan={10} className="p-12 text-center">
                      <Package className="h-12 w-12 text-slate-400 mx-auto mb-4" />
                      <h3 className="text-lg font-medium text-slate-900 mb-2">No products found</h3>
                      <p className="text-slate-600">
                        {searchQuery ? 'Try adjusting your search terms' : 'Get started by adding your first product'}
                      </p>
                    </td>
                  </tr>
                ) : (
                  products.map((product: any) => (
                    <ProductTableRow
                      key={product.id}
                      product={product}
                      isSelected={selectedProducts.includes(product.id)}
                      onSelect={() => handleSelectProduct(product.id)}
                      onDelete={() => handleDelete(product.id)}
                      onEdit={() => handleEdit(product)}
                      categories={categories}
                      brands={brands}
                    />
                  ))
                )}
              </tbody>
            </table>
          </div>

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="flex items-center justify-between px-6 py-4 border-t border-slate-200 bg-white">
              <div className="flex items-center text-sm text-slate-600">
                Showing {((filters.page || 1) - 1) * (filters.page_size || 20) + 1} to{' '}
                {Math.min((filters.page || 1) * (filters.page_size || 20), totalCount)} of{' '}
                {totalCount} products
              </div>
              
              <div className="flex items-center space-x-2">
                <Button
                  variant="outline"
                  size="sm"
                  disabled={(filters.page || 1) <= 1}
                  onClick={() => handlePageChange((filters.page || 1) - 1)}
                  className="bg-white text-slate-700 border-slate-200 hover:bg-primary hover:text-white hover:border-primary transition-all duration-200"
                >
                  Previous
                </Button>
                
                {Array.from({ length: Math.min(5, totalPages) }, (_, i) => {
                  const page = i + 1;
                  return (
                    <Button
                      key={page}
                      variant="pagination"
                      size="sm"
                      onClick={() => handlePageChange(page)}
                      className={cn(
                        "bg-white border-slate-200",
                        (filters.page || 1) === page 
                          ? "text-primary border-primary hover:bg-primary hover:text-white" 
                          : "text-slate-700 hover:bg-primary hover:text-white hover:border-primary"
                      )}
                    >
                      {page}
                    </Button>
                  );
                })}
                
                <Button
                  variant="outline"
                  size="sm"
                  disabled={(filters.page || 1) >= totalPages}
                  onClick={() => handlePageChange((filters.page || 1) + 1)}
                  className="bg-white text-slate-700 border-slate-200 hover:bg-primary hover:text-white hover:border-primary transition-all duration-200"
                >
                  Next
                </Button>
              </div>
            </div>
          )}
        </div>
      </div>

      <EditProductDialog
        product={editingProduct}
        open={!!editingProduct}
        onOpenChange={(open) => !open && setEditingProduct(null)}
        onSuccess={() => {
          queryClient.invalidateQueries({ queryKey: QUERY_KEYS.products });
          queryClient.invalidateQueries({ queryKey: QUERY_KEYS.productStats });
          setEditingProduct(null);
        }}
      />

      <AddProductDialog
        open={showAddProduct}
        onClose={() => setShowAddProduct(false)}
        onSuccess={handleAddProductSuccess}
      />
    </>
  );
}

// Product Table Row Component
interface ProductTableRowProps {
  product: ProductListItem;
  isSelected: boolean;
  onSelect: () => void;
  onDelete: () => void;
  onEdit: () => void;
  categories: Category[];
  brands: Brand[];
}

function ProductTableRow({ product, isSelected, onSelect, onDelete, onEdit, categories, brands }: ProductTableRowProps) {
  const stockStatusColors = {
    'in_stock': 'text-green-700',
    'low_stock': 'text-orange-700',
    'out_of_stock': 'text-red-700'
  };

  const getStockStatusText = (status: string | undefined) => {
    if (!status) return 'Unknown';
    return status.replace(/_/g, ' ');
  };

  const getStockStatusColor = (status: string | undefined) => {
    if (!status || !stockStatusColors[status as keyof typeof stockStatusColors]) {
      return 'text-slate-700';
    }
    return stockStatusColors[status as keyof typeof stockStatusColors];
  };

  return (
    <tr className="border-b border-slate-200 hover:bg-slate-50/50">
      <td className="p-4">
        <input
          type="checkbox"
          checked={isSelected}
          onChange={onSelect}
          className="rounded-lg border-slate-300 text-primary focus:ring-primary"
        />
      </td>
      <td className="p-4">
        <div className="flex items-center gap-3">
          {product.featured_image && (
            <div className="relative h-12 w-12 rounded-lg border border-slate-200 overflow-hidden">
              <Image
                src={product.featured_image}
                alt={product.name}
                fill
                className="object-cover"
              />
            </div>
          )}
          <div>
            <h3 className="font-medium text-slate-900">{product.name}</h3>
            <p className="text-sm text-slate-500">SKU: {(product as any).sku || 'N/A'}</p>
          </div>
        </div>
      </td>
      <td className="p-4 text-slate-700">
        {(() => {
          if ((product as any).category_name) return (product as any).category_name;
          if (typeof (product as any).category === 'object' && (product as any).category?.name) {
            return (product as any).category.name;
          }
          const catId = (product as any).category_id || (product as any).category;
          if (catId) {
            const cat = categories.find((c) => c.id === Number(catId));
            if (cat) return cat.name;
          }
          return 'Uncategorized';
        })()}
      </td>
      <td className="p-4 text-slate-700">{formatCurrency(product.price)}</td>
      <td className="p-4 text-slate-700">{product.stock}</td>
      <td className="p-4 text-slate-700">
        <div className="flex items-center gap-1">
          <Gem className="h-4 w-4 text-amber-500" />
          {(product as any).beauty_points ?? 0}
        </div>
      </td>
      <td className="p-4 text-slate-700">
        <div className="flex items-center gap-1">
          <Star className="h-4 w-4 text-yellow-500 fill-yellow-500" />
          {((product as any).rating ?? 0).toFixed(1)}
        </div>
      </td>
      <td className="p-4 text-slate-700">
        {(() => {
          if ((product as any).brand_name) return (product as any).brand_name;
          if (typeof (product as any).brand === 'object' && (product as any).brand?.name) {
            return (product as any).brand.name;
          }
          const brandId = (product as any).brand_id || (product as any).brand;
          if (brandId) {
            const br = brands.find((b) => b.id === Number(brandId));
            if (br) return br.name;
          }
          return 'Unassigned';
        })()}
      </td>
      <td className="p-4 text-slate-700">
        {formatDate(product.created_at)}
      </td>
      <td className="p-4">
        <div className="flex items-center gap-2">
          <Button
            variant="ghost"
            size="icon"
            onClick={onEdit}
            className="h-8 w-8"
          >
            <Pencil className="h-4 w-4 text-slate-500" />
          </Button>
          <Button
            variant="ghost"
            size="icon"
            onClick={onDelete}
            className="h-8 w-8 text-red-500 hover:text-red-600 hover:bg-red-50"
          >
            <Trash2 className="h-4 w-4" />
          </Button>
        </div>
      </td>
    </tr>
  );
}

export default function ProductsPage() {
  return <ProductsPageInner />;
} 