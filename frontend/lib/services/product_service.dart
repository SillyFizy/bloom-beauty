import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import 'data_service.dart';
import 'api_service.dart';
import 'storage_service.dart';

/// Service responsible for all product-related data operations
/// Provides abstraction between UI components and data sources
class ProductService {
  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();

  final DataService _dataService = DataService();
  
  // Cache for frequently accessed data
  List<Product>? _cachedProducts;
  DateTime? _lastCacheUpdate;
  static const Duration _cacheExpiry = Duration(minutes: 30);
  
  // Recently viewed products storage key
  static const String _recentlyViewedKey = 'recently_viewed_products';
  static const int _maxRecentlyViewed = 10;

  /// Get all products with caching
  Future<List<Product>> getAllProducts({bool forceRefresh = false}) async {
    if (_shouldRefreshCache() || forceRefresh) {
      await _refreshProductCache();
    }
    return _cachedProducts ?? [];
  }

  /// Get products by category
  Future<List<Product>> getProductsByCategory(String categoryId) async {
    final products = await getAllProducts();
    return products.where((product) => product.categoryId == categoryId).toList();
  }

  /// Get bestselling products (rating >= 4.5)
  Future<List<Product>> getBestsellingProducts() async {
    final products = await getAllProducts();
    return products.where((product) => product.rating >= 4.5).toList();
  }

  /// Get new arrivals (latest products)
  Future<List<Product>> getNewArrivals({int limit = 4}) async {
    final products = await getAllProducts();
    final sortedProducts = List<Product>.from(products)
      ..sort((a, b) => b.id.compareTo(a.id)); // Assuming newer products have higher IDs
    return sortedProducts.take(limit).toList();
  }

  /// Get trending products (high review count)
  Future<List<Product>> getTrendingProducts({int minReviews = 100}) async {
    final products = await getAllProducts();
    return products.where((product) => product.reviewCount > minReviews).toList();
  }

