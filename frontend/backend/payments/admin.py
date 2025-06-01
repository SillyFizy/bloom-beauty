from django.contrib import admin
from .models import Payment

@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):
    list_display = ['id', 'order', 'amount', 'payment_method', 'status', 'created_at']
    list_filter = ['payment_method', 'status', 'created_at']
    search_fields = ['order__id', 'transaction_id']
    readonly_fields = ['created_at', 'updated_at']
    date_hierarchy = 'created_at'
    
    fieldsets = (
        ('Payment Information', {
            'fields': ('order', 'amount', 'payment_method', 'status')
        }),
        ('Transaction Details', {
            'fields': ('transaction_id', 'created_at', 'updated_at')
        }),
    )
    
    def save_model(self, request, obj, form, change):
        """When payment status is updated to completed, update the order as well"""
        super().save_model(request, obj, form, change)
        
        # If payment was marked as completed, update order
        if 'status' in form.changed_data and obj.status == 'completed':
            order = obj.order
            if not order.is_paid:
                order.is_paid = True
                order.save()
                
                # Add status history entry
                from orders.models import OrderStatusHistory
                OrderStatusHistory.objects.create(
                    order=order,
                    status=order.status,
                    notes=f"Payment completed for order (Payment ID: {obj.id})."
                )
