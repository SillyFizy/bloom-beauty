import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'product_provider.dart';
import 'celebrity_provider.dart';
import 'celebrity_picks_provider.dart';
import 'search_provider.dart';
import 'review_provider.dart';
import 'cart_provider.dart';
import 'app_state_provider.dart';
import 'category_provider.dart';

/// Centralized provider setup for the entire application
/// This file manages all providers using MultiProvider pattern
class AppProviders {
  /// Create all providers for the application
  /// Uses MultiProvider to organize multiple providers cleanly
  static Widget create({required Widget child}) {
    return MultiProvider(
      providers: [
        /// App State Provider - Manages global app state
        ChangeNotifierProvider<AppStateProvider>(
          create: (_) => AppStateProvider(),
          lazy: false, // Initialize immediately for global state
        ),

        /// Product Provider - Manages product data and state
        ChangeNotifierProvider<ProductProvider>(
          create: (_) => ProductProvider(),
          lazy: false, // Initialize immediately for critical data
        ),

        /// Category Provider - Manages category filtering and sorting
        ChangeNotifierProvider<CategoryProvider>(
          create: (_) => CategoryProvider(),
          lazy: false, // Initialize immediately for categories screen
        ),

        /// Celebrity Provider - Manages celebrity data and endorsements
        ChangeNotifierProvider<CelebrityProvider>(
          create: (_) => CelebrityProvider(),
          lazy: false, // Initialize immediately for home screen
        ),

        /// Celebrity Picks Provider - Manages celebrity picks screen functionality
        ChangeNotifierProvider<CelebrityPicksProvider>(
          create: (_) => CelebrityPicksProvider(),
          lazy: true, // Load only when celebrity picks screen is opened
        ),

        /// Search Provider - Manages search functionality
        ChangeNotifierProvider<SearchProvider>(
          create: (_) => SearchProvider(),
          lazy: false, // Initialize immediately for search functionality
        ),

        /// Review Provider - Manages product reviews and ratings
        ChangeNotifierProvider<ReviewProvider>(
          create: (_) => ReviewProvider(),
          lazy: true, // Load only when needed
        ),

        /// Cart Provider - Manages shopping cart state
        ChangeNotifierProvider<CartProvider>(
          create: (_) {
            final cartProvider = CartProvider();
            // Load cart from storage when app starts
            cartProvider.loadCartFromStorage();
            return cartProvider;
          },
          lazy: false, // Initialize immediately for cart functionality
        ),
      ],
      child: child,
    );
  }

  /// Initialize all providers with their initial data
  /// Call this after the providers are created in the widget tree
  static Future<void> initializeProviders(BuildContext context) async {
    try {
      // Initialize providers in parallel for better performance
      await Future.wait([
        _initializeProductProvider(context),
        _initializeCategoryProvider(context),
        _initializeCelebrityProvider(context),
        _initializeSearchProvider(context),
        _initializeCartProvider(context),
        // Note: ReviewProvider is lazy-loaded when needed
      ]);
    } catch (e) {
      debugPrint('Error initializing providers: $e');
    }
  }

  /// Initialize Product Provider
  static Future<void> _initializeProductProvider(BuildContext context) async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    await productProvider.initialize();
  }

  /// Initialize Category Provider
  static Future<void> _initializeCategoryProvider(BuildContext context) async {
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    await categoryProvider.initialize();
  }

  /// Initialize Celebrity Provider
  static Future<void> _initializeCelebrityProvider(BuildContext context) async {
    final celebrityProvider = Provider.of<CelebrityProvider>(context, listen: false);
    await celebrityProvider.initialize();
  }

  /// Initialize Search Provider
  static Future<void> _initializeSearchProvider(BuildContext context) async {
    final searchProvider = Provider.of<SearchProvider>(context, listen: false);
    await searchProvider.initialize();
  }

  /// Initialize Cart Provider
  static Future<void> _initializeCartProvider(BuildContext context) async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    await cartProvider.loadCartFromStorage();
  }

  /// Initialize Review Provider (called when needed)
  static Future<void> initializeReviewProvider(BuildContext context) async {
    final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
    await reviewProvider.initialize();
  }

  /// Refresh all providers' data
  static Future<void> refreshAllProviders(BuildContext context) async {
    try {
      await Future.wait([
        Provider.of<ProductProvider>(context, listen: false).refresh(),
        Provider.of<CategoryProvider>(context, listen: false).refresh(),
        Provider.of<CelebrityProvider>(context, listen: false).refresh(),
        Provider.of<SearchProvider>(context, listen: false).refresh(),
        Provider.of<ReviewProvider>(context, listen: false).refresh(),
        // Cart doesn't need refresh as it's local storage based
      ]);
    } catch (e) {
      debugPrint('Error refreshing providers: $e');
    }
  }

  /// Clear all cached data in providers
  static void clearAllCaches(BuildContext context) {
    Provider.of<ProductProvider>(context, listen: false).clearCache();
    Provider.of<CategoryProvider>(context, listen: false).clearFilters();
    Provider.of<CelebrityProvider>(context, listen: false).clearCache();
    Provider.of<SearchProvider>(context, listen: false).clearSearch();
    Provider.of<ReviewProvider>(context, listen: false).clearCache();
    // Cart cache clearing would log out user, so we don't include it here
  }

  /// Check if all critical providers are initialized
  static bool areProvidersInitialized(BuildContext context) {
    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      final celebrityProvider = Provider.of<CelebrityProvider>(context, listen: false);
      
      return productProvider.products.isNotEmpty &&
             categoryProvider.categories.isNotEmpty &&
             celebrityProvider.celebrities.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get provider instances for direct access (use sparingly)
  static ProductProvider getProductProvider(BuildContext context) =>
      Provider.of<ProductProvider>(context, listen: false);

  static CategoryProvider getCategoryProvider(BuildContext context) =>
      Provider.of<CategoryProvider>(context, listen: false);

  static CelebrityProvider getCelebrityProvider(BuildContext context) =>
      Provider.of<CelebrityProvider>(context, listen: false);

  static CelebrityPicksProvider getCelebrityPicksProvider(BuildContext context) =>
      Provider.of<CelebrityPicksProvider>(context, listen: false);

  static SearchProvider getSearchProvider(BuildContext context) =>
      Provider.of<SearchProvider>(context, listen: false);

  static ReviewProvider getReviewProvider(BuildContext context) =>
      Provider.of<ReviewProvider>(context, listen: false);

  static CartProvider getCartProvider(BuildContext context) =>
      Provider.of<CartProvider>(context, listen: false);
}

