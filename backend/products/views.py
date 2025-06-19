from django.shortcuts import render, get_object_or_404
from django.db.models import Q, F, Count, Avg, Sum, Min, Max, Case, When, Value, IntegerField
from rest_framework import viewsets, permissions, filters, status, mixins
from rest_framework.decorators import action, throttle_classes
from rest_framework.response import Response
from rest_framework.throttling import UserRateThrottle, AnonRateThrottle
from django_filters.rest_framework import DjangoFilterBackend
from django.db import transaction
from django.utils.decorators import method_decorator
from django.views.decorators.cache import cache_page
from django.core.cache import cache
from django.conf import settings
import datetime
from datetime import timedelta

from .models import (
    Product, Category, ProductImage, Brand, 
    ProductAttribute, ProductAttributeValue, 
    ProductVariant, InventoryLog, Review, ProductRating
)
from .serializers import (
    ProductSerializer, CategorySerializer, ProductImageSerializer,
    BrandSerializer, ProductAttributeSerializer, ProductAttributeValueSerializer,
    ProductVariantSerializer, InventoryLogSerializer, ProductListSerializer,
    ProductRatingSerializer
)
from .permissions import IsAdminOrReadOnly
from .filters import ProductFilter

# Custom throttle classes
class ProductRateThrottle(UserRateThrottle):
    scope = 'product'

# Create your views here.

class CategoryViewSet(viewsets.ModelViewSet):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer
    permission_classes = [IsAdminOrReadOnly]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['name', 'description']
    ordering_fields = ['name', 'created_at']
    lookup_field = 'slug'
    
    def get_queryset(self):
        queryset = Category.objects.filter(is_active=True)
        if self.request.user.is_staff:
            # Staff users can see all categories
            queryset = Category.objects.all()
        return queryset
    
    @method_decorator(cache_page(60*60*2))  # Cache for 2 hours
    @action(detail=True)
    def products(self, request, slug=None):
        """Get all products in this category"""
        category = self.get_object()
        products = Product.objects.filter(category=category, is_active=True)
        
        # Include products from subcategories if requested
        include_subcategories = request.query_params.get('include_subcategories', 'false').lower() == 'true'
        if include_subcategories:
            subcategories = Category.objects.filter(parent=category)
            for subcategory in subcategories:
                subcategory_products = Product.objects.filter(category=subcategory, is_active=True)
                products = products | subcategory_products
        
        # Apply additional filtering
        price_min = request.query_params.get('price_min')
        price_max = request.query_params.get('price_max')
        brand_id = request.query_params.get('brand')
        
        if price_min:
            products = products.filter(price__gte=price_min)
        if price_max:
            products = products.filter(price__lte=price_max)
        if brand_id:
            products = products.filter(brand_id=brand_id)
            
        # Apply sorting
        sort_by = request.query_params.get('sort_by', 'created_at')
        sort_dir = request.query_params.get('sort_dir', 'desc')
        
        order_field = '-' + sort_by if sort_dir == 'desc' else sort_by
        products = products.order_by(order_field)
        
        page = self.paginate_queryset(products)
        if page is not None:
            serializer = ProductListSerializer(page, many=True, context={'request': request})
            return self.get_paginated_response(serializer.data)
            
        serializer = ProductListSerializer(products, many=True, context={'request': request})
        return Response(serializer.data)
    
    @method_decorator(cache_page(60*60*24))  # Cache for 24 hours
    @action(detail=False)
    def tree(self, request):
        """
        Get hierarchical category tree
        """
        top_categories = Category.objects.filter(parent=None, is_active=True)
        
        def get_children(category):
            children = Category.objects.filter(parent=category, is_active=True)
            return [
                {
                    'id': child.id,
                    'name': child.name,
                    'slug': child.slug,
                    'children': get_children(child)
                }
                for child in children
            ]
        
        result = [
            {
                'id': category.id,
                'name': category.name,
                'slug': category.slug,
                'children': get_children(category)
            }
            for category in top_categories
        ]
        
        return Response(result)

