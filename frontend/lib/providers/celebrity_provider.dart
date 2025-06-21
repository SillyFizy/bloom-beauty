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

  // Cache management
  DateTime? _lastCelebritiesUpdate;
  DateTime? _lastCelebrityPicksUpdate;
  bool _isInitialized = false;
  static const Duration _cacheExpiry = Duration(minutes: 20);

  // Getters
  List<Celebrity> get celebrities => List.unmodifiable(_celebrities);
  List<Map<String, dynamic>> get celebrityPicks =>
      List.unmodifiable(_celebrityPicks);
  List<Celebrity> get trendingCelebrities =>
      List.unmodifiable(_trendingCelebrities);
  List<Celebrity> get searchResults => List.unmodifiable(_searchResults);

  Celebrity? get selectedCelebrity => _selectedCelebrity;
  CelebrityStatistics? get celebrityStatistics => _celebrityStatistics;

  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get error => _error;
  bool get hasError => _error != null;

  String get currentSearchQuery => _currentSearchQuery;
  Map<String, List<Product>> get celebrityProducts =>
      Map.unmodifiable(_celebrityProducts);
  Map<String, Map<String, String>> get celebritySocialMedia =>
      Map.unmodifiable(_celebritySocialMedia);

  /// Check if cache is still valid for specific data type
  bool _isCacheValid(DateTime? lastUpdate) {
    if (lastUpdate == null) return false;
    return DateTime.now().difference(lastUpdate) < _cacheExpiry;
  }

  /// Initialize and load all celebrity data with smart caching
  Future<void> initialize() async {
    if (_isInitialized && _hasValidCache()) {
      debugPrint(
          'CelebrityProvider: Using cached data, skipping initialization');
      return;
    }

    debugPrint('CelebrityProvider: Initializing with fresh data');
    await loadCelebrities(showLoading: false);
    await loadCelebrityPicks(showLoading: false);
    await loadTrendingCelebrities();
    await loadCelebrityStatistics();
    _isInitialized = true;
  }

  /// Check if we have valid cache for essential data
  bool _hasValidCache() {
    final hasValidTimestamps = _isCacheValid(_lastCelebritiesUpdate) &&
        _isCacheValid(_lastCelebrityPicksUpdate);

    final hasData = _celebrities.isNotEmpty && _celebrityPicks.isNotEmpty;

    debugPrint(
        'CelebrityProvider: Cache validation - timestamps: $hasValidTimestamps, data: $hasData');
    return hasValidTimestamps && hasData;
  }

  /// Load all celebrities with caching
  Future<void> loadCelebrities(
      {bool forceRefresh = false, bool showLoading = true}) async {
    if (!forceRefresh &&
        _isCacheValid(_lastCelebritiesUpdate) &&
        _celebrities.isNotEmpty) {
      debugPrint('CelebrityProvider: Using cached celebrities');
      return;
    }

    try {
      debugPrint('CelebrityProvider: Fetching fresh celebrities');
      if (showLoading) {
        _setLoading(true);
      }
      _clearError();

      _celebrities =
          await _celebrityService.getAllCelebrities(forceRefresh: forceRefresh);
      _lastCelebritiesUpdate = DateTime.now();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading celebrities: $e');
      _setError('Failed to load celebrities');
    } finally {
      if (showLoading) {
        _setLoading(false);
      }
    }
  }

  /// Load celebrity picks data with caching
  Future<void> loadCelebrityPicks(
      {bool forceRefresh = false, bool showLoading = true}) async {
    if (!forceRefresh &&
        _isCacheValid(_lastCelebrityPicksUpdate) &&
        _celebrityPicks.isNotEmpty) {
      debugPrint(
          'CelebrityProvider: Using cached celebrity picks (${_celebrityPicks.length} items)');
      return;
    }

    try {
      debugPrint('CelebrityProvider: Fetching fresh celebrity picks');
      if (showLoading) {
        _setLoading(true);
      }
      _clearError();

      final picks =
          await _celebrityService.getCelebrityPicks(forceRefresh: forceRefresh);

      if (picks.isEmpty) {
        debugPrint(
            'CelebrityProvider: No celebrity picks received from service');
        _setError('No celebrity picks available');
        return;
      }

      // Validate picks before setting
      final validPicks = <Map<String, dynamic>>[];
      for (int i = 0; i < picks.length; i++) {
        final pick = picks[i];
        if (_isValidCelebrityPick(pick)) {
          validPicks.add(pick);
        } else {
          debugPrint('CelebrityProvider: Invalid pick at index $i: $pick');
        }
      }

      if (validPicks.isEmpty) {
        debugPrint('CelebrityProvider: No valid celebrity picks found');
        _setError('No valid celebrity picks available');
        return;
      }

      _celebrityPicks = validPicks;
      _lastCelebrityPicksUpdate = DateTime.now();
      debugPrint(
          'CelebrityProvider: Successfully loaded ${_celebrityPicks.length} celebrity picks');

      notifyListeners();
    } catch (e) {
      debugPrint('CelebrityProvider: Error loading celebrity picks: $e');
      _setError('Failed to load celebrity picks: ${e.toString()}');
    } finally {
      if (showLoading) {
        _setLoading(false);
      }
    }
  }

  /// Validate celebrity pick data structure
  bool _isValidCelebrityPick(Map<String, dynamic> pick) {
    try {
      // Check required fields
      if (pick['product'] == null) {
        debugPrint('CelebrityProvider: Pick missing product field');
        return false;
      }

      if (pick['name'] == null || (pick['name'] as String).isEmpty) {
        debugPrint('CelebrityProvider: Pick missing or empty name field');
        return false;
      }

      // Validate product structure
      final product = pick['product'];
      if (product is! Map<String, dynamic>) {
        debugPrint('CelebrityProvider: Product is not a valid map');
        return false;
      }

      if (product['id'] == null || product['name'] == null) {
        debugPrint('CelebrityProvider: Product missing id or name');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('CelebrityProvider: Error validating pick: $e');
      return false;
    }
  }

  /// Load trending celebrities
  Future<void> loadTrendingCelebrities() async {
    try {
      _trendingCelebrities = await _celebrityService.getTrendingCelebrities();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load trending celebrities: $e');
    }
  }

  /// Load celebrity statistics
  Future<void> loadCelebrityStatistics() async {
    try {
      _celebrityStatistics = await _celebrityService.getCelebrityStatistics();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load celebrity statistics: $e');
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

      _selectedCelebrity =
          await _celebrityService.getCelebrityByName(celebrityName);

      if (_selectedCelebrity != null) {
        // ✅ IMMEDIATE NAVIGATION FIX: Notify listeners immediately with basic celebrity data
        _setLoading(false);
        notifyListeners();

        // Load additional celebrity data in background (don't await)
        _loadCelebrityDetailsInBackground(celebrityName);
      } else {
        _setLoading(false);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('CelebrityProvider: ERROR in selectCelebrity: $e');
      _setError('Failed to select celebrity: $e');
      _setLoading(false);
      notifyListeners(); // Ensure UI updates on error
      rethrow; // Rethrow so navigation can handle the error
    }
  }

  /// Select a celebrity by ID and load their detailed data
  Future<void> selectCelebrityById(int celebrityId) async {
    try {
      _setLoading(true);
      _clearError();

      debugPrint('CelebrityProvider: Selecting celebrity by ID: $celebrityId');

      _selectedCelebrity =
          await _celebrityService.getCelebrityById(celebrityId);

      if (_selectedCelebrity != null) {
        debugPrint(
            'CelebrityProvider: Found celebrity: ${_selectedCelebrity!.name}');

        // ✅ IMMEDIATE NAVIGATION FIX: Notify listeners immediately with basic celebrity data
        _setLoading(false);
        notifyListeners();

        // Load additional celebrity data in background (don't await)
        _loadCelebrityDetailsInBackground(_selectedCelebrity!.name);
      } else {
        debugPrint(
            'CelebrityProvider: No celebrity found with ID: $celebrityId');
        _setError('Celebrity not found');
        _setLoading(false);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('CelebrityProvider: ERROR in selectCelebrityById: $e');
      _setError('Failed to select celebrity: $e');
      _setLoading(false);
      notifyListeners(); // Ensure UI updates on error
      rethrow; // Rethrow so navigation can handle the error
    }
  }

  /// Load detailed celebrity information including products and social media
  Future<void> _loadCelebrityDetails(String celebrityName) async {
    try {
      if (_selectedCelebrity == null) {
        debugPrint('CelebrityProvider: ERROR - _selectedCelebrity is null');
        return;
      }

      debugPrint('CelebrityProvider: Loading full details for $celebrityName');
      debugPrint('CelebrityProvider: Celebrity ID: ${_selectedCelebrity!.id}');

      // ✅ PERFORMANCE FIX: Load all data in parallel instead of sequential
      debugPrint('CelebrityProvider: Starting parallel data fetch...');
      final results = await Future.wait([
        _celebrityService.getCelebrityMorningRoutine(_selectedCelebrity!.id),
        _celebrityService.getCelebrityEveningRoutine(_selectedCelebrity!.id),
        _celebrityService.getCelebrityPromotions(_selectedCelebrity!.id),
      ]);

      final morningRoutineProducts = results[0];
      final eveningRoutineProducts = results[1];
      final recommendedProducts = results[2];

      debugPrint(
          'CelebrityProvider: Loaded ${morningRoutineProducts.length} morning routine products');
      debugPrint(
          'CelebrityProvider: Loaded ${eveningRoutineProducts.length} evening routine products');
      debugPrint(
          'CelebrityProvider: Loaded ${recommendedProducts.length} recommended products');

      // Debug current celebrity state before update
      debugPrint('CelebrityProvider: BEFORE UPDATE:');
      debugPrint(
          '  - Morning routine: ${_selectedCelebrity!.morningRoutineProducts.length}');
      debugPrint(
          '  - Evening routine: ${_selectedCelebrity!.eveningRoutineProducts.length}');
      debugPrint(
          '  - Recommended: ${_selectedCelebrity!.recommendedProducts.length}');

      // Update the selected celebrity with the complete data
      _selectedCelebrity = _selectedCelebrity!.copyWith(
        morningRoutineProducts: morningRoutineProducts,
        eveningRoutineProducts: eveningRoutineProducts,
        recommendedProducts: recommendedProducts,
      );

      // Debug celebrity state after update
      debugPrint('CelebrityProvider: AFTER UPDATE:');
      debugPrint(
          '  - Morning routine: ${_selectedCelebrity!.morningRoutineProducts.length}');
      debugPrint(
          '  - Evening routine: ${_selectedCelebrity!.eveningRoutineProducts.length}');
      debugPrint(
          '  - Recommended: ${_selectedCelebrity!.recommendedProducts.length}');

      // Cache products for navigation compatibility
      final products = await getCelebrityProducts(celebrityName);
      _celebrityProducts[celebrityName] = products;

      debugPrint(
          'CelebrityProvider: Celebrity details loaded successfully - calling notifyListeners()');
      notifyListeners();

      // Force a rebuild by waiting a brief moment and notifying again
      await Future.delayed(const Duration(milliseconds: 100));
      debugPrint('CelebrityProvider: Force rebuild after data loading');
      notifyListeners();
    } catch (e) {
      debugPrint('CelebrityProvider: ERROR loading celebrity details: $e');
      debugPrint('CelebrityProvider: Stack trace: ${StackTrace.current}');
      _setError('Failed to load celebrity details: $e');
    }
  }

  /// Load celebrity details in background without blocking navigation
  void _loadCelebrityDetailsInBackground(String celebrityName) async {
    try {
      debugPrint(
          'CelebrityProvider: Loading celebrity details in background for $celebrityName');
      await _loadCelebrityDetails(celebrityName);
    } catch (e) {
      debugPrint('CelebrityProvider: Background loading error: $e');
      // Don't set error state since navigation already succeeded
    }
  }

  /// Load detailed celebrity information using celebrity ID
  Future<void> _loadCelebrityDetailsById(int celebrityId) async {
    try {
      if (_selectedCelebrity == null) {
        debugPrint('CelebrityProvider: ERROR - _selectedCelebrity is null');
        return;
      }

      debugPrint(
          'CelebrityProvider: Loading full details for celebrity ID: $celebrityId');

      // Load morning routine products
      debugPrint('CelebrityProvider: Starting morning routine fetch...');
      final morningRoutineProducts =
          await _celebrityService.getCelebrityMorningRoutine(celebrityId);
      debugPrint(
          'CelebrityProvider: Loaded ${morningRoutineProducts.length} morning routine products');

      if (morningRoutineProducts.isNotEmpty) {
        debugPrint(
            'CelebrityProvider: Morning routine products: ${morningRoutineProducts.map((p) => p.name).join(', ')}');
      }

      // Load evening routine products
      debugPrint('CelebrityProvider: Starting evening routine fetch...');
      final eveningRoutineProducts =
          await _celebrityService.getCelebrityEveningRoutine(celebrityId);
      debugPrint(
          'CelebrityProvider: Loaded ${eveningRoutineProducts.length} evening routine products');

      if (eveningRoutineProducts.isNotEmpty) {
        debugPrint(
            'CelebrityProvider: Evening routine products: ${eveningRoutineProducts.map((p) => p.name).join(', ')}');
      }

      // Load celebrity promotions/recommended products
      debugPrint('CelebrityProvider: Starting promotions fetch...');
      final recommendedProducts =
          await _celebrityService.getCelebrityPromotions(celebrityId);
      debugPrint(
          'CelebrityProvider: Loaded ${recommendedProducts.length} recommended products');

      if (recommendedProducts.isNotEmpty) {
        debugPrint(
            'CelebrityProvider: Recommended products: ${recommendedProducts.map((p) => p.name).join(', ')}');
      }

      // Debug current celebrity state before update
      debugPrint('CelebrityProvider: BEFORE UPDATE:');
      debugPrint(
          '  - Morning routine: ${_selectedCelebrity!.morningRoutineProducts.length}');
      debugPrint(
          '  - Evening routine: ${_selectedCelebrity!.eveningRoutineProducts.length}');
      debugPrint(
          '  - Recommended: ${_selectedCelebrity!.recommendedProducts.length}');

      // Update the selected celebrity with the complete data
      _selectedCelebrity = _selectedCelebrity!.copyWith(
        morningRoutineProducts: morningRoutineProducts,
        eveningRoutineProducts: eveningRoutineProducts,
        recommendedProducts: recommendedProducts,
      );

      // Debug celebrity state after update
      debugPrint('CelebrityProvider: AFTER UPDATE:');
      debugPrint(
          '  - Morning routine: ${_selectedCelebrity!.morningRoutineProducts.length}');
      debugPrint(
          '  - Evening routine: ${_selectedCelebrity!.eveningRoutineProducts.length}');
      debugPrint(
          '  - Recommended: ${_selectedCelebrity!.recommendedProducts.length}');

      debugPrint(
          'CelebrityProvider: Celebrity details loaded successfully - calling notifyListeners()');
      notifyListeners();

      // Force a rebuild by waiting a brief moment and notifying again
      await Future.delayed(const Duration(milliseconds: 100));
      debugPrint('CelebrityProvider: Force rebuild after data loading');
      notifyListeners();
    } catch (e) {
      debugPrint('CelebrityProvider: ERROR loading celebrity details: $e');
      debugPrint('CelebrityProvider: Stack trace: ${StackTrace.current}');
      _setError('Failed to load celebrity details: $e');
    }
  }

  /// Get celebrity products (morning and evening routine)
  Future<List<Product>> getCelebrityProducts(String celebrityName) async {
    try {
      // Find celebrity by name to get ID
      final celebrity = _celebrities.firstWhere(
        (c) => c.name == celebrityName || c.fullName == celebrityName,
        orElse: () => throw Exception('Celebrity not found'),
      );

      final morningProducts =
          await _celebrityService.getCelebrityMorningRoutine(celebrity.id);
      final eveningProducts =
          await _celebrityService.getCelebrityEveningRoutine(celebrity.id);

      // Combine and return unique products
      final allProducts = <Product>[];
      allProducts.addAll(morningProducts);
      for (final product in eveningProducts) {
        if (!allProducts.any((p) => p.id == product.id)) {
          allProducts.add(product);
        }
      }

      return allProducts;
    } catch (e) {
      debugPrint('Error getting celebrity products: $e');
      return [];
    }
  }

  /// Search celebrities by query
  Future<void> searchCelebrities(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      _currentSearchQuery = '';
      notifyListeners();
      return;
    }

    try {
      _setSearching(true);
      _currentSearchQuery = query;

      _searchResults = await _celebrityService.searchCelebrities(query);
      notifyListeners();
    } catch (e) {
      debugPrint('Error searching celebrities: $e');
      _setError('Failed to search celebrities');
    } finally {
      _setSearching(false);
    }
  }

  /// Clear search results
  void clearSearch() {
    _searchResults = [];
    _currentSearchQuery = '';
    notifyListeners();
  }

  /// Get celebrities by social media platform - stub implementation
  Future<List<Celebrity>> getCelebritiesBySocialMediaPlatform(
      String platform) async {
    try {
      // Filter celebrities by social media platform
      return _celebrities.where((celebrity) {
        switch (platform.toLowerCase()) {
          case 'instagram':
            return celebrity.socialMediaLinks['instagram']?.isNotEmpty ?? false;
          case 'facebook':
            return celebrity.socialMediaLinks['facebook']?.isNotEmpty ?? false;
          case 'snapchat':
            return celebrity.socialMediaLinks['snapchat']?.isNotEmpty ?? false;
          default:
            return false;
        }
      }).toList();
    } catch (e) {
      debugPrint('Error getting celebrities by social media platform: $e');
      return [];
    }
  }

  /// Get celebrity morning routine
  Future<List<Product>> getCelebrityMorningRoutine(String celebrityName) async {
    try {
      // Find celebrity by name to get ID
      final celebrity = _celebrities.firstWhere(
        (c) => c.name == celebrityName || c.fullName == celebrityName,
        orElse: () => throw Exception('Celebrity not found'),
      );

      return await _celebrityService.getCelebrityMorningRoutine(celebrity.id);
    } catch (e) {
      debugPrint('Error getting celebrity morning routine: $e');
      return [];
    }
  }

  /// Get celebrity evening routine
  Future<List<Product>> getCelebrityEveningRoutine(String celebrityName) async {
    try {
      // Find celebrity by name to get ID
      final celebrity = _celebrities.firstWhere(
        (c) => c.name == celebrityName || c.fullName == celebrityName,
        orElse: () => throw Exception('Celebrity not found'),
      );

      return await _celebrityService.getCelebrityEveningRoutine(celebrity.id);
    } catch (e) {
      debugPrint('Error getting celebrity evening routine: $e');
      return [];
    }
  }

  /// Get celebrity top products - stub implementation
  Future<List<Product>> getCelebrityTopProducts(String celebrityName) async {
    try {
      // Find celebrity by name to get ID
      final celebrity = _celebrities.firstWhere(
        (c) => c.name == celebrityName || c.fullName == celebrityName,
        orElse: () => throw Exception('Celebrity not found'),
      );

      // Get promotions and return the promoted products
      final promotions =
          await _celebrityService.getCelebrityPromotions(celebrity.id);
      return promotions;
    } catch (e) {
      debugPrint('Error getting celebrity top products: $e');
      return [];
    }
  }

  /// Validate celebrity data - stub implementation
  Future<bool> validateCelebrityData() async {
    try {
      // Basic validation - check if we have celebrities loaded
      return _celebrities.isNotEmpty;
    } catch (e) {
      debugPrint('Error validating celebrity data: $e');
      return false;
    }
  }

  /// Get celebrity featured picks (similar to celebrity picks but filtered for featured)
  Future<List<Map<String, dynamic>>> getFeaturedCelebrityPicks(
      {bool forceRefresh = false}) async {
    try {
      final allPicks =
          await _celebrityService.getCelebrityPicks(forceRefresh: forceRefresh);
      // Filter for featured picks if needed, for now return all
      return allPicks;
    } catch (e) {
      debugPrint('Error getting featured celebrity picks: $e');
      return [];
    }
  }

  /// Filter celebrities by category
  List<Celebrity> filterCelebritiesByCategory(String category) {
    if (category.isEmpty || category.toLowerCase() == 'all') {
      return _celebrities;
    }

    // Basic filtering - can be enhanced based on backend data structure
    return _celebrities.where((celebrity) {
      return celebrity.bio?.toLowerCase().contains(category.toLowerCase()) ??
          false;
    }).toList();
  }

  /// Get celebrity by ID
  Future<Celebrity?> getCelebrityById(int id) async {
    try {
      return await _celebrityService.getCelebrityById(id);
    } catch (e) {
      debugPrint('Error getting celebrity by ID: $e');
      return null;
    }
  }

  /// Refresh all celebrity data
  Future<void> refreshAllData() async {
    await loadCelebrities(forceRefresh: true);
    await loadCelebrityPicks(forceRefresh: true);
    await loadTrendingCelebrities();
    await loadCelebrityStatistics();
  }

  /// Refresh alias for backwards compatibility
  Future<void> refresh() async {
    await refreshAllData();
  }

  /// Get celebrity data for product - backwards compatibility method
  Future<Map<String, dynamic>> getCelebrityDataForProduct(
      String celebrityName) async {
    try {
      final celebrity = _celebrities.firstWhere(
        (c) => c.name == celebrityName || c.fullName == celebrityName,
        orElse: () => throw Exception('Celebrity not found'),
      );

      return {
        'socialMediaLinks': celebrity.socialMediaLinks,
        'recommendedProducts': celebrity.recommendedProducts,
        'morningRoutineProducts': celebrity.morningRoutineProducts,
        'eveningRoutineProducts': celebrity.eveningRoutineProducts,
      };
    } catch (e) {
      debugPrint('Error getting celebrity data for product: $e');
      return {
        'socialMediaLinks': <String, String>{},
        'recommendedProducts': <Product>[],
        'morningRoutineProducts': <Product>[],
        'eveningRoutineProducts': <Product>[],
      };
    }
  }

  /// Get celebrity data for navigation - backwards compatibility method
  Future<Map<String, dynamic>> getCelebrityDataForNavigation(
      String celebrityName) async {
    try {
      debugPrint('Getting celebrity data for navigation: $celebrityName');

      // Find celebrity
      final celebrity = _celebrities.firstWhere(
        (c) => c.name == celebrityName || c.fullName == celebrityName,
        orElse: () => throw Exception('Celebrity not found'),
      );

      // Get products
      final morningRoutine = await getCelebrityMorningRoutine(celebrityName);
      final eveningRoutine = await getCelebrityEveningRoutine(celebrityName);
      final topProducts = await getCelebrityTopProducts(celebrityName);

      // Update selected celebrity
      _selectedCelebrity = celebrity;
      notifyListeners();

      return {
        'celebrity': celebrity,
        'recommendedProducts': topProducts,
        'socialMediaLinks': celebrity.socialMediaLinks,
        'morningRoutineProducts': morningRoutine,
        'eveningRoutineProducts': eveningRoutine,
        'testimonial': celebrity.testimonial,
        'followerCount': 0, // Default value
        'isVerified': true, // Default value
        'totalEndorsements': topProducts.length,
      };
    } catch (e) {
      debugPrint('Error getting celebrity data for navigation: $e');
      _setError('Failed to load celebrity data: $e');
      rethrow;
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setSearching(bool searching) {
    _isSearching = searching;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear all cached data
  void clearCache() {
    debugPrint('Clearing celebrity cache...');
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
    _lastCelebritiesUpdate = null;
    _lastCelebrityPicksUpdate = null;
    _isInitialized = false;
    _clearError();
    notifyListeners();
  }

  @override
  void dispose() {
    // The service doesn't need disposal in this implementation
    super.dispose();
  }
}
