import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/celebrity_model.dart';

/// Enhanced API service with proper error handling and backend integration
class ApiService {
  static const String baseUrl = 'http://localhost:8000/api'; // Django backend
  static const Duration requestTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;

  /// Exception classes for better error handling
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Authentication token storage
  static String? _authToken;
  
  /// Set authentication token for API requests
  static void setAuthToken(String token) {
    _authToken = token;
  }
  
  /// Clear authentication token
  static void clearAuthToken() {
    _authToken = null;
  }
  
  /// Get headers with authentication if available
  static Map<String, String> get _headersWithAuth {
    final headers = Map<String, String>.from(_headers);
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  /// Generic GET request with error handling and retries
  static Future<Map<String, dynamic>> get(String endpoint, {int retryCount = 0}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headersWithAuth,
      ).timeout(requestTimeout);
      
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection');
    } on http.ClientException {
      throw ApiException('Request failed');
    } on FormatException {
      throw ApiException('Invalid response format');
    } catch (e) {
      if (retryCount < maxRetries) {
        debugPrint('Retrying request... Attempt ${retryCount + 1}');
        await Future.delayed(Duration(seconds: retryCount + 1));
        return get(endpoint, retryCount: retryCount + 1);
      }
      throw ApiException('Request failed after $maxRetries retries: $e');
    }
  }
  
  /// Generic POST request with error handling and retries
  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data, {int retryCount = 0}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headersWithAuth,
        body: json.encode(data),
      ).timeout(requestTimeout);
      
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection');
    } on http.ClientException {
      throw ApiException('Request failed');
    } on FormatException {
      throw ApiException('Invalid response format');
    } catch (e) {
      if (retryCount < maxRetries) {
        debugPrint('Retrying request... Attempt ${retryCount + 1}');
        await Future.delayed(Duration(seconds: retryCount + 1));
        return post(endpoint, data, retryCount: retryCount + 1);
      }
      throw ApiException('Request failed after $maxRetries retries: $e');
    }
  }

  /// Handle HTTP response and parse JSON
  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return json.decode(response.body);
      } catch (e) {
        throw ApiException('Invalid JSON response');
      }
    } else {
      final errorMessage = _getErrorMessage(response);
      throw ApiException('HTTP ${response.statusCode}: $errorMessage');
    }
  }

  /// Extract error message from response
  static String _getErrorMessage(http.Response response) {
    try {
      final body = json.decode(response.body);
      if (body is Map && body.containsKey('detail')) {
        return body['detail'];
      } else if (body is Map && body.containsKey('error')) {
        return body['error'];
      }
    } catch (e) {
      // If JSON parsing fails, return the raw body or default message
    }
    
    switch (response.statusCode) {
      case 400:
        return 'Bad request';
      case 401:
        return 'Unauthorized';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Not found';
      case 500:
        return 'Internal server error';
      default:
        return 'Request failed';
    }
  }

  // Product API endpoints
  static Future<List<Product>> getProducts() async {
    try {
      final response = await get('/products/');
      final List<dynamic> results = response['results'] ?? response['data'] ?? [];
      return results.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw ApiException('Failed to load products: $e');
    }
  }

  static Future<Product> getProduct(String id) async {
    try {
      final response = await get('/products/$id/');
      return Product.fromJson(response);
    } catch (e) {
      throw ApiException('Failed to load product: $e');
    }
  }

  static Future<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      final response = await get('/products/?category=$categoryId');
      final List<dynamic> results = response['results'] ?? response['data'] ?? [];
      return results.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw ApiException('Failed to load category products: $e');
    }
  }

  static Future<List<Product>> searchProducts(String query) async {
    try {
      final response = await get('/products/?search=${Uri.encodeComponent(query)}');
      final List<dynamic> results = response['results'] ?? response['data'] ?? [];
      return results.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw ApiException('Failed to search products: $e');
    }
  }

  // Celebrity API endpoints
  static Future<List<Celebrity>> getCelebrities() async {
    try {
      final response = await get('/celebrities/');
      final List<dynamic> results = response['results'] ?? response['data'] ?? [];
      return results.map((json) => Celebrity.fromJson(json)).toList();
    } catch (e) {
      throw ApiException('Failed to load celebrities: $e');
    }
  }

  static Future<Celebrity> getCelebrity(String id) async {
    try {
      final response = await get('/celebrities/$id/');
      return Celebrity.fromJson(response);
    } catch (e) {
      throw ApiException('Failed to load celebrity: $e');
    }
  }

  // Cart API endpoints
  static Future<Map<String, dynamic>> addToCart(String productId, int quantity) async {
    try {
      return await post('/cart/add/', {
        'product_id': productId,
        'quantity': quantity,
      });
    } catch (e) {
      throw ApiException('Failed to add to cart: $e');
    }
  }

  static Future<Map<String, dynamic>> removeFromCart(String productId) async {
    try {
      return await post('/cart/remove/', {
        'product_id': productId,
      });
    } catch (e) {
      throw ApiException('Failed to remove from cart: $e');
    }
  }

  static Future<Map<String, dynamic>> getCart() async {
    try {
      return await get('/cart/');
    } catch (e) {
      throw ApiException('Failed to load cart: $e');
    }
  }

  // Wishlist API endpoints
  static Future<Map<String, dynamic>> addToWishlist(String productId) async {
    try {
      return await post('/wishlist/add/', {
        'product_id': productId,
      });
    } catch (e) {
      throw ApiException('Failed to add to wishlist: $e');
    }
  }

  static Future<Map<String, dynamic>> removeFromWishlist(String productId) async {
    try {
      return await post('/wishlist/remove/', {
        'product_id': productId,
      });
    } catch (e) {
      throw ApiException('Failed to remove from wishlist: $e');
    }
  }

  static Future<Map<String, dynamic>> getWishlist() async {
    try {
      return await get('/wishlist/');
    } catch (e) {
      throw ApiException('Failed to load wishlist: $e');
    }
  }

  // Review API endpoints
  static Future<Map<String, dynamic>> submitReview(String productId, Map<String, dynamic> reviewData) async {
    try {
      return await post('/products/$productId/reviews/', reviewData);
    } catch (e) {
      throw ApiException('Failed to submit review: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getProductReviews(String productId) async {
    try {
      final response = await get('/products/$productId/reviews/');
      final List<dynamic> results = response['results'] ?? response['data'] ?? [];
      return results.cast<Map<String, dynamic>>();
    } catch (e) {
      throw ApiException('Failed to load reviews: $e');
    }
  }

  // Category API endpoints
  static Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await get('/categories/');
      final List<dynamic> results = response['results'] ?? response['data'] ?? [];
      return results.cast<Map<String, dynamic>>();
    } catch (e) {
      throw ApiException('Failed to load categories: $e');
    }
  }

  // Authentication endpoints
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      return await post('/auth/login/', {
        'email': email,
        'password': password,
      });
    } catch (e) {
      throw ApiException('Failed to login: $e');
    }
  }

  static Future<Map<String, dynamic>> register(Map<String, String> userData) async {
    try {
      return await post('/auth/register/', userData);
    } catch (e) {
      throw ApiException('Failed to register: $e');
    }
  }

  static Future<void> logout() async {
    try {
      await post('/auth/logout/', {});
      clearAuthToken();
    } catch (e) {
      throw ApiException('Failed to logout: $e');
    }
  }

  // Network connectivity check
  static Future<bool> isConnected() async {
    try {
      await get('/health/');
      return true;
    } catch (e) {
      return false;
    }
  }

  // Batch operations for performance
  static Future<List<Product>> getProductsBatch(List<String> productIds) async {
    try {
      final response = await post('/products/batch/', {
        'product_ids': productIds,
      });
      final List<dynamic> results = response['results'] ?? response['data'] ?? [];
      return results.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw ApiException('Failed to load products batch: $e');
    }
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// Network state management
class NetworkManager {
  static bool _isOnline = true;
  static final List<VoidCallback> _listeners = [];

  static bool get isOnline => _isOnline;

  static void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  static void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  static void setNetworkState(bool isOnline) {
    if (_isOnline != isOnline) {
      _isOnline = isOnline;
      for (final listener in _listeners) {
        listener();
      }
    }
  }

  static Future<void> checkConnectivity() async {
    final isConnected = await ApiService.isConnected();
    setNetworkState(isConnected);
  }
}
