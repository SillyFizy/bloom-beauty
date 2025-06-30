"use client";

import React, { useState, useMemo } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Badge } from '@/components/ui/badge';
import { MapPin, Edit2, Trash2, Save, X, Plus } from 'lucide-react';
import { IRAQI_GOVERNORATES, ShippingZone } from '@/types/shipping';
import { useSetSameGovernorate, useUpdateSameGovernorate, useRemoveSameGovernorate } from '@/hooks/use-shipping';
import { useToast } from '@/hooks/useToast';

interface SameGovernorateCardProps {
  sameGovernorate?: ShippingZone;
  isLoading?: boolean;
  usedGovernorateIds?: string[];
}

export function SameGovernorateCard({ sameGovernorate, isLoading, usedGovernorateIds = [] }: SameGovernorateCardProps) {
  const [isEditing, setIsEditing] = useState(!sameGovernorate);
  const [selectedGovernorate, setSelectedGovernorate] = useState(sameGovernorate?.governorate.id || '');
  const [price, setPrice] = useState(sameGovernorate?.price.toString() || '');
  const [errors, setErrors] = useState<{ governorate?: string; price?: string }>({});

  const { toast } = useToast();
  const setSameGovernorateMutation = useSetSameGovernorate();
  const updateSameGovernorateMutation = useUpdateSameGovernorate();
  const removeSameGovernorateMutation = useRemoveSameGovernorate();

  const validateForm = () => {
    const newErrors: typeof errors = {};
    
    if (!selectedGovernorate) {
      newErrors.governorate = 'Please select a governorate';
    }
    
    const priceNum = parseFloat(price);
    if (!price || isNaN(priceNum) || priceNum <= 0) {
      newErrors.price = 'Price must be a positive number';
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSave = async () => {
    if (!validateForm()) return;

    try {
      const priceNum = parseFloat(price);
      
      if (sameGovernorate) {
        await updateSameGovernorateMutation.mutateAsync(priceNum);
        toast({
          title: "Success",
          description: "Same governorate shipping updated successfully",
        });
      } else {
        await setSameGovernorateMutation.mutateAsync({
          governorateId: selectedGovernorate,
          price: priceNum
        });
        toast({
          title: "Success",
          description: "Same governorate shipping set successfully",
        });
      }
      
      setIsEditing(false);
      setErrors({});
    } catch (error) {
      toast({
        title: "Error",
        description: "Failed to save same governorate shipping",
        variant: "destructive",
      });
    }
  };

  const handleDelete = async () => {
    if (!sameGovernorate) return;
    
    try {
      await removeSameGovernorateMutation.mutateAsync();
      toast({
        title: "Success",
        description: "Same governorate shipping removed successfully",
      });
      setIsEditing(true);
      setSelectedGovernorate('');
      setPrice('');
    } catch (error) {
      toast({
        title: "Error",
        description: "Failed to remove same governorate shipping",
        variant: "destructive",
      });
    }
  };

  const handleCancel = () => {
    setIsEditing(false);
    setSelectedGovernorate(sameGovernorate?.governorate.id || '');
    setPrice(sameGovernorate?.price.toString() || '');
    setErrors({});
  };

  const selectedGov = IRAQI_GOVERNORATES.find(g => g.id === selectedGovernorate);

  // Compute available governorates excluding those already used in other zones (but allow current selection)
  const availableGovernorates = React.useMemo(() => {
    return IRAQI_GOVERNORATES.filter(gov => {
      if (sameGovernorate && gov.id === sameGovernorate.governorate.id) return true;
      return !usedGovernorateIds.includes(gov.id);
    });
  }, [usedGovernorateIds, sameGovernorate]);

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <div className="flex items-center space-x-2">
            <MapPin className="h-5 w-5 text-blue-600" />
            <CardTitle>Same Governorate Shipping</CardTitle>
          </div>
          <CardDescription>
            Set the primary governorate and shipping price
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="animate-pulse space-y-4">
            <div className="h-4 bg-gray-200 rounded w-3/4"></div>
            <div className="h-10 bg-gray-200 rounded"></div>
            <div className="h-10 bg-gray-200 rounded"></div>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className="relative overflow-hidden">
      <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-blue-500 to-blue-600"></div>
      
      <CardHeader>
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-2">
            <MapPin className="h-5 w-5 text-blue-600" />
            <CardTitle>Same Governorate Shipping</CardTitle>
            {sameGovernorate && !isEditing && (
              <Badge variant="secondary" className="bg-blue-100 text-blue-800">
                Active
              </Badge>
            )}
          </div>
          
          {!isEditing && sameGovernorate && (
            <div className="flex items-center space-x-2">
              <Button
                size="sm"
                variant="outline"
                onClick={() => setIsEditing(true)}
                className="h-8 w-8 p-0"
              >
                <Edit2 className="h-4 w-4" />
              </Button>
              <Button
                size="sm"
                variant="outline"
                onClick={handleDelete}
                disabled={removeSameGovernorateMutation.isPending}
                className="h-8 w-8 p-0 text-red-600 hover:text-red-700"
              >
                <Trash2 className="h-4 w-4" />
              </Button>
            </div>
          )}
        </div>
        
        <CardDescription>
          Set the primary governorate with standard shipping price
        </CardDescription>
      </CardHeader>

      <CardContent className="space-y-6">
        {!isEditing && sameGovernorate ? (
          <div className="space-y-4">
            <div className="flex items-center justify-between p-4 bg-blue-50 rounded-lg border border-blue-200">
              <div>
                <h4 className="font-medium text-gray-900">
                  {sameGovernorate.governorate.name}
                </h4>
                <p className="text-sm text-gray-600">
                  {sameGovernorate.governorate.nameArabic}
                </p>
              </div>
              <div className="text-right">
                <p className="text-lg font-semibold text-green-600">
                  {sameGovernorate.price.toLocaleString()} IQD
                </p>
                <p className="text-xs text-gray-500">Shipping Fee</p>
              </div>
            </div>
          </div>
        ) : (
          <div className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="governorate">Select Governorate</Label>
              <Select
                value={selectedGovernorate}
                onValueChange={setSelectedGovernorate}
                disabled={!!sameGovernorate && !isEditing}
              >
                <SelectTrigger className={errors.governorate ? 'border-red-500' : ''}>
                  <SelectValue placeholder="Choose a governorate" />
                </SelectTrigger>
                <SelectContent>
                  {availableGovernorates.map((gov) => (
                    <SelectItem key={gov.id} value={gov.id}>
                      <div className="flex items-center justify-between w-full">
                        <span>{gov.name}</span>
                        <span className="text-sm text-gray-500 ml-2">{gov.nameArabic}</span>
                      </div>
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              {errors.governorate && (
                <p className="text-sm text-red-600">{errors.governorate}</p>
              )}
            </div>

            <div className="space-y-2">
              <Label htmlFor="price">Shipping Price (IQD)</Label>
              <div className="relative">
                <Input
                  id="price"
                  type="number"
                  value={price}
                  onChange={(e) => setPrice(e.target.value)}
                  placeholder="Enter shipping price"
                  className={errors.price ? 'border-red-500' : ''}
                  min="0"
                  step="1000"
                />
                <span className="absolute right-3 top-1/2 transform -translate-y-1/2 text-sm text-gray-500">
                  IQD
                </span>
              </div>
              {errors.price && (
                <p className="text-sm text-red-600">{errors.price}</p>
              )}
            </div>

            <div className="flex items-center space-x-2 pt-4">
              <Button
                onClick={handleSave}
                disabled={setSameGovernorateMutation.isPending || updateSameGovernorateMutation.isPending}
                className="flex items-center space-x-2"
              >
                {sameGovernorate ? <Save className="h-4 w-4" /> : <Plus className="h-4 w-4" />}
                <span>{sameGovernorate ? 'Update' : 'Set Same Governorate'}</span>
              </Button>
              
              {sameGovernorate && (
                <Button
                  variant="outline"
                  onClick={handleCancel}
                  className="flex items-center space-x-2"
                >
                  <X className="h-4 w-4" />
                  <span>Cancel</span>
                </Button>
              )}
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  );
} 