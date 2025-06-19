import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/celebrity_model.dart';
import '../models/category_model.dart' as category_model;

import '../services/product_service.dart';
import '../services/category_service.dart';
import '../services/api_service.dart';

enum CelebrityPicksSortOption {
  newest,
  mostPopular,
  priceLowToHigh,
  priceHighToLow,
  highestRated,
}

enum BrowseMode {
  celebrity,
  category,
}

class CelebrityPicksProvider with ChangeNotifier {
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();

  // State variables
  List<Product> _allCelebrityProducts = [];
  List<Map<String, dynamic>> _rawCelebrityPicks = []; // Raw backend data
  List<Product> _filteredProducts = [];
  List<Celebrity> _celebrities = [];
  List<category_model.Category> _categories = [];
  List<Product> _displayProducts = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  final bool _isSearching = false;
  bool _hasMoreProducts = true;
  String? _error;

  // Browse mode state
  BrowseMode _browseMode = BrowseMode.celebrity;

  // Filter state
  String _searchQuery = '';
  String? _selectedCelebrityId;
  int? _selectedCategoryId;
  CelebrityPicksSortOption _sortOption = CelebrityPicksSortOption.newest;
  double _minPriceFilter = 0;
  double _maxPriceFilter = 500000; // Default max price
  double _minRatingFilter = 0;

  // Pagination
  int _currentPage = 0;
  final int _itemsPerPage = 20;

  // Getters
  List<Product> get displayProducts => List.unmodifiable(_displayProducts);
  List<Product> get filteredProducts => List.unmodifiable(_filteredProducts);
  List<Celebrity> get celebrities => List.unmodifiable(_celebrities);
  List<category_model.Category> get categories =>
      List.unmodifiable(_categories);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSearching => _isSearching;
  bool get hasMoreProducts => _hasMoreProducts;
  String? get error => _error;
  bool get hasError => _error != null;

  String get searchQuery => _searchQuery;
  String? get selectedCelebrityId => _selectedCelebrityId;
  int? get selectedCategoryId => _selectedCategoryId;
  BrowseMode get browseMode => _browseMode;
  CelebrityPicksSortOption get sortOption => _sortOption;
  double get minPriceFilter => _minPriceFilter;
  double get maxPriceFilter => _maxPriceFilter;
  double get minRatingFilter => _minRatingFilter;

  // Get min and max prices from all products
  double getMinPrice() {
    if (_allCelebrityProducts.isEmpty) return 0;
    return _allCelebrityProducts
        .map((p) => p.price)
        .reduce((a, b) => a < b ? a : b);
  }

  double getMaxPrice() {
    if (_allCelebrityProducts.isEmpty) return 500000;
    return _allCelebrityProducts
        .map((p) => p.price)
        .reduce((a, b) => a > b ? a : b);
  }

  // Get celebrities that have picks (for filtering)
  List<String> get celebritiesWithPicks {
    final celebrityNames = <String>{};
    for (final pick in _rawCelebrityPicks) {
      final celebrityData = pick['celebrity'] as Map<String, dynamic>?;
      if (celebrityData != null) {
        final name = celebrityData['name'] as String? ?? '';
        if (name.isNotEmpty) {
          celebrityNames.add(name);
        }
      }
    }
    return celebrityNames.toList()..sort();
  }

  // Get selected celebrity
  Celebrity? get selectedCelebrity {
    if (_selectedCelebrityId == null) return null;
    try {
      return _celebrities.firstWhere((c) => c.name == _selectedCelebrityId);
    } catch (e) {
      return null;
    }
  }

  // Get selected category
  category_model.Category? get selectedCategory {
    if (_selectedCategoryId == null) return null;
    try {
      return _categories.firstWhere((c) => c.id == _selectedCategoryId);
    } catch (e) {
      return null;
    }
  }

