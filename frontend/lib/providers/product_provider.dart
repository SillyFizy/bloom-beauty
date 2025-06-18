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

  // Cache management
  DateTime? _lastNewArrivalsUpdate;
  DateTime? _lastBestsellingUpdate;
  DateTime? _lastTrendingUpdate;
  DateTime? _lastCelebritiesUpdate;
  bool _isInitialized = false;
  static const Duration _cacheExpiry = Duration(minutes: 15);

  String _currentSearchQuery = '';
  ProductSortOption _currentSortOption = ProductSortOption.newest;
  Map<String, dynamic> _currentFilters = {};

  // Getters
  List<Product> get products => List.unmodifiable(_products);
  List<Product> get filteredProducts => List.unmodifiable(_filteredProducts);
  List<Product> get newArrivals => List.unmodifiable(_newArrivals);
  List<Product> get bestsellingProducts =>
      List.unmodifiable(_bestsellingProducts);
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
  bool get isInitialized => _isInitialized;

  /// Check if cache is still valid for specific data type
  bool _isCacheValid(DateTime? lastUpdate) {
    if (lastUpdate == null) return false;
    return DateTime.now().difference(lastUpdate) < _cacheExpiry;
  }

  /// Initialize and load all product data with smart caching
  Future<void> initialize() async {
    if (_isInitialized && _hasValidCache()) {
      debugPrint('ProductProvider: Using cached data, skipping initialization');
      return;
    }

    debugPrint('ProductProvider: Initializing with fresh data');

    // Only load all products if we don't have them yet
    if (_products.isEmpty) {
      await loadAllProducts(showLoading: false);
    }

    await loadProductCategories();

    // Only load statistics if we don't have them yet
    if (_productStatistics == null) {
      await loadProductStatistics();
    }

    _isInitialized = true;
  }

  /// Check if we have valid cache for all essential data
  bool _hasValidCache() {
    final hasValidTimestamps = _isCacheValid(_lastNewArrivalsUpdate) &&
        _isCacheValid(_lastBestsellingUpdate) &&
        _isCacheValid(_lastTrendingUpdate);

    final hasData = _newArrivals.isNotEmpty &&
        _bestsellingProducts.isNotEmpty &&
        _trendingProducts.isNotEmpty;

    debugPrint(
        'ProductProvider: Cache validation - timestamps: $hasValidTimestamps, data: $hasData');
    return hasValidTimestamps && hasData;
  }

  /// Load all products
  Future<void> loadAllProducts(
      {bool forceRefresh = false, bool showLoading = true}) async {
    try {
      if (showLoading) {
        _setLoading(true);
      }
      _clearError();

      _products =
          await _productService.getAllProducts(forceRefresh: forceRefresh);
      _filteredProducts = List.from(_products);

      if (showLoading) {
        _setLoading(false);
      }
      notifyListeners();
    } catch (e) {
      _setError('Failed to load products: $e');
      if (showLoading) {
        _setLoading(false);
      }
    }
  }

  /// Load new arrivals products with caching
  Future<void> loadNewArrivals({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _isCacheValid(_lastNewArrivalsUpdate) &&
        _newArrivals.isNotEmpty) {
      debugPrint('ProductProvider: Using cached new arrivals');
      return;
    }

    try {
      debugPrint('ProductProvider: Fetching fresh new arrivals');
      _newArrivals = await _productService.getNewArrivals();
      _lastNewArrivalsUpdate = DateTime.now();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load new arrivals: $e');
    }
  }

  /// Load bestselling products with caching
  Future<void> loadBestsellingProducts({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _isCacheValid(_lastBestsellingUpdate) &&
        _bestsellingProducts.isNotEmpty) {
      debugPrint('ProductProvider: Using cached bestselling products');
      return;
    }

    try {
      debugPrint('ProductProvider: Fetching fresh bestselling products');
      _bestsellingProducts = await _productService.getBestsellingProducts();
      _lastBestsellingUpdate = DateTime.now();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load bestselling products: $e');
    }
  }

  /// Load trending products with caching
  Future<void> loadTrendingProducts({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _isCacheValid(_lastTrendingUpdate) &&
        _trendingProducts.isNotEmpty) {
      debugPrint('ProductProvider: Using cached trending products');
      return;
    }

    try {
      debugPrint('ProductProvider: Fetching fresh trending products');
      _trendingProducts = await _productService.getTrendingProducts();
      _lastTrendingUpdate = DateTime.now();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load trending products: $e');
    }
  }

  /// Load product categories (new arrivals, bestselling, trending, featured) with caching
  Future<void> loadProductCategories({bool forceRefresh = false}) async {
    await Future.wait([
      loadNewArrivals(forceRefresh: forceRefresh),
      loadBestsellingProducts(forceRefresh: forceRefresh),
      loadTrendingProducts(forceRefresh: forceRefresh),
    ]);

    // Load featured products (derived from other categories)
    try {
      _featuredProducts = await _productService.getFeaturedProducts();
    } catch (e) {
      debugPrint('Failed to load featured products: $e');
    }
  }

  /// Force refresh all data (for pull-to-refresh)
  Future<void> refreshAllData() async {
    debugPrint('ProductProvider: Force refreshing all data');
    _isInitialized = false;
    _lastNewArrivalsUpdate = null;
    _lastBestsellingUpdate = null;
    _lastTrendingUpdate = null;

    await initialize();
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

      final categoryProducts =
          await _productService.getProductsByCategory(categoryId);
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

      _filteredProducts =
          await _productService.sortProducts(_filteredProducts, sortOption);

      if (_searchResults.isNotEmpty) {
        _searchResults =
            await _productService.sortProducts(_searchResults, sortOption);
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

  /// Get product detail from backend API
  Future<Product?> getProductDetail(String productId) async {
    try {
      _setLoading(true);
      _clearError();

      final product = await _productService.getProductDetail(productId);

      _setLoading(false);
      if (product != null) {
        // Add to recently viewed
        await addToRecentlyViewed(product);
      }

      return product;
    } catch (e) {
      _setError('Failed to get product detail: $e');
      _setLoading(false);
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
  Future<void> loadProductsByPriceRange(
      double minPrice, double maxPrice) async {
    try {
      _setLoading(true);
      _clearError();

      final priceRangeProducts =
          await _productService.getProductsByPriceRange(minPrice, maxPrice);
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

      final ratingProducts =
          await _productService.getProductsByRating(minRating);
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
    final categories =
        _products.map((product) => product.categoryId).toSet().toList();
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