class BrandViewSet(viewsets.ModelViewSet):
    queryset = Brand.objects.all()
    serializer_class = BrandSerializer
    permission_classes = [IsAdminOrReadOnly]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['name', 'description']
    ordering_fields = ['name', 'created_at']
    lookup_field = 'slug'
    
    def get_queryset(self):
        queryset = Brand.objects.filter(is_active=True)
        if self.request.user.is_staff:
            # Staff users can see all brands
            queryset = Brand.objects.all()
        return queryset
    
    @method_decorator(cache_page(60*60*2))  # Cache for 2 hours
    @action(detail=True)
    def products(self, request, slug=None):
        """Get all products for this brand"""
        brand = self.get_object()
        products = Product.objects.filter(brand=brand, is_active=True)
        
        # Apply additional filtering
        category_id = request.query_params.get('category')
        price_min = request.query_params.get('price_min')
        price_max = request.query_params.get('price_max')
        
        if category_id:
            products = products.filter(category_id=category_id)
        if price_min:
            products = products.filter(price__gte=price_min)
        if price_max:
            products = products.filter(price__lte=price_max)
            
        # Apply sorting
        sort_by = request.query_params.get('sort_by', 'created_at')
        sort_dir = request.query_params.get('sort_dir', 'desc')
        
        order_field = '-' + sort_by if sort_dir == 'desc' else sort_by
        products = products.order_by(order_field)
        
        page = self.paginate_queryset(products)
        if page is not None:
            serializer = ProductListSerializer(page, many=True, context={'request': request})
            return self.get_paginated_response(serializer.data)
            
        serializer = ProductListSerializer(products, many=True, context={'request': request})
        return Response(serializer.data)

class ProductAttributeViewSet(viewsets.ModelViewSet):
    queryset = ProductAttribute.objects.all()
    serializer_class = ProductAttributeSerializer
    permission_classes = [IsAdminOrReadOnly]
    
    @action(detail=True)
    def values(self, request, pk=None):
        """Get all values for this attribute"""
        attribute = self.get_object()
        values = ProductAttributeValue.objects.filter(attribute=attribute)
        serializer = ProductAttributeValueSerializer(values, many=True)
        return Response(serializer.data)

class ProductAttributeValueViewSet(viewsets.ModelViewSet):
    queryset = ProductAttributeValue.objects.all()
    serializer_class = ProductAttributeValueSerializer
    permission_classes = [IsAdminOrReadOnly]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['attribute']