  /// Get a specific product by ID
  Future<Product?> getProductById(String id) async {
    final products = await getAllProducts();
    try {
      return products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Search products by name or description
  Future<List<Product>> searchProducts(String query) async {
    if (query.isEmpty) return [];
    
    final products = await getAllProducts();
    final lowercaseQuery = query.toLowerCase();
    
    return products.where((product) {
      return product.name.toLowerCase().contains(lowercaseQuery) ||
             product.description.toLowerCase().contains(lowercaseQuery) ||
             product.brand.toLowerCase().contains(lowercaseQuery) ||
             product.ingredients.any((ingredient) => 
               ingredient.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  /// Get products by brand
  Future<List<Product>> getProductsByBrand(String brand) async {
    final products = await getAllProducts();
    return products.where((product) => 
      product.brand.toLowerCase() == brand.toLowerCase()).toList();
  }

  /// Get products within price range
  Future<List<Product>> getProductsByPriceRange(double minPrice, double maxPrice) async {
    final products = await getAllProducts();
    return products.where((product) => 
      product.price >= minPrice && product.price <= maxPrice).toList();
  }

  /// Get products with specific rating or higher
  Future<List<Product>> getProductsByRating(double minRating) async {
    final products = await getAllProducts();
    return products.where((product) => product.rating >= minRating).toList();
  }

  /// Get featured products (combination of bestselling and trending)
  Future<List<Product>> getFeaturedProducts({int limit = 6}) async {
    final bestselling = await getBestsellingProducts();
    final trending = await getTrendingProducts();
    
    // Combine and remove duplicates
    final featured = <String, Product>{};
    for (final product in [...bestselling, ...trending]) {
      featured[product.id] = product;
    }
    
    final featuredList = featured.values.toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
    
    return featuredList.take(limit).toList();
  }

  /// Get product recommendations based on category and rating
  Future<List<Product>> getRecommendedProducts(String productId, {int limit = 4}) async {
    final currentProduct = await getProductById(productId);
    if (currentProduct == null) return [];
    
    final products = await getAllProducts();
    final recommendations = products.where((product) => 
      product.id != productId &&
      product.categoryId == currentProduct.categoryId &&
      product.rating >= 4.0
    ).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
    
    return recommendations.take(limit).toList();
  }

  /// Get recently viewed products (placeholder - would integrate with storage)
  Future<List<Product>> getRecentlyViewedProducts() async {
    try {
      final recentlyViewedJson = await StorageService.getString(_recentlyViewedKey);
      if (recentlyViewedJson == null) return [];
      
      final List<dynamic> productIds = json.decode(recentlyViewedJson);
      final allProducts = await getAllProducts();
      
      final recentlyViewed = <Product>[];
      for (final productId in productIds) {
        try {
          final product = allProducts.firstWhere((p) => p.id == productId);
          recentlyViewed.add(product);
        } catch (e) {
          // Product not found, skip it
        }
      }
      
      return recentlyViewed;
    } catch (e) {
      debugPrint('Error loading recently viewed products: $e');
      return [];
    }
  }

  /// Add product to recently viewed (placeholder)
  Future<void> addToRecentlyViewed(Product product) async {
    try {
      final recentlyViewedIds = await _getRecentlyViewedIds();
      
      // Remove if already exists to move to front
      recentlyViewedIds.remove(product.id);
      
      // Add to front
      recentlyViewedIds.insert(0, product.id);
      
      // Keep only the most recent ones
      if (recentlyViewedIds.length > _maxRecentlyViewed) {
        recentlyViewedIds.removeRange(_maxRecentlyViewed, recentlyViewedIds.length);
      }
      
      // Save back to storage
      await StorageService.setString(_recentlyViewedKey, json.encode(recentlyViewedIds));
    } catch (e) {
      debugPrint('Error adding product to recently viewed: $e');
    }
  }

  /// Helper method to get recently viewed product IDs
  Future<List<String>> _getRecentlyViewedIds() async {
    try {
      final recentlyViewedJson = await StorageService.getString(_recentlyViewedKey);
      if (recentlyViewedJson == null) return [];
      
      final List<dynamic> ids = json.decode(recentlyViewedJson);
      return ids.cast<String>();
    } catch (e) {
      return [];
    }
  }

  /// Filter products by multiple criteria
  Future<List<Product>> filterProducts({
    String? categoryId,
    String? brand,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    List<String>? ingredients,
    bool? inStock,
  }) async {
    final products = await getAllProducts();
    
    return products.where((product) {
      if (categoryId != null && product.categoryId != categoryId) return false;
      if (brand != null && product.brand.toLowerCase() != brand.toLowerCase()) return false;
      if (minPrice != null && product.price < minPrice) return false;
      if (maxPrice != null && product.price > maxPrice) return false;
      if (minRating != null && product.rating < minRating) return false;
      if (inStock != null && product.isInStock != inStock) return false;
      if (ingredients != null && ingredients.isNotEmpty) {
        final hasIngredient = ingredients.any((ingredient) =>
          product.ingredients.any((productIngredient) =>
            productIngredient.toLowerCase().contains(ingredient.toLowerCase())
          )
        );
        if (!hasIngredient) return false;
      }
      return true;
    }).toList();
  }

  /// Sort products by various criteria
  Future<List<Product>> sortProducts(
    List<Product> products, 
    ProductSortOption sortOption
  ) async {
    final sortedProducts = List<Product>.from(products);
    
    switch (sortOption) {
      case ProductSortOption.nameAsc:
        sortedProducts.sort((a, b) => a.name.compareTo(b.name));
        break;
      case ProductSortOption.nameDesc:
        sortedProducts.sort((a, b) => b.name.compareTo(a.name));
        break;
      case ProductSortOption.priceAsc:
        sortedProducts.sort((a, b) => a.price.compareTo(b.price));
        break;
      case ProductSortOption.priceDesc:
        sortedProducts.sort((a, b) => b.price.compareTo(a.price));
        break;
      case ProductSortOption.ratingAsc:
        sortedProducts.sort((a, b) => a.rating.compareTo(b.rating));
        break;
      case ProductSortOption.ratingDesc:
        sortedProducts.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case ProductSortOption.popularityDesc:
        sortedProducts.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
        break;
      case ProductSortOption.newest:
        sortedProducts.sort((a, b) => b.id.compareTo(a.id));
        break;
    }
    
    return sortedProducts;
  }

  /// Get product statistics
  Future<ProductStatistics> getProductStatistics() async {
    final products = await getAllProducts();
    
    if (products.isEmpty) {
      return ProductStatistics(
        totalProducts: 0,
        averageRating: 0.0,
        averagePrice: 0.0,
        inStockCount: 0,
        outOfStockCount: 0,
        brandCount: 0,
        categoryCount: 0,
      );
    }

    final totalProducts = products.length;
    final averageRating = products.fold(0.0, (sum, product) => sum + product.rating) / totalProducts;
    final averagePrice = products.fold(0.0, (sum, product) => sum + product.price) / totalProducts;
    final inStockCount = products.where((product) => product.isInStock).length;
    final outOfStockCount = totalProducts - inStockCount;
    final brandCount = products.map((product) => product.brand).toSet().length;
    final categoryCount = products.map((product) => product.categoryId).toSet().length;

    return ProductStatistics(
      totalProducts: totalProducts,
      averageRating: averageRating,
      averagePrice: averagePrice,
      inStockCount: inStockCount,
      outOfStockCount: outOfStockCount,
      brandCount: brandCount,
      categoryCount: categoryCount,
    );
  }

  /// Private methods

  bool _shouldRefreshCache() {
    if (_cachedProducts == null || _lastCacheUpdate == null) return true;
    return DateTime.now().difference(_lastCacheUpdate!) > _cacheExpiry;
  }

  Future<void> _refreshProductCache() async {
    try {
      // In production, this would call the API
      // For now, use the data service
      _cachedProducts = _dataService.getAllProducts();
      _lastCacheUpdate = DateTime.now();
    } catch (e) {
      // Handle error gracefully
      print('Error refreshing product cache: $e');
      _cachedProducts ??= [];
    }
  }

  /// Clear cache (useful for testing or force refresh)
  void clearCache() {
    _cachedProducts = null;
    _lastCacheUpdate = null;
  }

  /// Dispose resources
  void dispose() {
    clearCache();
  }
}

/// Enum for product sorting options
enum ProductSortOption {
  nameAsc,
  nameDesc,
  priceAsc,
  priceDesc,
  ratingAsc,
  ratingDesc,
  popularityDesc,
  newest,
}

/// Product statistics model
class ProductStatistics {
  final int totalProducts;
  final double averageRating;
  final double averagePrice;
  final int inStockCount;
  final int outOfStockCount;
  final int brandCount;
  final int categoryCount;

  ProductStatistics({
    required this.totalProducts,
    required this.averageRating,
    required this.averagePrice,
    required this.inStockCount,
    required this.outOfStockCount,
    required this.brandCount,
    required this.categoryCount,
  });
} 