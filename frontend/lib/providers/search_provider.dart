import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/category_model.dart' as category_model;
import '../services/product_service.dart';
import '../services/category_service.dart';
import '../services/storage_service.dart';

enum SearchSortOption {
  relevance,
  newest,
  priceLowToHigh,
  priceHighToLow,
  highestRated,
  mostPopular,
}

class SearchProvider with ChangeNotifier {
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();

  // State variables
  List<Product> _allProducts = [];
  List<Product> _searchResults = [];
  List<String> _searchHistory = [];
  List<String> _popularSearches = [];
  List<String> _searchSuggestions = [];
  List<category_model.Category> _categories = [];

  bool _isLoading = false;
  bool _isSearching = false;
  bool _isLoadingMore = false;
  String? _error;

  // Search state
  String _currentQuery = '';
  int? _selectedCategoryId;
  SearchSortOption _sortOption = SearchSortOption.relevance;
  double _minPriceFilter = 0;
  double _maxPriceFilter = 1000000;
  double _minRatingFilter = 0;

  // Pagination
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasMoreResults = true;

  // Getters
  List<Product> get searchResults => List.unmodifiable(_searchResults);
  List<String> get searchHistory => List.unmodifiable(_searchHistory);
  List<String> get popularSearches => List.unmodifiable(_popularSearches);
  List<String> get searchSuggestions => List.unmodifiable(_searchSuggestions);
  List<category_model.Category> get categories =>
      List.unmodifiable(_categories);

  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasError => _error != null;
  String? get error => _error;

  String get currentQuery => _currentQuery;
  int? get selectedCategoryId => _selectedCategoryId;
  SearchSortOption get sortOption => _sortOption;
  double get minPriceFilter => _minPriceFilter;
  double get maxPriceFilter => _maxPriceFilter;
  double get minRatingFilter => _minRatingFilter;
  bool get hasMoreResults => _hasMoreResults;
  bool get hasActiveFilters =>
      _selectedCategoryId != null ||
      _minPriceFilter > getMinPrice() ||
      _maxPriceFilter < getMaxPrice() ||
      _minRatingFilter > 0;
  bool get hasSearchHistory => _searchHistory.isNotEmpty;
  int get searchHistoryCount => _searchHistory.length;

