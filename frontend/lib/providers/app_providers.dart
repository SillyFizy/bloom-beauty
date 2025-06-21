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
import 'wishlist_provider.dart';
import 'auth_provider.dart';
import 'recently_viewed_provider.dart';
import '../models/product_model.dart';
import '../services/essential_data_service.dart';

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

        /// Wishlist Provider - Manages wishlist state
        ChangeNotifierProvider<WishlistProvider>(
          create: (_) {
            final wishlistProvider = WishlistProvider();
            // Load wishlist from storage when app starts
            wishlistProvider.loadWishlistFromStorage();
            return wishlistProvider;
          },
          lazy: false, // Initialize immediately for wishlist functionality
        ),

        /// Auth Provider - Manages authentication state
        ChangeNotifierProvider<AuthProvider>(
          create: (_) {
            final authProvider = AuthProvider();
            // Don't initialize auth state automatically to prevent setState during build
            return authProvider;
          },
          lazy: false, // Initialize immediately for auth functionality
        ),

        /// Recently Viewed Provider - Manages recently viewed products
        ChangeNotifierProvider<RecentlyViewedProvider>(
          create: (_) {
            final recentlyViewedProvider = RecentlyViewedProvider();
            // Load recently viewed from storage when app starts
            recentlyViewedProvider.initialize();
            return recentlyViewedProvider;
          },
          lazy: false, // Initialize immediately for recently viewed functionality
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
        _initializeWishlistProvider(context),
        _initializeRecentlyViewedProvider(context),
        _initializeAuthProvider(context),
        // Note: ReviewProvider is lazy-loaded when needed
      ]);
    } catch (e) {
      debugPrint('Error initializing providers: $e');
    }
  }

  /// Initialize only essential providers for fast app startup
  /// This is called for immediate app functionality
  static Future<void> initializeEssentialProviders(BuildContext context) async {
    try {
      debugPrint('AppProviders: Initializing essential providers only');
      
      // Initialize only essential providers that don't require network calls
      await Future.wait([
        _initializeCartProvider(context),
        _initializeWishlistProvider(context),
        _initializeRecentlyViewedProvider(context),
        _initializeAuthProvider(context), // Initialize auth provider to check login state
      ]);
      
      // Load essential data in background without blocking
      _loadEssentialDataInBackground(context);
      
      debugPrint('AppProviders: Essential providers initialized successfully');
    } catch (e) {
      debugPrint('Error initializing essential providers: $e');
    }
  }

  /// Load essential data in background without blocking the UI
  static void _loadEssentialDataInBackground(BuildContext context) {
    // Use a timer to avoid context issues
    Future.delayed(Duration.zero, () async {
      try {
        final data = await EssentialDataService.loadAllEssentialData();
        if (EssentialDataService.isEssentialDataValid(data)) {
          debugPrint('AppProviders: Essential data loaded successfully in background');
          // Optionally notify providers of the loaded data
          _notifyProvidersOfEssentialData(data);
        } else {
          debugPrint('AppProviders: Essential data loading failed or incomplete');
        }
      } catch (error) {
        debugPrint('AppProviders: Error loading essential data in background: $error');
      }
    });
  }

  /// Notify providers of loaded essential data
  static void _notifyProvidersOfEssentialData(Map<String, dynamic> data) {
    try {
      // This is optional - providers can use this data if available
      // but they should not depend on it for basic functionality
      debugPrint('AppProviders: Notifying providers of essential data');
    } catch (e) {
      debugPrint('AppProviders: Error notifying providers of essential data: $e');
    }
  }

  /// Initialize data providers lazily when needed
  /// This is called when the user navigates to screens that need the data
  static Future<void> initializeDataProviders(BuildContext context) async {
    try {
      debugPrint('AppProviders: Initializing data providers');
      
      // Initialize data providers that require network calls
      await Future.wait([
        _initializeProductProvider(context),
        _initializeCategoryProvider(context),
        _initializeCelebrityProvider(context),
        _initializeSearchProvider(context),
      ]);
      
      debugPrint('AppProviders: Data providers initialized successfully');
    } catch (e) {
      debugPrint('Error initializing data providers: $e');
    }
  }

  /// Initialize a specific provider when needed
  static Future<void> initializeProviderIfNeeded<T extends ChangeNotifier>(
    BuildContext context,
    Future<void> Function(BuildContext) initFunction,
  ) async {
    try {
      await initFunction(context);
    } catch (e) {
      debugPrint('Error initializing provider: $e');
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

  /// Initialize Wishlist Provider
  static Future<void> _initializeWishlistProvider(BuildContext context) async {
    final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);
    await wishlistProvider.loadWishlistFromStorage();
  }

  /// Initialize Auth Provider
  static Future<void> _initializeAuthProvider(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.initialize();
  }

  /// Initialize Recently Viewed Provider
  static Future<void> _initializeRecentlyViewedProvider(BuildContext context) async {
    final recentlyViewedProvider = Provider.of<RecentlyViewedProvider>(context, listen: false);
    await recentlyViewedProvider.initialize();
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
        Provider.of<WishlistProvider>(context, listen: false).refresh(),
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
    // Cart and wishlist cache clearing would affect user data, so we don't include them here
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

  static WishlistProvider getWishlistProvider(BuildContext context) =>
      Provider.of<WishlistProvider>(context, listen: false);
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

  /// Wishlist Provider getter
  WishlistProvider get wishlistProvider => read<WishlistProvider>();
  WishlistProvider get watchWishlistProvider => watch<WishlistProvider>();

  /// Auth Provider getter
  AuthProvider get authProvider => read<AuthProvider>();
  AuthProvider get watchAuthProvider => watch<AuthProvider>();

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

  T selectWishlist<T>(T Function(WishlistProvider provider) selector) =>
      select<WishlistProvider, T>(selector);
  
  /// Optimized selectors for specific commonly used values
  bool get isCartEmpty => selectCart((cart) => cart.isEmpty);
  int get cartItemCount => selectCart((cart) => cart.itemCount);
  double get cartTotal => selectCart((cart) => cart.totalPrice);
  
  bool get isWishlistEmpty => selectWishlist((wishlist) => wishlist.isEmpty);
  int get wishlistItemCount => selectWishlist((wishlist) => wishlist.itemCount);
  
  bool get isProductsLoading => selectProduct((provider) => provider.isLoading);
  bool get isCelebritiesLoading => selectCelebrity((provider) => provider.isLoading);
  
  /// Check if a specific product is in wishlist (optimized)
  bool isProductInWishlist(String productId) =>
      selectWishlist((wishlist) => wishlist.isInWishlist(productId));
      
  /// Check if a specific product is in cart (optimized)
  bool isProductInCart(String productId) =>
      selectCart((cart) => cart.isInCart(productId));
      
  /// Get cart quantity for a specific product (optimized)
  int getCartQuantity(String productId) =>
      selectCart((cart) => cart.getProductQuantity(productId));
      
  /// Auth status selectors (optimized)
  bool get isAuthenticated => select<AuthProvider, bool>((auth) => auth.isAuthenticated);
  bool get isAuthLoading => select<AuthProvider, bool>((auth) => auth.isLoading);
  String? get currentUserName => select<AuthProvider, String?>((auth) => auth.firstName);
  String? get currentUserPhone => select<AuthProvider, String?>((auth) => auth.phoneNumber);
}

/// Consumer widgets for common provider access patterns
class ProductConsumer extends StatelessWidget {
  final Widget Function(BuildContext context, ProductProvider provider, Widget? child) builder;
  final Widget? child;

  const ProductConsumer({
    super.key,
    required this.builder,
    this.child,
  });

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
    super.key,
    required this.builder,
    this.child,
  });

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
    super.key,
    required this.builder,
    this.child,
  });

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
    super.key,
    required this.builder,
    this.child,
  });

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
    super.key,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: builder,
      child: child,
    );
  }
}

