'use client';

import React, { useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import Image from 'next/image';
import Link from 'next/link';
import { 
  ArrowLeft,
  Edit,
  Star,
  Instagram,
  Facebook,
  MessageCircle,
  ExternalLink,
  User,
  Calendar,
  Activity,
  Package,
  Sun,
  Moon,
  TrendingUp,
  Plus,
  Trash2,
  Eye,
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Separator } from '@/components/ui/separator';
import { RequireAuth } from '@/components/auth/require-auth';
import { DashboardLayout } from '@/components/layout/dashboard-layout';
import { 
  useCelebrity, 
  useCelebrityPromotions,
  useMorningRoutine,
  useEveningRoutine,
  useDeleteCelebrity,
  useDeleteMorningRoutineItem,
  useDeleteEveningRoutineItem,
} from '@/hooks/use-celebrities';
import { formatDate } from '@/lib/utils';
import { apiClient } from '@/lib/api';
import { EditCelebrityDialog } from '@/components/celebrities/edit-celebrity-dialog';
import { AddRoutineDialog } from '@/components/celebrities/add-routine-dialog';
import { EditRoutineDialog } from '@/components/celebrities/edit-routine-dialog';

export default function CelebrityDetailPage() {
  const params = useParams();
  const router = useRouter();
  const celebrityId = parseInt(params.id as string);
  
  const [activeTab, setActiveTab] = useState('overview');
  const [showEditDialog, setShowEditDialog] = useState(false);
  const [showAddRoutineDialog, setShowAddRoutineDialog] = useState(false);
  const [routineDialogType, setRoutineDialogType] = useState<'morning' | 'evening'>('morning');
  const [editingRoutineItem, setEditingRoutineItem] = useState<any>(null);
  const [showEditRoutineDialog, setShowEditRoutineDialog] = useState(false);

  // API hooks
  const { data: celebrity, isLoading, error } = useCelebrity(celebrityId);
  const { data: promotions } = useCelebrityPromotions(celebrityId);
  const { data: morningRoutine } = useMorningRoutine(celebrityId);
  const { data: eveningRoutine } = useEveningRoutine(celebrityId);
  const deleteCelebrity = useDeleteCelebrity();
  const deleteMorningItem = useDeleteMorningRoutineItem();
  const deleteEveningItem = useDeleteEveningRoutineItem();

  const handleDelete = async () => {
    if (!celebrity) return;
    
    if (confirm(`Are you sure you want to delete ${celebrity.full_name}? This action cannot be undone.`)) {
      try {
        await deleteCelebrity.mutateAsync(celebrity.id);
        router.push('/celebrities');
      } catch (error) {
        console.error('Failed to delete celebrity:', error);
      }
    }
  };

  const handleAddRoutineStep = (type: 'morning' | 'evening') => {
    setRoutineDialogType(type);
    setShowAddRoutineDialog(true);
  };

  const handleEditRoutineStep = (item: any, type: 'morning' | 'evening') => {
    setEditingRoutineItem(item);
    setRoutineDialogType(type);
    setShowEditRoutineDialog(true);
  };

  const handleDeleteRoutineStep = async (item: any, type: 'morning' | 'evening') => {
    if (!celebrity || !confirm(`Are you sure you want to remove this step from the ${type} routine?`)) {
      return;
    }

    try {
      if (type === 'morning') {
        await deleteMorningItem.mutateAsync({ 
          itemId: item.id, 
          celebrityId: celebrity.id 
        });
      } else {
        await deleteEveningItem.mutateAsync({ 
          itemId: item.id, 
          celebrityId: celebrity.id 
        });
      }
    } catch (error) {
      console.error('Failed to delete routine step:', error);
    }
  };

  const getSocialMediaIcon = (platform: string) => {
    switch (platform) {
      case 'instagram': return <Instagram className="h-4 w-4" />;
      case 'facebook': return <Facebook className="h-4 w-4" />;
      case 'snapchat': return <MessageCircle className="h-4 w-4" />;
      default: return <ExternalLink className="h-4 w-4" />;
    }
  };

  // Loading state
  if (isLoading) {
    return (
      <RequireAuth>
        <DashboardLayout title="Celebrity Details">
          <Card>
            <CardContent className="flex items-center justify-center py-12">
              <div className="flex items-center space-x-2">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
                <span className="text-muted-foreground">Loading celebrity details...</span>
              </div>
            </CardContent>
          </Card>
        </DashboardLayout>
      </RequireAuth>
    );
  }

  // Error state
  if (error || !celebrity) {
    return (
      <RequireAuth>
        <DashboardLayout title="Celebrity Not Found">
          <Card>
            <CardContent className="flex flex-col items-center justify-center py-12">
              <div className="text-center">
                <div className="text-destructive mb-2">Celebrity not found</div>
                <p className="text-sm text-muted-foreground mb-4">
                  The celebrity you're looking for doesn't exist or has been removed.
                </p>
                <Link href="/celebrities">
                  <Button>
                    <ArrowLeft className="h-4 w-4 mr-2" />
                    Back to Celebrities
                  </Button>
                </Link>
              </div>
            </CardContent>
          </Card>
        </DashboardLayout>
      </RequireAuth>
    );
  }

  return (
    <RequireAuth>
      <DashboardLayout title={celebrity.full_name}>
        <div className="space-y-6">
          {/* Header */}
          <div className="flex items-center gap-4">
            <Link href="/celebrities">
              <Button variant="outline" size="sm">
                <ArrowLeft className="h-4 w-4 mr-2" />
                Back to Celebrities
              </Button>
            </Link>
            <div className="flex-1" />
            <Button
              variant="outline"
              onClick={() => setShowEditDialog(true)}
            >
              <Edit className="h-4 w-4 mr-2" />
              Edit Celebrity
            </Button>
            <Button
              variant="destructive"
              onClick={handleDelete}
              disabled={deleteCelebrity.isPending}
            >
              <Trash2 className="h-4 w-4 mr-2" />
              Delete
            </Button>
          </div>

          {/* Celebrity Profile Card */}
          <Card>
            <CardContent className="p-6">
              <div className="flex flex-col md:flex-row gap-6">
                {/* Profile Image */}
                <div className="flex-shrink-0">
                  <div className="relative w-32 h-32 rounded-full overflow-hidden bg-muted">
                    {celebrity.image ? (
                      <Image
                        src={apiClient.getMediaUrl(celebrity.image)}
                        alt={celebrity.full_name}
                        fill
                        className="object-cover"
                      />
                    ) : (
                      <div className="w-full h-full bg-gradient-to-br from-primary/20 to-primary/5 flex items-center justify-center">
                        <User className="h-16 w-16 text-primary/40" />
                      </div>
                    )}
                  </div>
                </div>

                {/* Profile Info */}
                <div className="flex-1">
                  <div className="flex items-start justify-between mb-4">
                    <div>
                      <h1 className="text-3xl font-bold text-foreground">{celebrity.full_name}</h1>
                      <div className="flex items-center gap-2 mt-2">
                        <Badge variant={celebrity.is_active ? 'default' : 'secondary'}>
                          {celebrity.is_active ? 'Active' : 'Inactive'}
                        </Badge>
                        <Badge variant="outline" className="flex items-center gap-1">
                          <Star className="h-3 w-3" />
                          Celebrity
                        </Badge>
                      </div>
                    </div>
                  </div>

                  {/* Bio */}
                  {celebrity.bio && (
                    <div className="mb-4">
                      <p className="text-muted-foreground leading-relaxed">{celebrity.bio}</p>
                    </div>
                  )}

                  {/* Social Media Links */}
                  {Object.keys(celebrity.social_media_links).length > 0 && (
                    <div className="mb-4">
                      <h3 className="text-sm font-medium text-foreground mb-2">Social Media</h3>
                      <div className="flex items-center gap-2">
                        {Object.entries(celebrity.social_media_links).map(([platform, url]) => (
                          <a
                            key={platform}
                            href={url}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="flex items-center gap-2 px-3 py-1 rounded-lg bg-muted hover:bg-muted/80 transition-colors text-sm"
                          >
                            {getSocialMediaIcon(platform)}
                            <span className="capitalize">{platform}</span>
                            <ExternalLink className="h-3 w-3" />
                          </a>
                        ))}
                      </div>
                    </div>
                  )}

                  {/* Stats */}
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                    <div className="text-center p-3 bg-muted/50 rounded-lg">
                      <div className="text-2xl font-bold text-primary">{celebrity.total_promotions}</div>
                      <div className="text-xs text-muted-foreground">Total Promotions</div>
                    </div>
                    <div className="text-center p-3 bg-muted/50 rounded-lg">
                      <div className="text-2xl font-bold text-amber-600">{celebrity.featured_promotions_count}</div>
                      <div className="text-xs text-muted-foreground">Featured</div>
                    </div>
                    <div className="text-center p-3 bg-muted/50 rounded-lg">
                      <div className="text-2xl font-bold text-orange-600">{celebrity.morning_routine_count}</div>
                      <div className="text-xs text-muted-foreground">Morning Items</div>
                    </div>
                    <div className="text-center p-3 bg-muted/50 rounded-lg">
                      <div className="text-2xl font-bold text-blue-600">{celebrity.evening_routine_count}</div>
                      <div className="text-xs text-muted-foreground">Evening Items</div>
                    </div>
                  </div>

                  {/* Metadata */}
                  <div className="flex items-center gap-4 mt-4 text-sm text-muted-foreground">
                    <div className="flex items-center gap-1">
                      <Calendar className="h-4 w-4" />
                      Created {formatDate(celebrity.created_at)}
                    </div>
                    <div className="flex items-center gap-1">
                      <Activity className="h-4 w-4" />
                      Updated {formatDate(celebrity.updated_at)}
                    </div>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Tabs Content */}
          <Tabs value={activeTab} onValueChange={setActiveTab}>
            <TabsList className="grid w-full grid-cols-3">
              <TabsTrigger value="overview" className="flex items-center gap-2">
                <TrendingUp className="h-4 w-4" />
                Promotions
              </TabsTrigger>
              <TabsTrigger value="morning" className="flex items-center gap-2">
                <Sun className="h-4 w-4" />
                Morning Routine
              </TabsTrigger>
              <TabsTrigger value="evening" className="flex items-center gap-2">
                <Moon className="h-4 w-4" />
                Evening Routine
              </TabsTrigger>
            </TabsList>

            {/* Product Promotions Tab */}
            <TabsContent value="overview" className="space-y-4">
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center justify-between">
                    <span className="flex items-center gap-2">
                      <Package className="h-5 w-5" />
                      Product Promotions ({promotions?.promotions.length || 0})
                    </span>
                    <Button size="sm">
                      <Plus className="h-4 w-4 mr-2" />
                      Add Promotion
                    </Button>
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  {promotions?.promotions && promotions.promotions.length > 0 ? (
                    <div className="grid gap-4">
                      {promotions.promotions.map((promotion) => (
                        <div
                          key={promotion.id}
                          className="flex items-center gap-4 p-4 border rounded-lg hover:bg-muted/50 transition-colors"
                        >
                          <div className="relative w-16 h-16 rounded-lg overflow-hidden bg-muted">
                            {promotion.product.featured_image ? (
                              <Image
                                src={apiClient.getMediaUrl(promotion.product.featured_image)}
                                alt={promotion.product.name}
                                fill
                                className="object-cover"
                              />
                            ) : (
                              <div className="w-full h-full bg-gradient-to-br from-muted to-muted/50 flex items-center justify-center">
                                <Package className="h-6 w-6 text-muted-foreground" />
                              </div>
                            )}
                          </div>
                          
                          <div className="flex-1">
                            <h4 className="font-medium text-foreground">{promotion.product.name}</h4>
                            {promotion.product.brand && (
                              <p className="text-sm text-muted-foreground">by {promotion.product.brand.name}</p>
                            )}
                            {promotion.testimonial && (
                              <p className="text-sm text-muted-foreground mt-1 line-clamp-2">
                                "{promotion.testimonial}"
                              </p>
                            )}
                            <div className="flex items-center gap-2 mt-2">
                              <Badge variant="secondary" className="text-xs">
                                {promotion.promotion_type.replace('_', ' ')}
                              </Badge>
                              {promotion.is_featured && (
                                <Badge variant="default" className="text-xs">
                                  <Star className="h-3 w-3 mr-1" />
                                  Featured
                                </Badge>
                              )}
                            </div>
                          </div>
                          
                          <div className="text-right">
                            <div className="text-lg font-bold text-primary">
                              ${promotion.product.price}
                            </div>
                            <div className="flex items-center gap-1 mt-2">
                              <Button variant="ghost" size="sm">
                                <Eye className="h-4 w-4" />
                              </Button>
                              <Button variant="ghost" size="sm">
                                <Edit className="h-4 w-4" />
                              </Button>
                              <Button variant="ghost" size="sm" className="text-destructive">
                                <Trash2 className="h-4 w-4" />
                              </Button>
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <div className="text-center py-8 text-muted-foreground">
                      <Package className="h-8 w-8 mx-auto mb-2 opacity-50" />
                      <p>No product promotions yet</p>
                      <Button size="sm" className="mt-2">
                        Add first promotion
                      </Button>
                    </div>
                  )}
                </CardContent>
              </Card>
            </TabsContent>

            {/* Morning Routine Tab */}
            <TabsContent value="morning" className="space-y-4">
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center justify-between">
                    <span className="flex items-center gap-2">
                      <Sun className="h-5 w-5" />
                      Morning Routine ({morningRoutine?.morning_routine.length || 0} steps)
                    </span>
                    <Button 
                      size="sm"
                      onClick={() => handleAddRoutineStep('morning')}
                    >
                      <Plus className="h-4 w-4 mr-2" />
                      Add Step
                    </Button>
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  {morningRoutine?.morning_routine && morningRoutine.morning_routine.length > 0 ? (
                    <div className="space-y-4">
                      {morningRoutine.morning_routine.map((item) => (
                        <div
                          key={item.id}
                          className="flex items-center gap-4 p-4 border rounded-lg"
                        >
                          <div className="flex-shrink-0 w-8 h-8 rounded-full bg-primary text-primary-foreground flex items-center justify-center text-sm font-medium">
                            {item.order}
                          </div>
                          
                          <div className="relative w-12 h-12 rounded-lg overflow-hidden bg-muted">
                            {item.product.featured_image ? (
                              <Image
                                src={apiClient.getMediaUrl(item.product.featured_image)}
                                alt={item.product.name}
                                fill
                                className="object-cover"
                              />
                            ) : (
                              <div className="w-full h-full bg-gradient-to-br from-muted to-muted/50 flex items-center justify-center">
                                <Package className="h-5 w-5 text-muted-foreground" />
                              </div>
                            )}
                          </div>
                          
                          <div className="flex-1">
                            <h4 className="font-medium text-foreground">{item.product.name}</h4>
                            {item.product.brand && (
                              <p className="text-sm text-muted-foreground">by {item.product.brand.name}</p>
                            )}
                            {item.description && (
                              <p className="text-sm text-muted-foreground mt-1">{item.description}</p>
                            )}
                          </div>
                          
                          <div className="flex items-center gap-1">
                            <Button 
                              variant="ghost" 
                              size="sm"
                              onClick={() => handleEditRoutineStep(item, 'morning')}
                            >
                              <Edit className="h-4 w-4" />
                            </Button>
                            <Button 
                              variant="ghost" 
                              size="sm" 
                              className="text-destructive"
                              onClick={() => handleDeleteRoutineStep(item, 'morning')}
                            >
                              <Trash2 className="h-4 w-4" />
                            </Button>
                          </div>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <div className="text-center py-8 text-muted-foreground">
                      <Sun className="h-8 w-8 mx-auto mb-2 opacity-50" />
                      <p>No morning routine steps yet</p>
                      <Button 
                        size="sm" 
                        className="mt-2"
                        onClick={() => handleAddRoutineStep('morning')}
                      >
                        Add first step
                      </Button>
                    </div>
                  )}
                </CardContent>
              </Card>
            </TabsContent>

            {/* Evening Routine Tab */}
            <TabsContent value="evening" className="space-y-4">
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center justify-between">
                    <span className="flex items-center gap-2">
                      <Moon className="h-5 w-5" />
                      Evening Routine ({eveningRoutine?.evening_routine.length || 0} steps)
                    </span>
                    <Button 
                      size="sm"
                      onClick={() => handleAddRoutineStep('evening')}
                    >
                      <Plus className="h-4 w-4 mr-2" />
                      Add Step
                    </Button>
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  {eveningRoutine?.evening_routine && eveningRoutine.evening_routine.length > 0 ? (
                    <div className="space-y-4">
                      {eveningRoutine.evening_routine.map((item) => (
                        <div
                          key={item.id}
                          className="flex items-center gap-4 p-4 border rounded-lg"
                        >
                          <div className="flex-shrink-0 w-8 h-8 rounded-full bg-blue-600 text-white flex items-center justify-center text-sm font-medium">
                            {item.order}
                          </div>
                          
                          <div className="relative w-12 h-12 rounded-lg overflow-hidden bg-muted">
                            {item.product.featured_image ? (
                              <Image
                                src={apiClient.getMediaUrl(item.product.featured_image)}
                                alt={item.product.name}
                                fill
                                className="object-cover"
                              />
                            ) : (
                              <div className="w-full h-full bg-gradient-to-br from-muted to-muted/50 flex items-center justify-center">
                                <Package className="h-5 w-5 text-muted-foreground" />
                              </div>
                            )}
                          </div>
                          
                          <div className="flex-1">
                            <h4 className="font-medium text-foreground">{item.product.name}</h4>
                            {item.product.brand && (
                              <p className="text-sm text-muted-foreground">by {item.product.brand.name}</p>
                            )}
                            {item.description && (
                              <p className="text-sm text-muted-foreground mt-1">{item.description}</p>
                            )}
                          </div>
                          
                          <div className="flex items-center gap-1">
                            <Button 
                              variant="ghost" 
                              size="sm"
                              onClick={() => handleEditRoutineStep(item, 'evening')}
                            >
                              <Edit className="h-4 w-4" />
                            </Button>
                            <Button 
                              variant="ghost" 
                              size="sm" 
                              className="text-destructive"
                              onClick={() => handleDeleteRoutineStep(item, 'evening')}
                            >
                              <Trash2 className="h-4 w-4" />
                            </Button>
                          </div>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <div className="text-center py-8 text-muted-foreground">
                      <Moon className="h-8 w-8 mx-auto mb-2 opacity-50" />
                      <p>No evening routine steps yet</p>
                      <Button 
                        size="sm" 
                        className="mt-2"
                        onClick={() => handleAddRoutineStep('evening')}
                      >
                        Add first step
                      </Button>
                    </div>
                  )}
                </CardContent>
              </Card>
            </TabsContent>
          </Tabs>

          {/* Edit Dialog */}
          {showEditDialog && (
            <EditCelebrityDialog
              celebrity={celebrity}
              open={showEditDialog}
              onOpenChange={setShowEditDialog}
            />
          )}

          {/* Add Routine Dialog */}
          <AddRoutineDialog
            celebrityId={celebrityId}
            celebrityName={celebrity.full_name}
            routineType={routineDialogType}
            open={showAddRoutineDialog}
            onOpenChange={setShowAddRoutineDialog}
          />

          {/* Edit Routine Dialog */}
          {editingRoutineItem && (
            <EditRoutineDialog
              routineItem={editingRoutineItem}
              routineType={routineDialogType}
              open={showEditRoutineDialog}
              onOpenChange={(open) => {
                setShowEditRoutineDialog(open);
                if (!open) {
                  setEditingRoutineItem(null);
                }
              }}
            />
          )}
        </div>
      </DashboardLayout>
    </RequireAuth>
  );
} 