from django.contrib import admin
from .models import Order, OrderItem, ShippingAddress, OrderStatusHistory

class OrderItemInline(admin.TabularInline):
    model = OrderItem
    extra = 0
    readonly_fields = ['subtotal']

class OrderStatusHistoryInline(admin.TabularInline):
    model = OrderStatusHistory
    extra = 0
    readonly_fields = ['created_at']
    
@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ['id', 'user', 'status', 'payment_method', 'total_amount', 'is_paid', 'created_at']
    list_filter = ['status', 'payment_method', 'is_paid', 'created_at']
    search_fields = ['id', 'user__username', 'user__email', 'shipping_address__full_name']
    readonly_fields = ['payment_status', 'created_at', 'updated_at']
    date_hierarchy = 'created_at'
    inlines = [OrderItemInline, OrderStatusHistoryInline]
    
    fieldsets = (
        ('Order Information', {
            'fields': ('user', 'shipping_address', 'status', 'payment_method', 'is_paid', 'payment_status')
        }),
        ('Financial Details', {
            'fields': ('subtotal', 'shipping_fee', 'discount', 'total_amount')
        }),
        ('Additional Details', {
            'fields': ('notes', 'tracking_number', 'created_at', 'updated_at')
        }),
    )
    
    def save_model(self, request, obj, form, change):
        """When updating an order status, add a status history entry"""
        if change and 'status' in form.changed_data:
            # Save the status change to history
            OrderStatusHistory.objects.create(
                order=obj,
                status=obj.status,
                notes=f"Status updated to {obj.get_status_display()} by admin user {request.user.username}"
            )
        super().save_model(request, obj, form, change)

@admin.register(ShippingAddress)
class ShippingAddressAdmin(admin.ModelAdmin):
    list_display = ['id', 'user', 'full_name', 'city', 'country', 'is_default']
    list_filter = ['is_default', 'country', 'city']
    search_fields = ['full_name', 'user__username', 'user__email', 'address_line1', 'city']
    readonly_fields = ['created_at', 'updated_at']
    
    fieldsets = (
        ('User Information', {
            'fields': ('user', 'full_name', 'phone_number')
        }),
        ('Address Details', {
            'fields': ('address_line1', 'address_line2', 'city', 'state', 'postal_code', 'country')
        }),
        ('Settings', {
            'fields': ('is_default', 'created_at', 'updated_at')
        }),
    )

@admin.register(OrderStatusHistory)
class OrderStatusHistoryAdmin(admin.ModelAdmin):
    list_display = ['id', 'order', 'status', 'created_at']
    list_filter = ['status', 'created_at']
    search_fields = ['order__id', 'notes']
    readonly_fields = ['created_at']
    date_hierarchy = 'created_at'
