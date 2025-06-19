import 'dart:async';
import '../models/product_model.dart';
import '../models/celebrity_model.dart';
import 'api_service.dart';
import 'package:flutter/foundation.dart';

/// Service responsible for all celebrity-related data operations
/// Provides abstraction between UI components and celebrity data sources
class CelebrityService {
  static final CelebrityService _instance = CelebrityService._internal();
  factory CelebrityService() => _instance;
  CelebrityService._internal();

  // Cache for celebrity data
  List<Celebrity>? _cachedCelebrities;
  Map<int, List<Product>> _cachedMorningRoutines = {};
  Map<int, List<Product>> _cachedEveningRoutines = {};
  Map<int, List<Product>> _cachedPromotions = {};
  DateTime? _lastCacheUpdate;
  static const Duration _cacheExpiry = Duration(minutes: 30);

  /// Check if cache needs refresh
  bool _shouldRefreshCache() {
    return _lastCacheUpdate == null ||
        DateTime.now().difference(_lastCacheUpdate!) > _cacheExpiry;
  }

  /// Get all celebrities with caching
  Future<List<Celebrity>> getAllCelebrities({bool forceRefresh = false}) async {
    if (_shouldRefreshCache() || forceRefresh || _cachedCelebrities == null) {
      await _refreshCelebrityCache();
    }
    return _cachedCelebrities ?? [];
  }

  /// Refresh celebrity cache from API
  Future<void> _refreshCelebrityCache() async {
    try {
      final response = await ApiService.get('/v1/celebrities/');
      final List<dynamic> results =
          response['results'] ?? response['data'] ?? [];

      _cachedCelebrities = results
          .map((json) => Celebrity.fromJson(json as Map<String, dynamic>))
          .toList();

      _lastCacheUpdate = DateTime.now();
      debugPrint(
          'Refreshed celebrity cache: ${_cachedCelebrities?.length} celebrities');
    } catch (e) {
      debugPrint('Error refreshing celebrity cache: $e');
      _cachedCelebrities ??= [];
    }
  }

  /// Get celebrity by ID
  Future<Celebrity?> getCelebrityById(int id) async {
    try {
      final response = await ApiService.get('/v1/celebrities/$id/');
      return Celebrity.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching celebrity by ID $id: $e');
      return null;
    }
  }

  /// Get celebrity by name (compatibility method)
  Future<Celebrity?> getCelebrityByName(String name) async {
    final celebrities = await getAllCelebrities();
    debugPrint('CelebrityService: getCelebrityByName searching for: "$name"');
    debugPrint(
        'CelebrityService: Available celebrities: ${celebrities.map((c) => '"${c.name}" (ID: ${c.id})').join(', ')}');

    try {
      // Try exact name match first
      try {
        final found = celebrities.firstWhere((celebrity) =>
            celebrity.name.toLowerCase().trim() == name.toLowerCase().trim());
        debugPrint(
            'CelebrityService: Found exact match: ${found.name} (ID: ${found.id})');
        return found;
      } catch (e) {
        // Continue to next match attempt
      }

      // Try fullName match
      try {
        final found = celebrities.firstWhere((celebrity) =>
            celebrity.fullName?.toLowerCase().trim() ==
            name.toLowerCase().trim());
        debugPrint(
            'CelebrityService: Found fullName match: ${found.fullName} (ID: ${found.id})');
        return found;
      } catch (e) {
        // Continue to next match attempt
      }

      // Try partial matches (contains)
      try {
        final found = celebrities.firstWhere((celebrity) =>
            celebrity.name.toLowerCase().contains(name.toLowerCase().trim()) ||
            (celebrity.fullName
                    ?.toLowerCase()
                    .contains(name.toLowerCase().trim()) ??
                false));
        debugPrint(
            'CelebrityService: Found partial match: ${found.name} (ID: ${found.id})');
        return found;
      } catch (e) {
        // Continue to next match attempt
      }

      // Try first name match
      final searchFirstName = name.split(' ').first.toLowerCase().trim();
      try {
        final found = celebrities.firstWhere((celebrity) =>
            celebrity.name.toLowerCase().split(' ').first == searchFirstName ||
            (celebrity.fullName?.toLowerCase().split(' ').first ==
                searchFirstName));
        debugPrint(
            'CelebrityService: Found first name match: ${found.name} (ID: ${found.id})');
        return found;
      } catch (e) {
        // No match found
      }

      debugPrint('CelebrityService: No celebrity found for name: "$name"');
      return null;
    } catch (e) {
      debugPrint('CelebrityService: Error in getCelebrityByName: $e');
      return null;
    }
  }

