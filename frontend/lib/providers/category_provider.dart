import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/category_model.dart' as category_model;
import '../services/product_service.dart';
import '../services/category_service.dart';

enum SortOption {
  newest,
  priceAscending,
  priceDescending,
  rating,
  popularity,
  name,
}

enum FilterOption {
  all,
  inStock,
  discounted,
  celebrityPicks,
  featured,
  newArrivals,
  bestselling,
  trending,
}

class CategoryProvider with ChangeNotifier {
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();

  // State variables
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<category_model.Category> _categories = [];

  bool _isLoading = false;
  final bool _isLoadingProducts = false;
  String? _error;

  // Filter and sort state
  int? _selectedCategoryId;
  SortOption _selectedSortOption = SortOption.newest;
  Set<FilterOption> _selectedFilters = {FilterOption.all};
  double _minPrice = 0;
  double _maxPrice = 1000000;
  double _minRating = 0;
  String _searchQuery = '';

  // Getters
  List<Product> get allProducts => List.unmodifiable(_allProducts);
  List<Product> get filteredProducts => List.unmodifiable(_filteredProducts);
  List<category_model.Category> get categories =>
      List.unmodifiable(_categories);
  bool get isLoading => _isLoading;
  bool get isLoadingProducts => _isLoadingProducts;
  String? get error => _error;
  bool get hasError => _error != null;

  int? get selectedCategoryId => _selectedCategoryId;
  SortOption get selectedSortOption => _selectedSortOption;
  Set<FilterOption> get selectedFilters => Set.unmodifiable(_selectedFilters);
  double get minPrice => _minPrice;
  double get maxPrice => _maxPrice;
  double get minRating => _minRating;
  String get searchQuery => _searchQuery;

  // Get selected category
  category_model.Category? get selectedCategory {
    if (_selectedCategoryId == null) return null;
    try {
      return _categories.firstWhere((c) => c.id == _selectedCategoryId);
    } catch (e) {
      return null;
    }
  }

  /// Initialize provider
  Future<void> initialize() async {
    try {
      _setLoading(true);
      _clearError();

      // Load categories and products concurrently
      await Future.wait([
        _loadCategories(),
        _loadAllProducts(),
      ]);

      // Reset filters to ensure all products show initially
      _resetFiltersToDefault();

      // Apply initial filtering
      _applyFiltersAndSort();

      _setLoading(false);
    } catch (e) {
      _setError('Failed to initialize categories: $e');
      _setLoading(false);
    }
  }

  /// Reset filters to default state
  void _resetFiltersToDefault() {
    _selectedCategoryId = null;
    _selectedSortOption = SortOption.newest;
    _selectedFilters = {FilterOption.all};
    _minRating = 0;
    _searchQuery = '';

    // Set price range based on actual product prices if products are loaded
    if (_allProducts.isNotEmpty) {
      final priceRange = availablePriceRange;
      _minPrice = priceRange['min']!;
      _maxPrice = priceRange['max']! * 1.1; // Add 10% buffer
    } else {
      _minPrice = 0;
      _maxPrice = double.infinity; // Allow all prices initially
    }
  }

  /// Load all categories
  Future<void> _loadCategories() async {
    _categories = await _categoryService.getAllCategories();
  }

  /// Load all products
  Future<void> _loadAllProducts() async {
    // ✅ Force refresh to ensure latest data and prevent rating inconsistencies
    _allProducts = await _productService.getAllProducts(forceRefresh: true);

    // Initialize filtered products to show all products initially
    _filteredProducts = List.from(_allProducts);
  }

