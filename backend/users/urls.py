# users/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenRefreshView
from .views import (
    UserRegistrationView, 
    CustomTokenObtainPairView, 
    UserProfileView,
    EmailVerificationView,
    PasswordChangeView,
    UserAddressView,
    ProfilePictureUpdateView,
    UserTierViewSet,
    PointTransactionViewSet,
    NotificationPreferencesView,
    UserPreferencesView,
    OrderHistoryView,
    OrderDetailView
)

# Create router for viewsets
router = DefaultRouter()
router.register(r'tier', UserTierViewSet, basename='user-tier')
router.register(r'points', PointTransactionViewSet, basename='point-transactions')

urlpatterns = [
    # Authentication
    path('register/', UserRegistrationView.as_view(), name='register'),
    path('login/', CustomTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('verify-email/', EmailVerificationView.as_view(), name='email-verify'),
    
    # User profile management
    path('profile/', UserProfileView.as_view(), name='profile'),
    path('change-password/', PasswordChangeView.as_view(), name='change-password'),
    path('address/', UserAddressView.as_view(), name='address'),
    path('profile-picture/', ProfilePictureUpdateView.as_view(), name='profile-picture'),
    path('notification-preferences/', NotificationPreferencesView.as_view(), name='notification-preferences'),
    path('preferences/', UserPreferencesView.as_view(), name='user-preferences'),
    
    # Order history
    path('orders/', OrderHistoryView.as_view(), name='order-history'),
    path('orders/<int:pk>/', OrderDetailView.as_view(), name='order-detail'),
    
    # Include router URLs for tier and points
    path('', include(router.urls)),
]