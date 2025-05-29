from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    ProductViewSet, CategoryViewSet, BrandViewSet,
    ProductAttributeViewSet, ProductAttributeValueViewSet,
    ProductImageViewSet, ProductVariantViewSet, InventoryLogViewSet
)

router = DefaultRouter()
router.register(r'categories', CategoryViewSet)
router.register(r'brands', BrandViewSet)
router.register(r'attributes', ProductAttributeViewSet)
router.register(r'attribute-values', ProductAttributeValueViewSet)
router.register(r'images', ProductImageViewSet)
router.register(r'variants', ProductVariantViewSet)
router.register(r'inventory-log', InventoryLogViewSet, basename='inventory-log')
router.register(r'', ProductViewSet)

urlpatterns = [
    path('', include(router.urls)),
] 