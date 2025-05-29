from django.contrib import admin
from django.contrib.admin.sites import AdminSite
from django.db.models import Sum, Count, Avg, Q, F, Value, IntegerField
from django.utils import timezone
from datetime import timedelta, datetime
from django.http import HttpResponseRedirect
from django.urls import path, reverse
from django.contrib import messages
from django.contrib.admin import SimpleListFilter

from users.models import User, PointTransaction
from products.models import Product, Category, Brand, ProductVariant, InventoryLog
from orders.models import Order, OrderItem, ShippingAddress, OrderStatusHistory
from cart.models import Cart, CartItem, CartVariantItem
from payments.models import Payment

# Import admin modules to register with our custom admin site
import users.admin
import products.admin
import orders.admin
import cart.admin
import payments.admin

class LowStockFilter(SimpleListFilter):
    title = 'stock status'
    parameter_name = 'stock_status'

    def lookups(self, request, model_admin):
        return (
            ('low', 'Low Stock'),
            ('out', 'Out of Stock'),
            ('normal', 'Normal Stock'),
        )

    def queryset(self, request, queryset):
        if self.value() == 'low':
            return queryset.filter(stock__lte=F('low_stock_threshold'), stock__gt=0)
        if self.value() == 'out':
            return queryset.filter(stock=0)
        if self.value() == 'normal':
            return queryset.filter(stock__gt=F('low_stock_threshold'))
        return queryset

