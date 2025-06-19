"""
URL configuration for joulina_backend project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/4.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path, include, re_path
from django.conf import settings
from django.conf.urls.static import static
from rest_framework import permissions
from drf_yasg.views import get_schema_view
from drf_yasg import openapi
from .admin import admin_site

# Create API schema view with versioning
schema_view = get_schema_view(
   openapi.Info(
      title="Joulina Beauty API",
      default_version='v1',
      description="API for Joulina luxury e-commerce platform",
      terms_of_service="https://www.joulina.com/terms/",
      contact=openapi.Contact(email="contact@joulina.com"),
      license=openapi.License(name="Proprietary"),
   ),
   public=True,
   permission_classes=(permissions.AllowAny,),
)

# Define versioned API paths
api_v1_patterns = [
    path('users/', include('users.urls')),
    path('products/', include('products.urls')),
    path('celebrities/', include('celebrities.urls')),
    path('cart/', include('cart.urls')),
    path('orders/', include('orders.urls')),
    path('payments/', include('payments.urls')),
]

# Main URL patterns
urlpatterns = [
    path('admin/', admin_site.urls),
    
    # Versioned API endpoints
    path('api/v1/', include(api_v1_patterns)),
    
    # Documentation
    path('docs/', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui'),
    path('docs/redoc/', schema_view.with_ui('redoc', cache_timeout=0), name='schema-redoc'),
    
    # API versioning redirection for backward compatibility
    re_path(r'^api/(?!v[0-9]).*$', include(api_v1_patterns)),
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
