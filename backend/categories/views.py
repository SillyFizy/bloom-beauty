from rest_framework import generics, status, permissions
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from django.shortcuts import get_object_or_404
from django.db.models import Q
from .models import NavigationCategory
from .serializers import (
    NavigationCategorySerializer,
    NavigationCategoryCreateSerializer, 
    NavigationCategoryUpdateSerializer,
    NavigationCategoryPublicSerializer
)

# Public endpoint for frontend to get active categories
@api_view(['GET'])
@permission_classes([permissions.AllowAny])
def get_navigation_categories(request):
    """
    Get all active navigation categories for frontend consumption
    """
    try:
        categories = NavigationCategory.objects.filter(
            is_active=True
        ).order_by('order', 'name')
        
        serializer = NavigationCategoryPublicSerializer(categories, many=True)
        
        return Response({
            'success': True,
            'count': len(serializer.data),
            'categories': serializer.data
        }, status=status.HTTP_200_OK)
    
    except Exception as e:
        return Response({
            'success': False,
            'error': 'Failed to fetch navigation categories',
            'details': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# Admin endpoints for CRUD operations
class NavigationCategoryListView(generics.ListCreateAPIView):
    """
    GET: List all navigation categories (admin)
    POST: Create new navigation category (admin)
    """
    queryset = NavigationCategory.objects.all().order_by('order', 'name')
    permission_classes = [permissions.IsAdminUser]
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return NavigationCategoryCreateSerializer
        return NavigationCategorySerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            category = serializer.save()
            response_serializer = NavigationCategorySerializer(category)
            return Response({
                'success': True,
                'message': 'Navigation category created successfully',
                'category': response_serializer.data
            }, status=status.HTTP_201_CREATED)
        return Response({
            'success': False,
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)

class NavigationCategoryDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    GET: Retrieve specific navigation category (admin)
    PUT/PATCH: Update navigation category (admin)  
    DELETE: Delete navigation category (admin)
    """
    queryset = NavigationCategory.objects.all()
    permission_classes = [permissions.IsAdminUser]
    
    def get_serializer_class(self):
        if self.request.method in ['PUT', 'PATCH']:
            return NavigationCategoryUpdateSerializer
        return NavigationCategorySerializer

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        
        if serializer.is_valid():
            category = serializer.save()
            response_serializer = NavigationCategorySerializer(category)
            return Response({
                'success': True,
                'message': 'Navigation category updated successfully',
                'category': response_serializer.data
            }, status=status.HTTP_200_OK)
        
        return Response({
            'success': False,
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        category_name = instance.name
        instance.delete()
        return Response({
            'success': True,
            'message': f'Navigation category "{category_name}" deleted successfully'
        }, status=status.HTTP_204_NO_CONTENT)

# Bulk operations for admin
@api_view(['POST'])
@permission_classes([permissions.IsAdminUser])
def bulk_update_categories(request):
    """
    Bulk update category orders and active status
    Expected format: [{"id": 1, "order": 0, "is_active": true}, ...]
    """
    try:
        categories_data = request.data.get('categories', [])
        
        if not categories_data:
            return Response({
                'success': False,
                'error': 'No categories data provided'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        updated_count = 0
        for category_data in categories_data:
            category_id = category_data.get('id')
            if not category_id:
                continue
                
            try:
                category = NavigationCategory.objects.get(id=category_id)
                if 'order' in category_data:
                    category.order = category_data['order']
                if 'is_active' in category_data:
                    category.is_active = category_data['is_active']
                category.save()
                updated_count += 1
            except NavigationCategory.DoesNotExist:
                continue
        
        return Response({
            'success': True,
            'message': f'Successfully updated {updated_count} categories'
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'error': 'Failed to bulk update categories',
            'details': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([permissions.IsAdminUser])
def category_statistics(request):
    """
    Get statistics about navigation categories
    """
    try:
        total_categories = NavigationCategory.objects.count()
        active_categories = NavigationCategory.objects.filter(is_active=True).count()
        inactive_categories = total_categories - active_categories
        
        return Response({
            'success': True,
            'statistics': {
                'total_categories': total_categories,
                'active_categories': active_categories,
                'inactive_categories': inactive_categories,
                'categories_with_icons': NavigationCategory.objects.exclude(icon='').count(),
                'avg_keywords_per_category': NavigationCategory.objects.filter(
                    is_active=True
                ).count()  # Simplified for now
            }
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'error': 'Failed to get category statistics',
            'details': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR) 