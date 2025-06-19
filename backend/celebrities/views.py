from rest_framework import generics, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.db.models import Prefetch, Q
from django.conf import settings
from .models import Celebrity, CelebrityProductPromotion, CelebrityMorningRoutine, CelebrityEveningRoutine
from .serializers import (
    CelebrityListSerializer, 
    CelebrityDetailSerializer, 
    CelebrityProductPromotionSerializer,
    ProductCelebrityEndorsementSerializer
)
from products.models import Product
from products.serializers import ProductSerializer, ProductListSerializer


class CelebrityListView(generics.ListAPIView):
    """List all active celebrities with summary information"""
    serializer_class = CelebrityListSerializer
    permission_classes = [AllowAny]
    
    def get_queryset(self):
        return Celebrity.objects.filter(is_active=True).prefetch_related(
            'product_promotions'
        ).order_by('first_name', 'last_name')


class CelebrityDetailView(generics.RetrieveAPIView):
    """Get detailed celebrity information by ID"""
    serializer_class = CelebrityDetailSerializer
    permission_classes = [AllowAny]
    lookup_field = 'pk'
    
    def get_queryset(self):
        return Celebrity.objects.filter(is_active=True).prefetch_related(
            Prefetch(
                'morning_routine_items',
                queryset=CelebrityMorningRoutine.objects.select_related('product').order_by('order')
            ),
            Prefetch(
                'evening_routine_items', 
                queryset=CelebrityEveningRoutine.objects.select_related('product').order_by('order')
            ),
            Prefetch(
                'product_promotions',
                queryset=CelebrityProductPromotion.objects.select_related('product').order_by('-is_featured', '-created_at')
            )
        )


@api_view(['GET'])
@permission_classes([AllowAny])
def celebrity_promotions(request, celebrity_id):
    """Get all product promotions for a specific celebrity"""
    celebrity = get_object_or_404(Celebrity, id=celebrity_id, is_active=True)
    
    promotions = CelebrityProductPromotion.objects.filter(
        celebrity=celebrity
    ).select_related('product').order_by('-is_featured', '-created_at')
    
    # Filter by promotion type if specified
    promotion_type = request.GET.get('type')
    if promotion_type:
        promotions = promotions.filter(promotion_type=promotion_type)
    
    serializer = CelebrityProductPromotionSerializer(promotions, many=True)
    return Response({
        'celebrity': celebrity.full_name,
        'promotions': serializer.data
    })


@api_view(['GET'])
@permission_classes([AllowAny])
def celebrity_morning_routine(request, celebrity_id):
    """Get celebrity's morning routine products"""
    celebrity = get_object_or_404(Celebrity, id=celebrity_id, is_active=True)
    
    routine_items = CelebrityMorningRoutine.objects.filter(
        celebrity=celebrity
    ).select_related('product').order_by('order')
    
    products_data = []
    for item in routine_items:
        product_serializer = ProductSerializer(item.product)
        products_data.append({
            'order': item.order,
            'description': item.description,
            'product': product_serializer.data
        })
    
    return Response({
        'celebrity': celebrity.full_name,
        'morning_routine': products_data
    })


@api_view(['GET'])
@permission_classes([AllowAny])
def celebrity_evening_routine(request, celebrity_id):
    """Get celebrity's evening routine products"""
    celebrity = get_object_or_404(Celebrity, id=celebrity_id, is_active=True)
    
    routine_items = CelebrityEveningRoutine.objects.filter(
        celebrity=celebrity
    ).select_related('product').order_by('order')
    
    products_data = []
    for item in routine_items:
        product_serializer = ProductSerializer(item.product)
        products_data.append({
            'order': item.order,
            'description': item.description,
            'product': product_serializer.data
        })
    
    return Response({
        'celebrity': celebrity.full_name,
        'evening_routine': products_data
    })


