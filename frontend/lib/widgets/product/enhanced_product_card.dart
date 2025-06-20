import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../models/product_model.dart';
import '../../utils/formatters.dart';
import '../../utils/wishlist_utils.dart';
import '../../screens/celebrity/celebrity_screen.dart';
import '../../providers/celebrity_provider.dart';
import '../common/wishlist_button.dart';

class EnhancedProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;
  final bool isSmallScreen;

  // Prevent rapid navigation attempts
  static bool _isNavigating = false;

  const EnhancedProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onFavorite,
    this.isSmallScreen = false,
  });

  void _navigateToCelebrityProfile(BuildContext context) async {
    if (product.celebrityEndorsement == null || _isNavigating) return;

    _isNavigating = true;
    try {
      // Use the provider to select celebrity and navigate
      final celebrityProvider = context.read<CelebrityProvider>();

      // Use provider's loading state instead of dialog to prevent Navigator conflicts
      await celebrityProvider
          .selectCelebrity(product.celebrityEndorsement!.celebrityName);

      // Check context is still valid before navigation
      if (!context.mounted) return;

      // Navigate to celebrity screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CelebrityScreen(),
        ),
      );
    } catch (e) {
      debugPrint('Error navigating to celebrity profile: $e');

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load celebrity profile: $e'),
            backgroundColor: AppConstants.errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      _isNavigating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDiscount =
        product.discountPrice != null && product.discountPrice! < product.price;
    final currentPrice = product.getCurrentPrice();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine card dimensions based on available space
        final cardWidth = constraints.maxWidth;
        final isMobile = cardWidth < 200;
        final isTablet = cardWidth >= 200 && cardWidth < 300;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor,
              borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
              border: Border.all(
                color: AppConstants.borderColor.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppConstants.textSecondary.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image Section - Adjusted for bigger details
                Expanded(
                  flex:
                      isMobile ? 6 : 5, // Reduced to give more space to details
                  child: _buildImageSection(
                      hasDiscount, isMobile, isTablet, context),
                ),

                // Product Details Section - More space for bigger layout
                Expanded(
                  flex:
                      isMobile ? 6 : 6, // Increased for bigger text and spacing
                  child: _buildDetailsSection(
                      currentPrice, hasDiscount, isMobile, isTablet, context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageSection(
      bool hasDiscount, bool isMobile, bool isTablet, BuildContext context) {
    return Stack(
      children: [
        // Main image container
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(isMobile ? 12 : 16),
            ),
            color: AppConstants.backgroundColor,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(isMobile ? 12 : 16),
            ),
            child: product.images.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: product.images.first,
                    fit: BoxFit.cover,
                    memCacheWidth: isMobile
                        ? 400
                        : (isTablet ? 500 : 600), // Increased cache sizes
                    memCacheHeight: isMobile ? 400 : (isTablet ? 500 : 600),
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        color: Colors.white,
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        _buildImagePlaceholder(isMobile),
                  )
                : _buildImagePlaceholder(isMobile),
          ),
        ),

        // Wishlist button
        Positioned(
          top: isMobile ? 6 : 8,
          left: isMobile ? 6 : 8,
          child: WishlistButton(
            product: product,
            size: isMobile ? 16 : 18,
            onPressed: onFavorite,
            heroTag: 'enhanced_card_wishlist_${product.id}',
          ),
        ),

        // Discount badge - Moved to top-right to avoid overlap with wishlist
        if (hasDiscount)
          Positioned(
            top: isMobile ? 6 : 8,
            right: isMobile ? 6 : 8,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 6 : 8,
                vertical: isMobile ? 2 : 3,
              ),
              decoration: BoxDecoration(
                color: AppConstants.errorColor,
                borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.errorColor.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '${(((product.price - product.discountPrice!) / product.price) * 100).round()}% OFF',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 8 : 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),

        // Beauty Points Badge - Moved to bottom-right corner of image
        // Always show beauty points, even if 0
        Positioned(
          bottom: isMobile ? 6 : 8,
          right: isMobile ? 6 : 8,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 6 : 8, // Increased padding
              vertical: isMobile ? 3 : 4, // Increased padding
            ),
            decoration: BoxDecoration(
              color: AppConstants.favoriteColor,
              borderRadius: BorderRadius.circular(
                  isMobile ? 10 : 12), // Increased border radius
              boxShadow: [
                BoxShadow(
                  color: AppConstants.favoriteColor.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.stars_rounded,
                  size: isMobile ? 12 : 14, // Increased icon size
                  color: Colors.white,
                ),
                SizedBox(width: isMobile ? 2 : 3),
                Text(
                  '+${product.beautyPoints}',
                  style: TextStyle(
                    fontSize: isMobile ? 10 : 12, // Increased font size
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Out of stock overlay
        if (!product.isInStock)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(isMobile ? 12 : 16),
                ),
              ),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                    vertical: isMobile ? 6 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                  ),
                  child: Text(
                    'Out of Stock',
                    style: TextStyle(
                      color: AppConstants.errorColor,
                      fontSize: isMobile ? 12 : 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImagePlaceholder(bool isMobile) {
    return Container(
      color: AppConstants.backgroundColor,
      child: Center(
        child: Icon(
          Icons.spa_outlined,
          size: isMobile ? 32 : 40,
          color: AppConstants.accentColor.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildDetailsSection(double currentPrice, bool hasDiscount,
      bool isMobile, bool isTablet, BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate if we need compact layout based on available height
        final isCompactLayout = constraints.maxHeight < 140;

        return ClipRect(
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 8 : 12), // Matching home screen
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product name and brand section (matching home screen style)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Title
                      Text(
                        product.name,
                        style: TextStyle(
                          fontSize:
                              isMobile ? 14 : 16, // Slightly bigger than home
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textPrimary,
                          height: 1.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Brand name directly under product name
                      if (product.brand.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          product.brand,
                          style: TextStyle(
                            fontSize:
                                isMobile ? 12 : 13, // Slightly bigger than home
                            fontWeight: FontWeight.w500,
                            color: AppConstants.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      // Celebrity Badge Area (if present)
                      if (product.celebrityEndorsement != null) ...[
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => _navigateToCelebrityProfile(context),
                          child: Row(
                            children: [
                              Container(
                                width: isMobile ? 20 : 24,
                                height: isMobile ? 20 : 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppConstants.accentColor,
                                    width: 1,
                                  ),
                                ),
                                child: ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: product
                                        .celebrityEndorsement!.celebrityImage,
                                    fit: BoxFit.cover,
                                    errorWidget: (context, error, stackTrace) {
                                      return Container(
                                        color: AppConstants.accentColor
                                            .withValues(alpha: 0.1),
                                        child: Center(
                                          child: Text(
                                            product.celebrityEndorsement!
                                                    .celebrityName.isNotEmpty
                                                ? product.celebrityEndorsement!
                                                    .celebrityName[0]
                                                    .toUpperCase()
                                                : 'C',
                                            style: TextStyle(
                                              fontSize: isMobile ? 8 : 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppConstants.accentColor,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  product.celebrityEndorsement!.celebrityName,
                                  style: TextStyle(
                                    fontSize: isMobile ? 10 : 11,
                                    color: AppConstants.accentColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 8), // Fixed spacing like home screen

                // Price and rating row (matching home screen layout)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Price on the left
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasDiscount) ...[
                            Text(
                              Formatters.formatPrice(product.price),
                              style: TextStyle(
                                fontSize: isMobile
                                    ? 12
                                    : 13, // Slightly bigger than home
                                fontWeight: FontWeight.w500,
                                color: AppConstants.textSecondary,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            Text(
                              Formatters.formatPrice(currentPrice),
                              style: TextStyle(
                                fontSize: isMobile
                                    ? 14
                                    : 16, // Slightly bigger than home
                                fontWeight: FontWeight.bold,
                                color: AppConstants.errorColor,
                              ),
                            ),
                          ] else ...[
                            Text(
                              Formatters.formatPrice(currentPrice),
                              style: TextStyle(
                                fontSize: isMobile
                                    ? 14
                                    : 16, // Slightly bigger than home
                                fontWeight: FontWeight.bold,
                                color: AppConstants.textPrimary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Rating on the right (matching home screen style)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppConstants.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            size:
                                isMobile ? 15 : 17, // Slightly bigger than home
                            color: AppConstants.accentColor,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            product.rating.toString(),
                            style: TextStyle(
                              fontSize: isMobile
                                  ? 13
                                  : 15, // Slightly bigger than home
                              color: AppConstants.accentColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
