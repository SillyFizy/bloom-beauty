"use client";

import React, { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Checkbox } from "@/components/ui/checkbox";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Separator } from "@/components/ui/separator";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { 
  Search, 
  Grid3X3, 
  Star, 
  Package, 
  X, 
  Plus,
  CheckCircle2,
  Circle
} from "lucide-react";
import Image from "next/image";
import { NavigationCategory, NavigationCategoryPublic } from "@/types/navigation-category";
import { usePublicNavigationCategories } from "@/hooks/use-navigation-categories";

interface SelectedNavigationCategory {
  id: number;
  name: string;
  is_featured?: boolean;
}

interface NavigationCategorySelectorProps {
  selectedCategories: SelectedNavigationCategory[];
  onCategoriesChange: (categories: SelectedNavigationCategory[]) => void;
  productName?: string;
  maxSelection?: number;
  showFeaturedToggle?: boolean;
  className?: string;
}

export const NavigationCategorySelector: React.FC<NavigationCategorySelectorProps> = ({
  selectedCategories,
  onCategoriesChange,
  productName = "this product",
  maxSelection = 5,
  showFeaturedToggle = true,
  className = "",
}) => {
  const [searchQuery, setSearchQuery] = useState("");
  const [filteredCategories, setFilteredCategories] = useState<NavigationCategoryPublic[]>([]);

  // Fetch navigation categories
  const { data: navigationCategories = [], isLoading, error } = usePublicNavigationCategories();

  // Filter categories based on search
  useEffect(() => {
    if (!navigationCategories.length) {
      setFilteredCategories([]);
      return;
    }

    const filtered = navigationCategories.filter(category =>
      category.name.toLowerCase().includes(searchQuery.toLowerCase())
    );

    setFilteredCategories(filtered);
  }, [navigationCategories, searchQuery]);

  const handleCategoryToggle = (category: NavigationCategoryPublic) => {
    const isSelected = selectedCategories.some(cat => cat.id === category.id);

    if (isSelected) {
      // Remove category
      const updated = selectedCategories.filter(cat => cat.id !== category.id);
      onCategoriesChange(updated);
    } else {
      // Add category (check max limit)
      if (selectedCategories.length >= maxSelection) {
        return; // Don't add if max reached
      }
      
      const updated = [
        ...selectedCategories,
        {
          id: category.id,
          name: category.name,
          is_featured: false,
        }
      ];
      onCategoriesChange(updated);
    }
  };

  const handleToggleFeatured = (categoryId: number) => {
    const updated = selectedCategories.map(cat =>
      cat.id === categoryId ? { ...cat, is_featured: !cat.is_featured } : cat
    );
    onCategoriesChange(updated);
  };

  const handleRemoveCategory = (categoryId: number) => {
    const updated = selectedCategories.filter(cat => cat.id !== categoryId);
    onCategoriesChange(updated);
  };

  const handleSelectAll = () => {
    const availableToSelect = filteredCategories
      .filter(cat => !selectedCategories.some(selected => selected.id === cat.id))
      .slice(0, maxSelection - selectedCategories.length);

    const newSelections = availableToSelect.map(cat => ({
      id: cat.id,
      name: cat.name,
      is_featured: false,
    }));

    onCategoriesChange([...selectedCategories, ...newSelections]);
  };

  const handleClearAll = () => {
    onCategoriesChange([]);
  };

  if (error) {
    return (
      <Card className={`border-red-200 ${className}`}>
        <CardContent className="p-6">
          <div className="text-center text-red-600">
            <p className="font-medium">Failed to load navigation categories</p>
            <p className="text-sm mt-1">Please try refreshing the page</p>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <div className={`space-y-6 ${className}`}>
      {/* Available Categories */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center justify-between">
            <span className="flex items-center gap-2">
              <Grid3X3 className="h-5 w-5" />
              Navigation Categories
            </span>
            <Badge variant="outline">
              {selectedCategories.length}/{maxSelection} selected
            </Badge>
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Search */}
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-4 w-4" />
            <Input
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search navigation categories..."
              className="pl-10"
            />
          </div>

          {/* Action Buttons */}
          <div className="flex items-center justify-between">
            <div className="flex gap-2">
              <Button
                type="button"
                variant="outline"
                size="sm"
                onClick={handleSelectAll}
                disabled={
                  selectedCategories.length >= maxSelection || 
                  filteredCategories.every(cat => selectedCategories.some(selected => selected.id === cat.id))
                }
              >
                <Plus className="h-4 w-4 mr-1" />
                Select All
              </Button>
              <Button
                type="button"
                variant="outline"
                size="sm"
                onClick={handleClearAll}
                disabled={selectedCategories.length === 0}
              >
                <X className="h-4 w-4 mr-1" />
                Clear All
              </Button>
            </div>
            <span className="text-sm text-muted-foreground">
              {filteredCategories.length} categories available
            </span>
          </div>

          {/* Categories Grid */}
          {isLoading ? (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
              {[...Array(6)].map((_, i) => (
                <div key={i} className="p-4 border rounded-lg">
                  <div className="animate-pulse">
                    <div className="h-4 bg-gray-200 rounded mb-2"></div>
                    <div className="h-3 bg-gray-200 rounded w-1/2"></div>
                  </div>
                </div>
              ))}
            </div>
          ) : filteredCategories.length === 0 ? (
            <div className="text-center py-8">
              <Grid3X3 className="h-8 w-8 text-muted-foreground mx-auto mb-2" />
              <p className="text-sm text-muted-foreground">
                {searchQuery ? `No categories found for "${searchQuery}"` : "No navigation categories available"}
              </p>
            </div>
          ) : (
            <ScrollArea className="h-64">
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3 pr-2">
                {filteredCategories.map((category) => {
                  const isSelected = selectedCategories.some(cat => cat.id === category.id);
                  const isDisabled = !isSelected && selectedCategories.length >= maxSelection;

                  return (
                    <div
                      key={category.id}
                      className={`group relative p-4 border-2 rounded-lg cursor-pointer transition-all ${
                        isSelected
                          ? 'border-primary bg-primary/5 shadow-sm'
                          : isDisabled
                          ? 'border-gray-200 bg-gray-50 cursor-not-allowed opacity-60'
                          : 'border-gray-200 hover:border-gray-300 hover:shadow-sm'
                      }`}
                      onClick={() => !isDisabled && handleCategoryToggle(category)}
                    >
                      <div className="flex items-start justify-between">
                        <div className="flex items-start space-x-3 flex-1">
                          {category.image_url ? (
                            <div className="relative w-10 h-10 rounded-lg overflow-hidden flex-shrink-0">
                              <Image
                                src={category.image_url}
                                alt={category.name}
                                fill
                                className="object-cover"
                              />
                            </div>
                          ) : (
                            <div className="w-10 h-10 rounded-lg bg-muted flex items-center justify-center flex-shrink-0">
                              <Package className="h-5 w-5 text-muted-foreground" />
                            </div>
                          )}
                          
                          <div className="flex-1 min-w-0">
                            <h4 className="font-medium text-sm truncate">{category.name}</h4>
                            <p className="text-xs text-muted-foreground mt-1">
                              Order: {category.order}
                            </p>
                          </div>
                        </div>
                        
                        <div className="flex-shrink-0 ml-2">
                          {isSelected ? (
                            <CheckCircle2 className="h-5 w-5 text-primary" />
                          ) : (
                            <Circle className="h-5 w-5 text-gray-300 group-hover:text-gray-400" />
                          )}
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            </ScrollArea>
          )}
        </CardContent>
      </Card>

      {/* Selected Categories */}
      {selectedCategories.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center justify-between">
              <span className="flex items-center gap-2">
                <CheckCircle2 className="h-5 w-5 text-green-600" />
                Selected Categories ({selectedCategories.length})
              </span>
              {showFeaturedToggle && (
                <Badge variant="outline" className="text-yellow-600">
                  <Star className="h-3 w-3 mr-1" />
                  {selectedCategories.filter(cat => cat.is_featured).length} Featured
                </Badge>
              )}
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {selectedCategories.map((category) => (
                <div
                  key={category.id}
                  className="flex items-center justify-between p-3 rounded-lg border bg-card"
                >
                  <div className="flex items-center space-x-3 flex-1">
                    <div className="w-8 h-8 rounded-lg bg-primary/10 flex items-center justify-center">
                      <Grid3X3 className="h-4 w-4 text-primary" />
                    </div>
                    
                    <div className="flex-1">
                      <h4 className="font-medium text-sm">{category.name}</h4>
                      {category.is_featured && (
                        <Badge variant="default" className="text-xs mt-1">
                          <Star className="h-3 w-3 mr-1" />
                          Featured in this category
                        </Badge>
                      )}
                    </div>
                  </div>
                  
                  <div className="flex items-center space-x-2">
                    {showFeaturedToggle && (
                      <Button
                        type="button"
                        variant={category.is_featured ? "default" : "outline"}
                        size="sm"
                        onClick={() => handleToggleFeatured(category.id)}
                        className="h-8"
                      >
                        <Star className="h-3 w-3" />
                      </Button>
                    )}
                    <Button
                      type="button"
                      variant="ghost"
                      size="sm"
                      onClick={() => handleRemoveCategory(category.id)}
                      className="h-8 w-8 p-0 text-red-500 hover:text-red-600 hover:bg-red-50"
                    >
                      <X className="h-4 w-4" />
                    </Button>
                  </div>
                </div>
              ))}
            </div>

            {showFeaturedToggle && (
              <>
                <Separator className="my-4" />
                <div className="p-3 bg-yellow-50 border border-yellow-200 rounded-lg">
                  <div className="flex items-start space-x-2">
                    <Star className="h-4 w-4 text-yellow-600 mt-0.5" />
                    <div>
                      <p className="text-sm font-medium text-yellow-800">
                        Featured Categories
                      </p>
                      <p className="text-xs text-yellow-700 mt-1">
                        {productName} will be highlighted in featured sections of selected categories.
                      </p>
                    </div>
                  </div>
                </div>
              </>
            )}
          </CardContent>
        </Card>
      )}
    </div>
  );
}; 