class WishlistConsumer extends StatelessWidget {
  final Widget Function(BuildContext context, WishlistProvider provider, Widget? child) builder;
  final Widget? child;

  const WishlistConsumer({
    super.key,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<WishlistProvider>(
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
    WishlistProvider wishlistProvider,
    Widget? child,
  ) builder;
  final Widget? child;

  const MultiProviderConsumer({
    super.key,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer5<ProductProvider, CategoryProvider, CelebrityProvider, CartProvider, WishlistProvider>(
      builder: (context, productProvider, categoryProvider, celebrityProvider, cartProvider, wishlistProvider, child) {
        return builder(context, productProvider, categoryProvider, celebrityProvider, cartProvider, wishlistProvider, child);
      },
      child: child,
    );
  }
}

/// Optimized Selector widgets for performance
/// These prevent unnecessary rebuilds by only listening to specific properties

/// Selector for cart item count (commonly used in badges)
class CartItemCountSelector extends StatelessWidget {
  final Widget Function(BuildContext context, int itemCount, Widget? child) builder;
  final Widget? child;

  const CartItemCountSelector({
    super.key,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<CartProvider, int>(
      selector: (context, cart) => cart.itemCount,
      builder: builder,
      child: child,
    );
  }
}

/// Selector for wishlist item count
class WishlistItemCountSelector extends StatelessWidget {
  final Widget Function(BuildContext context, int itemCount, Widget? child) builder;
  final Widget? child;

  const WishlistItemCountSelector({
    super.key,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<WishlistProvider, int>(
      selector: (context, wishlist) => wishlist.itemCount,
      builder: builder,
      child: child,
    );
  }
}

/// Selector for loading states
class LoadingStateSelector<T extends ChangeNotifier> extends StatelessWidget {
  final Widget Function(BuildContext context, bool isLoading, Widget? child) builder;
  final bool Function(T provider) selector;
  final Widget? child;

  const LoadingStateSelector({
    super.key,
    required this.builder,
    required this.selector,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<T, bool>(
      selector: (context, provider) => selector(provider),
      builder: builder,
      child: child,
    );
  }
}

/// Selector for specific product in wishlist status
class ProductWishlistSelector extends StatelessWidget {
  final String productId;
  final Widget Function(BuildContext context, bool isInWishlist, Widget? child) builder;
  final Widget? child;

  const ProductWishlistSelector({
    super.key,
    required this.productId,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<WishlistProvider, bool>(
      selector: (context, wishlist) => wishlist.isInWishlist(productId),
      builder: builder,
      child: child,
    );
  }
}

/// Selector for specific product in cart status
class ProductCartSelector extends StatelessWidget {
  final String productId;
  final Widget Function(BuildContext context, bool isInCart, Widget? child) builder;
  final Widget? child;

  const ProductCartSelector({
    super.key,
    required this.productId,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<CartProvider, bool>(
      selector: (context, cart) => cart.isInCart(productId),
      builder: builder,
      child: child,
    );
  }
}

/// Selector for cart total price
class CartTotalSelector extends StatelessWidget {
  final Widget Function(BuildContext context, double total, Widget? child) builder;
  final Widget? child;

  const CartTotalSelector({
    super.key,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<CartProvider, double>(
      selector: (context, cart) => cart.totalPrice,
      builder: builder,
      child: child,
    );
  }
}

/// Optimized selector for product lists that only rebuilds when list content changes
class ProductListSelector extends StatelessWidget {
  final Widget Function(BuildContext context, List<Product> products, Widget? child) builder;
  final List<Product> Function(ProductProvider provider) selector;
  final Widget? child;

  const ProductListSelector({
    super.key,
    required this.builder,
    required this.selector,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<ProductProvider, List<Product>>(
      selector: (context, provider) => selector(provider),
      shouldRebuild: (previous, next) {
        // Only rebuild if the list length changed or individual products changed
        if (previous.length != next.length) return true;
        for (int i = 0; i < previous.length; i++) {
          if (previous[i].id != next[i].id) return true;
        }
        return false;
      },
      builder: builder,
      child: child,
    );
  }
} 