@api_view(['GET'])
@permission_classes([AllowAny])
def celebrity_picks(request):
    """Get featured celebrity picks - products promoted by celebrities"""
    
    # Get featured promotions
    featured_promotions = CelebrityProductPromotion.objects.filter(
        is_featured=True,
        celebrity__is_active=True
    ).select_related('celebrity', 'product').order_by('-created_at')
    
    # Filter by celebrity if specified
    celebrity_id = request.GET.get('celebrity_id')
    if celebrity_id:
        featured_promotions = featured_promotions.filter(celebrity__id=celebrity_id)
    
    # Limit results
    limit = int(request.GET.get('limit', 20))
    featured_promotions = featured_promotions[:limit]
    
    picks_data = []
    for promotion in featured_promotions:
        product_serializer = ProductSerializer(promotion.product)
        picks_data.append({
            'celebrity': {
                'id': promotion.celebrity.id,
                'name': promotion.celebrity.full_name,
                'image': promotion.celebrity.image.url if promotion.celebrity.image else None
            },
            'product': product_serializer.data,
            'testimonial': promotion.testimonial,
            'promotion_type': promotion.promotion_type
        })
    
    return Response({
        'celebrity_picks': picks_data
    })


@api_view(['GET'])
@permission_classes([AllowAny])
def celebrity_picks_products(request):
    """Get celebrity picks in the original complex format for the existing UI"""
    
    try:
        limit = int(request.GET.get('limit', 4))
        
        # Get featured promotions with proper error handling
        featured_promotions = CelebrityProductPromotion.objects.filter(
            is_featured=True,
            celebrity__is_active=True,
            product__is_active=True
        ).select_related(
            'product', 
            'celebrity',
            'product__category',
            'product__brand'
        ).prefetch_related(
            'product__images'
        ).order_by('-created_at')[:limit]
        
        # If we don't have enough featured promotions, fallback to any promotions
        if len(featured_promotions) < limit:
            remaining_needed = limit - len(featured_promotions)
            existing_product_ids = [p.product.id for p in featured_promotions]
            
            fallback_promotions = CelebrityProductPromotion.objects.filter(
                celebrity__is_active=True,
                product__is_active=True
            ).exclude(
                product__id__in=existing_product_ids
            ).select_related(
                'product', 
                'celebrity',
                'product__category',
                'product__brand'
            ).prefetch_related(
                'product__images'
            ).order_by('-created_at')[:remaining_needed]
            
            featured_promotions = list(featured_promotions) + list(fallback_promotions)
        
        # Transform to the complex format expected by the original UI
        picks_data = []
        for promotion in featured_promotions:
            try:
                # Serialize product with all necessary fields
                product_serializer = ProductListSerializer(promotion.product, context={'request': request})
                celebrity = promotion.celebrity
                
                # Get related products with error handling
                try:
                    morning_routine = CelebrityMorningRoutine.objects.filter(
                        celebrity=celebrity
                    ).select_related('product', 'product__category', 'product__brand').prefetch_related('product__images')[:3]
                    
                    evening_routine = CelebrityEveningRoutine.objects.filter(
                        celebrity=celebrity
                    ).select_related('product', 'product__category', 'product__brand').prefetch_related('product__images')[:3]
                    
                    recommended_products = CelebrityProductPromotion.objects.filter(
                        celebrity=celebrity
                    ).exclude(id=promotion.id).select_related('product', 'product__category', 'product__brand').prefetch_related('product__images')[:3]
                except Exception as e:
                    print(f"Error fetching related products for celebrity {celebrity.id}: {e}")
                    morning_routine = []
                    evening_routine = []
                    recommended_products = []
                
                # Safely get celebrity image URL
                celebrity_image_url = None
                if celebrity.image:
                    try:
                        celebrity_image_url = celebrity.image.url
                        # Ensure full URL
                        if not celebrity_image_url.startswith('http'):
                            celebrity_image_url = request.build_absolute_uri(celebrity_image_url)
                    except Exception as e:
                        print(f"Error getting celebrity image URL: {e}")
                        celebrity_image_url = None
                
                # Build social media links safely
                social_media_links = {}
                if hasattr(celebrity, 'social_media_links') and celebrity.social_media_links:
                    try:
                        social_media_links = celebrity.social_media_links if isinstance(celebrity.social_media_links, dict) else {}
                    except Exception as e:
                        print(f"Error processing social media links: {e}")
                        social_media_links = {}
                
                pick_data = {
                    'product': product_serializer.data,
                    'name': celebrity.full_name or f"{celebrity.first_name} {celebrity.last_name}".strip(),
                    'image': celebrity_image_url,
                    'testimonial': promotion.testimonial or f"I absolutely love this {promotion.product.name}! It's become an essential part of my beauty routine.",
                    'socialMediaLinks': social_media_links,
                    'recommendedProducts': [
                        ProductListSerializer(rp.product, context={'request': request}).data 
                        for rp in recommended_products
                    ],
                    'morningRoutineProducts': [
                        ProductListSerializer(mr.product, context={'request': request}).data 
                        for mr in morning_routine
                    ],
                    'eveningRoutineProducts': [
                        ProductListSerializer(er.product, context={'request': request}).data 
                        for er in evening_routine
                    ],
                    'celebrity': {
                        'id': celebrity.id,
                        'name': celebrity.full_name or f"{celebrity.first_name} {celebrity.last_name}".strip(),
                        'image': celebrity_image_url,
                        'bio': celebrity.bio or f"Beauty expert and influencer {celebrity.full_name}"
                    }
                }
                picks_data.append(pick_data)
                
            except Exception as e:
                print(f"Error processing celebrity pick for promotion {promotion.id}: {e}")
                continue
        
        return Response(picks_data)
        
    except Exception as e:
        print(f"Error in celebrity_picks_products view: {e}")
        return Response({
            'error': 'Failed to fetch celebrity picks',
            'detail': str(e) if settings.DEBUG else 'Internal server error'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([AllowAny])
def product_celebrity_endorsements(request, product_id):
    """Get celebrity endorsements for a specific product"""
    product = get_object_or_404(Product, id=product_id)
    
    endorsements = CelebrityProductPromotion.objects.filter(
        product=product,
        celebrity__is_active=True
    ).select_related('celebrity').order_by('-is_featured', '-created_at')
    
    serializer = ProductCelebrityEndorsementSerializer(endorsements, many=True)
    
    return Response({
        'product': product.name,
        'endorsements': serializer.data
    })


@api_view(['GET'])
@permission_classes([AllowAny])
def celebrities_by_category(request):
    """Get celebrities who promote products in specific categories"""
    category_id = request.GET.get('category_id')
    
    if not category_id:
        return Response({'error': 'category_id parameter is required'}, status=status.HTTP_400_BAD_REQUEST)
    
    # Get celebrities who promote products in the specified category
    celebrities = Celebrity.objects.filter(
        is_active=True,
        product_promotions__product__category_id=category_id
    ).distinct().prefetch_related('product_promotions')
    
    serializer = CelebrityListSerializer(celebrities, many=True)
    
    return Response({
        'celebrities': serializer.data
    })


@api_view(['GET'])
@permission_classes([AllowAny])
def search_celebrities(request):
    """Search celebrities by name"""
    query = request.GET.get('q', '').strip()
    
    if not query:
        return Response({'error': 'Query parameter "q" is required'}, status=status.HTTP_400_BAD_REQUEST)
    
    celebrities = Celebrity.objects.filter(
        Q(first_name__icontains=query) | Q(last_name__icontains=query),
        is_active=True
    ).prefetch_related('product_promotions').order_by('first_name', 'last_name')
    
    serializer = CelebrityListSerializer(celebrities, many=True)
    
    return Response({
        'query': query,
        'results': serializer.data
    }) 