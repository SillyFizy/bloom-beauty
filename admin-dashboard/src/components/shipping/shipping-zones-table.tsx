"use client";

import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Badge } from '@/components/ui/badge';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { MapIcon, Edit2, Trash2, Save, X, Plus, Search } from 'lucide-react';
import { IRAQI_GOVERNORATES, ShippingZone } from '@/types/shipping';
import { useCreateShippingZone, useUpdateShippingZone, useDeleteShippingZone } from '@/hooks/use-shipping';
import { useToast } from '@/hooks/useToast';

interface ShippingZonesTableProps {
  zones: ShippingZone[];
  type: 'nearby' | 'other';
  isLoading?: boolean;
  usedGovernorateIds?: string[];
}

interface ZoneFormData {
  governorateId: string;
  price: string;
}

export function ShippingZonesTable({ zones, type, isLoading, usedGovernorateIds = [] }: ShippingZonesTableProps) {
  const [searchTerm, setSearchTerm] = useState('');
  const [editingZone, setEditingZone] = useState<ShippingZone | null>(null);
  const [showAddDialog, setShowAddDialog] = useState(false);
  const [formData, setFormData] = useState<ZoneFormData>({ governorateId: '', price: '' });
  const [errors, setErrors] = useState<{ governorate?: string; price?: string }>({});

  const { toast } = useToast();
  const createZoneMutation = useCreateShippingZone();
  const updateZoneMutation = useUpdateShippingZone();
  const deleteZoneMutation = useDeleteShippingZone();

  const typeConfig = {
    nearby: {
      title: 'Nearby Governorates',
      description: 'Manage shipping rates for nearby governorates',
      icon: MapIcon,
      color: 'orange',
      bgColor: 'bg-orange-50',
      borderColor: 'border-orange-200',
      textColor: 'text-orange-800',
      badgeColor: 'bg-orange-100',
      gradientFrom: 'from-orange-500',
      gradientTo: 'to-orange-600',
    },
    other: {
      title: 'Other Governorates',
      description: 'Manage shipping rates for distant governorates',
      icon: MapIcon,
      color: 'purple',
      bgColor: 'bg-purple-50',
      borderColor: 'border-purple-200',
      textColor: 'text-purple-800',
      badgeColor: 'bg-purple-100',
      gradientFrom: 'from-purple-500',
      gradientTo: 'to-purple-600',
    },
  };

  const config = typeConfig[type];
  const IconComponent = config.icon;

  // Get available governorates (not used in any shipping zone)
  const availableGovernorates = IRAQI_GOVERNORATES.filter(
    gov => !usedGovernorateIds.includes(gov.id)
  );

  // Filter zones based on search term
  const filteredZones = zones.filter(zone =>
    zone.governorate.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    zone.governorate.nameArabic.includes(searchTerm)
  );

  const validateForm = () => {
    const newErrors: typeof errors = {};
    
    if (!formData.governorateId) {
      newErrors.governorate = 'Please select a governorate';
    }
    
    const priceNum = parseFloat(formData.price);
    if (!formData.price || isNaN(priceNum) || priceNum <= 0) {
      newErrors.price = 'Price must be a positive number';
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleAdd = async () => {
    if (!validateForm()) return;

    try {
      await createZoneMutation.mutateAsync({
        governorate_id: formData.governorateId,
        price: parseFloat(formData.price),
        type,
      });
      
      toast({
        title: "Success",
        description: `${config.title.slice(0, -1)} added successfully`,
      });
      
      setShowAddDialog(false);
      setFormData({ governorateId: '', price: '' });
      setErrors({});
    } catch (error) {
      toast({
        title: "Error",
        description: `Failed to add ${config.title.toLowerCase().slice(0, -1)}`,
        variant: "destructive",
      });
    }
  };

  const handleUpdate = async (zone: ShippingZone) => {
    if (!validateForm()) return;

    try {
      await updateZoneMutation.mutateAsync({
        id: zone.id,
        data: { price: parseFloat(formData.price) },
      });
      
      toast({
        title: "Success",
        description: "Shipping zone updated successfully",
      });
      
      setEditingZone(null);
      setFormData({ governorateId: '', price: '' });
      setErrors({});
    } catch (error) {
      toast({
        title: "Error",
        description: "Failed to update shipping zone",
        variant: "destructive",
      });
    }
  };

  const handleDelete = async (zone: ShippingZone) => {
    try {
      await deleteZoneMutation.mutateAsync(zone.id);
      toast({
        title: "Success",
        description: "Shipping zone deleted successfully",
      });
    } catch (error) {
      toast({
        title: "Error",
        description: "Failed to delete shipping zone",
        variant: "destructive",
      });
    }
  };

  const startEdit = (zone: ShippingZone) => {
    setEditingZone(zone);
    setFormData({ governorateId: zone.governorate.id, price: zone.price.toString() });
    setErrors({});
  };

  const cancelEdit = () => {
    setEditingZone(null);
    setFormData({ governorateId: '', price: '' });
    setErrors({});
  };

  const openAddDialog = () => {
    setShowAddDialog(true);
    setFormData({ governorateId: '', price: '' });
    setErrors({});
  };

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <div className="flex items-center space-x-2">
            <IconComponent className={`h-5 w-5 text-${config.color}-600`} />
            <CardTitle>{config.title}</CardTitle>
          </div>
          <CardDescription>{config.description}</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="animate-pulse space-y-4">
            <div className="h-4 bg-gray-200 rounded w-1/4"></div>
            <div className="h-32 bg-gray-200 rounded"></div>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className="relative overflow-hidden">
      <div className={`absolute top-0 left-0 w-full h-1 bg-gradient-to-r ${config.gradientFrom} ${config.gradientTo}`}></div>
      
      <CardHeader>
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-2">
            <IconComponent className={`h-5 w-5 text-${config.color}-600`} />
            <CardTitle>{config.title}</CardTitle>
            <Badge variant="secondary" className={`${config.badgeColor} ${config.textColor}`}>
              {zones.length} zones
            </Badge>
          </div>
          
          <Dialog open={showAddDialog} onOpenChange={setShowAddDialog}>
            <DialogTrigger asChild>
              <Button onClick={openAddDialog} className="flex items-center space-x-2">
                <Plus className="h-4 w-4" />
                <span>Add Zone</span>
              </Button>
            </DialogTrigger>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>Add {config.title.slice(0, -1)}</DialogTitle>
                <DialogDescription>
                  Select a governorate and set its shipping price
                </DialogDescription>
              </DialogHeader>
              
              <div className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="add-governorate">Governorate</Label>
                  <Select
                    value={formData.governorateId}
                    onValueChange={(value) => setFormData({ ...formData, governorateId: value })}
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
                  <Label htmlFor="add-price">Shipping Price (IQD)</Label>
                  <div className="relative">
                    <Input
                      id="add-price"
                      type="number"
                      value={formData.price}
                      onChange={(e) => setFormData({ ...formData, price: e.target.value })}
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
                    onClick={handleAdd}
                    disabled={createZoneMutation.isPending}
                    className="flex items-center space-x-2"
                  >
                    <Plus className="h-4 w-4" />
                    <span>Add Zone</span>
                  </Button>
                  <Button
                    variant="outline"
                    onClick={() => setShowAddDialog(false)}
                    className="flex items-center space-x-2"
                  >
                    <X className="h-4 w-4" />
                    <span>Cancel</span>
                  </Button>
                </div>
              </div>
            </DialogContent>
          </Dialog>
        </div>
        
        <CardDescription>{config.description}</CardDescription>
      </CardHeader>

      <CardContent className="space-y-6">
        {zones.length > 0 && (
          <div className="flex items-center space-x-2">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
              <Input
                placeholder="Search governorates..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-10"
              />
            </div>
          </div>
        )}

        {filteredZones.length === 0 ? (
          <div className={`text-center py-12 ${config.bgColor} ${config.borderColor} border rounded-lg`}>
            <IconComponent className={`mx-auto h-12 w-12 text-${config.color}-400 mb-4`} />
            <h3 className="text-lg font-medium text-gray-900 mb-2">
              {zones.length === 0 ? `No ${config.title.toLowerCase()} configured` : 'No zones found'}
            </h3>
            <p className="text-gray-600 mb-4">
              {zones.length === 0 
                ? `Add governorates to the ${config.title.toLowerCase()} category`
                : 'Try adjusting your search terms'
              }
            </p>
            {zones.length === 0 && (
              <Button onClick={openAddDialog} className="flex items-center space-x-2">
                <Plus className="h-4 w-4" />
                <span>Add First Zone</span>
              </Button>
            )}
          </div>
        ) : (
          <div className="border rounded-lg overflow-hidden">
            <Table>
              <TableHeader>
                <TableRow className={config.bgColor}>
                  <TableHead className="font-semibold">Governorate</TableHead>
                  <TableHead className="font-semibold">Arabic Name</TableHead>
                  <TableHead className="font-semibold">Shipping Price</TableHead>
                  <TableHead className="font-semibold">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredZones.map((zone) => (
                  <TableRow key={zone.id} className="hover:bg-gray-50">
                    <TableCell className="font-medium">
                      {zone.governorate.name}
                    </TableCell>
                    <TableCell className="text-gray-600">
                      {zone.governorate.nameArabic}
                    </TableCell>
                    <TableCell>
                      {editingZone?.id === zone.id ? (
                        <div className="flex items-center space-x-2">
                          <div className="relative">
                            <Input
                              type="number"
                              value={formData.price}
                              onChange={(e) => setFormData({ ...formData, price: e.target.value })}
                              className={`w-32 ${errors.price ? 'border-red-500' : ''}`}
                              min="0"
                              step="1000"
                            />
                            <span className="absolute right-2 top-1/2 transform -translate-y-1/2 text-xs text-gray-500">
                              IQD
                            </span>
                          </div>
                          {errors.price && (
                            <p className="text-xs text-red-600">{errors.price}</p>
                          )}
                        </div>
                      ) : (
                        <span className="text-green-600 font-semibold">
                          {zone.price.toLocaleString()} IQD
                        </span>
                      )}
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center space-x-2">
                        {editingZone?.id === zone.id ? (
                          <>
                            <Button
                              size="sm"
                              onClick={() => handleUpdate(zone)}
                              disabled={updateZoneMutation.isPending}
                              className="h-8 w-8 p-0"
                            >
                              <Save className="h-4 w-4" />
                            </Button>
                            <Button
                              size="sm"
                              variant="outline"
                              onClick={cancelEdit}
                              className="h-8 w-8 p-0"
                            >
                              <X className="h-4 w-4" />
                            </Button>
                          </>
                        ) : (
                          <>
                            <Button
                              size="sm"
                              variant="outline"
                              onClick={() => startEdit(zone)}
                              className="h-8 w-8 p-0"
                            >
                              <Edit2 className="h-4 w-4" />
                            </Button>
                            <Button
                              size="sm"
                              variant="outline"
                              onClick={() => handleDelete(zone)}
                              disabled={deleteZoneMutation.isPending}
                              className="h-8 w-8 p-0 text-red-600 hover:text-red-700"
                            >
                              <Trash2 className="h-4 w-4" />
                            </Button>
                          </>
                        )}
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </CardContent>
    </Card>
  );
} 