class JoulinaAdminSite(AdminSite):
    site_header = 'Joulina Beauty Bloom Admin'
    site_title = 'Joulina Beauty Admin'
    index_title = 'Dashboard'
    
    def get_urls(self):
        urls = super().get_urls()
        custom_urls = [
            path('replenish-low-stock/', self.admin_view(self.replenish_low_stock_view), name='replenish-low-stock'),
            path('clean-abandoned-carts/', self.admin_view(self.clean_abandoned_carts_view), name='clean-abandoned-carts'),
            path('sales-report/', self.admin_view(self.sales_report_view), name='sales-report'),
        ]
        return custom_urls + urls
    
    def replenish_low_stock_view(self, request):
        """View to increase stock of low stock items"""
        if request.method == 'POST':
            # Get all low stock products
            low_stock_products = Product.objects.filter(stock__lte=F('low_stock_threshold'))
            
            # Increase stock by the specified amount
            for product in low_stock_products:
                replenish_amount = int(request.POST.get(f'product_{product.id}', 0))
                if replenish_amount > 0:
                    original_stock = product.stock
                    product.stock += replenish_amount
                    product.save()
                    
                    # Create inventory log
                    InventoryLog.objects.create(
                        product=product,
                        quantity=replenish_amount,
                        adjustment_type='stock_in',
                        reference=f"Bulk replenishment by {request.user.username}",
                        user=request.user
                    )
            
            messages.success(request, "Stock levels have been updated successfully.")
            return HttpResponseRedirect(reverse('admin:index'))
        
        # Get all products with low stock
        low_stock_products = Product.objects.filter(stock__lte=F('low_stock_threshold')).order_by('stock')
        
        context = {
            'title': 'Replenish Low Stock',
            'products': low_stock_products,
            **self.each_context(request),
        }
        
        return self.render_to_response(request, 'admin/replenish_low_stock.html', context)
    
    def clean_abandoned_carts_view(self, request):
        """View to clean abandoned carts"""
        if request.method == 'POST':
            days_old = int(request.POST.get('days_old', 7))
            cutoff_date = timezone.now() - timedelta(days=days_old)
            
            # Get abandoned carts
            abandoned_carts = Cart.objects.filter(
                merged=False,
                updated_at__lt=cutoff_date
            )
            
            count = abandoned_carts.count()
            abandoned_carts.delete()
            
            messages.success(request, f"{count} abandoned carts have been removed successfully.")
            return HttpResponseRedirect(reverse('admin:index'))
        
        # Count abandoned carts by age
        one_day = Cart.objects.filter(
            merged=False,
            updated_at__lt=timezone.now() - timedelta(days=1)
        ).count()
        
        three_days = Cart.objects.filter(
            merged=False,
            updated_at__lt=timezone.now() - timedelta(days=3)
        ).count()
        
        seven_days = Cart.objects.filter(
            merged=False,
            updated_at__lt=timezone.now() - timedelta(days=7)
        ).count()
        
        thirty_days = Cart.objects.filter(
            merged=False,
            updated_at__lt=timezone.now() - timedelta(days=30)
        ).count()
        
        context = {
            'title': 'Clean Abandoned Carts',
            'one_day': one_day,
            'three_days': three_days,
            'seven_days': seven_days,
            'thirty_days': thirty_days,
            **self.each_context(request),
        }
        
        return self.render_to_response(request, 'admin/clean_abandoned_carts.html', context)
    
    def sales_report_view(self, request):
        """View to show detailed sales reports"""
        # Default to current month
        today = timezone.now().date()
        start_date = request.GET.get('start_date', today.replace(day=1).isoformat())
        end_date = request.GET.get('end_date', today.isoformat())
        
        # Convert to datetime objects
        try:
            start_date = datetime.fromisoformat(start_date)
            end_date = datetime.fromisoformat(end_date)
            # Adjust end_date to include the entire day
            end_date = datetime.combine(end_date.date(), datetime.max.time())
        except ValueError:
            start_date = today.replace(day=1)
            end_date = today
        
        # Filter orders by date range
        orders = Order.objects.filter(
            created_at__gte=start_date,
            created_at__lte=end_date
        )
        
        # Get sales summary
        total_sales = orders.aggregate(
            total=Sum('total_amount'),
            count=Count('id'),
            avg=Avg('total_amount')
        )
        
        # Get sales by day
        sales_by_day = orders.values('created_at__date').annotate(
            day=F('created_at__date'),
            total=Sum('total_amount'),
            count=Count('id')
        ).order_by('day')
        
        # Get sales by product category
        sales_by_category = OrderItem.objects.filter(
            order__in=orders
        ).values(
            'product__category__name'
        ).annotate(
            category=F('product__category__name'),
            total=Sum('subtotal'),
            count=Sum('quantity')
        ).order_by('-total')
        
        # Get top selling products
        top_products = OrderItem.objects.filter(
            order__in=orders
        ).values(
            'product__name'
        ).annotate(
            product=F('product__name'),
            total=Sum('subtotal'),
            count=Sum('quantity')
        ).order_by('-count')[:10]
        
        context = {
            'title': 'Sales Report',
            'start_date': start_date.date().isoformat(),
            'end_date': end_date.date().isoformat(),
            'total_sales': total_sales,
            'sales_by_day': sales_by_day,
            'sales_by_category': sales_by_category,
            'top_products': top_products,
            **self.each_context(request),
        }
        
        return self.render_to_response(request, 'admin/sales_report.html', context)
    
    def render_to_response(self, request, template, context):
        """Helper to render templates for admin views"""
        from django.template.response import TemplateResponse
        return TemplateResponse(request, template, context)
    
    def get_app_list(self, request):
        """
        Return a sorted list of all the installed apps that have been
        registered in this site.
        """
        app_list = super().get_app_list(request)
        
        # Sort the apps alphabetically
        app_list.sort(key=lambda x: x['name'].lower())
        
        return app_list
    
    def index(self, request, extra_context=None):
        # Get date ranges
        today = timezone.now().date()
        yesterday = today - timedelta(days=1)
        this_week_start = today - timedelta(days=today.weekday())
        last_week_start = this_week_start - timedelta(days=7)
        this_month_start = today.replace(day=1)
        last_month_start = (this_month_start - timedelta(days=1)).replace(day=1)
        
        # Get sales data
        today_sales = Order.objects.filter(created_at__date=today).aggregate(
            total_sales=Sum('total_amount'),
            count=Count('id')
        )
        
        yesterday_sales = Order.objects.filter(created_at__date=yesterday).aggregate(
            total_sales=Sum('total_amount'),
            count=Count('id')
        )
        
        this_week_sales = Order.objects.filter(created_at__date__gte=this_week_start).aggregate(
            total_sales=Sum('total_amount'),
            count=Count('id')
        )
        
        last_week_sales = Order.objects.filter(
            created_at__date__gte=last_week_start,
            created_at__date__lt=this_week_start
        ).aggregate(
            total_sales=Sum('total_amount'),
            count=Count('id')
        )
        
        this_month_sales = Order.objects.filter(created_at__date__gte=this_month_start).aggregate(
            total_sales=Sum('total_amount'),
            count=Count('id')
        )
        
        last_month_sales = Order.objects.filter(
            created_at__date__gte=last_month_start,
            created_at__date__lt=this_month_start
        ).aggregate(
            total_sales=Sum('total_amount'),
            count=Count('id')
        )
        
        # Get user data
        total_users = User.objects.count()
        new_users_today = User.objects.filter(date_joined__date=today).count()
        new_users_week = User.objects.filter(date_joined__date__gte=this_week_start).count()
        new_users_month = User.objects.filter(date_joined__date__gte=this_month_start).count()
        
        # Get inventory data
        low_stock_products = Product.objects.filter(stock__lte=F('low_stock_threshold'), stock__gt=0).count()
        out_of_stock_products = Product.objects.filter(stock=0).count()
        total_products = Product.objects.count()
        active_products = Product.objects.filter(is_active=True).count()
        
        # Get order status data
        pending_orders = Order.objects.filter(status='pending').count()
        processing_orders = Order.objects.filter(status='processing').count()
        shipped_orders = Order.objects.filter(status='shipped').count()
        delivered_orders = Order.objects.filter(status='delivered').count()
        cancelled_orders = Order.objects.filter(status='cancelled').count()
        
        # Get payment data
        completed_payments = Payment.objects.filter(status='completed').count()
        pending_payments = Payment.objects.filter(status='pending').count()
        failed_payments = Payment.objects.filter(status='failed').count()
        
        # Get top selling products
        top_products = OrderItem.objects.values('product__name').annotate(
            total_sold=Sum('quantity')
        ).order_by('-total_sold')[:5]
        
        # Get cart stats
        active_carts = Cart.objects.filter(merged=False).count()
        abandoned_carts = Cart.objects.filter(
            merged=False, 
            updated_at__lt=timezone.now() - timedelta(days=1)
        ).count()
        
        # Recent orders
        recent_orders = Order.objects.order_by('-created_at')[:5]
        
        # Build context
        context = {
            'sales_data': {
                'today': today_sales,
                'yesterday': yesterday_sales,
                'this_week': this_week_sales,
                'last_week': last_week_sales,
                'this_month': this_month_sales,
                'last_month': last_month_sales,
            },
            'user_data': {
                'total': total_users,
                'new_today': new_users_today,
                'new_week': new_users_week,
                'new_month': new_users_month,
            },
            'inventory_data': {
                'low_stock': low_stock_products,
                'out_of_stock': out_of_stock_products,
                'total': total_products,
                'active': active_products,
            },
            'order_status': {
                'pending': pending_orders,
                'processing': processing_orders,
                'shipped': shipped_orders,
                'delivered': delivered_orders,
                'cancelled': cancelled_orders,
            },
            'payment_data': {
                'completed': completed_payments,
                'pending': pending_payments,
                'failed': failed_payments,
            },
            'top_products': top_products,
            'cart_data': {
                'active': active_carts,
                'abandoned': abandoned_carts,
            },
            'recent_orders': recent_orders,
            'has_low_stock': low_stock_products > 0 or out_of_stock_products > 0,
            'has_abandoned_carts': abandoned_carts > 0,
        }
        
        # Add custom admin actions
        context['admin_actions'] = [
            {
                'name': 'Replenish Low Stock',
                'url': reverse('admin:replenish-low-stock'),
                'description': f'Manage {low_stock_products} low stock products and {out_of_stock_products} out-of-stock products',
                'urgent': low_stock_products > 0 or out_of_stock_products > 0,
            },
            {
                'name': 'Clean Abandoned Carts',
                'url': reverse('admin:clean-abandoned-carts'),
                'description': f'Handle {abandoned_carts} abandoned shopping carts',
                'urgent': abandoned_carts > 10,
            },
            {
                'name': 'Sales Report',
                'url': reverse('admin:sales-report'),
                'description': 'View detailed sales analytics and reports',
                'urgent': False,
            },
        ]
        
        # Combine with any passed context
        if extra_context:
            context.update(extra_context)
        
        return super().index(request, context)

# Create the custom admin site
admin_site = JoulinaAdminSite(name='joulina_admin')

# Register each model with our custom admin site
# This re-registers all models from their respective admin.py files
# with our custom admin site instance
for model, admin_class in admin.site._registry.items():
    admin_site.register(model, admin_class.__class__) 