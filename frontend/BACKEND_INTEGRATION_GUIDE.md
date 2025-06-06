# Backend Integration Guide for Bloom Beauty Flutter App

## Overview

This guide outlines how to integrate the Bloom Beauty Flutter app with a real backend API. The app is already architected with a proper data layer, making backend integration straightforward.

## Current Architecture

### ✅ What's Already Implemented

1. **Proper Data Layer Separation**
   - All data flows through service layer (`ProductService`, `CelebrityService`, etc.)
   - No direct data access in UI components
   - Clean separation between data, business logic, and UI

2. **Provider Pattern Implementation**
   - All state management uses Provider pattern
   - Optimized with Selector widgets for performance
   - Centralized provider management in `AppProviders`

3. **API Service Foundation**
   - Basic `ApiService` with error handling
   - Authentication token management
   - Retry mechanisms and timeout handling

4. **Performance Optimization**
   - Caching mechanisms in place
   - Optimized rebuild prevention
   - Performance monitoring utilities

## Backend Integration Steps

### 1. Update API Configuration

```dart
// lib/services/api_service.dart
class ApiService {
  // Update these for your production backend
  static const String baseUrl = 'https://your-production-api.com/api';
  static const String stagingUrl = 'https://staging-api.com/api';
  static const String developmentUrl = 'http://localhost:8000/api';
  
  // Environment-based URL selection
  static String get currentBaseUrl {
    switch (Environment.current) {
      case Environment.production:
        return baseUrl;
      case Environment.staging:
        return stagingUrl;
      case Environment.development:
        return developmentUrl;
    }
  }
}
```

### 2. Environment Configuration

Create `lib/config/environment.dart`:

```dart
enum Environment { development, staging, production }

class EnvironmentConfig {
  static Environment current = Environment.development;
  
  static void setEnvironment(Environment env) {
    current = env;
  }
  
  static bool get isDevelopment => current == Environment.development;
  static bool get isStaging => current == Environment.staging;
  static bool get isProduction => current == Environment.production;
}
```

### 3. Update Service Layer

#### ProductService Integration

```dart
// lib/services/product_service.dart
class ProductService {
  // Replace DataService calls with API calls
  Future<List<Product>> getAllProducts({bool forceRefresh = false}) async {
    if (_shouldRefreshCache() || forceRefresh) {
      try {
        // Call real API
        _cachedProducts = await ApiService.getProducts();
        _lastCacheUpdate = DateTime.now();
      } catch (e) {
        // Fallback to cached data if API fails
        if (_cachedProducts == null) {
          throw e;
        }
        debugPrint('API failed, using cached data: $e');
      }
    }
    return _cachedProducts ?? [];
  }
}
```

### 4. Model Serialization

Update your models to support JSON serialization:

```dart
// lib/models/product_model.dart
class Product {
  // ... existing properties ...
  
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      // ... map all properties
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      // ... map all properties
    };
  }
}
```

### 5. Authentication Integration

```dart
// lib/providers/auth_provider.dart
class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  
  Future<bool> login(String email, String password) async {
    try {
      final response = await ApiService.login(email, password);
      _token = response['access_token'];
      _user = User.fromJson(response['user']);
      
      // Set token for future API calls
      ApiService.setAuthToken(_token!);
      
      // Save to secure storage
      await StorageService.setString('auth_token', _token!);
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Login failed: $e');
      return false;
    }
  }
}
```

### 6. Offline Support

```dart
// lib/services/offline_service.dart
class OfflineService {
  static Future<void> syncWhenOnline() async {
    if (await NetworkManager.isConnected()) {
      // Sync cart, wishlist, etc.
      await _syncCart();
      await _syncWishlist();
    }
  }
  
  static Future<void> _syncCart() async {
    final localCart = await StorageService.getCart();
    if (localCart.isNotEmpty) {
      await ApiService.syncCart(localCart);
    }
  }
}
```

## Testing Strategy

### 1. Unit Tests for Services

