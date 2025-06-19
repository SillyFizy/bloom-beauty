from django.contrib import admin
from django.utils.html import format_html
from .models import Celebrity, CelebrityProductPromotion, CelebrityMorningRoutine, CelebrityEveningRoutine


@admin.register(Celebrity)
class CelebrityAdmin(admin.ModelAdmin):
    list_display = ['full_name', 'image_tag', 'is_active', 'social_media_count', 'promotion_count', 'created_at']
    list_filter = ['is_active', 'created_at']
    search_fields = ['first_name', 'last_name']
    readonly_fields = ['created_at', 'updated_at']
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('first_name', 'last_name', 'image', 'bio')
        }),
        ('Social Media', {
            'fields': ('instagram_url', 'facebook_url', 'snapchat_url')
        }),
        ('Status', {
            'fields': ('is_active',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def image_tag(self, obj):
        if obj.image:
            return format_html('<img src="{}" width="50" height="50" style="border-radius: 50%;" />', obj.image.url)
        return "No Image"
    image_tag.short_description = 'Image'
    
    def social_media_count(self, obj):
        count = 0
        if obj.instagram_url:
            count += 1
        if obj.facebook_url:
            count += 1
        if obj.snapchat_url:
            count += 1
        return f"{count}/3"
    social_media_count.short_description = 'Social Media'
    
    def promotion_count(self, obj):
        return obj.product_promotions.count()
    promotion_count.short_description = 'Promotions'


class CelebrityProductPromotionInline(admin.TabularInline):
    model = CelebrityProductPromotion
    extra = 1
    fields = ['product', 'promotion_type', 'is_featured', 'testimonial']


class CelebrityMorningRoutineInline(admin.TabularInline):
    model = CelebrityMorningRoutine
    extra = 1
    fields = ['product', 'order', 'description']
    ordering = ['order']


class CelebrityEveningRoutineInline(admin.TabularInline):
    model = CelebrityEveningRoutine
    extra = 1
    fields = ['product', 'order', 'description']
    ordering = ['order']


@admin.register(CelebrityProductPromotion)
class CelebrityProductPromotionAdmin(admin.ModelAdmin):
    list_display = ['celebrity', 'product', 'promotion_type', 'is_featured', 'created_at']
    list_filter = ['promotion_type', 'is_featured', 'created_at']
    search_fields = ['celebrity__first_name', 'celebrity__last_name', 'product__name']
    raw_id_fields = ['celebrity', 'product']
    
    fieldsets = (
        ('Promotion Details', {
            'fields': ('celebrity', 'product', 'promotion_type', 'is_featured')
        }),
        ('Content', {
            'fields': ('testimonial',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    readonly_fields = ['created_at', 'updated_at']


@admin.register(CelebrityMorningRoutine)
class CelebrityMorningRoutineAdmin(admin.ModelAdmin):
    list_display = ['celebrity', 'product', 'order', 'created_at']
    list_filter = ['created_at']
    search_fields = ['celebrity__first_name', 'celebrity__last_name', 'product__name']
    raw_id_fields = ['celebrity', 'product']
    ordering = ['celebrity', 'order']
    
    fieldsets = (
        ('Routine Details', {
            'fields': ('celebrity', 'product', 'order')
        }),
        ('Description', {
            'fields': ('description',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    readonly_fields = ['created_at', 'updated_at']


@admin.register(CelebrityEveningRoutine)
class CelebrityEveningRoutineAdmin(admin.ModelAdmin):
    list_display = ['celebrity', 'product', 'order', 'created_at']
    list_filter = ['created_at']
    search_fields = ['celebrity__first_name', 'celebrity__last_name', 'product__name']
    raw_id_fields = ['celebrity', 'product']
    ordering = ['celebrity', 'order']
    
    fieldsets = (
        ('Routine Details', {
            'fields': ('celebrity', 'product', 'order')
        }),
        ('Description', {
            'fields': ('description',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    readonly_fields = ['created_at', 'updated_at']


# Add inlines to Celebrity admin
CelebrityAdmin.inlines = [CelebrityProductPromotionInline, CelebrityMorningRoutineInline, CelebrityEveningRoutineInline] 