  /// Initialize search provider
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await Future.wait([
        _loadAllProducts(),
        _loadCategories(),
        _loadSearchHistory(),
        _loadPopularSearches(),
      ]);
      _clearError();
    } catch (e) {
      _setError('Failed to initialize search: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load all products for search
  Future<void> _loadAllProducts() async {
    try {
      _allProducts = await _productService.getAllProducts();
      _updatePriceRange();
    } catch (e) {
      debugPrint('Error loading products: $e');
      rethrow;
    }
  }

  /// Load categories for filtering
  Future<void> _loadCategories() async {
    try {
      _categories = await _categoryService.getAllCategories();
    } catch (e) {
      debugPrint('Error loading categories: $e');
      rethrow;
    }
  }

  /// Load search history from storage
  Future<void> _loadSearchHistory() async {
    try {
      final history =
          await StorageService.getStringList('search_history') ?? [];
      // Clean up any empty or duplicate entries and limit to 15 items
      final cleanedHistory = history
          .where((item) => item.trim().isNotEmpty)
          .toSet() // Remove duplicates
          .take(15)
          .toList();

      _searchHistory = cleanedHistory;

      // Save cleaned history back to storage if it was modified
      if (cleanedHistory.length != history.length) {
        await _saveSearchHistory();
      }
    } catch (e) {
      debugPrint('Error loading search history: $e');
      _searchHistory = [];
    }
  }

  /// Save search history to storage
  Future<void> _saveSearchHistory() async {
    try {
      await StorageService.setStringList('search_history', _searchHistory);
    } catch (e) {
      debugPrint('Error saving search history: $e');
    }
  }

  /// Load popular searches based on backend data
  Future<void> _loadPopularSearches() async {
    try {
      // Generate popular searches from actual backend categories and brands
      final popularSet = <String>{};

      // Add real category names from backend
      for (final category in _categories) {
        if (category.name.isNotEmpty) {
          popularSet.add(category.name.toLowerCase());
        }
      }

      // Add top brands from backend products
      final brandCounts = <String, int>{};
      for (final product in _allProducts) {
        if (product.brand.isNotEmpty) {
          final brand = product.brand.toLowerCase();
          brandCounts[brand] = (brandCounts[brand] ?? 0) + 1;
        }
      }

      // Add top 5 brands by product count
      final topBrands = brandCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (int i = 0; i < 5 && i < topBrands.length; i++) {
        popularSet.add(topBrands[i].key);
      }

      // Add some common beauty terms as fallback
      popularSet.addAll([
        'lipstick',
        'foundation',
        'mascara',
        'eyeshadow',
        'blush',
      ]);

      _popularSearches = popularSet.take(10).toList();
    } catch (e) {
      debugPrint('Error loading popular searches: $e');
      // Fallback to basic terms if backend data fails
      _popularSearches = [
        'lipstick',
        'foundation',
        'mascara',
        'eyeshadow',
        'blush',
      ];
    }
  }

  /// Perform search with query
  Future<void> search(String query, {bool isNewSearch = true}) async {
    if (query.trim().isEmpty) {
      clearSearch();
      return;
    }

    if (isNewSearch) {
      _currentPage = 0;
      _hasMoreResults = true;
      _searchResults.clear();
      await _addToSearchHistory(query.trim());
    }

    _currentQuery = query.trim();
    _setSearching(true);

    try {
      final results = await _performSearch();

      if (isNewSearch) {
        _searchResults = results;
      } else {
        _searchResults.addAll(results);
      }

      _hasMoreResults = results.length == _pageSize;
      _clearError();
    } catch (e) {
      _setError('Search failed: $e');
    } finally {
      _setSearching(false);
    }
  }

  /// Load more search results
  Future<void> loadMoreResults() async {
    if (!_hasMoreResults || _isLoadingMore || _currentQuery.isEmpty) return;

    _currentPage++;
    _setLoadingMore(true);

    try {
      final results = await _performSearch();
      _searchResults.addAll(results);
      _hasMoreResults = results.length == _pageSize;
      _clearError();
    } catch (e) {
      _setError('Failed to load more results: $e');
      _currentPage--; // Revert page increment on error
    } finally {
      _setLoadingMore(false);
    }
  }

  /// Perform the actual search with filters and sorting
  Future<List<Product>> _performSearch() async {
    List<Product> filtered;

    // Use backend search if we have a query, otherwise use all products
    if (_currentQuery.isNotEmpty) {
      try {
        // Use backend search for better performance and accuracy
        filtered = await _productService.searchProducts(_currentQuery);

        // Note: Backend search already handles filtering out of stock products
        // and basic text search, so we only need to apply additional frontend filters
      } catch (e) {
        debugPrint('Search failed, falling back to local products: $e');
        // Fallback to local filtering if search fails
        filtered = List.from(_allProducts);
        final queryLower = _currentQuery.toLowerCase();
        filtered = filtered.where((product) {
          return product.name.toLowerCase().contains(queryLower) ||
              product.brand.toLowerCase().contains(queryLower) ||
              product.description.toLowerCase().contains(queryLower) ||
              (product.celebrityEndorsement?.celebrityName
                      .toLowerCase()
                      .contains(queryLower) ??
                  false);
        }).toList();
      }
    } else {
      filtered = List.from(_allProducts);
    }

    // Apply category filter
    if (_selectedCategoryId != null) {
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

    // Apply pagination
    final startIndex = _currentPage * _pageSize;
    final endIndex = (startIndex + _pageSize).clamp(0, filtered.length);

    return startIndex < filtered.length
        ? filtered.sublist(startIndex, endIndex)
        : [];
  }

  /// Apply sorting to search results
  void _applySorting(List<Product> products) {
    switch (_sortOption) {
      case SearchSortOption.relevance:
        // Keep original relevance order (could implement scoring algorithm)
        break;
      case SearchSortOption.newest:
        // Assuming products are already sorted by newest
        break;
      case SearchSortOption.priceLowToHigh:
        products.sort((a, b) =>
            (a.discountPrice ?? a.price).compareTo(b.discountPrice ?? b.price));
        break;
      case SearchSortOption.priceHighToLow:
        products.sort((a, b) =>
            (b.discountPrice ?? b.price).compareTo(a.discountPrice ?? a.price));
        break;
      case SearchSortOption.highestRated:
        products.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SearchSortOption.mostPopular:
        products.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
        break;
    }
  }

  /// Generate search suggestions based on input
  Future<void> generateSuggestions(String input) async {
    if (input.trim().isEmpty) {
      _searchSuggestions.clear();
      notifyListeners();
      return;
    }

    final inputLower = input.toLowerCase();
    final suggestions = <String>{};

    // Add product name suggestions
    for (final product in _allProducts) {
      if (product.name.toLowerCase().contains(inputLower)) {
        suggestions.add(product.name);
      }
      if (product.brand.toLowerCase().contains(inputLower)) {
        suggestions.add(product.brand);
      }
    }

    // Add category suggestions
    for (final category in _categories) {
      if (category.name.toLowerCase().contains(inputLower)) {
        suggestions.add(category.name);
      }
    }

    // Add popular search suggestions
    for (final popular in _popularSearches) {
      if (popular.toLowerCase().contains(inputLower)) {
        suggestions.add(popular);
      }
    }

    _searchSuggestions = suggestions.take(8).toList();
    notifyListeners();
  }

  /// Clear current search
  void clearSearch() {
    _currentQuery = '';
    _searchResults.clear();
    _searchSuggestions.clear();
    _currentPage = 0;
    _hasMoreResults = true;
    _clearError();
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _selectedCategoryId = null;
    _sortOption = SearchSortOption.relevance;
    _minPriceFilter = getMinPrice();
    _maxPriceFilter = getMaxPrice();
    _minRatingFilter = 0;

    if (_currentQuery.isNotEmpty) {
      search(_currentQuery, isNewSearch: true);
    } else {
      notifyListeners();
    }
  }

  /// Update sort option
  void updateSortOption(SearchSortOption option) {
    _sortOption = option;
    if (_currentQuery.isNotEmpty) {
      search(_currentQuery, isNewSearch: true);
    } else {
      notifyListeners();
    }
  }

  /// Apply category filter
  void applyCategoryFilter(int? categoryId) {
    _selectedCategoryId = categoryId;
    if (_currentQuery.isNotEmpty) {
      search(_currentQuery, isNewSearch: true);
    } else {
      notifyListeners();
    }
  }

  /// Apply price filter
  void applyPriceFilter(double minPrice, double maxPrice) {
    _minPriceFilter = minPrice;
    _maxPriceFilter = maxPrice;
    if (_currentQuery.isNotEmpty) {
      search(_currentQuery, isNewSearch: true);
    } else {
      notifyListeners();
    }
  }

  /// Apply rating filter
  void applyRatingFilter(double minRating) {
    _minRatingFilter = minRating;
    if (_currentQuery.isNotEmpty) {
      search(_currentQuery, isNewSearch: true);
    } else {
      notifyListeners();
    }
  }

  /// Add search query to history
  Future<void> _addToSearchHistory(String query) async {
    try {
      final trimmedQuery = query.trim();

      // Don't add empty queries or queries that are too short
      if (trimmedQuery.isEmpty || trimmedQuery.length < 2) {
        return;
      }

      // Remove if already exists to avoid duplicates (case-insensitive)
      _searchHistory.removeWhere(
          (item) => item.toLowerCase() == trimmedQuery.toLowerCase());

      // Add to beginning of the list
      _searchHistory.insert(0, trimmedQuery);

      // Keep only last 15 searches
      if (_searchHistory.length > 15) {
        _searchHistory = _searchHistory.take(15).toList();
      }

      // Save to storage
      await _saveSearchHistory();

      // Notify listeners to update UI
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving search history: $e');
    }
  }

  /// Clear search history
  Future<void> clearSearchHistory() async {
    try {
      _searchHistory.clear();
      await StorageService.remove('search_history');
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing search history: $e');
    }
  }

  /// Remove item from search history
  Future<void> removeFromSearchHistory(String query) async {
    try {
      _searchHistory.remove(query);
      await _saveSearchHistory();
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing from search history: $e');
    }
  }

  /// Get min price from all products
  double getMinPrice() {
    if (_allProducts.isEmpty) return 0;
    return _allProducts
        .map((p) => p.discountPrice ?? p.price)
        .reduce((a, b) => a < b ? a : b);
  }

  /// Get max price from all products
  double getMaxPrice() {
    if (_allProducts.isEmpty) return 1000000;
    return _allProducts
        .map((p) => p.discountPrice ?? p.price)
        .reduce((a, b) => a > b ? a : b);
  }

  /// Get search history for analytics/export
  List<String> getSearchHistoryForAnalytics() {
    return List.unmodifiable(_searchHistory);
  }

  /// Get search statistics
  Map<String, dynamic> getSearchStatistics() {
    return {
      'totalSearches': _searchHistory.length,
      'uniqueSearches': _searchHistory.toSet().length,
      'averageSearchLength': _searchHistory.isEmpty
          ? 0.0
          : _searchHistory.map((s) => s.length).reduce((a, b) => a + b) /
              _searchHistory.length,
      'mostRecentSearch':
          _searchHistory.isNotEmpty ? _searchHistory.first : null,
      'oldestSearch': _searchHistory.isNotEmpty ? _searchHistory.last : null,
    };
  }

  /// Import search history (for data migration or sync)
  Future<void> importSearchHistory(List<String> history) async {
    try {
      // Clean and deduplicate the imported history
      final cleanedHistory = history
          .where((item) => item.trim().isNotEmpty && item.length >= 2)
          .toSet()
          .take(15)
          .toList();

      _searchHistory = cleanedHistory;
      await _saveSearchHistory();
      notifyListeners();
    } catch (e) {
      debugPrint('Error importing search history: $e');
    }
  }

  /// Update price range when products change
  void _updatePriceRange() {
    if (_allProducts.isNotEmpty) {
      _minPriceFilter = getMinPrice();
      _maxPriceFilter = getMaxPrice();
    }
  }

  /// Refresh search data
  Future<void> refresh() async {
    await initialize();
    if (_currentQuery.isNotEmpty) {
      await search(_currentQuery, isNewSearch: true);
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) _clearError();
    notifyListeners();
  }

  void _setSearching(bool searching) {
    _isSearching = searching;
    if (searching) _clearError();
    notifyListeners();
  }

  void _setLoadingMore(bool loadingMore) {
    _isLoadingMore = loadingMore;
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
