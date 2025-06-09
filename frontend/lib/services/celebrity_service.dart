import 'dart:async';
import '../models/product_model.dart';
import '../models/celebrity_model.dart';
import 'data_service.dart';
import 'package:flutter/foundation.dart';

/// Service responsible for all celebrity-related data operations
/// Provides abstraction between UI components and celebrity data sources
class CelebrityService {
  static final CelebrityService _instance = CelebrityService._internal();
  factory CelebrityService() => _instance;
  CelebrityService._internal();

  final DataService _dataService = DataService();
  
  // Cache for celebrity data
  List<Celebrity>? _cachedCelebrities;
  List<Map<String, dynamic>>? _cachedCelebrityPicks;
  DateTime? _lastCacheUpdate;
  static const Duration _cacheExpiry = Duration(minutes: 30);

  /// Get all celebrities with caching
  Future<List<Celebrity>> getAllCelebrities({bool forceRefresh = false}) async {
    if (_shouldRefreshCache() || forceRefresh) {
      await _refreshCelebrityCache();
    }
    return _cachedCelebrities ?? [];
  }

  /// Get celebrity by name
  Future<Celebrity?> getCelebrityByName(String name) async {
    final celebrities = await getAllCelebrities();
    try {
      return celebrities.firstWhere(
        (celebrity) => celebrity.name.toLowerCase() == name.toLowerCase()
      );
    } catch (e) {
      return null;
    }
  }

  /// Get celebrity picks data formatted for UI components
  Future<List<Map<String, dynamic>>> getCelebrityPicks({bool forceRefresh = false}) async {
    if (_shouldRefreshCache() || forceRefresh) {
      await _refreshCelebrityCache();
    }
    return _cachedCelebrityPicks ?? [];
  }

  /// Get celebrity data for a specific product endorsement
  Future<Map<String, dynamic>> getCelebrityDataForProduct(String celebrityName) async {
    final celebrity = await getCelebrityByName(celebrityName);
    
    if (celebrity == null) {
      return {
        'socialMediaLinks': <String, String>{},
        'recommendedProducts': <Product>[],
        'morningRoutineProducts': <Product>[],
        'eveningRoutineProducts': <Product>[],
      };
    }

    return {
      'socialMediaLinks': celebrity.socialMediaLinks,
      'recommendedProducts': celebrity.recommendedProducts,
      'morningRoutineProducts': celebrity.morningRoutineProducts,
      'eveningRoutineProducts': celebrity.eveningRoutineProducts,
    };
  }

  /// Get celebrity's social media links
  Future<Map<String, String>> getCelebritySocialMedia(String celebrityName) async {
    final celebrity = await getCelebrityByName(celebrityName);
    return celebrity?.socialMediaLinks ?? {};
  }

  /// Get celebrity's recommended products
  Future<List<Product>> getCelebrityRecommendedProducts(String celebrityName) async {
    final celebrity = await getCelebrityByName(celebrityName);
    return celebrity?.recommendedProducts ?? [];
  }

  /// Get celebrity's morning routine products
  Future<List<Product>> getCelebrityMorningRoutine(String celebrityName) async {
    final celebrity = await getCelebrityByName(celebrityName);
    return celebrity?.morningRoutineProducts ?? [];
  }

  /// Get celebrity's evening routine products
  Future<List<Product>> getCelebrityEveningRoutine(String celebrityName) async {
    final celebrity = await getCelebrityByName(celebrityName);
    return celebrity?.eveningRoutineProducts ?? [];
  }

  /// Get all products associated with a celebrity
  Future<List<Product>> getAllCelebrityProducts(String celebrityName) async {
    final celebrity = await getCelebrityByName(celebrityName);
    if (celebrity == null) return [];

    final allProducts = <String, Product>{};
    
    // Add recommended products
    for (final product in celebrity.recommendedProducts) {
      allProducts[product.id] = product;
    }
    
    // Add morning routine products
    for (final product in celebrity.morningRoutineProducts) {
      allProducts[product.id] = product;
    }
    
    // Add evening routine products
    for (final product in celebrity.eveningRoutineProducts) {
      allProducts[product.id] = product;
    }

    return allProducts.values.toList();
  }

