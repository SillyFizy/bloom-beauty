import django_filters
from django.db.models import F
from .models import Product, Category, Brand

class ProductFilter(django_filters.FilterSet):
    min_price = django_filters.NumberFilter(field_name='price', lookup_expr='gte')
    max_price = django_filters.NumberFilter(field_name='price', lookup_expr='lte')
    category = django_filters.ModelChoiceFilter(queryset=Category.objects.all(), field_name='category')
    brand = django_filters.ModelChoiceFilter(queryset=Brand.objects.all(), field_name='brand')
    is_featured = django_filters.BooleanFilter(field_name='is_featured')
    is_active = django_filters.BooleanFilter(field_name='is_active')
    
    # Filter for products that are on sale
    on_sale = django_filters.BooleanFilter(method='filter_on_sale')
    
    # Filter for products with specific attributes
    attribute = django_filters.CharFilter(method='filter_by_attribute')
    
    # Filter for products with low stock
    low_stock = django_filters.BooleanFilter(method='filter_low_stock')
    
    class Meta:
        model = Product
        fields = ['category', 'brand', 
                  'min_price', 'max_price', 'is_featured', 'is_active',
                  'on_sale', 'attribute', 'low_stock']
    
    def filter_on_sale(self, queryset, name, value):
        if value:
            return queryset.filter(sale_price__isnull=False).filter(sale_price__lt=F('price'))
        return queryset
    
    def filter_by_attribute(self, queryset, name, value):
        """Filter products by attribute:value pair, e.g., 'color:red'"""
        if ':' not in value:
            return queryset
        
        attribute_name, attribute_value = value.split(':', 1)
        return queryset.filter(
            attributes__attribute__name=attribute_name,
            attributes__value=attribute_value
        )
    
    def filter_low_stock(self, queryset, name, value):
        """Filter products with low stock (stock <= threshold)"""
        if value:
            return queryset.filter(stock__lte=F('low_stock_threshold'))
        return queryset 