```dart
// test/services/product_service_test.dart
void main() {
  group('ProductService', () {
    late ProductService productService;
    
    setUp(() {
      productService = ProductService();
    });
    
    test('should load products from API', () async {
      // Mock API response
      final products = await productService.getAllProducts();
      expect(products, isNotEmpty);
    });
  });
}
```

### 2. Integration Tests

```dart
// integration_test/app_test.dart
void main() {
  group('App Integration', () {
    testWidgets('should load products and display them', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Verify products are loaded
      expect(find.byType(ProductCard), findsWidgets);
    });
  });
}
```

## Performance Considerations

### 1. Implement Pagination

```dart
class ProductProvider with ChangeNotifier {
  int _currentPage = 1;
  bool _hasMoreData = true;
  
  Future<void> loadMoreProducts() async {
    if (!_hasMoreData || _isLoading) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final newProducts = await _productService.getProducts(
        page: _currentPage + 1,
      );
      
      if (newProducts.isEmpty) {
        _hasMoreData = false;
      } else {
        _products.addAll(newProducts);
        _currentPage++;
      }
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

### 2. Image Optimization

```dart
// Use CachedNetworkImage with proper error handling
CachedNetworkImage(
  imageUrl: product.imageUrl,
  placeholder: (context, url) => ShimmerWidget(),
  errorWidget: (context, url, error) => DefaultProductImage(),
  memCacheWidth: 300, // Optimize memory usage
  memCacheHeight: 300,
)
```

## Security Considerations

### 1. Token Management

```dart
class SecureStorage {
  static const _storage = FlutterSecureStorage();
  
  static Future<void> storeToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }
  
  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }
}
```

### 2. API Key Protection

```dart
// Never hardcode API keys in the app
// Use environment variables or secure configuration
class ApiConfig {
  static String get apiKey => const String.fromEnvironment('API_KEY');
}
```

## Monitoring and Analytics

### 1. Error Tracking

```dart
// lib/services/analytics_service.dart
class AnalyticsService {
  static void trackError(String error, StackTrace stackTrace) {
    // Send to your analytics service
    // Firebase Crashlytics, Sentry, etc.
  }
  
  static void trackUserAction(String action, Map<String, dynamic> properties) {
    // Track user interactions
  }
}
```

### 2. Performance Monitoring

The app already includes `PerformanceMonitor` utility. Use it to track:

```dart
// In your providers
await PerformanceMonitor().time('product_load', () async {
  return await _productService.getAllProducts();
});
```

## Deployment Checklist

### ✅ Before Going Live

1. **Environment Configuration**
   - [ ] Production API URLs configured
   - [ ] Environment variables set
   - [ ] API keys secured

2. **Performance**
   - [ ] Image optimization implemented
   - [ ] Caching strategies in place
   - [ ] Lazy loading for large lists

3. **Security**
   - [ ] Authentication flow tested
   - [ ] Token refresh mechanism
   - [ ] Secure storage implementation

4. **Error Handling**
   - [ ] Network error handling
   - [ ] Offline mode support
   - [ ] User-friendly error messages

5. **Testing**
   - [ ] Unit tests passing
   - [ ] Integration tests passing
   - [ ] Manual testing completed

## API Endpoints Expected

Your backend should provide these endpoints:

```
Authentication:
POST /api/auth/login/
POST /api/auth/register/
POST /api/auth/logout/
POST /api/auth/refresh/

Products:
GET /api/products/
GET /api/products/{id}/
GET /api/products/?category={id}
GET /api/products/?search={query}

Categories:
GET /api/categories/

Cart:
GET /api/cart/
POST /api/cart/add/
POST /api/cart/remove/
PUT /api/cart/update/

Wishlist:
GET /api/wishlist/
POST /api/wishlist/add/
DELETE /api/wishlist/remove/

Reviews:
GET /api/products/{id}/reviews/
POST /api/products/{id}/reviews/
```

## Next Steps

1. Set up your backend with the above endpoints
2. Update the API configuration
3. Test the integration in development
4. Implement authentication flow
5. Add error handling and offline support
6. Deploy to staging for testing
7. Deploy to production

The app architecture is already optimized for backend integration. Most changes will be in the service layer, keeping the UI and business logic unchanged. 