import 'package:flutter/foundation.dart';
import '../models/celebrity_model.dart';
import '../models/product_model.dart';
import '../services/celebrity_service.dart';

/// Provider for managing celebrity state throughout the application
/// Uses the service layer for data operations and notifies listeners of state changes
class CelebrityProvider with ChangeNotifier {
  final CelebrityService _celebrityService = CelebrityService();

  // State variables
  List<Celebrity> _celebrities = [];
  List<Map<String, dynamic>> _celebrityPicks = [];
  List<Celebrity> _trendingCelebrities = [];
  List<Celebrity> _searchResults = [];
  
  Celebrity? _selectedCelebrity;
  CelebrityStatistics? _celebrityStatistics;
  
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;
  
  String _currentSearchQuery = '';
  Map<String, List<Product>> _celebrityProducts = {};
  Map<String, Map<String, String>> _celebritySocialMedia = {};

  // Getters
  List<Celebrity> get celebrities => List.unmodifiable(_celebrities);
  List<Map<String, dynamic>> get celebrityPicks => List.unmodifiable(_celebrityPicks);
  List<Celebrity> get trendingCelebrities => List.unmodifiable(_trendingCelebrities);
  List<Celebrity> get searchResults => List.unmodifiable(_searchResults);
  
  Celebrity? get selectedCelebrity => _selectedCelebrity;
  CelebrityStatistics? get celebrityStatistics => _celebrityStatistics;
  
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get error => _error;
  bool get hasError => _error != null;
  
  String get currentSearchQuery => _currentSearchQuery;
  Map<String, List<Product>> get celebrityProducts => Map.unmodifiable(_celebrityProducts);
  Map<String, Map<String, String>> get celebritySocialMedia => Map.unmodifiable(_celebritySocialMedia);

  /// Initialize and load all celebrity data
  Future<void> initialize() async {
    await loadCelebrities();
    await loadCelebrityPicks();
    await loadTrendingCelebrities();
    await loadCelebrityStatistics();
  }

  /// Load all celebrities
  Future<void> loadCelebrities({bool forceRefresh = false}) async {
    try {
      _setLoading(true);
      _clearError();
      
      _celebrities = await _celebrityService.getAllCelebrities(forceRefresh: forceRefresh);
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load celebrities: $e');
      _setLoading(false);
    }
  }

  /// Load celebrity picks data
  Future<void> loadCelebrityPicks({bool forceRefresh = false}) async {
    try {
      _clearError();
      
      _celebrityPicks = await _celebrityService.getCelebrityPicks(forceRefresh: forceRefresh);
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load celebrity picks: $e');
    }
  }

  /// Load trending celebrities
  Future<void> loadTrendingCelebrities() async {
    try {
      _trendingCelebrities = await _celebrityService.getTrendingCelebrities();
      notifyListeners();
    } catch (e) {
      print('Failed to load trending celebrities: $e');
    }
  }

  /// Load celebrity statistics
  Future<void> loadCelebrityStatistics() async {
    try {
      _celebrityStatistics = await _celebrityService.getCelebrityStatistics();
      notifyListeners();
    } catch (e) {
      print('Failed to load celebrity statistics: $e');
    }
  }

  /// Get celebrity by name
  Future<Celebrity?> getCelebrityByName(String name) async {
    try {
      return await _celebrityService.getCelebrityByName(name);
    } catch (e) {
      _setError('Failed to get celebrity: $e');
      return null;
    }
  }

  /// Select a celebrity and load their detailed data
  Future<void> selectCelebrity(String celebrityName) async {
    try {
      _setLoading(true);
      _clearError();
      
      _selectedCelebrity = await _celebrityService.getCelebrityByName(celebrityName);
      
      if (_selectedCelebrity != null) {
        // Load additional celebrity data
        await _loadCelebrityDetails(celebrityName);
      }
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to select celebrity: $e');
      _setLoading(false);
    }
  }

  /// Load detailed celebrity data (products, social media)
  Future<void> _loadCelebrityDetails(String celebrityName) async {
    try {
      final futures = await Future.wait([
        _celebrityService.getAllCelebrityProducts(celebrityName),
        _celebrityService.getCelebritySocialMedia(celebrityName),
        _celebrityService.getCelebrityRecommendedProducts(celebrityName),
        _celebrityService.getCelebrityMorningRoutine(celebrityName),
        _celebrityService.getCelebrityEveningRoutine(celebrityName),
      ]);
      
      _celebrityProducts[celebrityName] = futures[0] as List<Product>;
      _celebritySocialMedia[celebrityName] = futures[1] as Map<String, String>;
      
      // Store routine products separately if needed
      final recommendedProducts = futures[2] as List<Product>;
      final morningProducts = futures[3] as List<Product>;
      final eveningProducts = futures[4] as List<Product>;
      
      // You could store these in separate maps if needed
    } catch (e) {
      print('Failed to load celebrity details: $e');
    }
  }

  /// Clear selected celebrity
  void clearSelectedCelebrity() {
    _selectedCelebrity = null;
    notifyListeners();
  }

