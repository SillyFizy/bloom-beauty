import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wishlist_provider.dart';
import '../models/product_model.dart';

/// Utility class for managing wishlist state consistently across the app
class WishlistUtils {
  /// Normalize product data to ensure consistency across all screens
  static Product normalizeProduct(Product product) {
    debugPrint(
        '🔧 WishlistUtils: Normalizing product data for ${product.name}');
    debugPrint('   🆔 Original ID: ${product.id}');
    debugPrint('   📦 Original Name: ${product.name}');
    debugPrint('   🏷️ Original Brand: ${product.brand}');
    debugPrint('   🔗 Original Category: ${product.categoryId}');

    // Ensure the product has consistent formatting
    return Product(
      id: product.id, // Keep ID as-is (should be numeric string)
      name: product.name,
      description: product.description,
      price: product.price,
      discountPrice: product.discountPrice,
      images: product.images,
      categoryId: product.categoryId,
      brand: product.brand,
      rating: product.rating,
      reviewCount: product.reviewCount,
      isInStock: product.isInStock,
      ingredients: product.ingredients,
      beautyPoints: product.beautyPoints,
      variants: product.variants,
      reviews: product.reviews,
      celebrityEndorsement: product.celebrityEndorsement,
    );
  }

  /// Safely toggle a product in the wishlist with proper error handling
  static Future<bool> safeToggleWishlist(
    BuildContext context,
    Product product, {
    bool showSnackBar = true,
  }) async {
    try {
      debugPrint(
          '🔄 WishlistUtils: Starting safe toggle for product ${product.name} (ID: ${product.id})');

      // Normalize the product to ensure consistency
      final normalizedProduct = normalizeProduct(product);

      final wishlistProvider = context.read<WishlistProvider>();

      // Ensure provider is initialized
      if (!wishlistProvider.isInitialized) {
        debugPrint(
            '🔧 WishlistUtils: Provider not initialized, loading from storage...');
        await wishlistProvider.loadWishlistFromStorage();
      }

      final wasInWishlist = wishlistProvider.isInWishlist(normalizedProduct.id);
      debugPrint(
          '📊 WishlistUtils: Product was ${wasInWishlist ? 'IN' : 'NOT IN'} wishlist before toggle');

      final success = await wishlistProvider.toggleWishlist(normalizedProduct);
      debugPrint(
          '✅ WishlistUtils: Toggle operation ${success ? 'SUCCEEDED' : 'FAILED'}');

      if (success && context.mounted) {
        final isNowInWishlist = !wasInWishlist;
        debugPrint(
            '🔄 WishlistUtils: Product is now ${isNowInWishlist ? 'IN' : 'NOT IN'} wishlist');

        if (showSnackBar) {
          _showWishlistSnackBar(context, normalizedProduct, isNowInWishlist);
        }

        // Force a manual refresh to ensure all UI components sync
        Future.delayed(const Duration(milliseconds: 50), () {
          if (context.mounted) {
            wishlistProvider.forceRefreshButtonStates();
          }
        });
      }

      return success;
    } catch (e) {
      debugPrint('❌ WishlistUtils: Error toggling wishlist: $e');
      if (showSnackBar && context.mounted) {
        _showErrorSnackBar(context, 'Failed to update wishlist');
      }
      return false;
    }
  }

  /// Check if a product is in the wishlist with proper initialization
  static bool isProductInWishlist(BuildContext context, String productId) {
    try {
      final wishlistProvider = context.read<WishlistProvider>();

      // If not initialized, return false and trigger initialization
      if (!wishlistProvider.isInitialized) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          wishlistProvider.loadWishlistFromStorage();
        });
        return false;
      }

      return wishlistProvider.isInWishlist(productId);
    } catch (e) {
      debugPrint('Error checking wishlist status: $e');
      return false;
    }
  }

  /// Force refresh all wishlist button states across the app
  static void forceRefreshWishlistStates(BuildContext context) {
    try {
      final wishlistProvider = context.read<WishlistProvider>();
      wishlistProvider.forceRefreshButtonStates();
    } catch (e) {
      debugPrint('Error refreshing wishlist states: $e');
    }
  }

  /// Initialize wishlist provider if not already initialized
  static Future<void> ensureWishlistInitialized(BuildContext context) async {
    try {
      final wishlistProvider = context.read<WishlistProvider>();
      if (!wishlistProvider.isInitialized) {
        await wishlistProvider.loadWishlistFromStorage();
      }
    } catch (e) {
      debugPrint('Error initializing wishlist: $e');
    }
  }

  /// Get wishlist count safely
  static int getWishlistCount(BuildContext context) {
    try {
      final wishlistProvider = context.read<WishlistProvider>();
      return wishlistProvider.itemCount;
    } catch (e) {
      debugPrint('Error getting wishlist count: $e');
      return 0;
    }
  }

  /// Show wishlist feedback snackbar
  static void _showWishlistSnackBar(
    BuildContext context,
    Product product,
    bool isAdded,
  ) {
    final message = isAdded
        ? 'Added "${product.name}" to wishlist'
        : 'Removed "${product.name}" from wishlist';

    final icon = isAdded ? Icons.favorite : Icons.favorite_border;
    final color = isAdded
        ? const Color(0xFFE91E63) // Pink color for added
        : const Color(0xFF757575); // Gray color for removed

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  /// Show error snackbar
  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFD32F2F), // Red color for errors
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}

/// Mixin for screens that need wishlist functionality
mixin WishlistScreenMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    _initializeWishlist();
  }

  void _initializeWishlist() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WishlistUtils.ensureWishlistInitialized(context);
    });
  }

  /// Toggle wishlist for a product
  Future<bool> toggleWishlist(Product product) async {
    return await WishlistUtils.safeToggleWishlist(context, product);
  }

  /// Check if product is in wishlist
  bool isInWishlist(String productId) {
    return WishlistUtils.isProductInWishlist(context, productId);
  }

  /// Force refresh wishlist states
  void refreshWishlistStates() {
    WishlistUtils.forceRefreshWishlistStates(context);
  }
}