/// Extension on BuildContext for easy provider access
/// Provides convenience methods for accessing providers
extension ProviderExtension on BuildContext {
  /// Product Provider getter
  ProductProvider get productProvider => read<ProductProvider>();
  ProductProvider get watchProductProvider => watch<ProductProvider>();

  /// Category Provider getter
  CategoryProvider get categoryProvider => read<CategoryProvider>();
  CategoryProvider get watchCategoryProvider => watch<CategoryProvider>();

  /// Celebrity Provider getter
  CelebrityProvider get celebrityProvider => read<CelebrityProvider>();
  CelebrityProvider get watchCelebrityProvider => watch<CelebrityProvider>();

  /// Celebrity Picks Provider getter
  CelebrityPicksProvider get celebrityPicksProvider => read<CelebrityPicksProvider>();
  CelebrityPicksProvider get watchCelebrityPicksProvider => watch<CelebrityPicksProvider>();

  /// Search Provider getter
  SearchProvider get searchProvider => read<SearchProvider>();
  SearchProvider get watchSearchProvider => watch<SearchProvider>();

  /// Review Provider getter
  ReviewProvider get reviewProvider => read<ReviewProvider>();
  ReviewProvider get watchReviewProvider => watch<ReviewProvider>();

  /// Cart Provider getter
  CartProvider get cartProvider => read<CartProvider>();
  CartProvider get watchCartProvider => watch<CartProvider>();

  /// Select specific values for optimized rebuilds
  T selectProduct<T>(T Function(ProductProvider provider) selector) =>
      select<ProductProvider, T>(selector);

  T selectCategory<T>(T Function(CategoryProvider provider) selector) =>
      select<CategoryProvider, T>(selector);

  T selectCelebrity<T>(T Function(CelebrityProvider provider) selector) =>
      select<CelebrityProvider, T>(selector);

  T selectCelebrityPicks<T>(T Function(CelebrityPicksProvider provider) selector) =>
      select<CelebrityPicksProvider, T>(selector);

  T selectReview<T>(T Function(ReviewProvider provider) selector) =>
      select<ReviewProvider, T>(selector);

  T selectCart<T>(T Function(CartProvider provider) selector) =>
      select<CartProvider, T>(selector);
}

/// Consumer widgets for common provider access patterns
class ProductConsumer extends StatelessWidget {
  final Widget Function(BuildContext context, ProductProvider provider, Widget? child) builder;
  final Widget? child;

  const ProductConsumer({
    Key? key,
    required this.builder,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: builder,
      child: child,
    );
  }
}

class CelebrityConsumer extends StatelessWidget {
  final Widget Function(BuildContext context, CelebrityProvider provider, Widget? child) builder;
  final Widget? child;

  const CelebrityConsumer({
    Key? key,
    required this.builder,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<CelebrityProvider>(
      builder: builder,
      child: child,
    );
  }
}

class CelebrityPicksConsumer extends StatelessWidget {
  final Widget Function(BuildContext context, CelebrityPicksProvider provider, Widget? child) builder;
  final Widget? child;

  const CelebrityPicksConsumer({
    Key? key,
    required this.builder,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<CelebrityPicksProvider>(
      builder: builder,
      child: child,
    );
  }
}

class ReviewConsumer extends StatelessWidget {
  final Widget Function(BuildContext context, ReviewProvider provider, Widget? child) builder;
  final Widget? child;

  const ReviewConsumer({
    Key? key,
    required this.builder,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ReviewProvider>(
      builder: builder,
      child: child,
    );
  }
}

class CartConsumer extends StatelessWidget {
  final Widget Function(BuildContext context, CartProvider provider, Widget? child) builder;
  final Widget? child;

  const CartConsumer({
    Key? key,
    required this.builder,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: builder,
      child: child,
    );
  }
}

/// Multi-consumer for accessing multiple providers
class MultiProviderConsumer extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    ProductProvider productProvider,
    CategoryProvider categoryProvider,
    CelebrityProvider celebrityProvider,
    CartProvider cartProvider,
    Widget? child,
  ) builder;
  final Widget? child;

  const MultiProviderConsumer({
    Key? key,
    required this.builder,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer4<ProductProvider, CategoryProvider, CelebrityProvider, CartProvider>(
      builder: (context, productProvider, categoryProvider, celebrityProvider, cartProvider, child) {
        return builder(context, productProvider, categoryProvider, celebrityProvider, cartProvider, child);
      },
      child: child,
    );
  }
} 