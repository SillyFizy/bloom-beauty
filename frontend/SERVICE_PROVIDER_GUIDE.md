# Service Provider Architecture Guide

## Overview

This guide explains the comprehensive service provider architecture implemented for the Bloom Beauty Flutter app. The architecture follows best practices for data management, state management, and backend integration readiness.

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   UI Components │    │    Providers    │    │    Services     │
│                 │    │                 │    │                 │
│ - Screens       │◄──►│ - ProductProvider│◄──►│ - ProductService│
│ - Widgets       │    │ - CelebrityProv. │    │ - CelebrityServ.│
│ - Dialogs       │    │ - ReviewProvider │    │ - ReviewService │
│                 │    │ - CartProvider   │    │ - API Service   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Core Principles

### 1. **Separation of Concerns**
- **Services**: Handle all data operations, API calls, and business logic
- **Providers**: Manage application state and notify UI of changes
- **Components**: Handle only UI logic and user interactions

### 2. **Abstraction Layer**
- Services provide a clean interface between components and data sources
- When integrating with a real backend, only services need to be modified
- UI components remain unchanged during backend integration

### 3. **Centralized Data Management**
- All data operations go through services
- No direct API calls from UI components
- Consistent error handling and caching strategies

## Service Layer

### ProductService
Handles all product-related data operations:

```dart
final productService = ProductService();

// Get all products with caching
final products = await productService.getAllProducts();

// Search products
final searchResults = await productService.searchProducts('serum');

// Filter products
final filteredProducts = await productService.filterProducts(
  categoryId: 'skincare',
  minPrice: 10.0,
  maxPrice: 100.0,
);
```

**Key Features:**
- Automatic caching with configurable expiry
- Comprehensive filtering and sorting
- Search functionality
- Product recommendations
- Statistics and analytics

### CelebrityService
Manages celebrity endorsements and social media data:

```dart
final celebrityService = CelebrityService();

// Get celebrity data
final celebrity = await celebrityService.getCelebrityByName('Emma Stone');

// Get celebrity's products
final products = await celebrityService.getAllCelebrityProducts('Emma Stone');

// Get social media links
final socialMedia = await celebrityService.getCelebritySocialMedia('Emma Stone');
```

**Key Features:**
- Celebrity profile management
- Product endorsements
- Social media integration
- Trending celebrities
- Data validation

### ReviewService
Handles product reviews and ratings:

```dart
final reviewService = ReviewService();

// Get product reviews
final reviews = await reviewService.getProductReviews(productId);

// Add a new review
final success = await reviewService.addReview(
  productId: productId,
  userId: userId,
  userName: 'John Doe',
  rating: 4.5,
  comment: 'Great product!',
);

// Get review statistics
final stats = await reviewService.getReviewStatistics(productId);
```

**Key Features:**
- CRUD operations for reviews
- Review validation
- Sorting and filtering
- Statistics and analytics
- Moderation features

## Provider Layer

### ProductProvider
Manages product state throughout the application:

```dart
// In your widget
class ProductListWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ProductConsumer(
      builder: (context, productProvider, child) {
        if (productProvider.isLoading) {
          return CircularProgressIndicator();
        }
        
        return ListView.builder(
          itemCount: productProvider.filteredProducts.length,
          itemBuilder: (context, index) {
            final product = productProvider.filteredProducts[index];
            return ProductCard(product: product);
          },
        );
      },
    );
  }
}
```

**State Management:**
- Loading states
- Error handling
- Search functionality
- Filtering and sorting
- Caching management

### Usage with Context Extensions

```dart
// Easy access to providers
final products = context.productProvider.products;
final isLoading = context.selectProduct((provider) => provider.isLoading);

// Perform actions
await context.productProvider.searchProducts('moisturizer');
await context.celebrityProvider.selectCelebrity('Rihanna');
```

## Setup and Integration

### 1. App Integration

```dart
// In your main.dart
void main() {
  runApp(
    AppProviders.create(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}

// In your first screen
class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    await AppProviders.initializeProviders(context);
  }
  
  @override
  Widget build(BuildContext context) {
    // Your UI here
  }
}
```

### 2. Using Providers in Widgets

#### Method 1: Consumer Widgets
```dart
ProductConsumer(
  builder: (context, productProvider, child) {
    return ListView.builder(
      itemCount: productProvider.products.length,
      itemBuilder: (context, index) {
        return ProductCard(product: productProvider.products[index]);
      },
    );
  },
)
```

#### Method 2: Context Extensions
```dart
class ProductListWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final products = context.watchProductProvider.products;
    final isLoading = context.selectProduct((provider) => provider.isLoading);
    
    if (isLoading) return CircularProgressIndicator();
    
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        return ProductCard(product: products[index]);
      },
    );
  }
}
```

