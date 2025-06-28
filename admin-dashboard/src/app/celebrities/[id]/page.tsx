'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Image from 'next/image';
import { 
  User, 
  Star, 
  ExternalLink, 
  Calendar, 
  Activity,
  Edit,
  Trash2,
  Package,
  Heart,
  MapPin,
  Mail,
  Phone,
  Globe,
  ChevronLeft,
  MoreVertical,
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Separator } from '@/components/ui/separator';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { DashboardLayout } from '@/components/layout/dashboard-layout';
import { RequireAuth } from '@/components/auth/require-auth';
import { EditCelebrityDialog } from '@/components/celebrities/edit-celebrity-dialog';
import { CelebrityProductManager } from '@/components/celebrities/celebrity-product-manager';
import { useCelebrityById } from '@/hooks/use-celebrities';
import { formatDate } from '@/lib/utils';
import { apiClient } from '@/lib/api';

interface CelebrityDetailPageProps {
  params: {
    id: string;
  };
}

export default function CelebrityDetailPage({ params }: CelebrityDetailPageProps) {
  const { id } = params;
  const router = useRouter();
  const celebrityId = parseInt(id);

  // State
  const [showEditDialog, setShowEditDialog] = useState(false);

  // Data fetching
  const { data: celebrity, isLoading, error } = useCelebrityById(celebrityId);

  const handleDelete = async () => {
    if (!celebrity) return;
    
    if (!confirm(`Are you sure you want to delete ${celebrity.full_name}? This action cannot be undone.`)) {
      return;
    }

    try {
      // TODO: Implement delete celebrity functionality
      console.log('Delete celebrity:', celebrityId);
      // await deleteCelebrity(celebrityId);
      // router.push('/celebrities');
    } catch (error) {
      console.error('Failed to delete celebrity:', error);
    }
  };

  const getSocialMediaIcon = (platform: string) => {
    // Return a generic external link icon for now
    return <ExternalLink className="h-4 w-4" />;
  };

  if (isLoading) {
    return (
      <RequireAuth>
        <DashboardLayout title="Celebrity Profile">
          <div className="flex items-center justify-center min-h-[400px]">
            <div className="text-center">
              <div className="w-8 h-8 border-2 border-primary border-t-transparent rounded-full animate-spin mx-auto mb-4" />
              <p className="text-muted-foreground">Loading celebrity details...</p>
            </div>
          </div>
        </DashboardLayout>
      </RequireAuth>
    );
  }

  if (error || !celebrity) {
    return (
      <RequireAuth>
        <DashboardLayout title="Celebrity Not Found">
          <div className="flex items-center justify-center min-h-[400px]">
            <div className="text-center">
              <Package className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
              <h3 className="text-lg font-semibold text-muted-foreground mb-2">
                Celebrity not found
              </h3>
              <p className="text-sm text-muted-foreground mb-4">
                The celebrity you're looking for doesn't exist or has been removed.
              </p>
              <Button onClick={() => router.push('/celebrities')}>
                <ChevronLeft className="h-4 w-4 mr-2" />
                Back to Celebrities
              </Button>
            </div>
          </div>
        </DashboardLayout>
      </RequireAuth>
    );
  }

  return (
    <RequireAuth>
      <DashboardLayout title={celebrity.full_name}>
        <div className="flex flex-col h-full">
          <div className="flex-1 space-y-6 p-6">
            {/* Header */}
            <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 pb-6 border-b">
              <div className="flex items-center gap-4">
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => router.push('/celebrities')}
                  className="text-muted-foreground hover:text-foreground"
                >
                  <ChevronLeft className="h-4 w-4 mr-2" />
                  Back to Celebrities
                </Button>
                <Separator orientation="vertical" className="h-6 hidden sm:block" />
                <div>
                  <h1 className="text-2xl font-bold tracking-tight">Celebrity Profile</h1>
                  <p className="text-muted-foreground">
                    Manage {celebrity.full_name}'s profile and product recommendations
                  </p>
                </div>
              </div>
              
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button variant="outline" size="sm">
                    <MoreVertical className="h-4 w-4" />
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end">
                  <DropdownMenuItem onClick={() => setShowEditDialog(true)}>
                    <Edit className="h-4 w-4 mr-2" />
                    Edit Profile
                  </DropdownMenuItem>
                  <DropdownMenuSeparator />
                  <DropdownMenuItem 
                    className="text-destructive"
                    onClick={handleDelete}
                  >
                    <Trash2 className="h-4 w-4 mr-2" />
                    Delete Celebrity
                  </DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            </div>

            {/* Celebrity Profile Card */}
            <Card className="border-0 shadow-sm">
              <CardContent className="p-0">
                <div className="flex flex-col xl:flex-row">
                  {/* Profile Image Section */}
                  <div className="xl:w-80 bg-gradient-to-br from-muted/30 to-muted/10 p-8 flex flex-col items-center xl:items-start">
                    <div className="relative w-40 h-40 rounded-2xl overflow-hidden bg-white shadow-md mb-6">
                      {celebrity.image ? (
                        <Image
                          src={apiClient.getMediaUrl(celebrity.image)}
                          alt={celebrity.full_name}
                          fill
                          className="object-cover"
                          priority
                        />
                      ) : (
                        <div className="w-full h-full bg-gradient-to-br from-primary/20 to-primary/5 flex items-center justify-center">
                          <User className="h-20 w-20 text-primary/40" />
                        </div>
                      )}
                    </div>
                    
                    {/* Basic Info */}
                    <div className="text-center xl:text-left">
                      <h2 className="text-2xl font-bold text-foreground mb-2">{celebrity.full_name}</h2>
                      <div className="flex flex-wrap justify-center xl:justify-start gap-2 mb-4">
                        <Badge variant={celebrity.is_active ? 'default' : 'secondary'}>
                          {celebrity.is_active ? 'Active' : 'Inactive'}
                        </Badge>
                        <Badge variant="outline" className="flex items-center gap-1">
                          <Star className="h-3 w-3" />
                          Celebrity
                        </Badge>
                      </div>
                      
                      {/* Quick Stats */}
                      <div className="grid grid-cols-2 gap-3 text-sm">
                        <div className="text-center p-3 bg-white/50 rounded-lg">
                          <div className="text-lg font-bold text-primary">{celebrity.total_promotions}</div>
                          <div className="text-xs text-muted-foreground">Products</div>
                        </div>
                        <div className="text-center p-3 bg-white/50 rounded-lg">
                          <div className="text-lg font-bold text-rose-600">{celebrity.featured_promotions_count}</div>
                          <div className="text-xs text-muted-foreground">Featured</div>
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* Profile Info */}
                  <div className="flex-1 p-8 space-y-8">
                    {/* Bio */}
                    {celebrity.bio && (
                      <div>
                        <h3 className="text-lg font-semibold text-foreground mb-3">Biography</h3>
                        <p className="text-muted-foreground leading-relaxed">{celebrity.bio}</p>
                      </div>
                    )}

                    {/* Social Media Links */}
                    {Object.keys(celebrity.social_media_links).length > 0 && (
                      <div>
                        <h3 className="text-lg font-semibold text-foreground mb-3">Social Media</h3>
                        <div className="flex flex-wrap gap-3">
                          {Object.entries(celebrity.social_media_links).map(([platform, url]) => (
                            <a
                              key={platform}
                              href={url}
                              target="_blank"
                              rel="noopener noreferrer"
                              className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-muted hover:bg-muted/80 transition-colors text-sm font-medium"
                            >
                              {getSocialMediaIcon(platform)}
                              <span className="capitalize">{platform}</span>
                              <ExternalLink className="h-3 w-3" />
                            </a>
                          ))}
                        </div>
                      </div>
                    )}

                    {/* Detailed Statistics */}
                    <div>
                      <h3 className="text-lg font-semibold text-foreground mb-4">Product Statistics</h3>
                      <div className="grid grid-cols-2 gap-4">
                        <div className="p-4 bg-amber-50 rounded-xl border border-amber-100">
                          <div className="flex items-center gap-3">
                            <div className="p-2 bg-amber-100 rounded-lg">
                              <Package className="h-5 w-5 text-amber-600" />
                            </div>
                            <div>
                              <div className="text-2xl font-bold text-amber-600">{celebrity.morning_routine_count}</div>
                              <div className="text-sm text-muted-foreground">Morning Routine</div>
                            </div>
                          </div>
                        </div>
                        <div className="p-4 bg-blue-50 rounded-xl border border-blue-100">
                          <div className="flex items-center gap-3">
                            <div className="p-2 bg-blue-100 rounded-lg">
                              <Package className="h-5 w-5 text-blue-600" />
                            </div>
                            <div>
                              <div className="text-2xl font-bold text-blue-600">{celebrity.evening_routine_count}</div>
                              <div className="text-sm text-muted-foreground">Evening Routine</div>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>

                    {/* Metadata */}
                    <div className="flex flex-wrap items-center gap-6 pt-4 border-t text-sm text-muted-foreground">
                      <div className="flex items-center gap-2">
                        <Calendar className="h-4 w-4" />
                        <span>Created {formatDate(celebrity.created_at)}</span>
                      </div>
                      <div className="flex items-center gap-2">
                        <Activity className="h-4 w-4" />
                        <span>Updated {formatDate(celebrity.updated_at)}</span>
                      </div>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Product Management */}
            <CelebrityProductManager celebrity={celebrity} />

            {/* Edit Dialog */}
            {showEditDialog && (
              <EditCelebrityDialog
                celebrity={celebrity}
                open={showEditDialog}
                onOpenChange={setShowEditDialog}
              />
            )}
          </div>
        </div>
      </DashboardLayout>
    </RequireAuth>
  );
} 