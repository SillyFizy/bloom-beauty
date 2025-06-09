import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/celebrity_model.dart';
import '../models/category_model.dart' as category_model;

import '../services/product_service.dart';
import '../services/celebrity_service.dart';
import '../services/category_service.dart';

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
  final CelebrityService _celebrityService = CelebrityService();
  final CategoryService _categoryService = CategoryService();

  // State variables
  List<Product> _allCelebrityProducts = [];
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
  String? _selectedCategoryId;
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
  List<category_model.Category> get categories => List.unmodifiable(_categories);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSearching => _isSearching;
  bool get hasMoreProducts => _hasMoreProducts;
  String? get error => _error;
  bool get hasError => _error != null;
  
  String get searchQuery => _searchQuery;
  String? get selectedCelebrityId => _selectedCelebrityId;
  String? get selectedCategoryId => _selectedCategoryId;
  BrowseMode get browseMode => _browseMode;
  CelebrityPicksSortOption get sortOption => _sortOption;
  double get minPriceFilter => _minPriceFilter;
  double get maxPriceFilter => _maxPriceFilter;
  double get minRatingFilter => _minRatingFilter;
  
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

  /// Initialize and load initial data
  Future<void> initialize() async {
    try {
      _setLoading(true);
      _clearError();
      
      // Load celebrities, categories, and products concurrently
      await Future.wait([
        _loadCelebrities(),
        _loadCategories(),
        _loadAllCelebrityProducts(),
      ]);
      
      // Apply initial filtering and load first page
      await _applyFiltersAndSort();
      _loadDisplayProducts();
      
      _setLoading(false);
    } catch (e) {
      _setError('Failed to initialize celebrity picks: $e');
      _setLoading(false);
    }
  }

  /// Load all celebrities
  Future<void> _loadCelebrities() async {
    _celebrities = await _celebrityService.getAllCelebrities();
  }

  /// Load all categories
  Future<void> _loadCategories() async {
    _categories = await _categoryService.getAllCategories();
  }

  /// Load all products that have celebrity endorsements
  Future<void> _loadAllCelebrityProducts() async {
    final allProducts = await _productService.getAllProducts();
    _allCelebrityProducts = allProducts
        .where((product) => product.celebrityEndorsement != null)
        .toList();
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
  void selectCategory(String? categoryId) {
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
      filtered = filtered.where((product) => 
        product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        product.brand.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        product.description.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    // Apply celebrity filter (only when in celebrity browse mode)
    if (_browseMode == BrowseMode.celebrity && _selectedCelebrityId != null) {
      filtered = filtered.where((product) => 
        product.celebrityEndorsement?.celebrityName == _selectedCelebrityId
      ).toList();
    }
    
    // Apply category filter (only when in category browse mode)
    if (_browseMode == BrowseMode.category && _selectedCategoryId != null) {
      filtered = filtered.where((product) => 
        product.categoryId == _selectedCategoryId
      ).toList();
    }
    
    // Apply price filter
    filtered = filtered.where((product) {
      final price = product.discountPrice ?? product.price;
      return price >= _minPriceFilter && price <= _maxPriceFilter;
    }).toList();
    
    // Apply rating filter
    if (_minRatingFilter > 0) {
      filtered = filtered.where((product) => 
        product.rating >= _minRatingFilter
      ).toList();
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
    
    final newProducts = _filteredProducts.skip(startIndex).take(_itemsPerPage).toList();
    
    if (_currentPage == 0) {
      _displayProducts = newProducts;
    } else {
      _displayProducts.addAll(newProducts);
    }
    
    _hasMoreProducts = endIndex < _filteredProducts.length;
  }

  /// Toggle product wishlist status
  Future<void> toggleWishlist(String productId) async {
    try {
      // Find the product in display products
      final productIndex = _displayProducts.indexWhere((p) => p.id == productId);
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

  /// Get max price for price filter slider
  double getMaxPrice() {
    if (_allCelebrityProducts.isEmpty) return 500000;
    return _allCelebrityProducts
        .map((p) => p.discountPrice ?? p.price)
        .reduce((a, b) => a > b ? a : b);
  }

  /// Get min price for price filter slider
  double getMinPrice() {
    if (_allCelebrityProducts.isEmpty) return 0;
    return _allCelebrityProducts
        .map((p) => p.discountPrice ?? p.price)
        .reduce((a, b) => a < b ? a : b);
  }

  /// Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _selectedCelebrityId = null;
    _selectedCategoryId = null;
    _sortOption = CelebrityPicksSortOption.newest;
    _minPriceFilter = getMinPrice();
    _maxPriceFilter = getMaxPrice();
    _minRatingFilter = 0;
    _currentPage = 0;
    _hasMoreProducts = true;
    _displayProducts.clear();
    _applyFiltersAndSort();
    _loadDisplayProducts();
    notifyListeners();
  }

  /// Refresh all data
  Future<void> refresh() async {
    _currentPage = 0;
    _hasMoreProducts = true;
    _displayProducts.clear();
    await initialize();
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

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }


} 