  /// Get celebrity's product promotions
  Future<List<Product>> getCelebrityPromotions(int celebrityId,
      {bool forceRefresh = false}) async {
    debugPrint(
        'CelebrityService: getCelebrityPromotions called for ID $celebrityId');

    if (!forceRefresh && _cachedPromotions.containsKey(celebrityId)) {
      debugPrint(
          'CelebrityService: Returning cached promotions for $celebrityId');
      return _cachedPromotions[celebrityId]!;
    }

    try {
      final endpoint = '/v1/celebrities/$celebrityId/promotions/';
      debugPrint('CelebrityService: Making API call to $endpoint');

      final response = await ApiService.get(endpoint);
      debugPrint(
          'CelebrityService: API response keys: ${response.keys.toList()}');

      final List<dynamic> promotions = response['promotions'] ?? [];
      debugPrint(
          'CelebrityService: Found ${promotions.length} promotions in response');

      final products = promotions.map((promo) {
        debugPrint(
            'CelebrityService: Processing promotion: ${promo['product']?['name'] ?? 'Unknown'}');
        try {
          // Add detailed logging for debugging
          final productData = promo['product'] as Map<String, dynamic>;
          debugPrint(
              'CelebrityService: Product data keys: ${productData.keys.toList()}');

          // Validate and sanitize product data before parsing
          final sanitizedProductData = _sanitizeProductData(productData);

          return Product.fromJson(sanitizedProductData);
        } catch (e) {
          debugPrint('CelebrityService: Error parsing promotion product: $e');
          debugPrint('CelebrityService: Product data: ${promo['product']}');
          rethrow; // Re-throw to maintain error visibility
        }
      }).toList();

      debugPrint(
          'CelebrityService: Converted ${products.length} products from promotions');
      _cachedPromotions[celebrityId] = products;
      return products;
    } catch (e) {
      debugPrint(
          'CelebrityService: ERROR fetching celebrity promotions for $celebrityId: $e');
      debugPrint('CelebrityService: Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  /// Validate social media links
  Map<String, String> _validateSocialMediaLinks(dynamic socialMediaLinks) {
    if (socialMediaLinks == null) return {};

    try {
      if (socialMediaLinks is Map) {
        return Map<String, String>.from(socialMediaLinks);
      }
      return {};
    } catch (e) {
      debugPrint('CelebrityService: Error validating social media links: $e');
      return {};
    }
  }

  /// Validate product list
  List<Map<String, dynamic>> _validateProductList(dynamic productList) {
    if (productList == null) return [];

    try {
      if (productList is List) {
        return productList.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('CelebrityService: Error validating product list: $e');
      return [];
    }
  }

  /// Validate celebrity data
  Map<String, dynamic> _validateCelebrityData(dynamic celebrityData) {
    if (celebrityData == null) {
      return {
        'id': 0,
        'name': 'Celebrity',
        'image': '',
        'bio': 'Beauty expert'
      };
    }

    try {
      if (celebrityData is Map) {
        final celebrity = Map<String, dynamic>.from(celebrityData);
        return {
          'id': celebrity['id'] ?? 0,
          'name': celebrity['name'] ?? 'Celebrity',
          'image': celebrity['image'] ?? '',
          'bio': celebrity['bio'] ?? 'Beauty expert'
        };
      }
      return {
        'id': 0,
        'name': 'Celebrity',
        'image': '',
        'bio': 'Beauty expert'
      };
    } catch (e) {
      debugPrint('CelebrityService: Error validating celebrity data: $e');
      return {
        'id': 0,
        'name': 'Celebrity',
        'image': '',
        'bio': 'Beauty expert'
      };
    }
  }

  /// Create fallback celebrity picks when API fails
  Future<List<Map<String, dynamic>>> _createFallbackCelebrityPicks(
      int limit) async {
    try {
      final celebrities = await getAllCelebrities();
      final picks = <Map<String, dynamic>>[];

      for (final celebrity in celebrities.take(limit)) {
        // Use the data already available in the celebrity object
        if (celebrity.recommendedProducts.isNotEmpty) {
          picks.add({
            'product': celebrity
                .recommendedProducts.first, // Use first recommended product
            'name': celebrity.name,
            'image': celebrity.image ?? '',
            'testimonial': celebrity.testimonial,
            'socialMediaLinks': celebrity.socialMediaLinks,
            'recommendedProducts': celebrity.recommendedProducts,
            'morningRoutineProducts': celebrity.morningRoutineProducts,
            'eveningRoutineProducts': celebrity.eveningRoutineProducts,
            'celebrity': celebrity,
          });
        }
      }

      return picks;
    } catch (e) {
      debugPrint('Error creating fallback celebrity picks: $e');
      return [];
    }
  }

  /// Get celebrity data for navigation (compatibility method)
  Future<Map<String, dynamic>> getCelebrityDataForNavigation(
      String celebrityName) async {
    final celebrity = await getCelebrityByName(celebrityName);
    if (celebrity == null) {
      return {
        'recommendedProducts': <Product>[],
        'socialMediaLinks': <String, String>{},
        'morningRoutineProducts': <Product>[],
        'eveningRoutineProducts': <Product>[],
      };
    }

    final morningRoutine = await getCelebrityMorningRoutine(celebrity.id);
    final eveningRoutine = await getCelebrityEveningRoutine(celebrity.id);
    final promotions = await getCelebrityPromotions(celebrity.id);

    return {
      'recommendedProducts': promotions,
      'socialMediaLinks': celebrity.socialMediaLinks,
      'morningRoutineProducts': morningRoutine,
      'eveningRoutineProducts': eveningRoutine,
    };
  }

  /// Get celebrity data for a specific product endorsement (compatibility method)
  Future<Map<String, dynamic>> getCelebrityDataForProduct(
      String celebrityName) async {
    return await getCelebrityDataForNavigation(celebrityName);
  }

  /// Get celebrity's social media links (compatibility method)
  Future<Map<String, String>> getCelebritySocialMedia(
      String celebrityName) async {
    final celebrity = await getCelebrityByName(celebrityName);
    return celebrity?.socialMediaLinks ?? {};
  }

  /// Get celebrity's recommended products (compatibility method)
  Future<List<Product>> getCelebrityRecommendedProducts(
      String celebrityName) async {
    final celebrity = await getCelebrityByName(celebrityName);
    if (celebrity == null) return [];
    return await getCelebrityPromotions(celebrity.id);
  }

  /// Get celebrity's morning routine products (compatibility method)
  Future<List<Product>> getCelebrityMorningRoutineByName(
      String celebrityName) async {
    final celebrity = await getCelebrityByName(celebrityName);
    if (celebrity == null) return [];
    return await getCelebrityMorningRoutine(celebrity.id);
  }

  /// Get celebrity's evening routine products (compatibility method)
  Future<List<Product>> getCelebrityEveningRoutineByName(
      String celebrityName) async {
    final celebrity = await getCelebrityByName(celebrityName);
    if (celebrity == null) return [];
    return await getCelebrityEveningRoutine(celebrity.id);
  }

  /// Get all products associated with a celebrity
  Future<List<Product>> getAllCelebrityProducts(String celebrityName) async {
    final celebrity = await getCelebrityByName(celebrityName);
    if (celebrity == null) return [];

    final allProducts = <String, Product>{};

    // Get all product types
    final promotions = await getCelebrityPromotions(celebrity.id);
    final morningRoutine = await getCelebrityMorningRoutine(celebrity.id);
    final eveningRoutine = await getCelebrityEveningRoutine(celebrity.id);

    // Add all products to avoid duplicates
    for (final product in [
      ...promotions,
      ...morningRoutine,
      ...eveningRoutine
    ]) {
      allProducts[product.id] = product;
    }

    return allProducts.values.toList();
  }

  /// Search celebrities by name
  Future<List<Celebrity>> searchCelebrities(String query) async {
    try {
      final response = await ApiService.get(
          '/v1/celebrities/search/?q=${Uri.encodeComponent(query)}');
      final List<dynamic> results = response['results'] ?? [];

      return results
          .map((json) => Celebrity.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error searching celebrities: $e');
      return [];
    }
  }

  /// Get celebrities who endorse products in a specific category
  Future<List<Celebrity>> getCelebritiesByProductCategory(
      String categoryId) async {
    try {
      final response = await ApiService.get(
          '/v1/celebrities/category/filter/?category_id=$categoryId');
      final List<dynamic> results = response['celebrities'] ?? [];

      return results
          .map((json) => Celebrity.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching celebrities by category: $e');
      return [];
    }
  }

  /// Get celebrity statistics
  Future<CelebrityStatistics> getCelebrityStatistics() async {
    final celebrities = await getAllCelebrities();

    if (celebrities.isEmpty) {
      return CelebrityStatistics(
        totalCelebrities: 0,
        totalProducts: 0,
        averageProductsPerCelebrity: 0.0,
        socialMediaPlatforms: {},
      );
    }

    int totalProducts = 0;
    final socialMediaPlatforms = <String, int>{};

    for (final celebrity in celebrities) {
      totalProducts += celebrity.totalPromotions;

      for (final platform in celebrity.socialMediaLinks.keys) {
        socialMediaPlatforms[platform] =
            (socialMediaPlatforms[platform] ?? 0) + 1;
      }
    }

    return CelebrityStatistics(
      totalCelebrities: celebrities.length,
      totalProducts: totalProducts,
      averageProductsPerCelebrity: totalProducts / celebrities.length,
      socialMediaPlatforms: socialMediaPlatforms,
    );
  }

  /// Get trending celebrities (based on product endorsements)
  Future<List<Celebrity>> getTrendingCelebrities({int limit = 5}) async {
    final celebrities = await getAllCelebrities();

    // Sort by total number of promotions
    celebrities.sort((a, b) => b.totalPromotions.compareTo(a.totalPromotions));

    return celebrities.take(limit).toList();
  }

  /// Clear cache
  void clearCache() {
    _cachedCelebrities = null;
    _cachedMorningRoutines.clear();
    _cachedEveningRoutines.clear();
    _cachedPromotions.clear();
    _lastCacheUpdate = null;
  }

  /// Sanitize product data to handle parsing issues
  Map<String, dynamic> _sanitizeProductData(Map<String, dynamic> productData) {
    final sanitized = Map<String, dynamic>.from(productData);

    // ✅ MAP BACKEND FIELDS TO PRODUCT MODEL FIELDS
    // Handle field name mapping from backend to frontend
    if (sanitized.containsKey('sale_price')) {
      sanitized['discount_price'] = sanitized['sale_price'];
    }

    if (sanitized.containsKey('category_name')) {
      sanitized['brand'] = sanitized['category_name'];
    }

    if (sanitized.containsKey('brand_name')) {
      sanitized['brand'] = sanitized['brand_name'];
    }

    // Ensure all expected string fields are properly converted
    for (final key in [
      'price',
      'sale_price',
      'discount_price',
      'stock',
      'stock_quantity',
      'beauty_points',
      'rating',
      'review_count'
    ]) {
      if (sanitized[key] != null && sanitized[key] is! String) {
        sanitized[key] = sanitized[key].toString();
      }
    }

    // ✅ HANDLE CATEGORY FIELD PROPERLY
    if (sanitized['category'] != null) {
      if (sanitized['category'] is Map) {
        final categoryMap = sanitized['category'] as Map<String, dynamic>;
        sanitized['category_id'] = categoryMap['id']?.toString() ??
            categoryMap['name']?.toString() ??
            '1';
        sanitized['category'] =
            categoryMap['name']?.toString() ?? 'Beauty Products';
      } else if (sanitized['category'] is! String) {
        sanitized['category_id'] = sanitized['category'].toString();
        sanitized['category'] = 'Beauty Products'; // Default category name
      } else {
        sanitized['category_id'] = sanitized['category'];
      }
    } else {
      sanitized['category_id'] = '1';
      sanitized['category'] = 'Beauty Products';
    }

    // ✅ HANDLE BRAND FIELD PROPERLY
    if (sanitized['brand'] != null) {
      if (sanitized['brand'] is Map) {
        final brandMap = sanitized['brand'] as Map<String, dynamic>;
        sanitized['brand'] = brandMap['name']?.toString() ??
            brandMap['id']?.toString() ??
            'Beauty Brand';
      } else if (sanitized['brand'] is! String) {
        sanitized['brand'] = sanitized['brand'].toString();
      }
    } else {
      sanitized['brand'] =
          sanitized['brand_name']?.toString() ?? 'Beauty Brand';
    }

    // ✅ HANDLE IMAGES PROPERLY
    if (sanitized['images'] != null && sanitized['images'] is List) {
      final imagesList = sanitized['images'] as List;
      final processedImages = <String>[];

      for (final imageItem in imagesList) {
        if (imageItem is Map && imageItem['image'] != null) {
          // Handle complex image objects from backend
          processedImages.add(imageItem['image'].toString());
        } else if (imageItem is String) {
          processedImages.add(imageItem);
        }
      }

      sanitized['images'] = processedImages;
    } else {
      sanitized['images'] = <String>[];
    }

    // ✅ SET REQUIRED DEFAULTS FOR MISSING FIELDS
    // CRITICAL FIX: Use slug as ID since backend expects slug format
    sanitized['id'] =
        sanitized['slug']?.toString() ?? sanitized['id']?.toString() ?? '0';
    sanitized['name'] = sanitized['name']?.toString() ?? 'Product';
    sanitized['description'] = sanitized['description']?.toString() ?? '';
    sanitized['price'] = sanitized['price']?.toString() ?? '0.0';
    sanitized['rating'] = sanitized['rating']?.toString() ?? '0.0';
    sanitized['review_count'] = sanitized['review_count']?.toString() ?? '0';
    sanitized['is_in_stock'] = sanitized['stock'] != null
        ? (int.tryParse(sanitized['stock'].toString()) ?? 0) > 0
        : sanitized['is_active'] ?? true;
    sanitized['ingredients'] = <String>[];
    sanitized['beauty_points'] = sanitized['beauty_points']?.toString() ?? '0';
    sanitized['variants'] = <Map<String, dynamic>>[];
    sanitized['reviews'] = <Map<String, dynamic>>[];

    debugPrint(
        'CelebrityService: Sanitized product - ID: ${sanitized['id']}, Name: ${sanitized['name']}, Slug: ${sanitized['slug']}');
    return sanitized;
  }

  /// Get celebrity's morning routine
  Future<List<Product>> getCelebrityMorningRoutine(int celebrityId,
      {bool forceRefresh = false}) async {
    debugPrint(
        'CelebrityService: getCelebrityMorningRoutine called for ID $celebrityId');

    if (!forceRefresh && _cachedMorningRoutines.containsKey(celebrityId)) {
      debugPrint(
          'CelebrityService: Returning cached morning routine for $celebrityId');
      return _cachedMorningRoutines[celebrityId]!;
    }

    try {
      final endpoint = '/v1/celebrities/$celebrityId/morning-routine/';
      debugPrint('CelebrityService: Making API call to $endpoint');

      final response = await ApiService.get(endpoint);
      debugPrint(
          'CelebrityService: Morning routine API response keys: ${response.keys.toList()}');

      final List<dynamic> routine = response['morning_routine'] ?? [];
      debugPrint(
          'CelebrityService: Found ${routine.length} morning routine items in response');

      // ✅ ENHANCED ERROR HANDLING - Filter out failed products instead of failing completely
      final products = <Product>[];

      for (int i = 0; i < routine.length; i++) {
        final item = routine[i];
        debugPrint(
            'CelebrityService: Processing morning routine item ${i + 1}: ${item['product']?['name'] ?? 'Unknown'}');

        try {
          final productData = item['product'] as Map<String, dynamic>;
          debugPrint(
              'CelebrityService: Product data keys: ${productData.keys.toList()}');

          // Validate and sanitize product data before parsing
          final sanitizedProductData = _sanitizeProductData(productData);

          final product = Product.fromJson(sanitizedProductData);
          products.add(product);
          debugPrint(
              'CelebrityService: Successfully parsed product: ${product.name}');
        } catch (e) {
          debugPrint(
              'CelebrityService: Error parsing morning routine product ${i + 1}: $e');
          debugPrint('CelebrityService: Product data: ${item['product']}');
          // Continue with next product instead of failing completely
          continue;
        }
      }

      debugPrint(
          'CelebrityService: Successfully converted ${products.length}/${routine.length} products from morning routine');
      _cachedMorningRoutines[celebrityId] = products;
      return products;
    } catch (e) {
      debugPrint(
          'CelebrityService: ERROR fetching morning routine for $celebrityId: $e');
      debugPrint('CelebrityService: Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  /// Get celebrity's evening routine
  Future<List<Product>> getCelebrityEveningRoutine(int celebrityId,
      {bool forceRefresh = false}) async {
    debugPrint(
        'CelebrityService: getCelebrityEveningRoutine called for ID $celebrityId');

    if (!forceRefresh && _cachedEveningRoutines.containsKey(celebrityId)) {
      debugPrint(
          'CelebrityService: Returning cached evening routine for $celebrityId');
      return _cachedEveningRoutines[celebrityId]!;
    }

    try {
      final endpoint = '/v1/celebrities/$celebrityId/evening-routine/';
      debugPrint('CelebrityService: Making API call to $endpoint');

      final response = await ApiService.get(endpoint);
      debugPrint(
          'CelebrityService: Evening routine API response keys: ${response.keys.toList()}');

      final List<dynamic> routine = response['evening_routine'] ?? [];
      debugPrint(
          'CelebrityService: Found ${routine.length} evening routine items in response');

      // ✅ ENHANCED ERROR HANDLING - Filter out failed products instead of failing completely
      final products = <Product>[];

      for (int i = 0; i < routine.length; i++) {
        final item = routine[i];
        debugPrint(
            'CelebrityService: Processing evening routine item ${i + 1}: ${item['product']?['name'] ?? 'Unknown'}');

        try {
          final productData = item['product'] as Map<String, dynamic>;
          debugPrint(
              'CelebrityService: Product data keys: ${productData.keys.toList()}');

          // Validate and sanitize product data before parsing
          final sanitizedProductData = _sanitizeProductData(productData);

          final product = Product.fromJson(sanitizedProductData);
          products.add(product);
          debugPrint(
              'CelebrityService: Successfully parsed product: ${product.name}');
        } catch (e) {
          debugPrint(
              'CelebrityService: Error parsing evening routine product ${i + 1}: $e');
          debugPrint('CelebrityService: Product data: ${item['product']}');
          // Continue with next product instead of failing completely
          continue;
        }
      }

      debugPrint(
          'CelebrityService: Successfully converted ${products.length}/${routine.length} products from evening routine');
      _cachedEveningRoutines[celebrityId] = products;
      return products;
    } catch (e) {
      debugPrint(
          'CelebrityService: ERROR fetching evening routine for $celebrityId: $e');
      debugPrint('CelebrityService: Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  /// Get celebrity picks (featured promotions)
  Future<List<Map<String, dynamic>>> getCelebrityPicks(
      {int? celebrityId, int limit = 4, bool forceRefresh = false}) async {
    try {
      debugPrint(
          'CelebrityService: Fetching celebrity picks with limit $limit');

      // Use the new backend endpoint that returns the complete data structure
      final picks = await ApiService.getCelebrityPicks(limit: limit);

      debugPrint('CelebrityService: Received ${picks.length} celebrity picks');

      // Validate and sanitize each pick
      final validatedPicks = <Map<String, dynamic>>[];

      for (int i = 0; i < picks.length; i++) {
        try {
          final pick = picks[i];

          // Validate required fields
          if (pick['product'] == null) {
            debugPrint('CelebrityService: Skipping pick $i - missing product');
            continue;
          }

          if (pick['name'] == null || (pick['name'] as String).isEmpty) {
            debugPrint(
                'CelebrityService: Skipping pick $i - missing celebrity name');
            continue;
          }

          // Ensure all fields have default values
          final validatedPick = <String, dynamic>{
            'product': pick['product'],
            'name': pick['name'] ?? 'Celebrity',
            'image': pick['image'] ?? '',
            'testimonial': pick['testimonial'] ?? 'I love this product!',
            'socialMediaLinks':
                _validateSocialMediaLinks(pick['socialMediaLinks']),
            'recommendedProducts':
                _validateProductList(pick['recommendedProducts']),
            'morningRoutineProducts':
                _validateProductList(pick['morningRoutineProducts']),
            'eveningRoutineProducts':
                _validateProductList(pick['eveningRoutineProducts']),
            'celebrity': _validateCelebrityData(pick['celebrity']),
          };

          validatedPicks.add(validatedPick);
          debugPrint(
              'CelebrityService: Validated pick $i for ${validatedPick['name']}');
        } catch (e) {
          debugPrint('CelebrityService: Error validating pick $i: $e');
          continue;
        }
      }

      debugPrint(
          'CelebrityService: Returning ${validatedPicks.length} validated picks');
      return validatedPicks;
    } catch (e) {
      debugPrint('CelebrityService: Error fetching celebrity picks: $e');
      // Fallback to creating picks from celebrities and their promoted products
      return await _createFallbackCelebrityPicks(limit);
    }
  }
}

// CelebrityStatistics is now imported from celebrity_model.dart

/// Celebrity validation result
class CelebrityValidationResult {
  final bool isValid;
  final List<String> issues;

  CelebrityValidationResult({
    required this.isValid,
    required this.issues,
  });
}
