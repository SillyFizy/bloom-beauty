import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import 'data_service.dart';
import 'storage_service.dart';
import 'api_service.dart';

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
    return products
        .where((product) => product.categoryId == categoryId)
        .toList();
  }

  /// Get products by category name (for backend integration)
  Future<List<Product>> getProductsByCategoryName(String categoryName) async {
    final products = await getAllProducts();
    return products
        .where((product) => product.categoryId == categoryName)
        .toList();
  }

  /// Get bestselling products - using real API
  Future<List<Product>> getBestsellingProducts({int limit = 10}) async {
    try {
      // Use real API for bestselling products
      return await ApiService.getBestsellingProducts(limit: limit);
    } catch (e) {
      debugPrint(
          'Failed to load bestselling products from API, falling back to mock data: $e');
      // Fallback to mock data if API fails
      final products = await getAllProducts();
      return products
          .where((product) => product.rating >= 4.5)
          .take(limit)
          .toList();
    }
  }

  /// Get new arrivals (latest products) - using real API
  Future<List<Product>> getNewArrivals({int limit = 4}) async {
    try {
      // Use real API for new arrivals only
      return await ApiService.getNewArrivals(days: 30, limit: limit);
    } catch (e) {
      debugPrint(
          'Failed to load new arrivals from API, falling back to mock data: $e');
      // Fallback to mock data if API fails
      final products = await getAllProducts();
      final sortedProducts = List<Product>.from(products)
        ..sort((a, b) =>
            b.id.compareTo(a.id)); // Assuming newer products have higher IDs
      return sortedProducts.take(limit).toList();
    }
  }

  /// Get trending products - using real API
  Future<List<Product>> getTrendingProducts({int limit = 10}) async {
    try {
      // Use real API for trending products
      return await ApiService.getTrendingProducts(limit: limit);
    } catch (e) {
      debugPrint(
          'Failed to load trending products from API, falling back to mock data: $e');
      // Fallback to mock data if API fails
      final products = await getAllProducts();
      return products
          .where((product) => product.reviewCount > 100)
          .take(limit)
          .toList();
    }
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

  /// Get product detail from backend API using product ID
  Future<Product?> getProductDetail(String productId) async {
    try {
      debugPrint('Fetching product detail for ID: $productId');
      return await ApiService.getProductDetail(productId);
    } catch (e) {
      debugPrint('Failed to load product detail from API: $e');
      debugPrint('API Error details: $e');
      // Do NOT fall back to cached data for product details as it has incorrect descriptions
      // The cached data uses product name as description, which is wrong
      throw Exception(
          'Could not load product detail for ID: $productId. API Error: $e');
    }
  }

  /// Search products using backend search API
  Future<List<Product>> searchProducts(String query) async {
    if (query.isEmpty) return [];

    try {
      // Use backend search API for better performance and accuracy
      final searchResult = await ApiService.searchProducts(query);
      return searchResult['results'] as List<Product>;
    } catch (e) {
      debugPrint('Backend search failed, falling back to local search: $e');

      // Fallback to local search if backend fails
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
  }

  /// Get products by brand
  Future<List<Product>> getProductsByBrand(String brand) async {
    final products = await getAllProducts();
    return products
        .where((product) => product.brand.toLowerCase() == brand.toLowerCase())
        .toList();
  }

  /// Get products within price range
  Future<List<Product>> getProductsByPriceRange(
      double minPrice, double maxPrice) async {
    final products = await getAllProducts();
    return products
        .where(
            (product) => product.price >= minPrice && product.price <= maxPrice)
        .toList();
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
  Future<List<Product>> getRecommendedProducts(String productId,
      {int limit = 4}) async {
    final currentProduct = await getProductById(productId);
    if (currentProduct == null) return [];

    final products = await getAllProducts();
    final recommendations = products
        .where((product) =>
            product.id != productId &&
            product.categoryId == currentProduct.categoryId &&
            product.rating >= 4.0)
        .toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));

    return recommendations.take(limit).toList();
  }

  /// Get recently viewed products (placeholder - would integrate with storage)
  Future<List<Product>> getRecentlyViewedProducts() async {
    try {
      final recentlyViewedJson =
          await StorageService.getString(_recentlyViewedKey);
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
        recentlyViewedIds.removeRange(
            _maxRecentlyViewed, recentlyViewedIds.length);
      }

      // Save back to storage
      await StorageService.setString(
          _recentlyViewedKey, json.encode(recentlyViewedIds));
    } catch (e) {
      debugPrint('Error adding product to recently viewed: $e');
    }
  }

  /// Helper method to get recently viewed product IDs
  Future<List<String>> _getRecentlyViewedIds() async {
    try {
      final recentlyViewedJson =
          await StorageService.getString(_recentlyViewedKey);
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
      if (brand != null && product.brand.toLowerCase() != brand.toLowerCase())
        return false;
      if (minPrice != null && product.price < minPrice) return false;
      if (maxPrice != null && product.price > maxPrice) return false;
      if (minRating != null && product.rating < minRating) return false;
      if (inStock != null && product.isInStock != inStock) return false;
      if (ingredients != null && ingredients.isNotEmpty) {
        final hasIngredient = ingredients.any((ingredient) =>
            product.ingredients.any((productIngredient) => productIngredient
                .toLowerCase()
                .contains(ingredient.toLowerCase())));
        if (!hasIngredient) return false;
      }
      return true;
    }).toList();
  }

  /// Sort products by various criteria
  Future<List<Product>> sortProducts(
      List<Product> products, ProductSortOption sortOption) async {
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

    final totalProducts = products.length;
    final averageRating = products.isNotEmpty
        ? products.map((p) => p.rating).reduce((a, b) => a + b) / totalProducts
        : 0.0;
    final totalReviews =
        products.map((p) => p.reviewCount).reduce((a, b) => a + b);
    final inStockCount = products.where((p) => p.isInStock).length;

    return ProductStatistics(
      totalProducts: totalProducts,
      averageRating: averageRating,
      totalReviews: totalReviews,
      inStockCount: inStockCount,
      outOfStockCount: totalProducts - inStockCount,
    );
  }

  /// Batch operations for better performance
  Future<Map<String, Product?>> getProductsBatch(
      List<String> productIds) async {
    final products = await getAllProducts();
    final result = <String, Product?>{};

    for (final id in productIds) {
      try {
        result[id] = products.firstWhere((product) => product.id == id);
      } catch (e) {
        result[id] = null;
      }
    }

    return result;
  }

  /// Preload commonly accessed data
  Future<void> preloadData() async {
    try {
      // Preload in parallel for better performance
      await Future.wait([
        getAllProducts(),
        getBestsellingProducts(),
        getNewArrivals(),
        getTrendingProducts(),
      ]);
    } catch (e) {
      debugPrint('Error preloading data: $e');
    }
  }

  /// Private methods

  /// Check if cache should be refreshed
  bool _shouldRefreshCache() {
    if (_cachedProducts == null || _lastCacheUpdate == null) return true;
    return DateTime.now().difference(_lastCacheUpdate!) > _cacheExpiry;
  }

  /// Refresh product cache
  Future<void> _refreshProductCache() async {
    try {
      // Use backend API instead of mock data
      _cachedProducts = await ApiService.getAllProductsFromBackend();
      _lastCacheUpdate = DateTime.now();
      debugPrint(
          'Successfully loaded ${_cachedProducts?.length ?? 0} products from backend');
    } catch (e) {
      debugPrint('Error refreshing product cache from backend: $e');
      // Fallback to mock data if backend fails
      try {
        _cachedProducts = _dataService.getAllProducts();
        debugPrint('Fallback to mock data successful');
      } catch (fallbackError) {
        debugPrint('Fallback to mock data also failed: $fallbackError');
        _cachedProducts ??= []; // Fallback to empty list if both fail
      }
    }
  }

  /// Clear cache (useful for logout or data refresh)
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
  final int totalReviews;
  final int inStockCount;
  final int outOfStockCount;

  ProductStatistics({
    required this.totalProducts,
    required this.averageRating,
    required this.totalReviews,
    required this.inStockCount,
    required this.outOfStockCount,
  });
}
