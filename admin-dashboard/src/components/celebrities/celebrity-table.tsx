'use client';

import React, { useState, useMemo, useCallback } from 'react';
import Image from 'next/image';
import Link from 'next/link';
import { 
  Plus, 
  Search, 
  Filter, 
  MoreHorizontal, 
  Edit, 
  Trash2, 
  Eye,
  Star,
  Users,
  Instagram,
  Facebook,
  MessageCircle,
  ExternalLink,
  CheckSquare,
  Square,
  Download,
  Upload,
  Settings,
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Checkbox } from '@/components/ui/checkbox';
import { 
  useCelebrities, 
  useCelebrityStats, 
  useDeleteCelebrity, 
  useBulkDeleteCelebrities,
  useBulkUpdateCelebrities,
} from '@/hooks/use-celebrities';
import { CelebrityFilters, CelebrityListItem } from '@/types/celebrity';
import { formatDate, cn, debounce } from '@/lib/utils';
import { apiClient } from '@/lib/api';
import { AddCelebrityDialog } from '@/components/celebrities/add-celebrity-dialog';
import { EditCelebrityDialog } from '@/components/celebrities/edit-celebrity-dialog';

const ITEMS_PER_PAGE = 20;

export function CelebrityTable() {
  // State management
  const [filters, setFilters] = useState<CelebrityFilters>({
    page: 1,
    page_size: ITEMS_PER_PAGE,
    ordering: '-created_at',
  });
  const [selectedCelebrities, setSelectedCelebrities] = useState<number[]>([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [showAddDialog, setShowAddDialog] = useState(false);
  const [editingCelebrity, setEditingCelebrity] = useState<CelebrityListItem | null>(null);
  const [showFilters, setShowFilters] = useState(false);

  // API hooks
  const { data: celebritiesResponse, isLoading, error } = useCelebrities(filters);
  const { data: stats } = useCelebrityStats();
  const deleteCelebrity = useDeleteCelebrity();
  const bulkDeleteCelebrities = useBulkDeleteCelebrities();
  const bulkUpdateCelebrities = useBulkUpdateCelebrities();

  const celebrities = (celebritiesResponse as any)?.results || [];
  const totalCount = (celebritiesResponse as any)?.count || 0;
  const totalPages = Math.ceil(totalCount / ITEMS_PER_PAGE);

  // Debounced search
  const debouncedSearch = useCallback(
    debounce((query: string) => {
      setFilters(prev => ({ 
        ...prev, 
        search: query || undefined, 
        page: 1 
      }));
    }, 300),
    []
  );

  // Handlers
  const handleSearchChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    setSearchQuery(value);
    debouncedSearch(value);
  };

  const handleStatusFilter = (status: string) => {
    setFilters(prev => ({
      ...prev,
      is_active: status === 'all' ? undefined : status === 'active',
      page: 1,
    }));
  };

  const handleSort = (field: string) => {
    setFilters(prev => ({
      ...prev,
      ordering: prev.ordering === field ? `-${field}` : field,
      page: 1,
    }));
  };

  const handlePageChange = (page: number) => {
    setFilters(prev => ({ ...prev, page }));
  };

  const handleSelectCelebrity = (id: number, checked: boolean) => {
    setSelectedCelebrities(prev => 
      checked 
        ? [...prev, id]
        : prev.filter(celebId => celebId !== id)
    );
  };

  const handleSelectAll = (checked: boolean) => {
    setSelectedCelebrities(checked ? celebrities.map((c: any) => c.id) : []);
  };

  const handleDelete = async (id: number) => {
    if (confirm('Are you sure you want to delete this celebrity?')) {
      try {
        await deleteCelebrity.mutateAsync(id);
        setSelectedCelebrities(prev => prev.filter(celebId => celebId !== id));
      } catch (error) {
        console.error('Failed to delete celebrity:', error);
      }
    }
  };

  const handleBulkDelete = async () => {
    if (selectedCelebrities.length === 0) return;
    
    if (confirm(`Are you sure you want to delete ${selectedCelebrities.length} celebrities?`)) {
      try {
        await bulkDeleteCelebrities.mutateAsync(selectedCelebrities);
        setSelectedCelebrities([]);
      } catch (error) {
        console.error('Failed to bulk delete celebrities:', error);
      }
    }
  };

  const handleBulkStatusUpdate = async (isActive: boolean) => {
    if (selectedCelebrities.length === 0) return;
    
    try {
      await bulkUpdateCelebrities.mutateAsync({
        celebrityIds: selectedCelebrities,
        updates: { is_active: isActive },
      });
      setSelectedCelebrities([]);
    } catch (error) {
      console.error('Failed to update celebrity status:', error);
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
  if (isLoading && !celebrities.length) {
    return (
      <Card>
        <CardContent className="flex items-center justify-center py-12">
          <div className="flex items-center space-x-2">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
            <span className="text-muted-foreground">Loading celebrities...</span>
          </div>
        </CardContent>
      </Card>
    );
  }

  // Error state
  if (error) {
    return (
      <Card>
        <CardContent className="flex items-center justify-center py-12">
          <div className="text-center">
            <div className="text-destructive mb-2">Error loading celebrities</div>
            <p className="text-sm text-muted-foreground">
              {error.message || 'Something went wrong'}
            </p>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-6">
      {/* Stats Cards */}
      {stats && (
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Total Celebrities</CardTitle>
              <Users className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.total_celebrities}</div>
              <p className="text-xs text-muted-foreground">
                {stats.active_celebrities} active
              </p>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Total Promotions</CardTitle>
              <Star className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.total_promotions}</div>
              <p className="text-xs text-muted-foreground">
                {stats.featured_promotions} featured
              </p>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Routine Items</CardTitle>
              <Settings className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.total_routine_items}</div>
              <p className="text-xs text-muted-foreground">
                Morning & evening routines
              </p>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Active Rate</CardTitle>
              <CheckSquare className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">
                {stats.total_celebrities > 0 
                  ? Math.round((stats.active_celebrities / stats.total_celebrities) * 100)
                  : 0}%
              </div>
              <p className="text-xs text-muted-foreground">
                Celebrity activation rate
              </p>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Table Card */}
      <Card>
        <CardHeader>
          <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
            <CardTitle className="flex items-center gap-2">
              <Star className="h-5 w-5" />
              Celebrities ({totalCount})
            </CardTitle>
            
            <div className="flex items-center gap-2">
              <Button
                size="sm"
                onClick={() => setShowAddDialog(true)}
                className="bg-primary hover:bg-primary/90"
              >
                <Plus className="h-4 w-4 mr-2" />
                Add Celebrity
              </Button>
            </div>
          </div>

          {/* Search and Filters */}
          <div className="flex flex-col gap-4 sm:flex-row sm:items-center">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Search celebrities..."
                value={searchQuery}
                onChange={handleSearchChange}
                className="pl-10"
              />
            </div>
            
            <div className="flex items-center gap-2">
              <Select onValueChange={handleStatusFilter}>
                <SelectTrigger className="w-32">
                  <SelectValue placeholder="Status" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Status</SelectItem>
                  <SelectItem value="active">Active</SelectItem>
                  <SelectItem value="inactive">Inactive</SelectItem>
                </SelectContent>
              </Select>
              
              <Button
                variant="outline"
                size="sm"
                onClick={() => setShowFilters(!showFilters)}
              >
                <Filter className="h-4 w-4 mr-2" />
                Filters
              </Button>
            </div>
          </div>

          {/* Bulk Actions */}
          {selectedCelebrities.length > 0 && (
            <div className="flex items-center gap-2 p-3 bg-muted/50 rounded-lg">
              <span className="text-sm text-muted-foreground">
                {selectedCelebrities.length} selected
              </span>
              <div className="flex items-center gap-1 ml-auto">
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => handleBulkStatusUpdate(true)}
                >
                  Activate
                </Button>
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => handleBulkStatusUpdate(false)}
                >
                  Deactivate
                </Button>
                <Button
                  size="sm"
                  variant="destructive"
                  onClick={handleBulkDelete}
                >
                  <Trash2 className="h-4 w-4 mr-1" />
                  Delete
                </Button>
              </div>
            </div>
          )}
        </CardHeader>

        <CardContent>
          {/* Desktop Table */}
          <div className="hidden md:block overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b text-left">
                  <th className="pb-3 w-12">
                    <Checkbox
                      checked={selectedCelebrities.length === celebrities.length && celebrities.length > 0}
                      onCheckedChange={handleSelectAll}
                    />
                  </th>
                  <th 
                    className="pb-3 font-medium text-foreground cursor-pointer hover:text-primary"
                    onClick={() => handleSort('full_name')}
                  >
                    Celebrity
                  </th>
                  <th className="pb-3 font-medium text-foreground">Social Media</th>
                  <th 
                    className="pb-3 font-medium text-foreground cursor-pointer hover:text-primary"
                    onClick={() => handleSort('total_promotions')}
                  >
                    Promotions
                  </th>
                  <th className="pb-3 font-medium text-foreground">Status</th>
                  <th 
                    className="pb-3 font-medium text-foreground cursor-pointer hover:text-primary"
                    onClick={() => handleSort('created_at')}
                  >
                    Created
                  </th>
                  <th className="pb-3 font-medium text-foreground">Actions</th>
                </tr>
              </thead>
              <tbody>
                {celebrities.map((celebrity: any) => (
                  <CelebrityTableRow
                    key={celebrity.id}
                    celebrity={celebrity}
                    isSelected={selectedCelebrities.includes(celebrity.id)}
                    onSelect={handleSelectCelebrity}
                    onEdit={setEditingCelebrity}
                    onDelete={handleDelete}
                  />
                ))}
                {celebrities.length === 0 && (
                  <tr>
                    <td colSpan={7} className="py-12 text-center text-muted-foreground">
                      <div className="flex flex-col items-center gap-2">
                        <Star className="h-8 w-8 text-muted-foreground/50" />
                        <span>No celebrities found</span>
                        <Button onClick={() => setShowAddDialog(true)} size="sm">
                          Add your first celebrity
                        </Button>
                      </div>
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>

          {/* Mobile Cards */}
          <div className="md:hidden space-y-4">
            {celebrities.map((celebrity: any) => (
              <CelebrityMobileCard
                key={celebrity.id}
                celebrity={celebrity}
                isSelected={selectedCelebrities.includes(celebrity.id)}
                onSelect={handleSelectCelebrity}
                onEdit={setEditingCelebrity}
                onDelete={handleDelete}
              />
            ))}
            {celebrities.length === 0 && (
              <div className="py-12 text-center">
                <Star className="h-8 w-8 text-muted-foreground/50 mx-auto mb-2" />
                <p className="text-muted-foreground mb-4">No celebrities found</p>
                <Button onClick={() => setShowAddDialog(true)} size="sm">
                  Add your first celebrity
                </Button>
              </div>
            )}
          </div>

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="flex items-center justify-between mt-6">
              <div className="text-sm text-muted-foreground">
                Showing {((filters.page || 1) - 1) * ITEMS_PER_PAGE + 1} to{' '}
                {Math.min((filters.page || 1) * ITEMS_PER_PAGE, totalCount)} of {totalCount} celebrities
              </div>
              <div className="flex items-center gap-2">
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => handlePageChange((filters.page || 1) - 1)}
                  disabled={(filters.page || 1) <= 1}
                >
                  Previous
                </Button>
                <span className="text-sm">
                  Page {filters.page || 1} of {totalPages}
                </span>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => handlePageChange((filters.page || 1) + 1)}
                  disabled={(filters.page || 1) >= totalPages}
                >
                  Next
                </Button>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Dialogs */}
      <AddCelebrityDialog 
        open={showAddDialog} 
        onOpenChange={setShowAddDialog} 
      />
      
      {editingCelebrity && (
        <EditCelebrityDialog
          celebrity={editingCelebrity}
          open={!!editingCelebrity}
          onOpenChange={(open) => !open && setEditingCelebrity(null)}
        />
      )}
    </div>
  );
}

