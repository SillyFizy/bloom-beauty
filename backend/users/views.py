# users/views.py
from django.contrib.auth import get_user_model
from rest_framework import status, generics, permissions, viewsets
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.decorators import action
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.sites.shortcuts import get_current_site
from django.urls import reverse
from django.conf import settings
import jwt
from datetime import datetime, timedelta
from django.core.mail import send_mail
from django.utils.http import urlsafe_base64_encode, urlsafe_base64_decode
from django.utils.encoding import force_bytes, force_str
from django.db.models import Sum, Count, Q
from django.shortcuts import get_object_or_404
from rest_framework import serializers
from rest_framework.pagination import PageNumberPagination

from .models import User, PointTransaction
from .serializers import (
    UserSerializer, UserRegistrationSerializer,
    CustomTokenObtainPairSerializer, PasswordChangeSerializer,
    AddressSerializer,
    PointTransactionSerializer, NotificationPreferencesSerializer,
    ProfilePictureSerializer, UserPreferencesSerializer,
    OrderSummarySerializer
)
from orders.models import Order, OrderItem, OrderStatusHistory
from orders.serializers import OrderDetailSerializer

User = get_user_model()

class UserRegistrationView(generics.CreateAPIView):
    queryset = User.objects.all()
    permission_classes = [permissions.AllowAny]
    serializer_class = UserRegistrationSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        
        # Since we're using phone number auth, set user as verified by default
        # In production, you might want to implement SMS verification
        user.is_verified = True
        user.save()

        return Response({
            "user": UserSerializer(user, context=self.get_serializer_context()).data,
            "message": "User registered successfully."
        }, status=status.HTTP_201_CREATED)

class CustomTokenObtainPairView(TokenObtainPairView):
    serializer_class = CustomTokenObtainPairSerializer

class UserProfileView(generics.RetrieveUpdateAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user
    
    def update(self, request, *args, **kwargs):
        """
        Allow partial updates to user profile
        """
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)
        
        return Response(serializer.data)