  /// Select category filter
  void selectCategory(int? categoryId) {
    if (_selectedCategoryId == categoryId) return;

    _selectedCategoryId = categoryId;
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Update sort option
  void updateSortOption(SortOption sortOption) {
    if (_selectedSortOption == sortOption) return;

    _selectedSortOption = sortOption;
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Toggle filter option
  void toggleFilter(FilterOption filter) {
    if (filter == FilterOption.all) {
      _selectedFilters.clear();
      _selectedFilters.add(FilterOption.all);
    } else {
      _selectedFilters.remove(FilterOption.all);
      if (_selectedFilters.contains(filter)) {
        _selectedFilters.remove(filter);
      } else {
        _selectedFilters.add(filter);
      }

      if (_selectedFilters.isEmpty) {
        _selectedFilters.add(FilterOption.all);
      }
    }

    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Update price range filter
  void updatePriceRange(double minPrice, double maxPrice) {
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Update rating filter
  void updateRatingFilter(double minRating) {
    _minRating = minRating;
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Update search query
  void updateSearchQuery(String query) {
    _searchQuery = query;
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _resetFiltersToDefault();
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Apply filters and sorting
  void _applyFiltersAndSort() {
    List<Product> filtered = List.from(_allProducts);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) {
        return product.name
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            product.brand.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            product.description
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply category filter
    if (_selectedCategoryId != null) {
      // Find the selected category name to match with product.categoryId
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

    // Apply price range filter
    filtered = filtered.where((product) {
      final price = product.getCurrentPrice();
      return price >= _minPrice && price <= _maxPrice;
    }).toList();

    // Apply rating filter
    if (_minRating > 0) {
      filtered =
          filtered.where((product) => product.rating >= _minRating).toList();
    }

    // Apply additional filters
    if (!_selectedFilters.contains(FilterOption.all)) {
      for (final filter in _selectedFilters) {
        switch (filter) {
          case FilterOption.inStock:
            filtered = filtered.where((product) => product.isInStock).toList();
            break;
          case FilterOption.discounted:
            filtered = filtered
                .where((product) =>
                    product.discountPrice != null &&
                    product.discountPrice! < product.price)
                .toList();
            break;
          case FilterOption.celebrityPicks:
            filtered = filtered
                .where((product) => product.celebrityEndorsement != null)
                .toList();
            break;
          case FilterOption.featured:
            // This would require additional logic based on your featured products logic
            break;
          case FilterOption.newArrivals:
            // This would require additional logic based on your new arrivals logic
            break;
          case FilterOption.bestselling:
            // This would require additional logic based on your bestselling logic
            break;
          case FilterOption.trending:
            // This would require additional logic based on your trending logic
            break;
          default:
            break;
        }
      }
    }

    // Apply sorting
    switch (_selectedSortOption) {
      case SortOption.newest:
        // Assuming products are already sorted by newest
        break;
      case SortOption.priceAscending:
        filtered
            .sort((a, b) => a.getCurrentPrice().compareTo(b.getCurrentPrice()));
        break;
      case SortOption.priceDescending:
        filtered
            .sort((a, b) => b.getCurrentPrice().compareTo(a.getCurrentPrice()));
        break;
      case SortOption.rating:
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SortOption.popularity:
        filtered.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
        break;
      case SortOption.name:
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    _filteredProducts = filtered;
  }

  /// Get available price range from all products
  Map<String, double> get availablePriceRange {
    if (_allProducts.isEmpty) return {'min': 0.0, 'max': 0.0};

    final prices =
        _allProducts.map((product) => product.getCurrentPrice()).toList();
    return {
      'min': prices.reduce((a, b) => a < b ? a : b),
      'max': prices.reduce((a, b) => a > b ? a : b),
    };
  }

  /// Get filter counts
  Map<String, int> get filterCounts {
    return {
      'total': _allProducts.length,
      'filtered': _filteredProducts.length,
      'inStock': _allProducts.where((p) => p.isInStock).length,
      'discounted': _allProducts
          .where((p) => p.discountPrice != null && p.discountPrice! < p.price)
          .length,
      'celebrityPicks':
          _allProducts.where((p) => p.celebrityEndorsement != null).length,
    };
  }

  /// Refresh data
  Future<void> refresh() async {
    await initialize();
  }

  /// Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) _clearError();
  }

  void _clearError() {
    _error = null;
  }

  void _setError(String error) {
    _error = error;
    debugPrint('CategoryProvider Error: $error');
  }
}