  /// Search celebrities
  Future<void> searchCelebrities(String query) async {
    try {
      _setSearching(true);
      _clearError();
      _currentSearchQuery = query;
      
      if (query.isEmpty) {
        _searchResults = [];
      } else {
        _searchResults = await _celebrityService.searchCelebrities(query);
      }
      
      _setSearching(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to search celebrities: $e');
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

  /// Get celebrities by product category
  Future<List<Celebrity>> getCelebritiesByCategory(String categoryId) async {
    try {
      return await _celebrityService.getCelebritiesByProductCategory(categoryId);
    } catch (e) {
      print('Failed to get celebrities by category: $e');
      return [];
    }
  }

  /// Get celebrities by social media platform
  Future<List<Celebrity>> getCelebritiesBySocialMedia(String platform) async {
    try {
      return await _celebrityService.getCelebritiesBySocialMediaPlatform(platform);
    } catch (e) {
      print('Failed to get celebrities by social media: $e');
      return [];
    }
  }

  /// Get celebrity's recommended products
  Future<List<Product>> getCelebrityRecommendedProducts(String celebrityName) async {
    try {
      return await _celebrityService.getCelebrityRecommendedProducts(celebrityName);
    } catch (e) {
      print('Failed to get celebrity recommended products: $e');
      return [];
    }
  }

  /// Get celebrity's morning routine products
  Future<List<Product>> getCelebrityMorningRoutine(String celebrityName) async {
    try {
      return await _celebrityService.getCelebrityMorningRoutine(celebrityName);
    } catch (e) {
      print('Failed to get celebrity morning routine: $e');
      return [];
    }
  }

  /// Get celebrity's evening routine products
  Future<List<Product>> getCelebrityEveningRoutine(String celebrityName) async {
    try {
      return await _celebrityService.getCelebrityEveningRoutine(celebrityName);
    } catch (e) {
      print('Failed to get celebrity evening routine: $e');
      return [];
    }
  }

  /// Get celebrity's social media links
  Future<Map<String, String>> getCelebritySocialMedia(String celebrityName) async {
    try {
      return await _celebrityService.getCelebritySocialMedia(celebrityName);
    } catch (e) {
      print('Failed to get celebrity social media: $e');
      return {};
    }
  }

  /// Get celebrity's top rated products
  Future<List<Product>> getCelebrityTopProducts(String celebrityName) async {
    try {
      return await _celebrityService.getCelebrityTopProducts(celebrityName);
    } catch (e) {
      print('Failed to get celebrity top products: $e');
      return [];
    }
  }

  /// Get celebrity data for product endorsement
  Future<Map<String, dynamic>> getCelebrityDataForProduct(String celebrityName) async {
    try {
      return await _celebrityService.getCelebrityDataForProduct(celebrityName);
    } catch (e) {
      print('Failed to get celebrity data for product: $e');
      return {
        'socialMediaLinks': <String, String>{},
        'recommendedProducts': <Product>[],
        'morningRoutineProducts': <Product>[],
        'eveningRoutineProducts': <Product>[],
      };
    }
  }

  /// Validate celebrity data
  Future<CelebrityValidationResult> validateCelebrityData() async {
    try {
      return await _celebrityService.validateCelebrityData();
    } catch (e) {
      print('Failed to validate celebrity data: $e');
      return CelebrityValidationResult(isValid: false, issues: ['Validation failed']);
    }
  }

  /// Get all available social media platforms
  List<String> get availableSocialMediaPlatforms {
    final platforms = <String>{};
    for (final celebrity in _celebrities) {
      platforms.addAll(celebrity.socialMediaLinks.keys);
    }
    final platformList = platforms.toList();
    platformList.sort();
    return platformList;
  }

  /// Get celebrity counts by social media platform
  Map<String, int> get socialMediaPlatformCounts {
    final counts = <String, int>{};
    for (final celebrity in _celebrities) {
      for (final platform in celebrity.socialMediaLinks.keys) {
        counts[platform] = (counts[platform] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// Get celebrities with most products
  List<Celebrity> get celebritiesWithMostProducts {
    final celebritiesWithCounts = _celebrities.map((celebrity) {
      final productCount = [
        ...celebrity.recommendedProducts,
        ...celebrity.morningRoutineProducts,
        ...celebrity.eveningRoutineProducts,
      ].length;
      return {'celebrity': celebrity, 'count': productCount};
    }).toList();
    
    celebritiesWithCounts.sort((a, b) => 
      (b['count'] as int).compareTo(a['count'] as int)
    );
    
    return celebritiesWithCounts
        .map((item) => item['celebrity'] as Celebrity)
        .toList();
  }

  /// Check if celebrity has products in category
  bool celebrityHasProductsInCategory(String celebrityName, String categoryId) {
    final celebrity = _celebrities.where((c) => c.name == celebrityName).firstOrNull;
    if (celebrity == null) return false;
    
    final allProducts = [
      ...celebrity.recommendedProducts,
      ...celebrity.morningRoutineProducts,
      ...celebrity.eveningRoutineProducts,
    ];
    
    return allProducts.any((product) => product.categoryId == categoryId);
  }

  /// Get celebrity product count
  int getCelebrityProductCount(String celebrityName) {
    final celebrity = _celebrities.where((c) => c.name == celebrityName).firstOrNull;
    if (celebrity == null) return 0;
    
    return [
      ...celebrity.recommendedProducts,
      ...celebrity.morningRoutineProducts,
      ...celebrity.eveningRoutineProducts,
    ].length;
  }

  /// Refresh all data
  Future<void> refresh() async {
    await loadCelebrities(forceRefresh: true);
    await loadCelebrityPicks(forceRefresh: true);
    await loadTrendingCelebrities();
    await loadCelebrityStatistics();
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
    _celebrityService.clearCache();
    _celebrities = [];
    _celebrityPicks = [];
    _trendingCelebrities = [];
    _searchResults = [];
    _selectedCelebrity = null;
    _celebrityStatistics = null;
    _currentSearchQuery = '';
    _celebrityProducts = {};
    _celebritySocialMedia = {};
    _clearError();
    notifyListeners();
  }

  @override
  void dispose() {
    _celebrityService.dispose();
    super.dispose();
  }
} 