class PasswordChangeView(generics.UpdateAPIView):
    serializer_class = PasswordChangeSerializer
    permission_classes = [permissions.IsAuthenticated]

    def update(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        user = request.user
        if not user.check_password(serializer.validated_data['old_password']):
            return Response({"old_password": ["Wrong password."]}, status=status.HTTP_400_BAD_REQUEST)
        
        user.set_password(serializer.validated_data['new_password'])
        user.save()
        
        return Response({"message": "Password updated successfully"}, status=status.HTTP_200_OK)

class UserAddressView(generics.UpdateAPIView):
    serializer_class = AddressSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_object(self):
        return self.request.user
    
    def update(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        user = self.get_object()
        for key, value in serializer.validated_data.items():
            setattr(user, key, value)
        user.save()
        
        return Response({
            "message": "Address updated successfully",
            "address": AddressSerializer(user).data
        }, status=status.HTTP_200_OK)

class ProfilePictureUpdateView(generics.UpdateAPIView):
    serializer_class = ProfilePictureSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_object(self):
        return self.request.user
    
    def update(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        user = self.get_object()
        user.profile_picture = serializer.validated_data['profile_picture']
        user.save()
        
        return Response({
            "message": "Profile picture updated successfully",
            "profile_picture": serializer.data.get('profile_picture')
        }, status=status.HTTP_200_OK)

class UserTierViewSet(viewsets.ViewSet):
    permission_classes = [permissions.IsAuthenticated]
    
    def list(self, request):
        """Get user tier information"""
        user = request.user
        
        # Get point transactions summary
        earned_points = PointTransaction.objects.filter(
            user=user, transaction_type='earned'
        ).aggregate(total=Sum('points'))['total'] or 0
        
        redeemed_points = PointTransaction.objects.filter(
            user=user, transaction_type='redeemed'
        ).aggregate(total=Sum('points'))['total'] or 0
        
        # Calculate next tier requirements
        next_tier = None
        points_needed = 0
        
        if user.tier == 'normal':
            next_tier = 'pointz_tier_1'
            points_needed = 1000 - user.points
        elif user.tier == 'pointz_tier_1':
            next_tier = 'pointz_tier_2'
            points_needed = 5000 - user.points
        elif user.tier == 'pointz_tier_2':
            next_tier = 'pointz_tier_3'
            points_needed = 10000 - user.points
        
        return Response({
            'current_tier': user.tier,
            'next_tier': next_tier,
            'current_points': user.points,
            'points_needed_for_next_tier': max(0, points_needed),
            'earned_points': earned_points,
            'redeemed_points': redeemed_points,
            'pointz_expiry_date': user.pointz_expiry_date
        })
    
    @action(detail=False, methods=['get'])
    def benefits(self, request):
        """Get benefits for user's current tier"""
        user = request.user
        
        tier_benefits = {
            'normal': {
                'discount': '0%',
                'free_shipping': False,
                'exclusive_products': False,
                'early_access': False,
                'customer_support': 'Standard',
            },
            'pointz_tier_1': {
                'discount': '5%',
                'free_shipping': True,
                'exclusive_products': False,
                'early_access': False,
                'customer_support': 'Priority',
            },
            'pointz_tier_2': {
                'discount': '10%',
                'free_shipping': True,
                'exclusive_products': True,
                'early_access': False,
                'customer_support': 'Priority',
            },
            'pointz_tier_3': {
                'discount': '15%',
                'free_shipping': True,
                'exclusive_products': True,
                'early_access': True,
                'customer_support': 'VIP',
            },
            'celebrity': {
                'discount': '20%',
                'free_shipping': True,
                'exclusive_products': True,
                'early_access': True,
                'customer_support': 'Dedicated',
                'personal_stylist': True,
            }
        }
        
        return Response({
            'tier': user.tier,
            'benefits': tier_benefits.get(user.tier, {})
        })
    
    @action(detail=False, methods=['get'])
    def history(self, request):
        """Get point transaction history"""
        transactions = PointTransaction.objects.filter(user=request.user)
        page = self.paginate_queryset(transactions)
        if page is not None:
            serializer = PointTransactionSerializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = PointTransactionSerializer(transactions, many=True)
        return Response(serializer.data)
    
    @property
    def paginator(self):
        """The paginator instance for pagination"""
        if not hasattr(self, '_paginator'):
            self._paginator = PageNumberPagination()
            self._paginator.page_size = 10
        return self._paginator

    def paginate_queryset(self, queryset):
        """Return a paginated queryset"""
        if self.paginator is None:
            return None
        return self.paginator.paginate_queryset(queryset, self.request, view=self)

    def get_paginated_response(self, data):
        """Return a paginated response"""
        assert self.paginator is not None
        return self.paginator.get_paginated_response(data)

class PointTransactionViewSet(viewsets.ModelViewSet):
    serializer_class = PointTransactionSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return PointTransaction.objects.filter(user=self.request.user)
    
    def perform_create(self, serializer):
        # Only admin should be able to create point transactions directly
        if not self.request.user.is_staff:
            raise permissions.PermissionDenied("You don't have permission to perform this action.")
        
        transaction = serializer.save()
        
        # Update user points based on transaction type
        user = transaction.user
        if transaction.transaction_type == 'earned':
            user.points += transaction.points
        elif transaction.transaction_type == 'redeemed':
            if user.points < transaction.points:
                raise serializers.ValidationError({"points": "User doesn't have enough points"})
            user.points -= transaction.points
        elif transaction.transaction_type == 'expired':
            if user.points < transaction.points:
                transaction.points = user.points
            user.points -= transaction.points
        elif transaction.transaction_type == 'adjustment':
            user.points += transaction.points  # Can be negative for deduction
        
        # Update user tier based on new points total
        user.update_tier()
        user.save()

class NotificationPreferencesView(generics.UpdateAPIView):
    serializer_class = NotificationPreferencesSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_object(self):
        return self.request.user
    
    def update(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        
        user = self.get_object()
        for key, value in serializer.validated_data.items():
            setattr(user, key, value)
        user.save()
        
        return Response({
            "message": "Notification preferences updated successfully",
            "preferences": serializer.data
        })

class UserPreferencesView(generics.RetrieveUpdateAPIView):
    """API endpoint for managing user preferences"""
    serializer_class = UserPreferencesSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_object(self):
        return self.request.user
    
    def update(self, request, *args, **kwargs):
        serializer = self.get_serializer(self.get_object(), data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        
        return Response({
            "message": "User preferences updated successfully",
            "preferences": serializer.data
        })

class OrderHistoryPagination(PageNumberPagination):
    page_size = 10
    page_size_query_param = 'page_size'
    max_page_size = 50

class OrderHistoryView(generics.ListAPIView):
    """API endpoint for user order history"""
    serializer_class = OrderSummarySerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = OrderHistoryPagination
    
    def get_queryset(self):
        """Return only orders for the current user, ordered by creation date"""
        return Order.objects.filter(user=self.request.user).order_by('-created_at')
    
    def list(self, request, *args, **kwargs):
        # Get basic stats about orders
        order_stats = Order.objects.filter(user=request.user).aggregate(
            total_orders=Count('id'),
            completed_orders=Count('id', filter=Q(status='delivered')),
            ongoing_orders=Count('id', filter=Q(status__in=['pending', 'confirmed', 'processing', 'packed', 'shipped'])),
            cancelled_orders=Count('id', filter=Q(status='cancelled'))
        )
        
        # Get the paginated queryset
        queryset = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(queryset)
        
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            response = self.get_paginated_response(serializer.data)
            response.data['stats'] = order_stats
            return response
        
        serializer = self.get_serializer(queryset, many=True)
        return Response({
            'stats': order_stats,
            'results': serializer.data
        })

class OrderDetailView(generics.RetrieveAPIView):
    """API endpoint for viewing a specific order's details"""
    serializer_class = OrderDetailSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        """Return only orders belonging to the current user"""
        return Order.objects.filter(user=self.request.user)
    
    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        serializer = self.get_serializer(instance)
        
        # Get order status history
        status_history = OrderStatusHistory.objects.filter(order=instance).order_by('-created_at')
        history_data = []
        for history in status_history:
            history_data.append({
                'status': history.status,
                'status_display': dict(Order.STATUS_CHOICES).get(history.status),
                'notes': history.notes,
                'timestamp': history.created_at
            })
        
        data = serializer.data
        data['status_history'] = history_data
        
        return Response(data)