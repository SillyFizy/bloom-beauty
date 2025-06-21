import 'package:flutter/foundation.dart';
import 'api_service.dart';

/// Service for loading essential app data quickly during startup
/// This service provides minimal data needed for immediate app functionality
class EssentialDataService {
  static const String _logTag = 'EssentialDataService';

  /// Load essential app data for fast startup
  /// Returns basic categories and app statistics
  static Future<Map<String, dynamic>> loadEssentialAppData() async {
    try {
      debugPrint('$_logTag: Loading essential app data...');
      
      final data = await ApiService.getEssentialData();
      
      if (data['app_status'] == 'ready') {
        debugPrint('$_logTag: Essential app data loaded successfully');
        debugPrint('$_logTag: Categories: ${data['categories']?.length ?? 0}');
        debugPrint('$_logTag: Total products: ${data['stats']?['total_products'] ?? 0}');
      } else {
        debugPrint('$_logTag: Essential app data returned error status');
      }
      
      return data;
    } catch (e) {
      debugPrint('$_logTag: Error loading essential app data: $e');
      return {
        'categories': [],
        'stats': {'total_products': 0, 'total_categories': 0},
        'app_status': 'error',
        'error': e.toString(),
      };
    }
  }

  /// Load essential product data for fast startup
  /// Returns minimal featured products and product statistics
  static Future<Map<String, dynamic>> loadEssentialProductData() async {
    try {
      debugPrint('$_logTag: Loading essential product data...');
      
      final data = await ApiService.getEssentialProductData();
      
      if (data['status'] == 'ready') {
        debugPrint('$_logTag: Essential product data loaded successfully');
        debugPrint('$_logTag: Featured products: ${data['featured_products']?.length ?? 0}');
        debugPrint('$_logTag: Total products: ${data['stats']?['total_products'] ?? 0}');
      } else {
        debugPrint('$_logTag: Essential product data returned error status');
      }
      
      return data;
    } catch (e) {
      debugPrint('$_logTag: Error loading essential product data: $e');
      return {
        'featured_products': [],
        'stats': {'total_products': 0, 'featured_count': 0, 'on_sale_count': 0},
        'status': 'error',
        'error': e.toString(),
      };
    }
  }

  /// Load all essential data in parallel for maximum speed
  /// This is the main method to call during app startup
  static Future<Map<String, dynamic>> loadAllEssentialData() async {
    try {
      debugPrint('$_logTag: Loading all essential data in parallel...');
      
      final results = await Future.wait([
        loadEssentialAppData(),
        loadEssentialProductData(),
      ]);
      
      final appData = results[0];
      final productData = results[1];
      
      final combinedData = {
        'app_data': appData,
        'product_data': productData,
        'loaded_at': DateTime.now().toIso8601String(),
        'success': appData['app_status'] == 'ready' && productData['status'] == 'ready',
      };
      
      debugPrint('$_logTag: All essential data loaded. Success: ${combinedData['success']}');
      
      return combinedData;
    } catch (e) {
      debugPrint('$_logTag: Error loading all essential data: $e');
      return {
        'app_data': {'app_status': 'error'},
        'product_data': {'status': 'error'},
        'loaded_at': DateTime.now().toIso8601String(),
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Check if essential data is valid and complete
  static bool isEssentialDataValid(Map<String, dynamic> data) {
    try {
      final appData = data['app_data'] as Map<String, dynamic>?;
      final productData = data['product_data'] as Map<String, dynamic>?;
      
      if (appData == null || productData == null) {
        return false;
      }
      
      final appStatus = appData['app_status'] == 'ready';
      final productStatus = productData['status'] == 'ready';
      
      return appStatus && productStatus;
    } catch (e) {
      debugPrint('$_logTag: Error validating essential data: $e');
      return false;
    }
  }
} 