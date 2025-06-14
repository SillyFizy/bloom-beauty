import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

/// Provider for managing product state throughout the application
/// Uses the service layer for data operations and notifies listeners of state changes
class ProductProvider with ChangeNotifier {
  final ProductService _productService = ProductService();

  // State variables
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<Product> _newArrivals = [];
  List<Product> _bestsellingProducts = [];
  List<Product> _trendingProducts = [];
  List<Product> _featuredProducts = [];
  List<Product> _searchResults = [];
  
  ProductStatistics? _productStatistics;
  
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;
  
  String _currentSearchQuery = '';
  ProductSortOption _currentSortOption = ProductSortOption.newest;
  Map<String, dynamic> _currentFilters = {};

  // Getters
  List<Product> get products => List.unmodifiable(_products);
  List<Product> get filteredProducts => List.unmodifiable(_filteredProducts);
  List<Product> get newArrivals => List.unmodifiable(_newArrivals);
  List<Product> get bestsellingProducts => List.unmodifiable(_bestsellingProducts);
  List<Product> get trendingProducts => List.unmodifiable(_trendingProducts);
  List<Product> get featuredProducts => List.unmodifiable(_featuredProducts);
  List<Product> get searchResults => List.unmodifiable(_searchResults);
  
  ProductStatistics? get productStatistics => _productStatistics;
  
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get error => _error;
  bool get hasError => _error != null;
  
  String get currentSearchQuery => _currentSearchQuery;
  ProductSortOption get currentSortOption => _currentSortOption;
  Map<String, dynamic> get currentFilters => Map.unmodifiable(_currentFilters);

  /// Initialize and load all product data
  Future<void> initialize() async {
    await loadAllProducts();
    await loadProductCategories();
    await loadProductStatistics();
  }

  /// Load all products
  Future<void> loadAllProducts({bool forceRefresh = false}) async {
    try {
      _setLoading(true);
      _clearError();
      
      _products = await _productService.getAllProducts(forceRefresh: forceRefresh);
      _filteredProducts = List.from(_products);
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load products: $e');
      _setLoading(false);
    }
  }

  /// Load new arrivals products
  Future<void> loadNewArrivals() async {
    try {
      _newArrivals = await _productService.getNewArrivals();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load new arrivals: $e');
    }
  }

  /// Load bestselling products
  Future<void> loadBestsellingProducts() async {
    try {
      _bestsellingProducts = await _productService.getBestsellingProducts();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load bestselling products: $e');
    }
  }

  /// Load trending products
  Future<void> loadTrendingProducts() async {
    try {
      _trendingProducts = await _productService.getTrendingProducts();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load trending products: $e');
    }
  }

  /// Load product categories (new arrivals, bestselling, trending, featured)
  Future<void> loadProductCategories() async {
    try {
      final futures = await Future.wait([
        _productService.getNewArrivals(),
        _productService.getBestsellingProducts(),
        _productService.getTrendingProducts(),
        _productService.getFeaturedProducts(),
      ]);
      
      _newArrivals = futures[0];
      _bestsellingProducts = futures[1];
      _trendingProducts = futures[2];
      _featuredProducts = futures[3];
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load product categories: $e');
    }
  }

  /// Load product statistics
  Future<void> loadProductStatistics() async {
    try {
      _productStatistics = await _productService.getProductStatistics();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load product statistics: $e');
    }
  }

  /// Get products by category
  Future<void> loadProductsByCategory(String categoryId) async {
    try {
      _setLoading(true);
      _clearError();
      
      final categoryProducts = await _productService.getProductsByCategory(categoryId);
      _filteredProducts = categoryProducts;
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load category products: $e');
      _setLoading(false);
    }
  }

