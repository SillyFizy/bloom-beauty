from django.urls import path
from . import views

app_name = 'celebrities'

urlpatterns = [
    # Celebrity list and detail
    path('', views.CelebrityListView.as_view(), name='celebrity-list'),
    path('<int:pk>/', views.CelebrityDetailView.as_view(), name='celebrity-detail'),
    
    # Celebrity promotions and routines
    path('<int:celebrity_id>/promotions/', views.celebrity_promotions, name='celebrity-promotions'),
    path('<int:celebrity_id>/morning-routine/', views.celebrity_morning_routine, name='celebrity-morning-routine'),
    path('<int:celebrity_id>/evening-routine/', views.celebrity_evening_routine, name='celebrity-evening-routine'),
    
    # Celebrity picks and featured content
    path('picks/featured/', views.celebrity_picks, name='celebrity-picks'),
    path('picks/products/', views.celebrity_picks_products, name='celebrity-picks-products'),
    
    # Product-related endpoints
    path('products/<int:product_id>/endorsements/', views.product_celebrity_endorsements, name='product-endorsements'),
    
    # Category and search
    path('category/filter/', views.celebrities_by_category, name='celebrities-by-category'),
    path('search/', views.search_celebrities, name='search-celebrities'),
] 