class ProductViewSet(viewsets.ModelViewSet):
    queryset = Product.objects.all()
    serializer_class = ProductSerializer
    permission_classes = [IsAdminOrReadOnly]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_class = ProductFilter
    search_fields = ['name', 'description', 'meta_keywords', 'sku']
    ordering_fields = ['price', 'created_at', 'name', 'rating']
    lookup_field = 'slug'
    throttle_classes = [ProductRateThrottle]
    
    def get_queryset(self):
        queryset = Product.objects.filter(is_active=True).select_related('rating_stats', 'category', 'brand')
        if self.request.user and self.request.user.is_staff:
            # Staff users can see all products
            queryset = Product.objects.all().select_related('rating_stats', 'category', 'brand')
        return queryset
    
    def get_serializer_class(self):
        if self.action == 'list':
            return ProductListSerializer
        return ProductSerializer
    
    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context
    
    @method_decorator(cache_page(60*30))  # Cache for 30 minutes
    @action(detail=False, methods=['get'])
    def featured(self, request):
        """Get featured products"""
        limit = int(request.query_params.get('limit', 10))
        
        # Apply sorting BEFORE slicing
        sort_by = request.query_params.get('sort_by', 'created_at')
        sort_dir = request.query_params.get('sort_dir', 'desc')
        
        order_field = '-' + sort_by if sort_dir == 'desc' else sort_by
        featured_products = Product.objects.filter(
            is_featured=True, is_active=True
        ).select_related('rating_stats', 'category', 'brand').order_by(order_field)[:limit]
        
        page = self.paginate_queryset(featured_products)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        serializer = self.get_serializer(featured_products, many=True)
        return Response(serializer.data)
    
    @method_decorator(cache_page(60*30))  # Cache for 30 minutes
    @action(detail=False, methods=['get'])
    def on_sale(self, request):
        """Get products on sale"""
        limit = int(request.query_params.get('limit', 10))
        discount_min = request.query_params.get('discount_min')
        
        on_sale_products = Product.objects.filter(
            sale_price__isnull=False, 
            is_active=True
        ).filter(sale_price__lt=F('price'))
        
        # Filter by minimum discount percentage
        if discount_min:
            # Calculate discount percentage: ((price - sale_price) / price) * 100
            discount_min = float(discount_min)
            on_sale_products = on_sale_products.annotate(
                discount_percent=((F('price') - F('sale_price')) * 100 / F('price'))
            ).filter(discount_percent__gte=discount_min)
        
        # Apply sorting
        sort_by = request.query_params.get('sort_by', 'discount_percent')
        sort_dir = request.query_params.get('sort_dir', 'desc')
        
        if sort_by == 'discount_percent' and not discount_min:
            # Add the annotation if not already added
            on_sale_products = on_sale_products.annotate(
                discount_percent=((F('price') - F('sale_price')) * 100 / F('price'))
            )
        
        order_field = '-' + sort_by if sort_dir == 'desc' else sort_by
        on_sale_products = on_sale_products.order_by(order_field)[:limit]
        
        page = self.paginate_queryset(on_sale_products)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        serializer = self.get_serializer(on_sale_products, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'], permission_classes=[permissions.IsAdminUser])
    def low_stock(self, request):
        """Get products with low stock (admin only)"""
        if not request.user.is_staff:
            return Response(
                {"detail": "You do not have permission to perform this action."},
                status=status.HTTP_403_FORBIDDEN
            )
        
        is_out = request.query_params.get('is_out', 'false').lower() == 'true'
        
        if is_out:
            # Get products that are completely out of stock
            low_stock_products = Product.objects.filter(stock=0)
        else:
            # Get products with stock below threshold but not zero
            low_stock_products = Product.objects.filter(
                stock__lte=F('low_stock_threshold'),
                stock__gt=0
            )
        
        page = self.paginate_queryset(low_stock_products)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        serializer = self.get_serializer(low_stock_products, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def search(self, request):
        """Advanced product search with text, category, brand, price filters"""
        query = request.query_params.get('q', '')
        category_id = request.query_params.get('category')
        brand_id = request.query_params.get('brand')
        price_min = request.query_params.get('price_min')
        price_max = request.query_params.get('price_max')
        attribute = request.query_params.get('attribute')
        in_stock = request.query_params.get('in_stock', 'false').lower() == 'true'
        
        # Build query
        products = Product.objects.filter(is_active=True)
        
        if query:
            products = products.filter(
                Q(name__icontains=query) | 
                Q(description__icontains=query) |
                Q(meta_keywords__icontains=query) |
                Q(sku__icontains=query)
            )
        
        # Apply filters
        if category_id:
            products = products.filter(category_id=category_id)
        if brand_id:
            products = products.filter(brand_id=brand_id)
        if price_min:
            products = products.filter(price__gte=price_min)
        if price_max:
            products = products.filter(price__lte=price_max)
        if in_stock:
            products = products.filter(stock__gt=0)
        if attribute and ':' in attribute:
            attr_name, attr_value = attribute.split(':', 1)
            products = products.filter(
                attributes__attribute__name=attr_name,
                attributes__value=attr_value
            )
        
        # Apply sorting
        sort_by = request.query_params.get('sort_by', 'created_at')
        sort_dir = request.query_params.get('sort_dir', 'desc')
        
        order_field = '-' + sort_by if sort_dir == 'desc' else sort_by
        products = products.order_by(order_field)
        
        page = self.paginate_queryset(products)
        if page is not None:
            serializer = ProductListSerializer(page, many=True, context={'request': request})
            return self.get_paginated_response(serializer.data)
        
        serializer = ProductListSerializer(products, many=True, context={'request': request})
        return Response(serializer.data)
    
    @method_decorator(cache_page(60*60*24))  # Cache for 24 hours
    @action(detail=False, methods=['get'])
    def stats(self, request):
        """Get product statistics (total count, price ranges, etc.)"""
        # Get all active products
        products = Product.objects.filter(is_active=True)
        
        # Get category counts
        category_counts = {}
        categories = Category.objects.filter(is_active=True)
        for category in categories:
            count = products.filter(category=category).count()
            if count > 0:
                category_counts[category.name] = count
        
        # Get brand counts
        brand_counts = {}
        brands = Brand.objects.filter(is_active=True)
        for brand in brands:
            count = products.filter(brand=brand).count()
            if count > 0:
                brand_counts[brand.name] = count
        
        # Get price statistics
        price_stats = products.aggregate(
            min_price=Min('price'),
            max_price=Max('price'),
            avg_price=Avg('price')
        )
        
        # Get counts
        total_products = products.count()
        featured_count = products.filter(is_featured=True).count()
        on_sale_count = products.filter(sale_price__isnull=False).filter(sale_price__lt=F('price')).count()
        
        # Build response
        response_data = {
            'total_products': total_products,
            'featured_count': featured_count,
            'on_sale_count': on_sale_count,
            'price_stats': price_stats,
            'categories': category_counts,
            'brands': brand_counts
        }
        
        return Response(response_data)
    
    @action(detail=False, methods=['get'])
    def new_arrivals(self, request):
        """Get recently added products"""
        days = int(request.query_params.get('days', 30))
        limit = int(request.query_params.get('limit', 10))
        
        # Calculate date threshold
        threshold_date = datetime.datetime.now() - datetime.timedelta(days=days)
        
        # Get new products
        new_products = Product.objects.filter(
            is_active=True,
            created_at__gte=threshold_date
        ).order_by('-created_at')[:limit]
        
        serializer = ProductListSerializer(new_products, many=True, context={'request': request})
        return Response(serializer.data)
    
    @method_decorator(cache_page(60*30))  # Cache for 30 minutes
    @action(detail=False, methods=['get'])
    def bestselling(self, request):
        """
        Get best selling products from recent past period (default: 30 days, offset by 7 days)
        Uses two-step approach: 1) Get sales data from OrderItem, 2) Get fresh product data from Product
        """
        from orders.models import OrderItem
        
        limit = int(request.query_params.get('limit', 10))
        days = int(request.query_params.get('days', 30))  # Period length
        offset = int(request.query_params.get('offset', 7))  # Start offset (proven winners from past)
        
        # Calculate date thresholds for offset period
        end_date = datetime.datetime.now() - timedelta(days=offset)      # 7 days ago
        start_date = end_date - timedelta(days=days)                     # 37 days ago
        
        # STEP 1: Get sales analytics from OrderItem table (historical sales data)
        bestselling_sales = OrderItem.objects.filter(
            order__created_at__gte=start_date,
            order__created_at__lt=end_date,
            product__isnull=False,  # Only items with products (not variants)
            product__is_active=True  # Only active products
        ).values('product_id').annotate(
            total_sold=Sum('quantity')
        ).order_by('-total_sold')[:limit]
        
        # Extract product IDs from sales data
        bestselling_product_ids = [item['product_id'] for item in bestselling_sales]
        
        # STEP 2: Get fresh product details from Product table
        if bestselling_product_ids:
            # Get products and preserve the bestselling order
            bestselling_products = Product.objects.filter(
                id__in=bestselling_product_ids,
                is_active=True
            ).select_related('category', 'brand')
            
            # Create a dict for fast lookup and preserve order
            products_dict = {p.id: p for p in bestselling_products}
            initial_results = [products_dict[pid] for pid in bestselling_product_ids if pid in products_dict]
        else:
            initial_results = []
        
        # If we have enough bestselling products, return them
        if len(initial_results) >= limit:
            page = self.paginate_queryset(initial_results[:limit])
            if page is not None:
                serializer = self.get_serializer(page, many=True)
                return self.get_paginated_response(serializer.data)
            serializer = self.get_serializer(initial_results[:limit], many=True)
            return Response(serializer.data)
        
        # FALLBACK SYSTEM: Get trending IDs to exclude them from bestselling fallbacks
        trending_threshold = datetime.datetime.now() - timedelta(days=7)
        trending_sales = OrderItem.objects.filter(
            order__created_at__gte=trending_threshold,
            product__isnull=False,
            product__is_active=True
        ).values('product_id').annotate(
            total_sold=Sum('quantity')
        ).order_by('-total_sold')[:10]
        
        trending_ids = set(item['product_id'] for item in trending_sales)
        
        # If no trending from sales, add newest products to trending exclusion
        if len(trending_ids) < 10:
            newest_trending_ids = set(Product.objects.filter(
                is_active=True,
                price__gt=0,
                stock__gt=0
            ).exclude(
                id__in=trending_ids
            ).order_by('-created_at')[:(10 - len(trending_ids))].values_list('id', flat=True))
            trending_ids.update(newest_trending_ids)
        
        # Get excluded IDs (already selected + trending)
        excluded_ids = set(p.id for p in initial_results) | trending_ids
        remaining_needed = limit - len(initial_results)
        
        # Get fallback products with current data only
        fallback_products = list(Product.objects.filter(
            is_active=True,
            price__gt=0,  # Only products with valid current pricing
            stock__gt=0   # Only products with current stock
        ).exclude(
            id__in=excluded_ids
        ).select_related('category', 'brand').annotate(
            # Add scoring for better fallback selection
            score=Case(
                When(is_featured=True, then=Value(3)),
                When(sale_price__isnull=False, then=Value(2)),
                default=Value(1),
                output_field=IntegerField()
            )
        ).order_by('-score', '-created_at')[:remaining_needed])
        
        # Combine results
        final_results = initial_results + fallback_products
        
        # If still not enough, get remaining products (last resort)
        if len(final_results) < limit:
            still_needed = limit - len(final_results)
            final_excluded_ids = set(p.id for p in final_results) | trending_ids
            
            last_resort = list(Product.objects.filter(
                is_active=True
            ).exclude(
                id__in=final_excluded_ids
            ).select_related('category', 'brand').order_by('?')[:still_needed])
            
            final_results.extend(last_resort)
        
        # Ensure we don't exceed the limit
        final_results = final_results[:limit]
        
        page = self.paginate_queryset(final_results)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        serializer = self.get_serializer(final_results, many=True)
        return Response(serializer.data)
    
    @method_decorator(cache_page(60*15))  # Cache for 15 minutes (shorter for trending)
    @action(detail=False, methods=['get'])
    def trending(self, request):
        """
        Get trending products based on recent sales activity (default: last 7 days from now)
        Uses two-step approach: 1) Get sales data from OrderItem, 2) Get fresh product data from Product
        """
        from orders.models import OrderItem
        
        limit = int(request.query_params.get('limit', 10))
        days = int(request.query_params.get('days', 7))  # Default to 7 days for trending
        
        # Calculate date threshold (no offset - current period)
        threshold_date = datetime.datetime.now() - timedelta(days=days)
        
        # STEP 1: Get sales analytics from OrderItem table (recent sales data)
        trending_sales = OrderItem.objects.filter(
            order__created_at__gte=threshold_date,
            product__isnull=False,  # Only items with products (not variants)
            product__is_active=True  # Only active products
        ).values('product_id').annotate(
            total_sold=Sum('quantity')
        ).order_by('-total_sold')[:limit]
        
        # Extract product IDs from sales data
        trending_product_ids = [item['product_id'] for item in trending_sales]
        
        # STEP 2: Get fresh product details from Product table
        if trending_product_ids:
            # Get products and preserve the trending order
            trending_products = Product.objects.filter(
                id__in=trending_product_ids,
                is_active=True
            ).select_related('category', 'brand')
            
            # Create a dict for fast lookup and preserve order
            products_dict = {p.id: p for p in trending_products}
            results = [products_dict[pid] for pid in trending_product_ids if pid in products_dict]
        else:
            results = []
        
        # Fallback if no recent sales data (development/new site scenario)
        if len(results) < limit:
            remaining_needed = limit - len(results)
            
            # Add newest products as trending fallback with current valid data
            newest_products = Product.objects.filter(
                is_active=True,
                price__gt=0,  # Only products with valid current pricing
                stock__gt=0   # Only products with current stock
            ).select_related('category', 'brand').exclude(
                id__in=[p.id for p in results]
            ).order_by('-created_at')[:remaining_needed]
            
            results.extend(list(newest_products))
        
        page = self.paginate_queryset(results)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        serializer = self.get_serializer(results, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAdminUser])
    def update_stock(self, request, slug=None):
        """Update product stock"""
        product = self.get_object()
        
        try:
            # Get data from request
            quantity = int(request.data.get('quantity', 0))
            adjustment_type = request.data.get('adjustment_type', '')
            reference = request.data.get('reference', '')
            
            if adjustment_type not in ['stock_in', 'stock_out', 'adjustment']:
                return Response(
                    {"error": "Invalid adjustment type. Must be 'stock_in', 'stock_out', or 'adjustment'"},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            with transaction.atomic():
                # Update product stock based on adjustment type
                if adjustment_type == 'stock_in':
                    product.stock += quantity
                elif adjustment_type == 'stock_out':
                    if product.stock < quantity:
                        return Response(
                            {"error": f"Not enough stock. Current stock: {product.stock}, Requested: {quantity}"},
                            status=status.HTTP_400_BAD_REQUEST
                        )
                    product.stock -= quantity
                elif adjustment_type == 'adjustment':
                    # For direct adjustment, quantity can be negative
                    product.stock += quantity
                
                product.save()
                
                # Create inventory log
                InventoryLog.objects.create(
                    product=product,
                    quantity=abs(quantity),
                    adjustment_type=adjustment_type,
                    reference=reference,
                    user=request.user
                )
                
                # Serialize and return updated product
                serializer = self.get_serializer(product)
                return Response(serializer.data)
                
        except ValueError:
            return Response(
                {"error": "Invalid quantity value"},
                status=status.HTTP_400_BAD_REQUEST
            )
    
    @action(detail=True, methods=['get'])
    def variants(self, request, slug=None):
        """Get variants for a product"""
        product = self.get_object()
        variants = product.variants.filter(is_active=True)
        serializer = ProductVariantSerializer(variants, many=True, context={'request': request})
        return Response(serializer.data)
    
    @action(detail=True, methods=['get'])
    def images(self, request, slug=None):
        """Get all images for a product"""
        product = self.get_object()
        images = product.images.all()
        serializer = ProductImageSerializer(images, many=True, context={'request': request})
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def recommended(self, request):
        """Get recommended products based on category popularity"""
        limit = int(request.query_params.get('limit', 10))
        
        # Get popular categories by product count
        popular_categories = Category.objects.annotate(
            product_count=Count('products')
        ).order_by('-product_count')[:3]
        
        # Get a few products from each popular category
        recommended_products = []
        per_category = max(1, limit // len(popular_categories))
        
        for category in popular_categories:
            category_products = Product.objects.filter(
                category=category,
                is_active=True
            ).order_by('?')[:per_category]  # Random selection
            
            recommended_products.extend(list(category_products))
        
        # If we don't have enough products, add more from any category
        if len(recommended_products) < limit:
            more_products = Product.objects.filter(
                is_active=True
            ).exclude(
                id__in=[p.id for p in recommended_products]
            ).order_by('?')[:limit-len(recommended_products)]
            
            recommended_products.extend(list(more_products))
        
        serializer = ProductListSerializer(recommended_products, many=True, context={'request': request})
        return Response(serializer.data)

    @method_decorator(cache_page(60*15))  # Cache for 15 minutes
    @action(detail=True, methods=['get'])
    def rating(self, request, slug=None):
        """Get detailed rating information for a specific product"""
        product = self.get_object()
        try:
            rating_stats = product.rating_stats
            serializer = ProductRatingSerializer(rating_stats)
            return Response({
                'product_id': product.id,
                'product_name': product.name,
                'product_slug': product.slug,
                'rating_data': serializer.data
            })
        except ProductRating.DoesNotExist:
            return Response({
                'product_id': product.id,
                'product_name': product.name,
                'product_slug': product.slug,
                'rating_data': {
                    'total_reviews': 0,
                    'average_rating': 0.00,
                    'rating_1_count': 0,
                    'rating_2_count': 0,
                    'rating_3_count': 0,
                    'rating_4_count': 0,
                    'rating_5_count': 0,
                    'rating_distribution': [],
                    'rating_percentages': [],
                    'last_calculated': None
                }
            })
    
    @method_decorator(cache_page(60*30))  # Cache for 30 minutes  
    @action(detail=False, methods=['get'])
    def top_rated(self, request):
        """Get top-rated products"""
        limit = int(request.query_params.get('limit', 10))
        min_reviews = int(request.query_params.get('min_reviews', 5))  # Minimum reviews to be considered
        
        # Get products with ratings, sorted by average rating
        top_rated_products = Product.objects.filter(
            is_active=True,
            rating_stats__total_reviews__gte=min_reviews
        ).select_related('rating_stats', 'category', 'brand').order_by(
            '-rating_stats__average_rating', 
            '-rating_stats__total_reviews'
        )[:limit]
        
        serializer = self.get_serializer(top_rated_products, many=True)
        return Response({
            'count': len(top_rated_products),
            'min_reviews_filter': min_reviews,
            'results': serializer.data
        })

class ProductImageViewSet(viewsets.ModelViewSet):
    queryset = ProductImage.objects.all()
    serializer_class = ProductImageSerializer
    permission_classes = [IsAdminOrReadOnly]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['product']
    
    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context

class ProductVariantViewSet(viewsets.ModelViewSet):
    queryset = ProductVariant.objects.all()
    serializer_class = ProductVariantSerializer
    permission_classes = [IsAdminOrReadOnly]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['product', 'is_active']
    search_fields = ['name', 'sku']
    
    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAdminUser])
    def update_stock(self, request, pk=None):
        """Update variant stock"""
        variant = self.get_object()
        
        try:
            # Get data from request
            quantity = int(request.data.get('quantity', 0))
            adjustment_type = request.data.get('adjustment_type', '')
            reference = request.data.get('reference', '')
            
            if adjustment_type not in ['stock_in', 'stock_out', 'adjustment']:
                return Response(
                    {"error": "Invalid adjustment type. Must be 'stock_in', 'stock_out', or 'adjustment'"},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            with transaction.atomic():
                # Update variant stock based on adjustment type
                if adjustment_type == 'stock_in':
                    variant.stock += quantity
                elif adjustment_type == 'stock_out':
                    if variant.stock < quantity:
                        return Response(
                            {"error": f"Not enough stock. Current stock: {variant.stock}, Requested: {quantity}"},
                            status=status.HTTP_400_BAD_REQUEST
                        )
                    variant.stock -= quantity
                elif adjustment_type == 'adjustment':
                    # For direct adjustment, quantity can be negative
                    variant.stock += quantity
                
                variant.save()
                
                # Create inventory log
                InventoryLog.objects.create(
                    product=variant.product,
                    variant=variant,
                    quantity=abs(quantity),
                    adjustment_type=adjustment_type,
                    reference=reference,
                    user=request.user
                )
                
                # Serialize and return updated variant
                serializer = self.get_serializer(variant)
                return Response(serializer.data)
                
        except ValueError:
            return Response(
                {"error": "Invalid quantity value"},
                status=status.HTTP_400_BAD_REQUEST
            )

class InventoryLogViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = InventoryLogSerializer
    permission_classes = [permissions.IsAdminUser]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['product', 'variant', 'adjustment_type']
    ordering_fields = ['created_at']
    ordering = ['-created_at']
    
    def get_queryset(self):
        """Only return logs for the authenticated user"""
        # Adjust queryset based on parameters
        queryset = InventoryLog.objects.all()
        
        # Filter by date range if provided
        start_date = self.request.query_params.get('start_date', None)
        end_date = self.request.query_params.get('end_date', None)
        
        if start_date:
            queryset = queryset.filter(created_at__gte=start_date)
        if end_date:
            queryset = queryset.filter(created_at__lte=end_date)
            
        return queryset
