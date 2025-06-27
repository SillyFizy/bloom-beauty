'use client';

import React, { useState, useRef, useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import Image from 'next/image';
import { 
  Upload, 
  X, 
  Instagram, 
  Facebook, 
  MessageCircle, 
  User, 
  Eye,
  EyeOff,
  Loader2,
  Star,
  Camera,
  Edit,
} from 'lucide-react';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import {
  Form,
  FormControl,
  FormDescription,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from '@/components/ui/form';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Button } from '@/components/ui/button';
import { Switch } from '@/components/ui/switch';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import { useUpdateCelebrity } from '@/hooks/use-celebrities';
import { RoutineManager } from './routine-manager';
import { CelebrityFormData, CelebrityListItem } from '@/types/celebrity';
import { apiClient } from '@/lib/api';

// Form validation schema
const editCelebrityFormSchema = z.object({
  first_name: z.string()
    .min(1, 'First name is required')
    .min(2, 'First name must be at least 2 characters')
    .max(100, 'First name must be less than 100 characters')
    .regex(/^[a-zA-Z\s-']+$/, 'First name can only contain letters, spaces, hyphens, and apostrophes'),
  
  last_name: z.string()
    .min(1, 'Last name is required')
    .min(2, 'Last name must be at least 2 characters')
    .max(100, 'Last name must be less than 100 characters')
    .regex(/^[a-zA-Z\s-']+$/, 'Last name can only contain letters, spaces, hyphens, and apostrophes'),
  
  bio: z.string()
    .max(1000, 'Bio must be less than 1000 characters')
    .optional()
    .or(z.literal('')),
  
  instagram_url: z.string()
    .optional()
    .refine((val) => {
      if (!val) return true;
      return /^https?:\/\/(www\.)?(instagram\.com|instagr\.am)\//.test(val);
    }, 'Please enter a valid Instagram URL')
    .or(z.literal('')),
  
  facebook_url: z.string()
    .optional()
    .refine((val) => {
      if (!val) return true;
      return /^https?:\/\/(www\.)?facebook\.com\//.test(val);
    }, 'Please enter a valid Facebook URL')
    .or(z.literal('')),
  
  snapchat_url: z.string()
    .optional()
    .refine((val) => {
      if (!val) return true;
      return /^https?:\/\/(www\.)?(snapchat\.com|t\.snapchat\.com)\//.test(val);
    }, 'Please enter a valid Snapchat URL')
    .or(z.literal('')),
  
  is_active: z.boolean().default(true),
});

type EditCelebrityFormValues = z.infer<typeof editCelebrityFormSchema>;

interface EditCelebrityDialogProps {
  celebrity: CelebrityListItem;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function EditCelebrityDialog({ celebrity, open, onOpenChange }: EditCelebrityDialogProps) {
  const [selectedImage, setSelectedImage] = useState<File | null>(null);
  const [imagePreview, setImagePreview] = useState<string | null>(null);
  const [showAdvanced, setShowAdvanced] = useState(false);
  const [removeExistingImage, setRemoveExistingImage] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const updateCelebrity = useUpdateCelebrity();

  const form = useForm<EditCelebrityFormValues>({
    resolver: zodResolver(editCelebrityFormSchema),
    defaultValues: {
      first_name: '',
      last_name: '',
      bio: '',
      instagram_url: '',
      facebook_url: '',
      snapchat_url: '',
      is_active: true,
    },
  });

  // Initialize form with celebrity data
  useEffect(() => {
    if (celebrity && open) {
      form.reset({
        first_name: celebrity.first_name,
        last_name: celebrity.last_name,
        bio: celebrity.bio || '',
        instagram_url: celebrity.social_media_links.instagram || '',
        facebook_url: celebrity.social_media_links.facebook || '',
        snapchat_url: celebrity.social_media_links.snapchat || '',
        is_active: celebrity.is_active,
      });
      
      // Set initial image state
      setSelectedImage(null);
      setImagePreview(null);
      setRemoveExistingImage(false);
      
      // Show advanced section if social media links exist
      const hasSocialMedia = Object.keys(celebrity.social_media_links).length > 0;
      setShowAdvanced(hasSocialMedia);
    }
  }, [celebrity, open, form]);

  const handleImageSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      // Validate file type
      if (!file.type.startsWith('image/')) {
        form.setError('root', { 
          message: 'Please select a valid image file (JPEG, PNG, GIF, WebP)' 
        });
        return;
      }
      
      // Validate file size (max 5MB)
      if (file.size > 5 * 1024 * 1024) {
        form.setError('root', { 
          message: 'Image size must be less than 5MB' 
        });
        return;
      }

      setSelectedImage(file);
      setRemoveExistingImage(false);
      
      // Create preview
      const reader = new FileReader();
      reader.onload = (e) => {
        setImagePreview(e.target?.result as string);
      };
      reader.readAsDataURL(file);
      
      // Clear any previous errors
      form.clearErrors('root');
    }
  };

  const handleRemoveImage = () => {
    setSelectedImage(null);
    setImagePreview(null);
    setRemoveExistingImage(true);
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  const handleKeepExistingImage = () => {
    setSelectedImage(null);
    setImagePreview(null);
    setRemoveExistingImage(false);
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  const onSubmit = async (values: EditCelebrityFormValues) => {
    try {
      const updateData: Partial<CelebrityFormData> = {
        ...values,
      };

      // Handle image updates
      if (selectedImage) {
        updateData.image = selectedImage;
      } else if (removeExistingImage) {
        // This would need backend support to remove image
        // For now, we'll just not include the image field
      }

      await updateCelebrity.mutateAsync({
        id: celebrity.id,
        data: updateData,
      });
      
      // Reset form and close dialog
      handleClose();
    } catch (error) {
      console.error('Failed to update celebrity:', error);
    }
  };

  const handleClose = () => {
    form.reset();
    setSelectedImage(null);
    setImagePreview(null);
    setRemoveExistingImage(false);
    setShowAdvanced(false);
    onOpenChange(false);
  };

  // Get social media preview
  const getSocialMediaPreview = () => {
    const values = form.getValues();
    const links = [];
    
    if (values.instagram_url) links.push({ platform: 'Instagram', url: values.instagram_url, icon: Instagram });
    if (values.facebook_url) links.push({ platform: 'Facebook', url: values.facebook_url, icon: Facebook });
    if (values.snapchat_url) links.push({ platform: 'Snapchat', url: values.snapchat_url, icon: MessageCircle });
    
    return links;
  };

  // Get current image to display
  const getCurrentImage = () => {
    if (imagePreview) return imagePreview;
    if (removeExistingImage) return null;
    if (celebrity.image) return apiClient.getMediaUrl(celebrity.image);
    return null;
  };

  return (
    <Dialog open={open} onOpenChange={handleClose}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Edit className="h-5 w-5 text-primary" />
            Edit Celebrity: {celebrity.full_name}
          </DialogTitle>
          <DialogDescription>
            Update celebrity profile information, social media links, and photo.
          </DialogDescription>
        </DialogHeader>

        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
            {/* Image Upload Section */}
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <h3 className="text-lg font-medium flex items-center gap-2">
                  <Camera className="h-4 w-4" />
                  Profile Photo
                </h3>
                <div className="flex items-center gap-2">
                  {(getCurrentImage() || selectedImage) && (
                    <Button
                      type="button"
                      variant="outline"
                      size="sm"
                      onClick={handleRemoveImage}
                    >
                      <X className="h-4 w-4 mr-1" />
                      Remove
                    </Button>
                  )}
                  {removeExistingImage && celebrity.image && (
                    <Button
                      type="button"
                      variant="outline"
                      size="sm"
                      onClick={handleKeepExistingImage}
                    >
                      Keep Original
                    </Button>
                  )}
                </div>
              </div>

              <div className="flex items-center gap-6">
                {/* Image Preview */}
                <div className="relative">
                  {getCurrentImage() ? (
                    <div className="relative w-24 h-24 rounded-full overflow-hidden border-2 border-border">
                      <Image
                        src={getCurrentImage()!}
                        alt="Celebrity preview"
                        fill
                        className="object-cover"
                      />
                      {selectedImage && (
                        <div className="absolute inset-0 bg-primary/10 flex items-center justify-center">
                          <Badge variant="secondary" className="text-xs">
                            New
                          </Badge>
                        </div>
                      )}
                    </div>
                  ) : (
                    <div className="w-24 h-24 rounded-full bg-muted border-2 border-dashed border-border flex items-center justify-center">
                      <User className="h-8 w-8 text-muted-foreground" />
                    </div>
                  )}
                </div>

                {/* Upload Button */}
                <div className="flex-1">
                  <input
                    ref={fileInputRef}
                    type="file"
                    accept="image/*"
                    onChange={handleImageSelect}
                    className="hidden"
                  />
                  <Button
                    type="button"
                    variant="outline"
                    onClick={() => fileInputRef.current?.click()}
                    className="w-full"
                  >
                    <Upload className="h-4 w-4 mr-2" />
                    {getCurrentImage() ? 'Change Photo' : 'Upload Photo'}
                  </Button>
                  <p className="text-xs text-muted-foreground mt-2">
                    Recommended: Square image, at least 400x400px. Max 5MB.
                  </p>
                </div>
              </div>
            </div>

            <Separator />

            {/* Basic Information */}
            <div className="space-y-4">
              <h3 className="text-lg font-medium flex items-center gap-2">
                <User className="h-4 w-4" />
                Basic Information
              </h3>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <FormField
                  control={form.control}
                  name="first_name"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>First Name *</FormLabel>
                      <FormControl>
                        <Input
                          placeholder="Emma"
                          {...field}
                          className="transition-all focus:ring-2 focus:ring-primary/20"
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                <FormField
                  control={form.control}
                  name="last_name"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Last Name *</FormLabel>
                      <FormControl>
                        <Input
                          placeholder="Watson"
                          {...field}
                          className="transition-all focus:ring-2 focus:ring-primary/20"
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>

              <FormField
                control={form.control}
                name="bio"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Biography</FormLabel>
                    <FormControl>
                      <Textarea
                        placeholder="Tell us about this celebrity's background, achievements, and why they're a great brand ambassador..."
                        className="min-h-[100px] resize-none transition-all focus:ring-2 focus:ring-primary/20"
                        {...field}
                      />
                    </FormControl>
                    <FormDescription>
                      {form.watch('bio')?.length || 0}/1000 characters
                    </FormDescription>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="is_active"
                render={({ field }) => (
                  <FormItem className="flex flex-row items-center justify-between rounded-lg border p-4">
                    <div className="space-y-0.5">
                      <FormLabel className="text-base">Active Status</FormLabel>
                      <FormDescription>
                        Whether this celebrity profile is active and visible
                      </FormDescription>
                    </div>
                    <FormControl>
                      <Switch
                        checked={field.value}
                        onCheckedChange={field.onChange}
                      />
                    </FormControl>
                  </FormItem>
                )}
              />
            </div>

            <Separator />

            {/* Social Media Section */}
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <h3 className="text-lg font-medium">Social Media Links</h3>
                <Button
                  type="button"
                  variant="ghost"
                  size="sm"
                  onClick={() => setShowAdvanced(!showAdvanced)}
                >
                  {showAdvanced ? <EyeOff className="h-4 w-4 mr-1" /> : <Eye className="h-4 w-4 mr-1" />}
                  {showAdvanced ? 'Hide' : 'Show'} Social Media
                </Button>
              </div>

              {showAdvanced && (
                <div className="space-y-4">
                  <FormField
                    control={form.control}
                    name="instagram_url"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel className="flex items-center gap-2">
                          <Instagram className="h-4 w-4" />
                          Instagram URL
                        </FormLabel>
                        <FormControl>
                          <Input
                            placeholder="https://instagram.com/username"
                            {...field}
                            className="transition-all focus:ring-2 focus:ring-primary/20"
                          />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />

                  <FormField
                    control={form.control}
                    name="facebook_url"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel className="flex items-center gap-2">
                          <Facebook className="h-4 w-4" />
                          Facebook URL
                        </FormLabel>
                        <FormControl>
                          <Input
                            placeholder="https://facebook.com/username"
                            {...field}
                            className="transition-all focus:ring-2 focus:ring-primary/20"
                          />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />

                  <FormField
                    control={form.control}
                    name="snapchat_url"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel className="flex items-center gap-2">
                          <MessageCircle className="h-4 w-4" />
                          Snapchat URL
                        </FormLabel>
                        <FormControl>
                          <Input
                            placeholder="https://snapchat.com/add/username"
                            {...field}
                            className="transition-all focus:ring-2 focus:ring-primary/20"
                          />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                </div>
              )}

              {/* Social Media Preview */}
              {getSocialMediaPreview().length > 0 && (
                <div className="p-4 bg-muted/50 rounded-lg">
                  <h4 className="text-sm font-medium mb-2">Social Media Preview:</h4>
                  <div className="flex flex-wrap gap-2">
                    {getSocialMediaPreview().map(({ platform, url, icon: Icon }) => (
                      <Badge key={platform} variant="secondary" className="flex items-center gap-1">
                        <Icon className="h-3 w-3" />
                        {platform}
                      </Badge>
                    ))}
                  </div>
                </div>
              )}
            </div>

            {/* Error Display */}
            {form.formState.errors.root && (
              <div className="p-4 bg-destructive/10 border border-destructive/20 rounded-lg">
                <p className="text-sm text-destructive">
                  {form.formState.errors.root.message}
                </p>
              </div>
            )}

            <DialogFooter className="gap-2">
              <Button
                type="button"
                variant="outline"
                onClick={handleClose}
                disabled={updateCelebrity.isPending}
              >
                Cancel
              </Button>
              <Button
                type="submit"
                disabled={updateCelebrity.isPending}
                className="min-w-[120px]"
              >
                {updateCelebrity.isPending ? (
                  <>
                    <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                    Updating...
                  </>
                ) : (
                  <>
                    <Star className="h-4 w-4 mr-2" />
                    Update Celebrity
                  </>
                )}
              </Button>
            </DialogFooter>
          </form>
        </Form>

        {/* Routine Manager below form */}
        {celebrity.id && (
          <>
            <Separator className="my-6" />
            <h3 className="text-lg font-semibold mb-2">Skincare Routines</h3>
            <RoutineManager celebrityId={celebrity.id} celebrityName={celebrity.full_name} />
          </>
        )}
      </DialogContent>
    </Dialog>
  );
} 