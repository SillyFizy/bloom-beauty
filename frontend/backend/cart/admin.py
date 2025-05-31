from django.contrib import admin
from .models import Cart, CartItem, CartVariantItem

class CartItemInline(admin.TabularInline):
    model = CartItem
    extra = 0
    raw_id_fields = ['product']
    readonly_fields = ['subtotal']

class CartVariantItemInline(admin.TabularInline):
    model = CartVariantItem
    extra = 0
    raw_id_fields = ['variant']
    readonly_fields = ['subtotal']

@admin.register(Cart)
class CartAdmin(admin.ModelAdmin):
    list_display = ['id', 'get_owner', 'total', 'item_count', 'created_at', 'updated_at', 'merged']
    list_filter = ['created_at', 'updated_at', 'merged']
    search_fields = ['user__username', 'user__email', 'session_key']
    readonly_fields = ['total', 'item_count', 'created_at', 'updated_at']
    date_hierarchy = 'created_at'
    inlines = [CartItemInline, CartVariantItemInline]
    
    def get_owner(self, obj):
        if obj.user:
            return f"{obj.user.username} (User ID: {obj.user.id})"
        return f"Anonymous ({obj.session_key})"
    get_owner.short_description = 'Owner'
    
    def has_add_permission(self, request):
        return False  # Prevent manual creation of carts
