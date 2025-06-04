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

  /// Generic GET request with error handling and retries
  static Future<Map<String, dynamic>> get(String endpoint, {int retryCount = 0}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
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
        headers: _headers,
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

  // Health check endpoint
  static Future<bool> healthCheck() async {
    try {
      await get('/health/');
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  
  @override
  String toString() => 'ApiException: $message';
}
