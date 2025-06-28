'use client';

import React, { useState, useEffect } from 'react';
import { Search, Star, User, X, Plus, Heart } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent } from '@/components/ui/card';
import { Checkbox } from '@/components/ui/checkbox';
import { 
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { useCelebrities } from '@/hooks/use-celebrities';
import { celebritiesService } from '@/services/celebrities';
import { apiClient } from '@/lib/api';
import { Celebrity, CelebrityListItem } from '@/types/celebrity';
import Image from 'next/image';
import { toast } from 'react-hot-toast';

export interface SelectedCelebrity {
  id: number;
  name: string;
  image?: string;
  testimonial?: string;
}

interface CelebritySelectorProps {
  selectedCelebrities: SelectedCelebrity[];
  onCelebritiesChange: (celebrities: SelectedCelebrity[]) => void;
  productName?: string;
}

export function CelebritySelector({ 
  selectedCelebrities, 
  onCelebritiesChange, 
  productName = 'this product'
}: CelebritySelectorProps) {
  const [showDialog, setShowDialog] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCelebrityIds, setSelectedCelebrityIds] = useState<Set<number>>(new Set());
  const [testimonials, setTestimonials] = useState<Record<number, string>>({});

  // Fetch celebrities
  const { data: celebritiesData, isLoading } = useCelebrities({
    search: searchQuery,
    is_active: true,
    page_size: 50,
  });

  const celebrities = celebritiesData?.results || [];

  // Initialize selected celebrities when dialog opens
  useEffect(() => {
    if (showDialog) {
      const ids = new Set(selectedCelebrities.map(c => c.id));
      setSelectedCelebrityIds(ids);
      
      const testimonialMap: Record<number, string> = {};
      selectedCelebrities.forEach(c => {
        if (c.testimonial) {
          testimonialMap[c.id] = c.testimonial;
        }
      });
      setTestimonials(testimonialMap);
    }
  }, [showDialog, selectedCelebrities]);

  const handleCelebrityToggle = (celebrity: Celebrity | CelebrityListItem, checked: boolean) => {
    const newSelectedIds = new Set(selectedCelebrityIds);
    
    if (checked) {
      newSelectedIds.add(celebrity.id);
      // Add default testimonial if none exists
      if (!testimonials[celebrity.id]) {
        setTestimonials(prev => ({
          ...prev,
          [celebrity.id]: `I absolutely love ${productName}! It's become an essential part of my routine.`
        }));
      }
    } else {
      newSelectedIds.delete(celebrity.id);
      // Remove testimonial when unchecked
      const newTestimonials = { ...testimonials };
      delete newTestimonials[celebrity.id];
      setTestimonials(newTestimonials);
    }
    
    setSelectedCelebrityIds(newSelectedIds);
  };

  const handleTestimonialChange = (celebrityId: number, testimonial: string) => {
    setTestimonials(prev => ({
      ...prev,
      [celebrityId]: testimonial
    }));
  };

  const handleSave = () => {
    const newSelectedCelebrities: SelectedCelebrity[] = [];
    
    selectedCelebrityIds.forEach(id => {
      const celebrity = celebrities.find(c => c.id === id);
      if (celebrity) {
        newSelectedCelebrities.push({
          id: celebrity.id,
          name: celebrity.full_name,
          image: celebrity.image,
          testimonial: testimonials[id] || '',
        });
      }
    });

    onCelebritiesChange(newSelectedCelebrities);
    setShowDialog(false);
    toast.success(`${newSelectedCelebrities.length} celebrities selected for product endorsement`);
  };

  const handleRemoveCelebrity = (celebrityId: number) => {
    const updatedCelebrities = selectedCelebrities.filter(c => c.id !== celebrityId);
    onCelebritiesChange(updatedCelebrities);
  };

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h4 className="text-sm font-medium text-slate-700 mb-1">Celebrity Endorsements</h4>
          <p className="text-xs text-slate-500">
            Select celebrities who will recommend this featured product
          </p>
        </div>
        <Button
          type="button"
          variant="outline"
          size="sm"
          onClick={() => setShowDialog(true)}
          className="flex items-center gap-2"
        >
          <Plus className="h-4 w-4" />
          Add Celebrities
        </Button>
      </div>

      {/* Selected Celebrities List */}
      {selectedCelebrities.length > 0 ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          {selectedCelebrities.map((celebrity) => (
            <Card key={celebrity.id} className="border border-rose-200 bg-rose-50/50">
              <CardContent className="p-4">
                <div className="flex items-start gap-3">
                  <div className="relative w-12 h-12 rounded-full overflow-hidden bg-muted flex-shrink-0">
                    {celebrity.image ? (
                      <Image
                        src={apiClient.getMediaUrl(celebrity.image)}
                        alt={celebrity.name}
                        fill
                        className="object-cover"
                      />
                    ) : (
                      <div className="w-full h-full bg-gradient-to-br from-rose-100 to-rose-200 flex items-center justify-center">
                        <User className="h-6 w-6 text-rose-600" />
                      </div>
                    )}
                  </div>
                  
                  <div className="flex-1 min-w-0">
                    <div className="flex items-start justify-between">
                      <div>
                        <h5 className="font-medium text-slate-800 text-sm truncate">
                          {celebrity.name}
                        </h5>
                        <Badge variant="outline" className="text-xs mt-1">
                          <Heart className="h-3 w-3 mr-1 text-rose-500" />
                          Endorsing
                        </Badge>
                      </div>
                      <Button
                        type="button"
                        variant="ghost"
                        size="sm"
                        onClick={() => handleRemoveCelebrity(celebrity.id)}
                        className="h-6 w-6 p-0 text-slate-400 hover:text-slate-600"
                      >
                        <X className="h-4 w-4" />
                      </Button>
                    </div>
                    
                    {celebrity.testimonial && (
                      <p className="text-xs text-slate-600 mt-2 line-clamp-2">
                        "{celebrity.testimonial}"
                      </p>
                    )}
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      ) : (
        <div className="text-center py-8 border-2 border-dashed border-slate-200 rounded-lg">
          <Heart className="h-8 w-8 text-slate-400 mx-auto mb-2" />
          <p className="text-sm text-slate-500 mb-2">No celebrity endorsements yet</p>
          <p className="text-xs text-slate-400">
            Add celebrities to endorse this featured product
          </p>
        </div>
      )}

      {/* Celebrity Selection Dialog */}
      <Dialog open={showDialog} onOpenChange={setShowDialog}>
        <DialogContent 
          className="max-w-4xl w-full h-[85vh] max-h-[85vh] flex flex-col p-0 gap-0 overflow-hidden celebrity-dialog-content"
          style={{ height: '85vh', maxHeight: '85vh' }}
        >
          <DialogHeader className="flex-shrink-0 p-6 pb-4 border-b border-slate-200">
            <DialogTitle className="flex items-center gap-2">
              <Star className="h-5 w-5 text-rose-500" />
              Select Celebrity Endorsers
            </DialogTitle>
            <DialogDescription>
              Choose celebrities who will recommend this featured product. You can add testimonials for each celebrity.
            </DialogDescription>
          </DialogHeader>

          {/* Search - Fixed at top */}
          <div className="flex-shrink-0 px-6 py-4 border-b border-slate-100">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
              <Input
                placeholder="Search celebrities by name..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-9"
              />
            </div>
          </div>

          {/* Scrollable Celebrities List */}
          <div 
            className="flex-1 min-h-0 overflow-hidden celebrity-scroll-container" 
            style={{ minHeight: 0 }}
          >
            <div 
              className="h-full overflow-y-auto celebrity-scroll celebrity-scroll-area"
              style={{ 
                height: '100%',
                overflowY: 'auto',
                scrollBehavior: 'smooth'
              }}
            >
              <div className="p-6 pt-4">
                {isLoading ? (
                  <div className="flex items-center justify-center py-12">
                    <div className="flex flex-col items-center gap-3">
                      <div className="w-8 h-8 border-2 border-rose-500 border-t-transparent rounded-full animate-spin"></div>
                      <div className="text-sm text-slate-500">Loading celebrities...</div>
                    </div>
                  </div>
                ) : celebrities.length === 0 ? (
                  <div className="text-center py-12">
                    <User className="h-12 w-12 text-slate-300 mx-auto mb-4" />
                    <p className="text-sm text-slate-500 mb-1">No celebrities found</p>
                    <p className="text-xs text-slate-400">Try adjusting your search terms</p>
                  </div>
                ) : (
                  <div className="space-y-4">
                    {celebrities.map((celebrity) => {
                      const isSelected = selectedCelebrityIds.has(celebrity.id);
                      
                      return (
                        <div key={celebrity.id} className="space-y-4">
                          <Card className={`transition-all duration-200 ${isSelected ? 'border-rose-200 bg-rose-50 shadow-sm' : 'border-slate-200 hover:border-slate-300'}`}>
                            <CardContent className="p-4">
                              <div className="flex items-start gap-4">
                                <Checkbox
                                  checked={isSelected}
                                  onCheckedChange={(checked) => 
                                    handleCelebrityToggle(celebrity, checked as boolean)
                                  }
                                  className="mt-1 flex-shrink-0"
                                />
                                
                                <div className="relative w-12 h-12 rounded-full overflow-hidden bg-muted flex-shrink-0">
                                  {celebrity.image ? (
                                    <Image
                                      src={apiClient.getMediaUrl(celebrity.image)}
                                      alt={celebrity.full_name}
                                      fill
                                      className="object-cover"
                                    />
                                  ) : (
                                    <div className="w-full h-full bg-gradient-to-br from-slate-100 to-slate-200 flex items-center justify-center">
                                      <User className="h-6 w-6 text-slate-400" />
                                    </div>
                                  )}
                                </div>
                                
                                <div className="flex-1 min-w-0">
                                  <div className="flex items-center gap-2 mb-1">
                                    <h4 className="font-medium text-slate-800">
                                      {celebrity.full_name}
                                    </h4>
                                    <Badge variant="outline" className="text-xs">
                                      <Star className="h-3 w-3 mr-1" />
                                      {celebrity.total_promotions} products
                                    </Badge>
                                  </div>
                                  
                                  {celebrity.bio && (
                                    <p className="text-sm text-slate-600 line-clamp-2 mb-2">
                                      {celebrity.bio}
                                    </p>
                                  )}
                                </div>
                              </div>
                            </CardContent>
                          </Card>
                          
                          {/* Testimonial Input for Selected Celebrity */}
                          {isSelected && (
                            <div className="ml-16 testimonial-expand">
                              <div className="bg-rose-50 border border-rose-200 rounded-lg p-4">
                                <label className="block text-sm font-medium text-slate-700 mb-2">
                                  <Heart className="h-4 w-4 inline mr-1 text-rose-500" />
                                  Testimonial from {celebrity.full_name}
                                </label>
                                <Textarea
                                  placeholder={`"I absolutely love ${productName}! It's become an essential part of my routine." - ${celebrity.full_name}`}
                                  value={testimonials[celebrity.id] || ''}
                                  onChange={(e) => handleTestimonialChange(celebrity.id, e.target.value)}
                                  rows={3}
                                  className="resize-none bg-white border-rose-200 focus:border-rose-400 focus:ring-rose-400"
                                />
                                <p className="text-xs text-slate-500 mt-2 flex items-start gap-1">
                                  <Star className="h-3 w-3 text-rose-400 mt-0.5 flex-shrink-0" />
                                  This testimonial will be shown when customers view this celebrity's recommendations.
                                </p>
                              </div>
                            </div>
                          )}
                        </div>
                      );
                    })}
                    
                    {/* Scroll indicator when there are more items */}
                    {celebrities.length >= 10 && (
                      <div className="text-center py-4 border-t border-slate-100 mt-6">
                        <p className="text-xs text-slate-400 flex items-center justify-center gap-1">
                          <Search className="h-3 w-3" />
                          Use search to find specific celebrities
                        </p>
                      </div>
                    )}
                  </div>
                )}
              </div>
            </div>
          </div>

          {/* Footer - Fixed at bottom */}
          <DialogFooter className="flex-shrink-0 p-6 pt-4 border-t border-slate-200 bg-white">
            <div className="flex items-center justify-between w-full">
              <div className="text-sm text-slate-500">
                {selectedCelebrityIds.size > 0 ? (
                  <span className="flex items-center gap-1">
                    <Heart className="h-4 w-4 text-rose-500" />
                    {selectedCelebrityIds.size} celebrity{selectedCelebrityIds.size !== 1 ? 'ies' : ''} selected
                  </span>
                ) : (
                  'No celebrities selected'
                )}
              </div>
              <div className="flex gap-3">
                <Button variant="outline" onClick={() => setShowDialog(false)}>
                  Cancel
                </Button>
                <Button 
                  onClick={handleSave} 
                  className="bg-rose-500 hover:bg-rose-600"
                  disabled={selectedCelebrityIds.size === 0}
                >
                  <Heart className="h-4 w-4 mr-2" />
                  Save Selected
                </Button>
              </div>
            </div>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
} 