  /// Search celebrities by name
  Future<List<Celebrity>> searchCelebrities(String query) async {
    if (query.isEmpty) return [];
    
    final celebrities = await getAllCelebrities();
    final lowercaseQuery = query.toLowerCase();
    
    return celebrities.where((celebrity) =>
      celebrity.name.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }

  /// Get celebrities who endorse products in a specific category
  Future<List<Celebrity>> getCelebritiesByProductCategory(String categoryId) async {
    final celebrities = await getAllCelebrities();
    
    return celebrities.where((celebrity) {
      final allProducts = [
        ...celebrity.recommendedProducts,
        ...celebrity.morningRoutineProducts,
        ...celebrity.eveningRoutineProducts,
      ];
      
      return allProducts.any((product) => product.categoryId == categoryId);
    }).toList();
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
      final celebrityProductCount = [
        ...celebrity.recommendedProducts,
        ...celebrity.morningRoutineProducts,
        ...celebrity.eveningRoutineProducts,
      ].length;
      totalProducts += celebrityProductCount;
      
      for (final platform in celebrity.socialMediaLinks.keys) {
        socialMediaPlatforms[platform] = (socialMediaPlatforms[platform] ?? 0) + 1;
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
    
    // Sort by total number of products they endorse
    final celebritiesWithProductCount = celebrities.map((celebrity) {
      final productCount = [
        ...celebrity.recommendedProducts,
        ...celebrity.morningRoutineProducts,
        ...celebrity.eveningRoutineProducts,
      ].length;
      
      return {'celebrity': celebrity, 'productCount': productCount};
    }).toList();
    
    celebritiesWithProductCount.sort((a, b) => 
      (b['productCount'] as int).compareTo(a['productCount'] as int)
    );
    
    return celebritiesWithProductCount
        .take(limit)
        .map((item) => item['celebrity'] as Celebrity)
        .toList();
  }

  /// Get celebrity's most popular products (by rating)
  Future<List<Product>> getCelebrityTopProducts(String celebrityName, {int limit = 3}) async {
    final allProducts = await getAllCelebrityProducts(celebrityName);
    
    allProducts.sort((a, b) => b.rating.compareTo(a.rating));
    return allProducts.take(limit).toList();
  }

  /// Get celebrities with social media presence on specific platform
  Future<List<Celebrity>> getCelebritiesBySocialMediaPlatform(String platform) async {
    final celebrities = await getAllCelebrities();
    
    return celebrities.where((celebrity) =>
      celebrity.socialMediaLinks.containsKey(platform.toLowerCase())
    ).toList();
  }

  /// Validate celebrity data integrity
  Future<CelebrityValidationResult> validateCelebrityData() async {
    final celebrities = await getAllCelebrities();
    final issues = <String>[];
    
    for (final celebrity in celebrities) {
      // Check if celebrity has image
      if (celebrity.image.isEmpty) {
        issues.add('${celebrity.name}: Missing image');
      }
      
      // Check if celebrity has testimonial
      if (celebrity.testimonial?.isEmpty ?? true) {
        issues.add('${celebrity.name}: Missing testimonial');
      }
      
      // Check if celebrity has at least one product
      final totalProducts = [
        ...celebrity.recommendedProducts,
        ...celebrity.morningRoutineProducts,
        ...celebrity.eveningRoutineProducts,
      ].length;
      
      if (totalProducts == 0) {
        issues.add('${celebrity.name}: No associated products');
      }
      
      // Check if social media links are valid URLs
      for (final entry in celebrity.socialMediaLinks.entries) {
        if (!_isValidUrl(entry.value)) {
          issues.add('${celebrity.name}: Invalid ${entry.key} URL');
        }
      }
    }
    
    return CelebrityValidationResult(
      isValid: issues.isEmpty,
      issues: issues,
    );
  }

  /// Get comprehensive celebrity data for navigation (ready for backend integration)
  Future<Map<String, dynamic>> getCelebrityDataForNavigation(String celebrityName) async {
    try {
      // This method consolidates all celebrity data needed for the celebrity screen
      // Ready for backend API integration - just replace the data calls with API endpoints
      
      final futures = await Future.wait([
        getCelebrityByName(celebrityName),
        getCelebritySocialMedia(celebrityName),
        getCelebrityRecommendedProducts(celebrityName),
        getCelebrityMorningRoutine(celebrityName),
        getCelebrityEveningRoutine(celebrityName),
      ]);

      final celebrity = futures[0] as Celebrity?;
      final socialMedia = futures[1] as Map<String, String>;
      final recommendedProducts = futures[2] as List<Product>;
      final morningProducts = futures[3] as List<Product>;
      final eveningProducts = futures[4] as List<Product>;

      if (celebrity == null) {
        throw Exception('Celebrity not found: $celebrityName');
      }

      return {
        'celebrity': celebrity,
        'socialMediaLinks': socialMedia,
        'recommendedProducts': recommendedProducts,
        'morningRoutineProducts': morningProducts,
        'eveningRoutineProducts': eveningProducts,
        'testimonial': celebrity.testimonial ?? '',
        
        // Additional data that could come from backend
        'followerCount': celebrity.followerCount,
        'isVerified': celebrity.isVerified,
        'joinDate': DateTime.now(),
        'totalEndorsements': recommendedProducts.length + morningProducts.length + eveningProducts.length,
      };
    } catch (e) {
      throw Exception('Failed to load celebrity data: $e');
    }
  }

  /// Private methods

  bool _shouldRefreshCache() {
    if (_cachedCelebrities == null || _lastCacheUpdate == null) return true;
    return DateTime.now().difference(_lastCacheUpdate!) > _cacheExpiry;
  }

  Future<void> _refreshCelebrityCache() async {
    try {
      // In production, this would call the API
      _cachedCelebrities = _dataService.getAllCelebrities();
      _cachedCelebrityPicks = _dataService.getCelebrityPicks();
      _lastCacheUpdate = DateTime.now();
    } catch (e) {
      debugPrint('Error refreshing celebrity cache: $e');
      _cachedCelebrities ??= [];
      _cachedCelebrityPicks ??= [];
    }
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Clear cache
  void clearCache() {
    _cachedCelebrities = null;
    _cachedCelebrityPicks = null;
    _lastCacheUpdate = null;
  }

  /// Dispose resources
  void dispose() {
    clearCache();
  }
}

/// Celebrity statistics model
class CelebrityStatistics {
  final int totalCelebrities;
  final int totalProducts;
  final double averageProductsPerCelebrity;
  final Map<String, int> socialMediaPlatforms;

  CelebrityStatistics({
    required this.totalCelebrities,
    required this.totalProducts,
    required this.averageProductsPerCelebrity,
    required this.socialMediaPlatforms,
  });
}

/// Celebrity validation result
class CelebrityValidationResult {
  final bool isValid;
  final List<String> issues;

  CelebrityValidationResult({
    required this.isValid,
    required this.issues,
  });
} 
