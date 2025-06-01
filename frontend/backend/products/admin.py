from django.contrib import admin
from django.utils.html import format_html
from .models import (
    Category, Brand, Product, ProductImage, ProductVariant,
    ProductAttribute, ProductAttributeValue, InventoryLog
)

class SubcategoryInline(admin.TabularInline):
    model = Category
    extra = 0
    verbose_name = "Subcategory"
    verbose_name_plural = "Subcategories"
    fields = ['name', 'is_active']
    fk_name = 'parent'

@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ['name', 'parent', 'is_active', 'product_count', 'created_at']
    list_filter = ['is_active', 'parent']
    search_fields = ['name', 'description']
    readonly_fields = ['created_at', 'updated_at']
    prepopulated_fields = {'slug': ('name',)}
    inlines = [SubcategoryInline]
    
    def product_count(self, obj):
        return obj.products.count()
    product_count.short_description = 'Products'
    
    def get_queryset(self, request):
        # Filter to show only top-level categories in the list view
        qs = super().get_queryset(request)
        if request.path == '/admin/products/category/':
            return qs.filter(parent=None)
        return qs

@admin.register(Brand)
class BrandAdmin(admin.ModelAdmin):
    list_display = ['name', 'display_logo', 'is_active', 'product_count', 'created_at']
    list_filter = ['is_active']
    search_fields = ['name', 'description']
    readonly_fields = ['created_at', 'updated_at', 'display_logo_large']
    prepopulated_fields = {'slug': ('name',)}
    
    def display_logo(self, obj):
        if obj.logo:
            return format_html('<img src="{}" height="30" />', obj.logo.url)
        return "-"
    display_logo.short_description = 'Logo'
    
    def display_logo_large(self, obj):
        if obj.logo:
            return format_html('<img src="{}" height="100" />', obj.logo.url)
        return "-"
    display_logo_large.short_description = 'Logo Preview'
    
    def product_count(self, obj):
        return obj.products.count()
    product_count.short_description = 'Products'

class ProductImageInline(admin.TabularInline):
    model = ProductImage
    extra = 1
    fields = ['image', 'alt_text', 'is_feature', 'image_preview']
    readonly_fields = ['image_preview']
    
    def image_preview(self, obj):
        if obj.image:
            return format_html('<img src="{}" height="50" />', obj.image.url)
        return "-"
    image_preview.short_description = 'Preview'

class ProductVariantInline(admin.TabularInline):
    model = ProductVariant
    extra = 0
    fields = ['name', 'sku', 'price_adjustment', 'stock', 'is_active']

class InventoryLogInline(admin.TabularInline):
    model = InventoryLog
    extra = 0
    fields = ['adjustment_type', 'quantity', 'reference', 'created_at']
    readonly_fields = ['created_at']
    can_delete = False
    
    def has_add_permission(self, request, obj=None):
        return True
    
    def has_change_permission(self, request, obj=None):
        return False

@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ['name', 'sku', 'category', 'brand', 'price', 'sale_price', 'stock', 'is_active', 'is_featured']
    list_filter = ['is_active', 'is_featured', 'category', 'brand', 'created_at']
    search_fields = ['name', 'description', 'sku']
    readonly_fields = ['created_at', 'updated_at', 'display_featured_image']
    prepopulated_fields = {'slug': ('name',)}
    fieldsets = (
        ('Basic Information', {
            'fields': ('name', 'description', 'category', 'brand', 'featured_image', 'display_featured_image')
        }),
        ('Pricing', {
            'fields': ('price', 'sale_price')
        }),
        ('Inventory', {
            'fields': ('stock', 'sku', 'low_stock_threshold')
        }),
        ('Product Details', {
            'fields': ('weight', 'dimensions', 'attributes')
        }),
        ('Status', {
            'fields': ('is_active', 'is_featured')
        }),
        ('SEO', {
            'fields': ('slug', 'meta_keywords', 'meta_description')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at')
        }),
    )
    inlines = [ProductImageInline, ProductVariantInline, InventoryLogInline]
    filter_horizontal = ['attributes']
    
    def display_featured_image(self, obj):
        if obj.featured_image:
            return format_html('<img src="{}" height="150" />', obj.featured_image.url)
        return "-"
    display_featured_image.short_description = 'Featured Image Preview'
    
    def save_model(self, request, obj, form, change):
        """Log inventory changes when stock is updated"""
        if change and 'stock' in form.changed_data:
            original_obj = self.model.objects.get(pk=obj.pk)
            stock_diff = obj.stock - original_obj.stock
            
            if stock_diff != 0:
                adjustment_type = 'stock_in' if stock_diff > 0 else 'stock_out'
                
                # Create inventory log
                InventoryLog.objects.create(
                    product=obj,
                    quantity=abs(stock_diff),
                    adjustment_type=adjustment_type,
                    reference=f"Manual adjustment by admin {request.user.username}",
                    user=request.user
                )
                
        super().save_model(request, obj, form, change)

@admin.register(ProductVariant)
class ProductVariantAdmin(admin.ModelAdmin):
    list_display = ['name', 'product', 'sku', 'price_adjustment', 'stock', 'is_active']
    list_filter = ['is_active', 'product__category', 'created_at']
    search_fields = ['name', 'sku', 'product__name']
    readonly_fields = ['created_at', 'updated_at']
    filter_horizontal = ['attributes']
    
    fieldsets = (
        ('Variant Information', {
            'fields': ('product', 'name', 'sku', 'attributes')
        }),
        ('Pricing & Inventory', {
            'fields': ('price_adjustment', 'stock', 'is_active')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at')
        }),
    )
    
    def save_model(self, request, obj, form, change):
        """Log inventory changes when stock is updated"""
        if change and 'stock' in form.changed_data:
            original_obj = self.model.objects.get(pk=obj.pk)
            stock_diff = obj.stock - original_obj.stock
            
            if stock_diff != 0:
                adjustment_type = 'stock_in' if stock_diff > 0 else 'stock_out'
                
                # Create inventory log
                InventoryLog.objects.create(
                    product=obj.product,
                    variant=obj,
                    quantity=abs(stock_diff),
                    adjustment_type=adjustment_type,
                    reference=f"Manual adjustment by admin {request.user.username}",
                    user=request.user
                )
                
        super().save_model(request, obj, form, change)

@admin.register(ProductAttribute)
class ProductAttributeAdmin(admin.ModelAdmin):
    list_display = ['name']
    search_fields = ['name']

class AttributeValueInline(admin.TabularInline):
    model = ProductAttributeValue
    extra = 1

@admin.register(ProductAttributeValue)
class ProductAttributeValueAdmin(admin.ModelAdmin):
    list_display = ['attribute', 'value']
    list_filter = ['attribute']
    search_fields = ['value', 'attribute__name']

@admin.register(InventoryLog)
class InventoryLogAdmin(admin.ModelAdmin):
    list_display = ['product', 'variant', 'quantity', 'adjustment_type', 'reference', 'user', 'created_at']
    list_filter = ['adjustment_type', 'created_at']
    search_fields = ['product__name', 'variant__name', 'reference', 'user__username']
    readonly_fields = ['created_at']
    date_hierarchy = 'created_at'
    
    def has_change_permission(self, request, obj=None):
        return False  # Inventory logs should not be editable
