import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/celebrity_model.dart';
import '../constants/app_constants.dart';

/// Enhanced API service with proper error handling and backend integration
class ApiService {
  // Use centralized API base URL configuration
  static String get baseUrl {
    return AppConstants.apiBaseUrl;
  }

  static const Duration requestTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;

  // ✅ CRITICAL FIX: Add rate limiting to prevent 429 errors
  static DateTime? _lastRequestTime;
  static const Duration _minRequestInterval =
      Duration(milliseconds: 100); // Reduced to 100ms between requests

  /// Rate limiting: Wait before making request if needed
  static Future<void> _waitForRateLimit([String? endpoint]) async {
    if (_lastRequestTime != null) {
      // Special handling for celebrity endpoints - no rate limiting during init
      if (endpoint != null && endpoint.contains('celebrities')) {
        // Only apply minimal rate limiting for celebrity endpoints
        final timeSinceLastRequest =
            DateTime.now().difference(_lastRequestTime!);
        const minCelebrityInterval = Duration(milliseconds: 50);
        if (timeSinceLastRequest < minCelebrityInterval) {
          final waitTime = minCelebrityInterval - timeSinceLastRequest;
          await Future.delayed(waitTime);
        }
      } else {
        final timeSinceLastRequest =
            DateTime.now().difference(_lastRequestTime!);
        if (timeSinceLastRequest < _minRequestInterval) {
          final waitTime = _minRequestInterval - timeSinceLastRequest;
          debugPrint(
              'ApiService: Rate limiting - waiting ${waitTime.inMilliseconds}ms');
          await Future.delayed(waitTime);
        }
      }
    }
    _lastRequestTime = DateTime.now();
  }

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
      {int retryCount = 0, bool requireAuth = true}) async {
    try {
      // ✅ CRITICAL FIX: Apply rate limiting before making request
      await _waitForRateLimit(endpoint);

      print('DEBUG: Making GET request to: $baseUrl$endpoint');
      final headers = requireAuth ? _headersWithAuth : _headers;
      final response = await http
          .get(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
          )
          .timeout(requestTimeout);

      print('DEBUG: Response status: ${response.statusCode}');

      // ✅ Handle 429 Too Many Requests specifically
      if (response.statusCode == 429) {
        debugPrint(
            'ApiService: Hit rate limit (429), waiting longer before retry...');
        if (retryCount < maxRetries) {
          // Shorter wait for celebrity endpoints
          final waitTime = endpoint.contains('celebrities')
              ? Duration(milliseconds: 500 * (retryCount + 1))
              : Duration(seconds: (retryCount + 1) * 2);
          await Future.delayed(waitTime);
          return get(endpoint,
              retryCount: retryCount + 1, requireAuth: requireAuth);
        } else {
          throw ApiException('Rate limit exceeded. Please try again later.');
        }
      }

      return _handleResponse(response);
    } on Exception catch (e) {
      // Handle network-related exceptions
      if (e.runtimeType.toString() == 'SocketException') {
        print('DEBUG: SocketException: $e');
        throw ApiException('No internet connection: $e');
      } else if (e is http.ClientException) {
        print('DEBUG: ClientException: $e');
        throw ApiException('Request failed: $e');
      } else {
        print('DEBUG: Other Exception: $e');
        throw ApiException('Request failed: $e');
      }
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
        return get(endpoint,
            retryCount: retryCount + 1, requireAuth: requireAuth);
      }
      throw ApiException('Request failed after $maxRetries retries: $e');
    }
  }

  /// Generic POST request with error handling and retries
  static Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> data,
      {int retryCount = 0}) async {
    try {
      // ✅ CRITICAL FIX: Apply rate limiting before making request
      await _waitForRateLimit(endpoint);

      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: _headersWithAuth,
            body: json.encode(data),
          )
          .timeout(requestTimeout);

      // ✅ Handle 429 Too Many Requests specifically
      if (response.statusCode == 429) {
        debugPrint(
            'ApiService: Hit rate limit (429) on POST, waiting longer before retry...');
        if (retryCount < maxRetries) {
          // Wait longer for rate limit errors
          await Future.delayed(Duration(seconds: (retryCount + 1) * 2));
          return post(endpoint, data, retryCount: retryCount + 1);
        } else {
          throw ApiException('Rate limit exceeded. Please try again later.');
        }
      }

      return _handleResponse(response);
    } on Exception catch (e) {
      // Handle network-related exceptions
      if (e.runtimeType.toString() == 'SocketException') {
        throw ApiException('No internet connection');
      } else if (e is http.ClientException) {
        throw ApiException('Request failed');
      } else {
        throw ApiException('Request failed: $e');
      }
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

  /// Get list of products - basic API wrapper
  static Future<List<Product>> getProducts() async {
    try {
      final response = await get('/v1/products/', requireAuth: false);
      final List<dynamic> results =
          response['results'] ?? response['data'] ?? [];
      // ✅ CRITICAL FIX: Use fromBackendApi to ensure slug-based IDs
      return results.map((json) => Product.fromBackendApi(json)).toList();
    } catch (e) {
      throw ApiException('Failed to load products: $e');
    }
  }

  /// Get all products from backend API with pagination handling
  static Future<List<Product>> getAllProductsFromBackend({int? limit}) async {
    try {
      List<Product> allProducts = [];
      String? nextUrl = '/v1/products/';

      while (nextUrl != null) {
        print('DEBUG: Fetching products from: $nextUrl');
        final response = await get(
            nextUrl.startsWith('/') ? nextUrl : '/v1/products/$nextUrl',
            requireAuth: false);

        final List<dynamic> results = response['results'] ?? [];
        final List<Product> pageProducts = results
            .map((json) => Product.fromBackendApi(json as Map<String, dynamic>))
            .where((product) =>
                product.isInStock) // Filter out out of stock products
            .toList();

        allProducts.addAll(pageProducts);

        // Handle pagination
        nextUrl = response['next'];
        if (nextUrl != null) {
          // Extract just the query part from the full URL
          final uri = Uri.parse(nextUrl);
          // Remove the /api part since baseUrl already includes it
          String path = uri.path;
          if (path.startsWith('/api/')) {
            path = path.substring(4); // Remove '/api'
          }
          nextUrl = '$path?${uri.query}';
        }

        // Apply limit if specified
        if (limit != null && allProducts.length >= limit) {
          allProducts = allProducts.take(limit).toList();
          break;
        }

        print(
            'DEBUG: Loaded ${pageProducts.length} products, total: ${allProducts.length}');
      }

      print('DEBUG: Final product count: ${allProducts.length}');
      return allProducts;
    } catch (e) {
      print('DEBUG: Error loading products from backend: $e');
      throw ApiException('Failed to load products from backend: $e');
    }
  }

  static Future<Product> getProduct(String id) async {
    try {
      final response = await get('/v1/products/$id/', requireAuth: false);
      return Product.fromJson(response);
    } catch (e) {
      throw ApiException('Failed to load product: $e');
    }
  }

  /// Get product detail by ID - includes images, variants, and full details
  static Future<Product> getProductDetail(String productId) async {
    try {
      print('DEBUG: Fetching product detail for slug: $productId');

      // ✅ SIMPLE SLUG-BASED API CALL - Backend expects slug format
      final response =
          await get('/v1/products/$productId/', requireAuth: false);

      // Convert backend data format to match frontend model expectations
      final productData = Map<String, dynamic>.from(response);

      // Ensure we preserve the description from the backend database
      // The description field comes directly from the products_product.description column
      // It should already be in the response, but ensure it's not null or empty
      if (productData['description'] == null ||
          productData['description'].toString().trim().isEmpty) {
        productData['description'] = 'Product description coming soon.';
      }

      // ✅ USE REAL BACKEND RATING DATA (no more mock data)
      // Rating and review count come directly from backend API response

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

      // Use beauty points from backend (no more mock data)
      // The beauty_points field should be included in the backend response
      print('DEBUG: Backend beauty_points: ${productData['beauty_points']}');

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

      // If still no images, use random image from backend media
      if (finalImages.isEmpty) {
        // Use platform-aware URL for images
        final baseImageUrl = _getImageBaseUrl();
        final fallbackImages = [
          'tiana-eyeshadow-palette_1_product_33_20250507_195811.jpg',
          'riding-solo-single-shadow_1_product_312_20250508_214207.jpg',
          'tease-me-shadow-palette_1_product_460_20250509_210720.jpg',
          'tease-me-shadow-palette_3_product_462_20250509_210720.jpg',
          'nude-x-shadow-palette_1_product_283_20250508_212340.jpg',
          'yerimua-bad-lip-duo_1_product_350_20250508_220246.jpg',
          'must-be-cindy-lip-kits_1_product_10_20250507_194300.jpg',
          'nude-x-soft-matte-lipstick_1_product_464_20250509_212000.jpg',
          'volumizing-mascara_1_product_456_20250509_205844.jpg',
          'volumizing-mascara_3_product_458_20250509_205845.jpg',
          'stay-blushing-cute-lip-and-cheek-balm_1_product_299_20250508_213502.jpg',
          'rosy-mcmichael-vol-2-pink-dream-blushes_5_product_292_20250508_212928.jpg',
          'final-finish-baked-highlighter_1_product_173_20250508_162654.jpg',
          'loose-powder_2_product_99_20250508_151153.jpg',
          'sand-snatchural-palette_1_product_445_20250509_204951.jpg',
          'sand-snatchural-palette_2_product_450_20250509_205245.jpg',
          'nude-x-12-piece-brush-set_1_product_125_20250508_153613.jpg',
          'eyebrow-911-essentials-various-shades_1_product_441_20250509_204423.jpg',
          'flawless-stay-powder-foundation_6_product_225_20250508_203603.jpg',
          'loose-powder_1_product_94_20250508_151043.jpg',
        ];

        // Use product ID to select a consistent random image
        final productIdNum = int.tryParse(productData['id'].toString()) ?? 0;
        final imageIndex = productIdNum % fallbackImages.length;
        final fallbackImage = fallbackImages[imageIndex];
        final imageUrl = '$baseImageUrl/media/products/$fallbackImage';
        finalImages.add(imageUrl);

        print(
            'DEBUG: Product ${productData['name']} has no images, using fallback: $imageUrl');
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

      // Set default values for missing fields to match fromBackendApi format
      productData['is_in_stock'] = (productData['stock'] ?? 0) > 0;
      productData['ingredients'] = []; // Empty for now as per requirements
      productData['reviews'] = []; // Empty for now as per requirements
      productData['category_id'] = productData['category']?.toString() ?? '';
      productData['brand'] = productData['brand_name'] ?? '';
      productData['discount_price'] = productData['sale_price'];

      // CRITICAL FIX: Use slug as ID for consistency with other screens
      // All other screens (home, categories, search) use slug as product ID
      // Product detail should also use slug for wishlist consistency
      final productSlug = productData['slug'] ?? productData['id'].toString();

      print('DEBUG: Product Detail API Response Analysis:');
      print('  Numeric ID: ${productData['id']}');
      print('  Slug: ${productData['slug']}');
      print('  Using slug as ID: $productSlug');
      print('  Backend Rating: ${productData['rating']}');
      print('  Backend Review Count: ${productData['review_count']}');
      print('  Backend is_featured: ${productData['is_featured']}');

      // Format the data to match what fromBackendApi expects
      final formattedData = {
        'id': productSlug, // Use slug as ID for wishlist consistency
        'slug': productSlug, // Ensure slug is preserved
        'name': productData['name'],
        'price': productData['price'],
        'sale_price': productData['sale_price'],
        'beauty_points': productData['beauty_points'],
        'stock': productData['stock'],
        'featured_image': productData['images']?.isNotEmpty == true
            ? productData['images'][0]
            : null,
        'category_name': productData['category_id'],
        'brand_name': productData['brand'],
        // ✅ CRITICAL FIX: Include rating and review_count from backend
        'rating': productData['rating'],
        'review_count': productData['review_count'],
        // ✅ CRITICAL FIX: Include is_featured from backend
        'is_featured': productData['is_featured'],
      };

      print('DEBUG: Using fromBackendApi for consistency');
      print('DEBUG: Formatted data ID (slug): ${formattedData['id']}');
      print('DEBUG: Formatted data name: ${formattedData['name']}');
      print('DEBUG: Product will use slug for wishlist operations');

      // Use fromBackendApi for consistency with other screens
      final product = Product.fromBackendApi(formattedData);

      print(
          'DEBUG: Product created with rating: ${product.rating}, reviewCount: ${product.reviewCount}, isFeatured: ${product.isFeatured}');

      // Override with detailed data from product detail API
      return Product(
        id: product.id, // Keep consistent ID format
        name: productData['name'] ?? product.name,
        description: productData['description'] ?? product.description,
        price: product.price,
        discountPrice: product.discountPrice,
        images: finalImages.isNotEmpty ? finalImages : product.images,
        categoryId: product.categoryId,
        brand: product.brand,
        rating: product.rating,
        reviewCount: product.reviewCount,
        isInStock: product.isInStock,
        ingredients: [], // Keep empty as per requirements
        beautyPoints: product.beautyPoints,
        variants: [], // Keep empty for now
        reviews: [], // Keep empty for now
        celebrityEndorsement: null,
        isFeatured: product
            .isFeatured, // ✅ CRITICAL FIX: Include is_featured from backend
      );
    } catch (e) {
      throw ApiException('Failed to load product detail: $e');
    }
  }

  static Future<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      final response = await get('/v1/products/?category=$categoryId');
      final List<dynamic> results =
          response['results'] ?? response['data'] ?? [];
      // ✅ CRITICAL FIX: Use fromBackendApi to ensure slug-based IDs
      return results.map((json) => Product.fromBackendApi(json)).toList();
    } catch (e) {
      throw ApiException('Failed to load category products: $e');
    }
  }

  static Future<Map<String, dynamic>> searchProducts(
    String query, {
    int? page,
    int? pageSize,
    String? category,
    String? brand,
    double? priceMin,
    double? priceMax,
    String? sortBy,
    String? sortDir,
    bool? inStock,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{
        'search': query,
      };

      if (page != null) queryParams['page'] = page.toString();
      if (pageSize != null) queryParams['page_size'] = pageSize.toString();
      if (category != null) queryParams['category'] = category;
      if (brand != null) queryParams['brand'] = brand;
      if (priceMin != null) queryParams['price_min'] = priceMin.toString();
      if (priceMax != null) queryParams['price_max'] = priceMax.toString();
      if (sortBy != null) queryParams['sort_by'] = sortBy;
      if (sortDir != null) queryParams['sort_dir'] = sortDir;
      if (inStock != null) queryParams['in_stock'] = inStock.toString();

      // Build URL with query parameters
      final uri =
          Uri.parse('/v1/products/').replace(queryParameters: queryParams);
      final response = await get(uri.toString());

      final List<dynamic> results = response['results'] ?? [];
      final products = results
          .map((json) => Product.fromBackendApi(json as Map<String, dynamic>))
          .where((product) =>
              product.isInStock) // Filter out out of stock products
          .toList();

      // Return pagination info along with products
      return {
        'results': products,
        'count': response['count'] ?? products.length,
        'next': response['next'],
        'previous': response['previous'],
      };
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

      final response = await get(endpoint, requireAuth: false);

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

      final response = await get(endpoint, requireAuth: false);

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

  // Celebrity API endpoints (public, no authentication required)
  static Future<List<Celebrity>> getCelebrities() async {
    try {
      final response = await get('/v1/celebrities/', requireAuth: false);
      final List<dynamic> results =
          response['results'] ?? response['data'] ?? [];
      return results.map((json) => Celebrity.fromJson(json)).toList();
    } catch (e) {
      throw ApiException('Failed to load celebrities: $e');
    }
  }

  static Future<Celebrity> getCelebrity(String id) async {
    try {
      final response = await get('/v1/celebrities/$id/', requireAuth: false);
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

  // Category API endpoints (public, no authentication required)
  static Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await get('/v1/categories/', requireAuth: false);
      final List<dynamic> results =
          response['results'] ?? response['data'] ?? [];
      return results.cast<Map<String, dynamic>>();
    } catch (e) {
      throw ApiException('Failed to load categories: $e');
    }
  }

  // Celebrity API endpoints

  static Future<Celebrity> getCelebrityById(int id) async {
    try {
      final response = await get('/v1/celebrities/$id/', requireAuth: false);
      return Celebrity.fromJson(response);
    } catch (e) {
      throw ApiException('Failed to load celebrity: $e');
    }
  }

  static Future<List<Product>> getCelebrityPromotions(int celebrityId) async {
    try {
      final response = await get('/v1/celebrities/$celebrityId/promotions/',
          requireAuth: false);
      final List<dynamic> promotions = response['promotions'] ?? [];
      return promotions
          .map((promo) =>
              Product.fromJson(promo['product'] as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiException('Failed to load celebrity promotions: $e');
    }
  }

  static Future<List<Product>> getCelebrityMorningRoutine(
      int celebrityId) async {
    try {
      final response = await get(
          '/v1/celebrities/$celebrityId/morning-routine/',
          requireAuth: false);
      final List<dynamic> routine = response['morning_routine'] ?? [];
      return routine
          .map((item) =>
              Product.fromJson(item['product'] as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiException('Failed to load celebrity morning routine: $e');
    }
  }

  static Future<List<Product>> getCelebrityEveningRoutine(
      int celebrityId) async {
    try {
      final response = await get(
          '/v1/celebrities/$celebrityId/evening-routine/',
          requireAuth: false);
      final List<dynamic> routine = response['evening_routine'] ?? [];
      return routine
          .map((item) =>
              Product.fromJson(item['product'] as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiException('Failed to load celebrity evening routine: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getCelebrityPicks(
      {int limit = 4}) async {
    try {
      final response =
          await get('/v1/celebrities/picks/products/?limit=$limit');

      // Handle response - the get method returns Map<String, dynamic>
      List<dynamic> results;
      if (response.containsKey('results')) {
        results = response['results'] as List<dynamic>;
      } else if (response.containsKey('data')) {
        results = response['data'] as List<dynamic>;
      } else if (response is List) {
        results = response as List<dynamic>;
      } else {
        results = [];
      }

      return results.cast<Map<String, dynamic>>();
    } catch (e) {
      throw ApiException('Failed to load celebrity picks: $e');
    }
  }

  static Future<List<Celebrity>> searchCelebrities(String query) async {
    try {
      final response = await get(
          '/v1/celebrities/search/?q=${Uri.encodeComponent(query)}',
          requireAuth: false);
      final List<dynamic> results = response['results'] ?? [];
      return results.map((json) => Celebrity.fromJson(json)).toList();
    } catch (e) {
      throw ApiException('Failed to search celebrities: $e');
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

  /// Get platform-aware base URL for images
  static String _getImageBaseUrl() {
    return AppConstants.baseUrl;
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
