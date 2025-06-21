import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

class NavigationCategory {
  final String name;
  final String value;
  final String icon;
  final List<String> keywordsList;
  final int order;

  NavigationCategory({
    required this.name,
    required this.value,
    required this.icon,
    required this.keywordsList,
    required this.order,
  });

  factory NavigationCategory.fromJson(Map<String, dynamic> json) {
    return NavigationCategory(
      name: json['name'] ?? '',
      value: json['value'] ?? '',
      icon: json['icon'] ?? '',
      keywordsList: List<String>.from(json['keywords_list'] ?? []),
      order: json['order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'icon': icon,
      'keywords_list': keywordsList,
      'order': order,
    };
  }

  @override
  String toString() {
    return 'NavigationCategory(name: $name, value: $value, order: $order)';
  }
}

class NavigationCategoryService {
  static final String _baseUrl = '${AppConstants.baseUrl}/api/v1/categories';
  
  // Cache for categories to avoid unnecessary API calls
  static List<NavigationCategory>? _cachedCategories;
  static DateTime? _lastFetchTime;
  static const Duration _cacheExpiration = Duration(minutes: 30);

  /// Get navigation categories from backend
  static Future<List<NavigationCategory>> getNavigationCategories({
    bool forceRefresh = false,
  }) async {
    try {
      // Check cache validity
      if (!forceRefresh && 
          _cachedCategories != null && 
          _lastFetchTime != null &&
          DateTime.now().difference(_lastFetchTime!) < _cacheExpiration) {
        debugPrint('NavigationCategoryService: Using cached categories');
        return _cachedCategories!;
      }

      debugPrint('NavigationCategoryService: Fetching categories from API');
      
      final url = Uri.parse('$_baseUrl/navigation/');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('NavigationCategoryService: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true && data['categories'] != null) {
          final List<dynamic> categoriesJson = data['categories'];
          
          final categories = categoriesJson
              .map((json) => NavigationCategory.fromJson(json))
              .toList();

          // Sort by order
          categories.sort((a, b) => a.order.compareTo(b.order));

          // Update cache
          _cachedCategories = categories;
          _lastFetchTime = DateTime.now();

          debugPrint('NavigationCategoryService: Successfully loaded ${categories.length} categories');
          for (var cat in categories) {
            debugPrint('  - ${cat.name} (${cat.value}) [${cat.keywordsList.length} keywords]');
          }

          return categories;
        } else {
          throw Exception('Invalid response format: ${data['error'] ?? 'Unknown error'}');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          'Failed to load categories: ${response.statusCode} - ${errorData['error'] ?? 'Unknown error'}'
        );
      }
    } catch (e) {
      debugPrint('NavigationCategoryService: Error fetching categories: $e');
      
      // Return cached data if available, even if expired
      if (_cachedCategories != null && !forceRefresh) {
        debugPrint('NavigationCategoryService: Falling back to cached categories due to error');
        return _cachedCategories!;
      }
      
      // Return default fallback categories if all else fails
      debugPrint('NavigationCategoryService: Using fallback categories');
      return _getFallbackCategories();
    }
  }

  /// Get fallback categories in case API fails
  static List<NavigationCategory> _getFallbackCategories() {
    return [
      NavigationCategory(
        name: 'EYES',
        value: 'eyes',
        icon: 'visibility',
        keywordsList: ['eye', 'mascara', 'shadow', 'liner', 'eyebrow'],
        order: 1,
      ),
      NavigationCategory(
        name: 'FACE',
        value: 'face',
        icon: 'face',
        keywordsList: ['foundation', 'powder', 'concealer', 'blush', 'bronzer'],
        order: 2,
      ),
      NavigationCategory(
        name: 'LIPS',
        value: 'lips',
        icon: 'lips',
        keywordsList: ['lip', 'gloss', 'balm', 'lipstick'],
        order: 3,
      ),
      NavigationCategory(
        name: 'SKIN',
        value: 'skin',
        icon: 'spa',
        keywordsList: ['serum', 'moisturizer', 'cleanser', 'cream', 'skin'],
        order: 4,
      ),
      NavigationCategory(
        name: 'BODY',
        value: 'body',
        icon: 'person',
        keywordsList: ['body', 'lotion', 'scrub', 'bath'],
        order: 5,
      ),
    ];
  }

  /// Clear cached categories (useful for admin updates)
  static void clearCache() {
    _cachedCategories = null;
    _lastFetchTime = null;
    debugPrint('NavigationCategoryService: Cache cleared');
  }

  /// Get category by value
  static Future<NavigationCategory?> getCategoryByValue(String value) async {
    try {
      final categories = await getNavigationCategories();
      return categories.firstWhere(
        (category) => category.value.toLowerCase() == value.toLowerCase(),
      );
    } catch (e) {
      debugPrint('NavigationCategoryService: Category not found for value: $value');
      return null;
    }
  }

  /// Check if categories are cached and valid
  static bool get hasCachedData {
    return _cachedCategories != null && 
           _lastFetchTime != null &&
           DateTime.now().difference(_lastFetchTime!) < _cacheExpiration;
  }

  /// Get cached categories without API call (returns null if no cache)
  static List<NavigationCategory>? get cachedCategories => _cachedCategories;
} 