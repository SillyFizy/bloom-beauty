from django.urls import path
from . import views

app_name = 'categories'

urlpatterns = [
    # Public endpoints for frontend
    path('navigation/', views.get_navigation_categories, name='navigation-categories'),
    
    # Admin endpoints for CRUD operations
    path('admin/categories/', views.NavigationCategoryListView.as_view(), name='admin-category-list'),
    path('admin/categories/<int:pk>/', views.NavigationCategoryDetailView.as_view(), name='admin-category-detail'),
    path('admin/categories/bulk-update/', views.bulk_update_categories, name='admin-category-bulk-update'),
    path('admin/categories/statistics/', views.category_statistics, name='admin-category-statistics'),
] 