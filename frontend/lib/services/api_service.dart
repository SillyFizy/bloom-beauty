import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/celebrity_model.dart';

/// Enhanced API service with proper error handling and backend integration
class ApiService {
  // Use 10.0.2.2 for Android emulator to reach host machine
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api'; // Android emulator special IP
    } else {
      return 'http://127.0.0.1:8000/api'; // iOS simulator and other platforms
    }
  }

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
  static Future<Map<String, dynamic>> get(String endpoint,
      {int retryCount = 0}) async {
    try {
      print('DEBUG: Making GET request to: $baseUrl$endpoint');
      final response = await http
          .get(
            Uri.parse('$baseUrl$endpoint'),
            headers: _headersWithAuth,
          )
          .timeout(requestTimeout);

      print('DEBUG: Response status: ${response.statusCode}');
      return _handleResponse(response);
    } on SocketException catch (e) {
      print('DEBUG: SocketException: $e');
      throw ApiException('No internet connection: $e');
    } on http.ClientException catch (e) {
      print('DEBUG: ClientException: $e');
      throw ApiException('Request failed: $e');
    } on FormatException catch (e) {
      print('DEBUG: FormatException: $e');
      throw ApiException('Invalid response format: $e');
    } catch (e) {
      print('DEBUG: Generic error: $e');
      print('DEBUG: Error type: ${e.runtimeType}');
      if (retryCount < maxRetries) {
        debugPrint('Retrying request... Attempt ${retryCount + 1}');
        await Future.delayed(Duration(seconds: retryCount + 1));
        return get(endpoint, retryCount: retryCount + 1);
      }
      throw ApiException('Request failed after $maxRetries retries: $e');
    }
  }

  /// Generic POST request with error handling and retries
  static Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> data,
      {int retryCount = 0}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: _headersWithAuth,
            body: json.encode(data),
          )
          .timeout(requestTimeout);

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
        print('DEBUG: Response body length: ${response.body.length}');
        print(
            'DEBUG: Response body preview: ${response.body.substring(0, math.min(200, response.body.length))}...');
        final decoded = json.decode(response.body);
        print('DEBUG: JSON decoded successfully, type: ${decoded.runtimeType}');
        if (decoded is Map) {
          return decoded as Map<String, dynamic>;
        } else if (decoded is List) {
          // If response is a list, wrap it in a map
          return {'data': decoded};
        } else {
          throw ApiException(
              'Unexpected response type: ${decoded.runtimeType}');
        }
      } catch (e) {
        print('DEBUG: JSON decode error: $e');
        print('DEBUG: Raw response body: ${response.body}');
        throw ApiException('Invalid JSON response: $e');
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
      final List<dynamic> results =
          response['results'] ?? response['data'] ?? [];
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

  /// Get product detail by slug - includes images, variants, and full details
  static Future<Product> getProductDetail(String slug) async {
    try {
      print('DEBUG: Fetching product detail for slug: $slug');
      final response = await get('/v1/products/$slug/');

      // Convert backend data format to match frontend model expectations
      final productData = Map<String, dynamic>.from(response);

      // Ensure we preserve the description from the backend database
      // The description field comes directly from the products_product.description column
      // It should already be in the response, but ensure it's not null or empty
      if (productData['description'] == null ||
          productData['description'].toString().trim().isEmpty) {
        productData['description'] = 'Product description coming soon.';
      }

      // Add mock rating and beauty points since backend doesn't have them yet
      final productId = int.tryParse(productData['id'].toString()) ?? 0;
      productData['rating'] =
          4.5 + (productId % 10) / 10.0; // Mock rating 4.5-5.4
      productData['review_count'] =
          50 + (productId % 200); // Mock review count 50-249

      // Safe price conversion - handle both string and number formats
      double price = 0.0;
      if (productData['price'] != null) {
        if (productData['price'] is String) {
          price = double.tryParse(productData['price']) ?? 0.0;
        } else if (productData['price'] is num) {
          price = productData['price'].toDouble();
        }
      }
      productData['price'] = price; // Ensure price is stored as double
      productData['beauty_points'] =
          (price * 0.1).round(); // 10% of price as beauty points

      // Convert images array to proper format with better null handling
      List<String> finalImages = [];

      // First try to get images from the images array
      if (productData['images'] != null && productData['images'] is List) {
        final List<dynamic> imageObjects = productData['images'];
        for (var imgObj in imageObjects) {
          String? imageUrl;
          if (imgObj is String) {
            imageUrl = imgObj;
          } else if (imgObj is Map && imgObj['image'] != null) {
            imageUrl = imgObj['image'].toString();
          }

          if (imageUrl != null && imageUrl.isNotEmpty) {
            finalImages.add(imageUrl);
          }
        }
      }

      // If no images found, try featured_image
      if (finalImages.isEmpty && productData['featured_image'] != null) {
        final featuredImage = productData['featured_image'].toString();
        if (featuredImage.isNotEmpty) {
          finalImages.add(featuredImage);
        }
      }

      // If still no images, add a placeholder
      if (finalImages.isEmpty) {
        // You can add a default placeholder image URL here if needed
        finalImages = [];
      }

      productData['images'] = finalImages;

      // Convert variants if they exist
      if (productData['variants'] != null) {
        final List<dynamic> variants = productData['variants'];
        productData['variants'] = variants.map((variant) {
          return {
            'id': variant['id'].toString(),
            'name': variant['name'],
            'color': variant['attributes']?.isNotEmpty == true
                ? variant['attributes'][0]['value']
                : 'Standard',
            'images': [], // Will use product images for now
            'price_adjustment': variant['price_adjustment'],
          };
        }).toList();
      } else {
        productData['variants'] = [];
      }

      // Safe sale_price conversion
      if (productData['sale_price'] != null) {
        if (productData['sale_price'] is String) {
          productData['sale_price'] =
              double.tryParse(productData['sale_price']) ?? 0.0;
        } else if (productData['sale_price'] is num) {
          productData['sale_price'] = productData['sale_price'].toDouble();
        }
      }

      // Set default values for missing fields
      productData['is_in_stock'] = (productData['stock'] ?? 0) > 0;
      productData['ingredients'] = []; // Empty for now as per requirements
      productData['reviews'] = []; // Empty for now as per requirements
      productData['category_id'] = productData['category']?.toString() ?? '';
      productData['brand'] = productData['brand_name'] ?? '';
      productData['discount_price'] = productData['sale_price'];

      return Product.fromJson(productData);
    } catch (e) {
      throw ApiException('Failed to load product detail: $e');
    }
  }

  static Future<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      final response = await get('/v1/products/?category=$categoryId');
      final List<dynamic> results =
          response['results'] ?? response['data'] ?? [];
      return results.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw ApiException('Failed to load category products: $e');
    }
  }

  static Future<List<Product>> searchProducts(String query) async {
    try {
      final response =
          await get('/v1/products/?search=${Uri.encodeComponent(query)}');
      final List<dynamic> results =
          response['results'] ?? response['data'] ?? [];
      return results.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw ApiException('Failed to search products: $e');
    }
  }

  /// Get new arrivals from the real API
  static Future<List<Product>> getNewArrivals(
      {int days = 30, int limit = 4}) async {
    try {
      final response =
          await get('/v1/products/new_arrivals/?days=$days&limit=$limit');

      // Handle response - the get method returns Map<String, dynamic>
      List<dynamic> results;
      if (response.containsKey('results')) {
        results = response['results'];
      } else if (response.containsKey('data')) {
        results = response['data'];
      } else {
        // If response is directly an array, handle it
        results = response['data'] ?? [];
      }

      return results.map((json) => Product.fromNewArrivalsApi(json)).toList();
    } catch (e) {
      throw ApiException('Failed to load new arrivals: $e');
    }
  }

  /// Get bestselling products from the real API
  static Future<List<Product>> getBestsellingProducts(
      {int limit = 10, int? days}) async {
    try {
      String endpoint = '/v1/products/bestselling/?limit=$limit';
      if (days != null) {
        endpoint += '&days=$days';
      }

      final response = await get(endpoint);

      // Handle response - the get method returns Map<String, dynamic>
      List<dynamic> results;
      if (response.containsKey('results')) {
        results = response['results'];
      } else if (response.containsKey('data')) {
        results = response['data'];
      } else {
        // If response is directly an array, handle it
        results = response['data'] ?? [];
      }

      return results.map((json) => Product.fromBestsellingApi(json)).toList();
    } catch (e) {
      throw ApiException('Failed to load bestselling products: $e');
    }
  }

  /// Get trending products from the real API
  static Future<List<Product>> getTrendingProducts(
      {int limit = 10, int? days}) async {
    try {
      String endpoint = '/v1/products/trending/?limit=$limit';
      if (days != null) {
        endpoint += '&days=$days';
      }

      final response = await get(endpoint);

      // Handle response - the get method returns Map<String, dynamic>
      List<dynamic> results;
      if (response.containsKey('results')) {
        results = response['results'];
      } else if (response.containsKey('data')) {
        results = response['data'];
      } else {
        // If response is directly an array, handle it
        results = response['data'] ?? [];
      }

      return results.map((json) => Product.fromTrendingApi(json)).toList();
    } catch (e) {
      throw ApiException('Failed to load trending products: $e');
    }
  }

  // Celebrity API endpoints
  static Future<List<Celebrity>> getCelebrities() async {
    try {
      final response = await get('/celebrities/');
      final List<dynamic> results =
          response['results'] ?? response['data'] ?? [];
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
  static Future<Map<String, dynamic>> addToCart(
      String productId, int quantity) async {
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

  static Future<Map<String, dynamic>> removeFromWishlist(
      String productId) async {
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
  static Future<Map<String, dynamic>> submitReview(
      String productId, Map<String, dynamic> reviewData) async {
    try {
      return await post('/products/$productId/reviews/', reviewData);
    } catch (e) {
      throw ApiException('Failed to submit review: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getProductReviews(
      String productId) async {
    try {
      final response = await get('/products/$productId/reviews/');
      final List<dynamic> results =
          response['results'] ?? response['data'] ?? [];
      return results.cast<Map<String, dynamic>>();
    } catch (e) {
      throw ApiException('Failed to load reviews: $e');
    }
  }

  // Category API endpoints
  static Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await get('/categories/');
      final List<dynamic> results =
          response['results'] ?? response['data'] ?? [];
      return results.cast<Map<String, dynamic>>();
    } catch (e) {
      throw ApiException('Failed to load categories: $e');
    }
  }

  // Authentication endpoints
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      return await post('/auth/login/', {
        'email': email,
        'password': password,
      });
    } catch (e) {
      throw ApiException('Failed to login: $e');
    }
  }

  static Future<Map<String, dynamic>> register(
      Map<String, String> userData) async {
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
      final List<dynamic> results =
          response['results'] ?? response['data'] ?? [];
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
  String toString() =>
      'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
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