#### Method 3: Selector for Performance
```dart
Selector<ProductProvider, List<Product>>(
  selector: (context, provider) => provider.filteredProducts,
  builder: (context, products, child) {
    return ProductGrid(products: products);
  },
)
```

## Backend Integration

When ready to integrate with a real backend, follow these steps:

### 1. Update API Service
```dart
// lib/services/api_service.dart
class ApiService {
  static const String baseUrl = 'https://your-api.com/api';
  
  Future<List<Product>> getProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/products'));
    // Handle response and return products
  }
  
  Future<Product> createProduct(Product product) async {
    final response = await http.post(
      Uri.parse('$baseUrl/products'),
      body: jsonEncode(product.toJson()),
    );
    // Handle response
  }
}
```

### 2. Update Service Implementations
```dart
// In ProductService
Future<List<Product>> getAllProducts({bool forceRefresh = false}) async {
  if (_shouldRefreshCache() || forceRefresh) {
    // Change this line from:
    // _cachedProducts = _dataService.getAllProducts();
    // To:
    _cachedProducts = await _apiService.getProducts();
    _lastCacheUpdate = DateTime.now();
  }
  return _cachedProducts ?? [];
}
```

### 3. UI Components Remain Unchanged
The UI components don't need any changes because they're already using the service layer through providers.

## Best Practices

### 1. Error Handling
```dart
// In providers
try {
  _setLoading(true);
  final data = await _service.getData();
  _data = data;
  _setLoading(false);
} catch (e) {
  _setError('Failed to load data: $e');
  _setLoading(false);
}
```

### 2. Loading States
```dart
// Always show loading states
if (provider.isLoading) {
  return LoadingWidget();
}

if (provider.hasError) {
  return ErrorWidget(
    message: provider.error,
    onRetry: () => provider.refresh(),
  );
}
```

### 3. Optimized Rebuilds
```dart
// Use Selector for specific properties
Selector<ProductProvider, bool>(
  selector: (context, provider) => provider.isLoading,
  builder: (context, isLoading, child) {
    // Only rebuilds when isLoading changes
    return isLoading ? LoadingSpinner() : ProductList();
  },
)
```

### 4. Cache Management
```dart
// Clear caches when appropriate
void onLogout() {
  AppProviders.clearAllCaches(context);
}

// Refresh data when needed
void onRefresh() {
  AppProviders.refreshAllProviders(context);
}
```

## Testing

### Service Testing
```dart
void main() {
  group('ProductService', () {
    late ProductService productService;
    
    setUp(() {
      productService = ProductService();
    });
    
    test('should return products', () async {
      final products = await productService.getAllProducts();
      expect(products, isNotEmpty);
    });
  });
}
```

### Provider Testing
```dart
void main() {
  group('ProductProvider', () {
    late ProductProvider productProvider;
    
    setUp(() {
      productProvider = ProductProvider();
    });
    
    test('should load products', () async {
      await productProvider.loadAllProducts();
      expect(productProvider.products, isNotEmpty);
      expect(productProvider.isLoading, false);
    });
  });
}
```

## Common Patterns

### 1. Data Refresh Pattern
```dart
// Pull to refresh
RefreshIndicator(
  onRefresh: () => context.productProvider.refresh(),
  child: ProductList(),
)
```

### 2. Search Pattern
```dart
// Search functionality
TextField(
  onChanged: (query) => context.productProvider.searchProducts(query),
  decoration: InputDecoration(hintText: 'Search products...'),
)
```

### 3. Filter Pattern
```dart
// Filter products
FilterBottomSheet(
  onApplyFilters: (filters) {
    context.productProvider.filterProducts(
      categoryId: filters.categoryId,
      minPrice: filters.minPrice,
      maxPrice: filters.maxPrice,
    );
  },
)
```

## Migration Guide

To migrate existing code to use this architecture:

### 1. Identify Data Operations
- Find all places where data is fetched or manipulated
- Replace direct API calls with service calls
- Move business logic to services

### 2. Update State Management
- Replace StatefulWidget state with Provider state where appropriate
- Use Consumer widgets or context extensions
- Remove manual state synchronization

### 3. Clean Up Components
- Remove business logic from UI components
- Keep only UI-related code in widgets
- Use providers for all data access

### 4. Test Thoroughly
- Test all data flows
- Verify error handling
- Check loading states
- Ensure proper cache behavior

## Performance Considerations

### 1. Lazy Loading
- Use lazy providers for non-critical data
- Initialize only when needed
- Implement pagination for large datasets

### 2. Selective Updates
- Use Selector widgets for specific properties
- Minimize unnecessary rebuilds
- Cache computed values

### 3. Memory Management
- Clear caches when appropriate
- Dispose providers properly
- Monitor memory usage

This architecture provides a solid foundation for your Flutter app that's ready for backend integration and scales well as your app grows. 