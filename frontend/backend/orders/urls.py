from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import OrderViewSet, ShippingAddressViewSet, CheckoutView

router = DefaultRouter()
router.register(r'addresses', ShippingAddressViewSet, basename='shipping-address')
router.register(r'orders', OrderViewSet, basename='order')

urlpatterns = [
    path('', include(router.urls)),
    path('checkout/', CheckoutView.as_view({'post': 'create'}), name='checkout'),
] 