  /// Initialize and load initial data using production backend endpoints
  Future<void> initialize() async {
    try {
      _setLoading(true);
      _clearError();

      debugPrint(
          'CelebrityPicksProvider: Starting initialization with backend data...');

      // Load celebrities and categories first
      await Future.wait([
        _loadCelebritiesFromBackend(),
        _loadCategories(),
      ]);

      // Then load celebrity picks products
      await _loadCelebrityPicksFromBackend();

      // Apply initial filtering and load first page
      await _applyFiltersAndSort();
      _loadDisplayProducts();

      debugPrint(
          'CelebrityPicksProvider: Successfully initialized with ${_allCelebrityProducts.length} celebrity picks');
      _setLoading(false);
    } catch (e) {
      debugPrint('CelebrityPicksProvider: Initialization error: $e');
      _setError('Failed to initialize celebrity picks: $e');
      _setLoading(false);
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    try {
      _setLoading(true);
      _clearError();

      // Clear existing data
      _allCelebrityProducts.clear();
      _rawCelebrityPicks.clear();
      _filteredProducts.clear();
      _displayProducts.clear();
      _celebrities.clear();
      _categories.clear();

      // Reset pagination
      _currentPage = 0;
      _hasMoreProducts = true;

      // Reload all data
      await Future.wait([
        _loadCelebritiesFromBackend(),
        _loadCategories(),
      ]);

      await _loadCelebrityPicksFromBackend();

      // Apply filters and load display products
      await _applyFiltersAndSort();
      _loadDisplayProducts();

      _setLoading(false);
    } catch (e) {
      _setError('Failed to refresh celebrity picks: $e');
      _setLoading(false);
    }
  }

  /// Load celebrities from backend /v1/celebrities/ endpoint
  Future<void> _loadCelebritiesFromBackend() async {
    try {
      debugPrint(
          'CelebrityPicksProvider: Loading celebrities from /v1/celebrities/...');
      _celebrities = await ApiService.getCelebrities();
      debugPrint(
          'CelebrityPicksProvider: Loaded ${_celebrities.length} celebrities from backend');
    } catch (e) {
      debugPrint('CelebrityPicksProvider: Error loading celebrities: $e');
      _celebrities = [];
    }
  }

  /// Load all categories
  Future<void> _loadCategories() async {
    try {
      _categories = await _categoryService.getAllCategories();
      debugPrint(
          'CelebrityPicksProvider: Loaded ${_categories.length} categories');
    } catch (e) {
      debugPrint('CelebrityPicksProvider: Error loading categories: $e');
      _categories = [];
    }
  }

  /// Load celebrity picks from backend /v1/celebrities/picks/featured/ endpoint
  Future<void> _loadCelebrityPicksFromBackend() async {
    try {
      debugPrint(
          'CelebrityPicksProvider: Loading celebrity picks from /v1/celebrities/picks/featured/...');

      // Get celebrity picks from backend with a high limit for comprehensive data
      final response =
          await ApiService.get('/v1/celebrities/picks/featured/?limit=100');
      _rawCelebrityPicks = (response['celebrity_picks'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          [];

      debugPrint(
          'CelebrityPicksProvider: Loaded ${_rawCelebrityPicks.length} celebrity picks from backend');

      // Convert celebrity picks to Product models with celebrity endorsement information
      _allCelebrityProducts = [];

      for (final pick in _rawCelebrityPicks) {
        try {
          final productData = pick['product'] as Map<String, dynamic>?;
          final celebrityData = pick['celebrity'] as Map<String, dynamic>?;

          if (productData != null && celebrityData != null) {
            debugPrint(
                'CelebrityPicksProvider: Processing pick with celebrity: ${celebrityData['name']} and product: ${productData['name']}');
            // Create product from backend data using proper backend API method
            final product = Product.fromBackendApi(productData);

            // Add celebrity endorsement information to the product (handle null values safely)
            final celebrityName =
                celebrityData['name']?.toString() ?? 'Celebrity';
            final celebrityImageRaw = celebrityData['image'];
            final celebrityImage = celebrityImageRaw?.toString() ?? '';
            final testimonial =
                pick['testimonial']?.toString() ?? 'I love this product!';

            final endorsement = CelebrityEndorsement(
              celebrityName: celebrityName,
              celebrityImage: celebrityImage,
              testimonial: testimonial,
            );

            debugPrint(
                'CelebrityPicksProvider: Processing celebrity $celebrityName with testimonial: $testimonial');

            // Create a new product with celebrity endorsement
            final productWithEndorsement = Product(
              id: product.id,
              name: product.name,
              description: product.description,
              price: product.price,
              discountPrice: product.discountPrice,
              images: product.images,
              categoryId: product.categoryId,
              brand: product.brand,
              rating: product.rating,
              reviewCount: product.reviewCount,
              isInStock: product.isInStock,
              ingredients: product.ingredients,
              beautyPoints: product.beautyPoints,
              variants: product.variants,
              reviews: product.reviews,
              celebrityEndorsement: endorsement, // Add celebrity endorsement
            );

            _allCelebrityProducts.add(productWithEndorsement);
            debugPrint(
                'CelebrityPicksProvider: Added product ${product.name} with celebrity endorsement from ${endorsement.celebrityName}');
          }
        } catch (e) {
          debugPrint(
              'CelebrityPicksProvider: Error parsing celebrity pick: $e');
          continue;
        }
      }

      debugPrint(
          'CelebrityPicksProvider: Successfully processed ${_allCelebrityProducts.length} products with celebrity endorsements');
    } catch (e) {
      debugPrint(
          'CelebrityPicksProvider: Error loading celebrity picks from backend: $e');

      // Fallback: if backend fails, try to get some products with celebrity endorsements
      try {
        final allProducts = await _productService.getAllProducts();
        _allCelebrityProducts = allProducts
            .where((product) => product.celebrityEndorsement != null)
            .toList();
        debugPrint(
            'CelebrityPicksProvider: Fallback loaded ${_allCelebrityProducts.length} products with existing celebrity endorsements');
      } catch (fallbackError) {
        debugPrint(
            'CelebrityPicksProvider: Fallback also failed: $fallbackError');
        _allCelebrityProducts = [];
      }
    }
  }

  /// Search products by name
  Future<void> searchProducts(String query) async {
    _searchQuery = query.trim();
    _currentPage = 0;
    _hasMoreProducts = true;
    _displayProducts.clear();

    await _applyFiltersAndSort();
    _loadDisplayProducts();
    notifyListeners();
  }

  /// Clear search
  void clearSearch() {
    _searchQuery = '';
    _currentPage = 0;
    _hasMoreProducts = true;
    _displayProducts.clear();
    _applyFiltersAndSort();
    _loadDisplayProducts();
    notifyListeners();
  }

  /// Select celebrity filter
  void selectCelebrity(String? celebrityId) {
    _selectedCelebrityId = celebrityId;
    _currentPage = 0;
    _hasMoreProducts = true;
    _displayProducts.clear();
    _applyFiltersAndSort();
    _loadDisplayProducts();
    notifyListeners();
  }

  /// Change sort option
  void changeSortOption(CelebrityPicksSortOption sortOption) {
    _sortOption = sortOption;
    _currentPage = 0;
    _hasMoreProducts = true;
    _displayProducts.clear();
    _applyFiltersAndSort();
    _loadDisplayProducts();
    notifyListeners();
  }

  /// Apply price filter
  void applyPriceFilter(double minPrice, double maxPrice) {
    _minPriceFilter = minPrice;
    _maxPriceFilter = maxPrice;
    _currentPage = 0;
    _hasMoreProducts = true;
    _displayProducts.clear();
    _applyFiltersAndSort();
    _loadDisplayProducts();
    notifyListeners();
  }

  /// Apply rating filter
  void applyRatingFilter(double minRating) {
    _minRatingFilter = minRating;
    _currentPage = 0;
    _hasMoreProducts = true;
    _displayProducts.clear();
    _applyFiltersAndSort();
    _loadDisplayProducts();
    notifyListeners();
  }

  /// Switch browse mode between celebrity and category
  void switchBrowseMode(BrowseMode mode) {
    if (_browseMode == mode) return;

    _browseMode = mode;
    // Clear current selections when switching modes
    _selectedCelebrityId = null;
    _selectedCategoryId = null;
    _currentPage = 0;
    _hasMoreProducts = true;
    _displayProducts.clear();
    _applyFiltersAndSort();
    _loadDisplayProducts();
    notifyListeners();
  }

  /// Select category filter
  void selectCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    _currentPage = 0;
    _hasMoreProducts = true;
    _displayProducts.clear();
    _applyFiltersAndSort();
    _loadDisplayProducts();
    notifyListeners();
  }

  /// Load more products (infinite scroll)
  Future<void> loadMoreProducts() async {
    if (_isLoadingMore || !_hasMoreProducts) return;

    _setLoadingMore(true);
    _currentPage++;
    _loadDisplayProducts();
    _setLoadingMore(false);
  }

  /// Apply all filters and sorting
  Future<void> _applyFiltersAndSort() async {
    List<Product> filtered = List.from(_allCelebrityProducts);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((product) =>
              product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              product.brand
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              product.description
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Apply celebrity filter (only when in celebrity browse mode)
    if (_browseMode == BrowseMode.celebrity && _selectedCelebrityId != null) {
      filtered = filtered
          .where((product) =>
              product.celebrityEndorsement?.celebrityName ==
              _selectedCelebrityId)
          .toList();

      debugPrint(
          'CelebrityPicksProvider: Filtered to ${filtered.length} products for celebrity $_selectedCelebrityId');
    }

    // Apply category filter (only when in category browse mode)
    if (_browseMode == BrowseMode.category && _selectedCategoryId != null) {
      try {
        final selectedCategory = _categories.firstWhere(
          (category) => category.id == _selectedCategoryId,
        );

        filtered = filtered
            .where((product) => product.categoryId == selectedCategory.name)
            .toList();
      } catch (e) {
        // Category not found, don't filter (show all products)
        debugPrint('Category with ID $_selectedCategoryId not found: $e');
      }
    }

    // Apply price filter
    filtered = filtered.where((product) {
      final price = product.discountPrice ?? product.price;
      return price >= _minPriceFilter && price <= _maxPriceFilter;
    }).toList();

    // Apply rating filter
    if (_minRatingFilter > 0) {
      filtered = filtered
          .where((product) => product.rating >= _minRatingFilter)
          .toList();
    }

    // Apply sorting
    _applySorting(filtered);

    _filteredProducts = filtered;
  }

  /// Apply sorting to filtered products
  void _applySorting(List<Product> products) {
    switch (_sortOption) {
      case CelebrityPicksSortOption.newest:
        // Assuming newer products have higher IDs
        products.sort((a, b) => b.id.compareTo(a.id));
        break;
      case CelebrityPicksSortOption.mostPopular:
        products.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
        break;
      case CelebrityPicksSortOption.priceLowToHigh:
        products.sort((a, b) {
          final priceA = a.discountPrice ?? a.price;
          final priceB = b.discountPrice ?? b.price;
          return priceA.compareTo(priceB);
        });
        break;
      case CelebrityPicksSortOption.priceHighToLow:
        products.sort((a, b) {
          final priceA = a.discountPrice ?? a.price;
          final priceB = b.discountPrice ?? b.price;
          return priceB.compareTo(priceA);
        });
        break;
      case CelebrityPicksSortOption.highestRated:
        products.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }
  }

  /// Load products for current page (pagination)
  void _loadDisplayProducts() {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;

    if (startIndex >= _filteredProducts.length) {
      _hasMoreProducts = false;
      return;
    }

    final newProducts =
        _filteredProducts.skip(startIndex).take(_itemsPerPage).toList();

    if (_currentPage == 0) {
      _displayProducts = newProducts;
    } else {
      _displayProducts.addAll(newProducts);
    }

    _hasMoreProducts = endIndex < _filteredProducts.length;
    notifyListeners();
  }

  /// Toggle product wishlist status
  Future<void> toggleWishlist(String productId) async {
    try {
      // Find the product in display products
      final productIndex =
          _displayProducts.indexWhere((p) => p.id == productId);
      if (productIndex != -1) {
        // Here you would typically call your wishlist service
        // For now, we'll just notify listeners for UI feedback
        notifyListeners();

        // You can add actual wishlist logic here
        debugPrint('Toggled wishlist for product: $productId');
      }
    } catch (e) {
      debugPrint('Error toggling wishlist: $e');
    }
  }

  /// Clear all filters
  void clearFilters() {
    _minPriceFilter = getMinPrice();
    _maxPriceFilter = getMaxPrice();
    _minRatingFilter = 0;
    _selectedCelebrityId = null;
    _selectedCategoryId = null;
    _searchQuery = '';
    _currentPage = 0;
    _hasMoreProducts = true;
    _displayProducts.clear();
    _applyFiltersAndSort();
    _loadDisplayProducts();
    notifyListeners();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setLoadingMore(bool loading) {
    _isLoadingMore = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
