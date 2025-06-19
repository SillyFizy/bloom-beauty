import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_constants.dart';
import '../common/optimized_image.dart';

class CartItemWidget extends StatelessWidget {
  final String productId; // Product ID for navigation
  final String imageUrl;
  final String name;
  final String brand;
  final double price;
  final int quantity;
  final String? variant;
  final int beautyPoints;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const CartItemWidget({
    super.key,
    required this.productId,
    required this.imageUrl,
    required this.name,
    required this.brand,
    required this.price,
    required this.quantity,
    this.variant,
    required this.beautyPoints,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  String _formatPrice(double price) {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(price)} IQD';
  }

  /// Navigate to product detail screen
  void _navigateToProductDetail(BuildContext context) {
    context.push('/product/$productId');
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 400;
        final isMediumScreen =
            constraints.maxWidth >= 400 && constraints.maxWidth < 600;

        return Card(
          margin: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 12,
              vertical: isSmallScreen ? 4 : 6),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
            child: Row(
              children: [
                // Product Image - Clickable
                GestureDetector(
                  onTap: () => _navigateToProductDetail(context),
                  child: _buildProductImage(
                    isSmallScreen ? 60 : (isMediumScreen ? 70 : 80),
                    isSmallScreen ? 60 : (isMediumScreen ? 70 : 80),
                    isSmallScreen,
                  ),
                ),

                SizedBox(width: isSmallScreen ? 8 : 12),

                // Product Details - Flexible to prevent overflow
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Brand
                      Text(
                        brand,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 10 : 12,
                          color: AppConstants.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      SizedBox(height: isSmallScreen ? 2 : 4),

                      // Product Name - Clickable
                      GestureDetector(
                        onTap: () => _navigateToProductDetail(context),
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize:
                                isSmallScreen ? 13 : (isMediumScreen ? 14 : 16),
                            fontWeight: FontWeight.w600,
                            color: AppConstants
                                .accentColor, // Make it accent color to indicate it's clickable
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Variant (if exists)
                      if (variant != null && variant!.isNotEmpty) ...[
                        SizedBox(height: isSmallScreen ? 2 : 4),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 6 : 8,
                              vertical: isSmallScreen ? 2 : 4),
                          decoration: BoxDecoration(
                            color:
                                AppConstants.accentColor.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(isSmallScreen ? 8 : 12),
                            border: Border.all(
                              color: AppConstants.accentColor
                                  .withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            variant!,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 9 : 11,
                              color: AppConstants.accentColor,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],

                      // Beauty Points (always show, even if 0)
                      SizedBox(height: isSmallScreen ? 2 : 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.stars_rounded,
                            color: AppConstants.favoriteColor,
                            size: isSmallScreen ? 12 : 14,
                          ),
                          SizedBox(width: isSmallScreen ? 3 : 4),
                          Text(
                            '+${beautyPoints * quantity} points',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 9 : 11,
                              color: AppConstants.favoriteColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: isSmallScreen ? 4 : 8),

                      // Price Info
                      if (isSmallScreen)
                        // For small screens, stack vertically to save space
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${_formatPrice(price)} × $quantity',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppConstants.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _formatPrice(price * quantity),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppConstants.accentColor,
                                ),
                                maxLines: 1,
                              ),
                            ),
                          ],
                        )
                      else
                        // For larger screens, show in row with proper overflow handling
                        Row(
                          children: [
                            Flexible(
                              flex: 2,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _formatPrice(price),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppConstants.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '× $quantity',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppConstants.textSecondary,
                              ),
                              maxLines: 1,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              flex: 2,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  _formatPrice(price * quantity),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppConstants.accentColor,
                                  ),
                                  maxLines: 1,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                SizedBox(width: isSmallScreen ? 4 : 8),

                // Action Buttons - Responsive layout
                Container(
                  constraints: BoxConstraints(
                    maxWidth: isSmallScreen ? 80 : 120,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Delete Button
                      Container(
                        width: isSmallScreen ? 32 : 40,
                        height: isSmallScreen ? 32 : 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppConstants.errorColor.withValues(alpha: 0.1),
                        ),
                        child: IconButton(
                          onPressed: onRemove,
                          icon: Icon(
                            Icons.delete_outline,
                            color: AppConstants.errorColor,
                            size: isSmallScreen ? 16 : 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 6 : 8),

                      // Quantity Controls
                      Container(
                        decoration: BoxDecoration(
                          color: AppConstants.backgroundColor,
                          borderRadius:
                              BorderRadius.circular(isSmallScreen ? 6 : 8),
                          border: Border.all(
                            color: AppConstants.borderColor,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Decrease Button
                            SizedBox(
                              width: isSmallScreen ? 24 : 30,
                              height: isSmallScreen ? 24 : 30,
                              child: IconButton(
                                onPressed: quantity > 1 ? onDecrement : null,
                                icon: Icon(
                                  Icons.remove,
                                  color: quantity > 1
                                      ? AppConstants.textPrimary
                                      : AppConstants.textSecondary,
                                  size: isSmallScreen ? 12 : 16,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ),

                            // Quantity Display
                            Container(
                              constraints: BoxConstraints(
                                minWidth: isSmallScreen ? 20 : 24,
                              ),
                              padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 2 : 4),
                              child: Text(
                                quantity.toString(),
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppConstants.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            // Increase Button
                            SizedBox(
                              width: isSmallScreen ? 24 : 30,
                              height: isSmallScreen ? 24 : 30,
                              child: IconButton(
                                onPressed: onIncrement,
                                icon: Icon(
                                  Icons.add,
                                  color: AppConstants.accentColor,
                                  size: isSmallScreen ? 12 : 16,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build product image with fallback support using the same approach as other screens
  Widget _buildProductImage(double width, double height, bool isSmallScreen) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppConstants.backgroundColor,
        border: Border.all(
          color: AppConstants.borderColor,
          width: 1,
        ),
        // Add subtle shadow to indicate it's clickable
        boxShadow: [
          BoxShadow(
            color: AppConstants.accentColor.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(7), // Slightly smaller to account for border
        child: _buildImageContent(width, height, isSmallScreen),
      ),
    );
  }

  /// Build the actual image content with backend image and fallback logic
  Widget _buildImageContent(double width, double height, bool isSmallScreen) {
    // If imageUrl is provided and not empty, use it
    if (imageUrl.isNotEmpty && imageUrl != 'null') {
      return OptimizedImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        memCacheWidth: width.toInt(),
        memCacheHeight: height.toInt(),
        borderRadius: BorderRadius.circular(7),
        errorWidget: _buildFallbackImage(width, height, isSmallScreen),
      );
    }

    // Fallback to backend media images
    return _buildFallbackImage(width, height, isSmallScreen);
  }

  /// Build fallback image using backend/media/products approach like other screens
  Widget _buildFallbackImage(double width, double height, bool isSmallScreen) {
    // List of verified fallback images from backend/media/products
    final List<String> fallbackImages = [
      'tiana-eyeshadow-palette_1_product_33_20250507_195811.jpg',
      'riding-solo-single-shadow_1_product_312_20250508_214207.jpg',
      'tease-me-shadow-palette_1_product_460_20250509_210720.jpg',
      'nude-x-shadow-palette_1_product_283_20250508_212340.jpg',
      'yerimua-bad-lip-duo_1_product_350_20250508_220246.jpg',
      'must-be-cindy-lip-kits_1_product_10_20250507_194300.jpg',
      'nude-x-soft-matte-lipstick_1_product_464_20250509_212000.jpg',
      'volumizing-mascara_1_product_456_20250509_205844.jpg',
      'stay-blushing-cute-lip-and-cheek-balm_1_product_299_20250508_213502.jpg',
      'rosy-mcmichael-vol-2-pink-dream-blushes_5_product_292_20250508_212928.jpg',
      'final-finish-baked-highlighter_1_product_173_20250508_162654.jpg',
      'loose-powder_2_product_99_20250508_151153.jpg',
      'sand-snatchural-palette_1_product_445_20250509_204951.jpg',
      'nude-x-12-piece-brush-set_1_product_125_20250508_153613.jpg',
      'eyebrow-911-essentials-various-shades_1_product_441_20250509_204423.jpg',
      'flawless-stay-powder-foundation_6_product_225_20250508_203603.jpg',
    ];

    // Use product name hash to select a consistent fallback image
    final productHashIndex = name.hashCode.abs() % fallbackImages.length;
    final fallbackImageUrl =
        '${AppConstants.baseUrl}/media/products/${fallbackImages[productHashIndex]}';

    return OptimizedImage(
      imageUrl: fallbackImageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      memCacheWidth: width.toInt(),
      memCacheHeight: height.toInt(),
      borderRadius: BorderRadius.circular(7),
      errorWidget: Container(
        width: width,
        height: height,
        color: AppConstants.backgroundColor,
        child: Icon(
          Icons.image,
          size: isSmallScreen ? 24 : 32,
          color: AppConstants.textSecondary,
        ),
      ),
    );
  }
}