// Celebrity Table Row Component
interface CelebrityTableRowProps {
  celebrity: CelebrityListItem;
  isSelected: boolean;
  onSelect: (id: number, checked: boolean) => void;
  onEdit: (celebrity: CelebrityListItem) => void;
  onDelete: (id: number) => void;
}

function CelebrityTableRow({ celebrity, isSelected, onSelect, onEdit, onDelete }: CelebrityTableRowProps) {
  const getSocialMediaIcon = (platform: string) => {
    switch (platform) {
      case 'instagram': return <Instagram className="h-4 w-4" />;
      case 'facebook': return <Facebook className="h-4 w-4" />;
      case 'snapchat': return <MessageCircle className="h-4 w-4" />;
      default: return <ExternalLink className="h-4 w-4" />;
    }
  };

  return (
    <tr className="border-b hover:bg-muted/50 transition-colors">
      <td className="py-4">
        <Checkbox
          checked={isSelected}
          onCheckedChange={(checked) => onSelect(celebrity.id, !!checked)}
        />
      </td>
      <td className="py-4">
        <div className="flex items-center gap-3">
          <div className="relative w-10 h-10 rounded-full overflow-hidden bg-muted">
            {celebrity.image ? (
              <Image
                src={apiClient.getMediaUrl(celebrity.image)}
                alt={celebrity.full_name}
                fill
                className="object-cover"
              />
            ) : (
              <div className="w-full h-full bg-gradient-to-br from-primary/20 to-primary/5 flex items-center justify-center">
                <span className="text-sm font-medium text-primary">
                  {celebrity.first_name[0]}{celebrity.last_name[0]}
                </span>
              </div>
            )}
          </div>
          <div>
            <div className="font-medium text-foreground">{celebrity.full_name}</div>
            {celebrity.bio && (
              <div className="text-sm text-muted-foreground line-clamp-1">
                {celebrity.bio.length > 50 ? `${celebrity.bio.substring(0, 50)}...` : celebrity.bio}
              </div>
            )}
          </div>
        </div>
      </td>
      <td className="py-4">
        <div className="flex items-center gap-1">
          {Object.entries(celebrity.social_media_links).map(([platform, url]) => (
            <a
              key={platform}
              href={url}
              target="_blank"
              rel="noopener noreferrer"
              className="p-1 rounded hover:bg-muted transition-colors"
              title={`${platform}: ${url}`}
            >
              {getSocialMediaIcon(platform)}
            </a>
          ))}
          {Object.keys(celebrity.social_media_links).length === 0 && (
            <span className="text-sm text-muted-foreground">None</span>
          )}
        </div>
      </td>
      <td className="py-4">
        <div className="flex items-center gap-2">
          <Badge variant="secondary" className="text-xs">
            {celebrity.total_promotions} total
          </Badge>
          {celebrity.featured_promotions_count > 0 && (
            <Badge variant="default" className="text-xs">
              <Star className="h-3 w-3 mr-1" />
              {celebrity.featured_promotions_count}
            </Badge>
          )}
        </div>
      </td>
      <td className="py-4">
        <Badge variant={celebrity.is_active ? 'default' : 'secondary'}>
          {celebrity.is_active ? 'Active' : 'Inactive'}
        </Badge>
      </td>
      <td className="py-4 text-sm text-muted-foreground">
        {formatDate(celebrity.created_at)}
      </td>
      <td className="py-4">
        <div className="flex items-center gap-2">
          <Link href={`/celebrities/${celebrity.id}`}>
            <Button variant="ghost" size="sm">
              <Eye className="h-4 w-4" />
            </Button>
          </Link>
          <Button variant="ghost" size="sm" onClick={() => onEdit(celebrity)}>
            <Edit className="h-4 w-4" />
          </Button>
          <Button
            variant="ghost"
            size="sm"
            onClick={() => onDelete(celebrity.id)}
            className="text-destructive hover:text-destructive"
          >
            <Trash2 className="h-4 w-4" />
          </Button>
        </div>
      </td>
    </tr>
  );
}

