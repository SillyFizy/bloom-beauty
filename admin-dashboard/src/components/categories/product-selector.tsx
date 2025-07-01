"use client";

import React, { useState, useMemo } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Checkbox } from "@/components/ui/checkbox";
import { Switch } from "@/components/ui/switch";
import { Separator } from "@/components/ui/separator";
import { ScrollArea } from "@/components/ui/scroll-area";
import { 
  Search, 
  Package, 
  Plus, 
  Minus,
  Image as ImageIcon,
  ShoppingCart,
  X
} from "lucide-react";
import Image from "next/image";
import { ProductBasic } from "@/types/navigation-category";
import { useSearchProducts } from "@/hooks/use-navigation-categories";
import { useDebounce } from "@/hooks/use-debounce";

interface ProductSelectorProps {
  categoryId: number;
  selectedProducts: number[];
  onProductsChange: (productIds: number[], clearExisting?: boolean) => void;
  onClose: () => void;
}

export const ProductSelector: React.FC<ProductSelectorProps> = ({
  categoryId,
  selectedProducts,
  onProductsChange,
  onClose,
}) => {
  const [searchTerm, setSearchTerm] = useState("");
  const [clearExisting, setClearExisting] = useState(false);
  const [currentSelection, setCurrentSelection] = useState<number[]>(selectedProducts);
  
  const debouncedSearch = useDebounce(searchTerm, 300);
  
  const { data: searchResults = [], isLoading: isSearching } = useSearchProducts({
    search: debouncedSearch,
    exclude_category: categoryId,
  });

  const handleProductToggle = (productId: number) => {
    const updatedSelection = currentSelection.includes(productId)
      ? currentSelection.filter(id => id !== productId)
      : [...currentSelection, productId];
    
    setCurrentSelection(updatedSelection);
  };

  const handleSelectAll = () => {
    const allProductIds = searchResults.map(product => product.id);
    const combinedIds = [...currentSelection, ...allProductIds];
    const newSelection = Array.from(new Set(combinedIds));
    setCurrentSelection(newSelection);
  };

  const handleClearSelection = () => {
    setCurrentSelection([]);
  };

  const handleConfirm = () => {
    onProductsChange(currentSelection, clearExisting);
    onClose();
  };

  const ProductCard: React.FC<{ product: ProductBasic; isSelected: boolean }> = ({ 
    product, 
    isSelected 
  }) => (
    <Card 
      className={`cursor-pointer transition-all duration-200 hover:shadow-md ${
        isSelected ? 'ring-2 ring-primary bg-primary/5' : 'hover:bg-muted/50'
      }`}
      onClick={() => handleProductToggle(product.id)}
    >
      <CardContent className="p-4">
        <div className="flex items-start space-x-3">
          <Checkbox 
            checked={isSelected}
            onCheckedChange={() => handleProductToggle(product.id)}
            className="mt-1"
          />
          
          <div className="flex-shrink-0">
            {product.image_url ? (
              <div className="relative w-12 h-12 rounded-lg overflow-hidden">
                <Image
                  src={product.image_url}
                  alt={product.name}
                  fill
                  className="object-cover"
                />
              </div>
            ) : (
              <div className="w-12 h-12 rounded-lg bg-muted flex items-center justify-center">
                <ImageIcon className="h-5 w-5 text-muted-foreground" />
              </div>
            )}
          </div>
          
          <div className="flex-1 min-w-0">
            <h4 className="font-medium text-sm truncate">{product.name}</h4>
            <div className="flex items-center space-x-2 mt-1">
              <Badge variant="secondary" className="text-xs">
                ${product.price}
              </Badge>
              {product.sale_price && (
                <Badge variant="destructive" className="text-xs">
                  ${product.sale_price}
                </Badge>
              )}
            </div>
            {product.sku && (
              <p className="text-xs text-muted-foreground mt-1">SKU: {product.sku}</p>
            )}
          </div>
        </div>
      </CardContent>
    </Card>
  );

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h3 className="text-lg font-semibold">Select Products</h3>
          <p className="text-sm text-muted-foreground">
            Choose products to add to this navigation category
          </p>
        </div>
        <Button variant="ghost" size="icon" onClick={onClose}>
          <X className="h-4 w-4" />
        </Button>
      </div>

      {/* Search */}
      <div className="space-y-2">
        <Label htmlFor="product-search">Search Products</Label>
        <div className="relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <Input
            id="product-search"
            placeholder="Search by name, SKU, or description..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="pl-10"
          />
        </div>
      </div>

      {/* Options */}
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-2">
          <Switch
            id="clear-existing"
            checked={clearExisting}
            onCheckedChange={setClearExisting}
          />
          <Label htmlFor="clear-existing" className="text-sm">
            Replace existing products
          </Label>
        </div>
        
        <div className="flex items-center space-x-2">
          <Badge variant="outline">
            {currentSelection.length} selected
          </Badge>
          {searchResults.length > 0 && (
            <>
              <Button 
                variant="ghost" 
                size="sm" 
                onClick={handleSelectAll}
                className="h-8"
              >
                <Plus className="h-3 w-3 mr-1" />
                Select All
              </Button>
              <Button 
                variant="ghost" 
                size="sm" 
                onClick={handleClearSelection}
                className="h-8"
              >
                <Minus className="h-3 w-3 mr-1" />
                Clear
              </Button>
            </>
          )}
        </div>
      </div>

      <Separator />

      {/* Results */}
      <div className="space-y-4">
        {debouncedSearch && !isSearching && searchResults.length === 0 && (
          <div className="text-center py-8">
            <Package className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
            <h4 className="text-sm font-medium">No products found</h4>
            <p className="text-xs text-muted-foreground">
              Try adjusting your search terms
            </p>
          </div>
        )}

        {debouncedSearch && isSearching && (
          <div className="text-center py-8">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto mb-4"></div>
            <p className="text-sm text-muted-foreground">Searching...</p>
          </div>
        )}

        {!debouncedSearch && (
          <div className="text-center py-8">
            <Search className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
            <h4 className="text-sm font-medium">Start typing to search</h4>
            <p className="text-xs text-muted-foreground">
              Search for products by name, SKU, or description
            </p>
          </div>
        )}

        {searchResults.length > 0 && (
          <ScrollArea className="h-96">
            <div className="space-y-2">
              {searchResults.map((product) => (
                <ProductCard
                  key={product.id}
                  product={product}
                  isSelected={currentSelection.includes(product.id)}
                />
              ))}
            </div>
          </ScrollArea>
        )}
      </div>

      {/* Action Buttons */}
      <div className="flex items-center justify-between pt-4 border-t">
        <div className="text-sm text-muted-foreground">
          {currentSelection.length > 0 && (
            <>
              {currentSelection.length} product{currentSelection.length !== 1 ? 's' : ''} selected
              {clearExisting && ' (will replace existing)'}
            </>
          )}
        </div>
        
        <div className="flex items-center space-x-2">
          <Button variant="ghost" onClick={onClose}>
            Cancel
          </Button>
          <Button 
            disabled={currentSelection.length === 0}
            onClick={handleConfirm}
          >
            <ShoppingCart className="h-4 w-4 mr-2" />
            Add {currentSelection.length} Product{currentSelection.length !== 1 ? 's' : ''}
          </Button>
        </div>
      </div>
    </div>
  );
}; 