  /// Search products
  Future<void> searchProducts(String query) async {
    try {
      _setSearching(true);
      _clearError();
      _currentSearchQuery = query;
      
      if (query.isEmpty) {
        _searchResults = [];
      } else {
        _searchResults = await _productService.searchProducts(query);
      }
      
      _setSearching(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to search products: $e');
      _setSearching(false);
    }
  }

  /// Clear search results
  void clearSearch() {
    _currentSearchQuery = '';
    _searchResults = [];
    _setSearching(false);
    notifyListeners();
  }

  /// Filter products
  Future<void> filterProducts({
    String? categoryId,
    String? brand,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    List<String>? ingredients,
    bool? inStock,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      // Update current filters
      _currentFilters = {
        if (categoryId != null) 'categoryId': categoryId,
        if (brand != null) 'brand': brand,
        if (minPrice != null) 'minPrice': minPrice,
        if (maxPrice != null) 'maxPrice': maxPrice,
        if (minRating != null) 'minRating': minRating,
        if (ingredients != null) 'ingredients': ingredients,
        if (inStock != null) 'inStock': inStock,
      };
      
      _filteredProducts = await _productService.filterProducts(
        categoryId: categoryId,
        brand: brand,
        minPrice: minPrice,
        maxPrice: maxPrice,
        minRating: minRating,
        ingredients: ingredients,
        inStock: inStock,
      );
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to filter products: $e');
      _setLoading(false);
    }
  }

  /// Clear all filters
  void clearFilters() {
    _currentFilters = {};
    _filteredProducts = List.from(_products);
    notifyListeners();
  }

  /// Sort products
  Future<void> sortProducts(ProductSortOption sortOption) async {
    try {
      _currentSortOption = sortOption;
      
      _filteredProducts = await _productService.sortProducts(_filteredProducts, sortOption);
      
      if (_searchResults.isNotEmpty) {
        _searchResults = await _productService.sortProducts(_searchResults, sortOption);
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to sort products: $e');
    }
  }

  /// Get product by ID
  Future<Product?> getProductById(String id) async {
    try {
      return await _productService.getProductById(id);
    } catch (e) {
      _setError('Failed to get product: $e');
      return null;
    }
  }

  /// Get product recommendations
  Future<List<Product>> getRecommendedProducts(String productId) async {
    try {
      return await _productService.getRecommendedProducts(productId);
    } catch (e) {
      debugPrint('Failed to get recommendations: $e');
      return [];
    }
  }

  /// Get products by brand
  Future<void> loadProductsByBrand(String brand) async {
    try {
      _setLoading(true);
      _clearError();
      
      final brandProducts = await _productService.getProductsByBrand(brand);
      _filteredProducts = brandProducts;
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load brand products: $e');
      _setLoading(false);
    }
  }

  /// Get products by price range
  Future<void> loadProductsByPriceRange(double minPrice, double maxPrice) async {
    try {
      _setLoading(true);
      _clearError();
      
      final priceRangeProducts = await _productService.getProductsByPriceRange(minPrice, maxPrice);
      _filteredProducts = priceRangeProducts;
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load price range products: $e');
      _setLoading(false);
    }
  }

  /// Get products by rating
  Future<void> loadProductsByRating(double minRating) async {
    try {
      _setLoading(true);
      _clearError();
      
      final ratingProducts = await _productService.getProductsByRating(minRating);
      _filteredProducts = ratingProducts;
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load rating products: $e');
      _setLoading(false);
    }
  }

  /// Add product to recently viewed
  Future<void> addToRecentlyViewed(Product product) async {
    try {
      await _productService.addToRecentlyViewed(product);
    } catch (e) {
      debugPrint('Failed to add to recently viewed: $e');
    }
  }

  /// Get recently viewed products
  Future<List<Product>> getRecentlyViewedProducts() async {
    try {
      return await _productService.getRecentlyViewedProducts();
    } catch (e) {
      debugPrint('Failed to get recently viewed products: $e');
      return [];
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    await loadAllProducts(forceRefresh: true);
    await loadProductCategories();
    await loadProductStatistics();
  }

  /// Get all available brands
  List<String> get availableBrands {
    final brands = _products.map((product) => product.brand).toSet().toList();
    brands.sort();
    return brands;
  }

  /// Get all available categories
  List<String> get availableCategories {
    final categories = _products.map((product) => product.categoryId).toSet().toList();
    categories.sort();
    return categories;
  }

  /// Get price range
  Map<String, double> get priceRange {
    if (_products.isEmpty) return {'min': 0.0, 'max': 0.0};
    
    final prices = _products.map((product) => product.price).toList();
    return {
      'min': prices.reduce((a, b) => a < b ? a : b),
      'max': prices.reduce((a, b) => a > b ? a : b),
    };
  }

  /// Get filter counts
  Map<String, int> getFilterCounts() {
    return {
      'total': _products.length,
      'filtered': _filteredProducts.length,
      'newArrivals': _newArrivals.length,
      'bestselling': _bestsellingProducts.length,
      'trending': _trendingProducts.length,
      'featured': _featuredProducts.length,
    };
  }

  /// Check if a product is in any category list
  bool isProductInCategory(String productId, String category) {
    final List<Product> categoryList;
    
    switch (category.toLowerCase()) {
      case 'new':
      case 'newarrivals':
        categoryList = _newArrivals;
        break;
      case 'bestselling':
      case 'bestseller':
        categoryList = _bestsellingProducts;
        break;
      case 'trending':
        categoryList = _trendingProducts;
        break;
      case 'featured':
        categoryList = _featuredProducts;
        break;
      default:
        return false;
    }
    
    return categoryList.any((product) => product.id == productId);
  }

  /// Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) _clearError();
  }

  void _setSearching(bool searching) {
    _isSearching = searching;
    if (searching) _clearError();
  }

  void _setError(String error) {
    _error = error;
    _isLoading = false;
    _isSearching = false;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  /// Clear all cached data
  void clearCache() {
    _productService.clearCache();
    _products = [];
    _filteredProducts = [];
    _newArrivals = [];
    _bestsellingProducts = [];
    _trendingProducts = [];
    _featuredProducts = [];
    _searchResults = [];
    _productStatistics = null;
    _currentSearchQuery = '';
    _currentFilters = {};
    _clearError();
    notifyListeners();
  }

  /// Load products (alias for loadAllProducts for consistency)
  Future<void> loadProducts({bool forceRefresh = false}) async {
    await loadAllProducts(forceRefresh: forceRefresh);
  }

  /// Load all products from the service layer

  @override
  void dispose() {
    _productService.dispose();
    super.dispose();
  }
} 