// Mobile Card Component
interface CelebrityMobileCardProps {
  celebrity: CelebrityListItem;
  isSelected: boolean;
  onSelect: (id: number, checked: boolean) => void;
  onEdit: (celebrity: CelebrityListItem) => void;
  onDelete: (id: number) => void;
}

function CelebrityMobileCard({ celebrity, isSelected, onSelect, onEdit, onDelete }: CelebrityMobileCardProps) {
  const getSocialMediaIcon = (platform: string) => {
    switch (platform) {
      case 'instagram': return <Instagram className="h-4 w-4" />;
      case 'facebook': return <Facebook className="h-4 w-4" />;
      case 'snapchat': return <MessageCircle className="h-4 w-4" />;
      default: return <ExternalLink className="h-4 w-4" />;
    }
  };

  return (
    <Card className={cn("transition-all", isSelected && "ring-2 ring-primary")}>
      <CardContent className="p-4">
        <div className="flex items-start gap-3">
          <Checkbox
            checked={isSelected}
            onCheckedChange={(checked) => onSelect(celebrity.id, !!checked)}
            className="mt-1"
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
              <div className="w-full h-full bg-gradient-to-br from-primary/20 to-primary/5 flex items-center justify-center">
                <span className="text-sm font-medium text-primary">
                  {celebrity.first_name[0]}{celebrity.last_name[0]}
                </span>
              </div>
            )}
          </div>
          
          <div className="flex-1 min-w-0">
            <div className="flex items-start justify-between">
              <div>
                <h3 className="font-medium text-foreground truncate">
                  {celebrity.full_name}
                </h3>
                {celebrity.bio && (
                  <p className="text-sm text-muted-foreground line-clamp-2 mt-1">
                    {celebrity.bio}
                  </p>
                )}
              </div>
              
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button variant="ghost" size="sm">
                    <MoreHorizontal className="h-4 w-4" />
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end">
                  <DropdownMenuLabel>Actions</DropdownMenuLabel>
                  <DropdownMenuSeparator />
                  <DropdownMenuItem asChild>
                    <Link href={`/celebrities/${celebrity.id}`}>
                      <Eye className="h-4 w-4 mr-2" />
                      View Details
                    </Link>
                  </DropdownMenuItem>
                  <DropdownMenuItem onClick={() => onEdit(celebrity)}>
                    <Edit className="h-4 w-4 mr-2" />
                    Edit
                  </DropdownMenuItem>
                  <DropdownMenuSeparator />
                  <DropdownMenuItem 
                    onClick={() => onDelete(celebrity.id)}
                    className="text-destructive"
                  >
                    <Trash2 className="h-4 w-4 mr-2" />
                    Delete
                  </DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            </div>
            
            <div className="flex items-center gap-2 mt-3">
              <Badge variant={celebrity.is_active ? 'default' : 'secondary'} className="text-xs">
                {celebrity.is_active ? 'Active' : 'Inactive'}
              </Badge>
              <Badge variant="secondary" className="text-xs">
                {celebrity.total_promotions} promotions
              </Badge>
              {celebrity.featured_promotions_count > 0 && (
                <Badge variant="default" className="text-xs">
                  <Star className="h-3 w-3 mr-1" />
                  {celebrity.featured_promotions_count}
                </Badge>
              )}
            </div>
            
            <div className="flex items-center justify-between mt-3">
              <div className="flex items-center gap-1">
                {Object.entries(celebrity.social_media_links).map(([platform, url]) => (
                  <a
                    key={platform}
                    href={url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="p-1 rounded hover:bg-muted transition-colors"
                  >
                    {getSocialMediaIcon(platform)}
                  </a>
                ))}
              </div>
              
              <span className="text-xs text-muted-foreground">
                {formatDate(celebrity.created_at)}
              </span>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  );
} 