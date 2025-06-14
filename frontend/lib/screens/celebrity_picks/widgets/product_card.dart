import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../models/product_model.dart';
import '../../../widgets/common/wishlist_button.dart';
import '../../../providers/celebrity_picks_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class CelebrityPicksProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onWishlistTap;
  final String Function(double) formatPrice;

  const CelebrityPicksProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onWishlistTap,
    required this.formatPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CelebrityPicksProvider>(
      builder: (context, provider, child) {
    final hasDiscount = product.discountPrice != null && 
                       product.discountPrice! < product.price;
    final currentPrice = product.discountPrice ?? product.price;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppConstants.borderColor.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppConstants.textSecondary.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                // Product Image with Beauty Points and Wishlist - More space for image
            Expanded(
              flex: 5,
              child: _buildImageSection(hasDiscount),
            ),
            
            // Product Details - More space for content
            Expanded(
              flex: 3,
              child: _buildDetailsSection(currentPrice, hasDiscount),
            ),
          ],
        ),
      ),
        );
      },
    );
  }

  Widget _buildImageSection(bool hasDiscount) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Product Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: _buildProductImage(),
          ),
          
          // Discount Badge
          if (hasDiscount)
            Positioned(
              top: 8,
              right: 8,
              child: _buildDiscountBadge(),
            ),
          
          // Beauty Points Badge (replaced rating)
          if (product.beautyPoints > 0)
          Positioned(
            bottom: 8,
            right: 8,
              child: _buildBeautyPointsBadge(),
          ),
          
          // Wishlist Button (moved to left)
          Positioned(
            top: 8,
            left: 8,
            child: _buildWishlistButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage() {
    final imageUrl = product.images.isNotEmpty 
        ? product.images.first 
        : 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=400&h=400&fit=crop';
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;
    
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      memCacheWidth: isSmallScreen ? 300 : 400,
      memCacheHeight: isSmallScreen ? 300 : 400,
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: AppConstants.borderColor.withOpacity(0.3),
        highlightColor: AppConstants.surfaceColor,
        child: Container(
          decoration: BoxDecoration(
            color: AppConstants.borderColor.withOpacity(0.3),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppConstants.favoriteColor.withOpacity(0.3),
                AppConstants.favoriteColor.withOpacity(0.1),
              ],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.spa_outlined,
              size: isSmallScreen ? 32 : 40,
              color: AppConstants.textSecondary.withOpacity(0.5),
            ),
          ),
      ),
        );
      },
    );
  }

  Widget _buildDiscountBadge() {
    final discountPercent = ((product.price - (product.discountPrice ?? product.price)) / product.price * 100).round();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 10,
        vertical: isSmallScreen ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: AppConstants.errorColor,
        borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
      ),
      child: Text(
        '-$discountPercent%',
        style: TextStyle(
          fontSize: isSmallScreen ? 11 : 13,
          fontWeight: FontWeight.bold,
          color: AppConstants.surfaceColor,
        ),
      ),
    );
      },
    );
  }

  Widget _buildBeautyPointsBadge() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;
        
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 10,
        vertical: isSmallScreen ? 4 : 6,
      ),
      decoration: BoxDecoration(
            color: AppConstants.favoriteColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
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
                size: isSmallScreen ? 12 : 14,
                color: Colors.white,
          ),
          const SizedBox(width: 2),
          Text(
                '+${product.beautyPoints}',
            style: TextStyle(
                  fontSize: isSmallScreen ? 10 : 12,
              fontWeight: FontWeight.bold,
                  color: Colors.white,
            ),
          ),
        ],
      ),
        );
      },
    );
  }

  Widget _buildWishlistButton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;
        
        return WishlistButton(
          product: product,
          size: isSmallScreen ? 18 : 20,
          onPressed: onWishlistTap,
          heroTag: 'celebrity_picks_wishlist_${product.id}',
        );
      },
    );
  }

  Widget _buildDetailsSection(double currentPrice, bool hasDiscount) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        
        // Define screen categories
        final isVerySmall = screenWidth < 400;
        final isSmall = screenWidth >= 400 && screenWidth < 600;
        final isMedium = screenWidth >= 600 && screenWidth < 900;
        final isLarge = screenWidth >= 900;
        
        // Calculate padding based on screen size
        EdgeInsets padding;
        if (isVerySmall) {
          padding = const EdgeInsets.all(8);
        } else if (isSmall) {
          padding = const EdgeInsets.all(12);
        } else if (isMedium) {
          padding = const EdgeInsets.all(16);
        } else {
          padding = const EdgeInsets.all(20);
        }

    return Padding(
          padding: padding,
          child: LayoutBuilder(
            builder: (context, contentConstraints) {
              final contentHeight = contentConstraints.maxHeight;
              final isVeryCompactHeight = contentHeight < 100;
              final isCompactHeightAdjusted = contentHeight < 140;
              
              return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                  // Product Name - Flexible
                  Flexible(
                    flex: 2,
            child: Text(
              product.name,
              style: TextStyle(
                        fontSize: _getNameFontSize(isVerySmall, isSmall, isMedium, isLarge, isCompactHeightAdjusted),
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimary,
                        height: 1.2,
              ),
                      maxLines: isVeryCompactHeight ? 1 : (isCompactHeightAdjusted ? 1 : 2),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
                  // Dynamic spacing
                  if (!isVeryCompactHeight)
                    SizedBox(height: isVerySmall ? 4 : (isCompactHeightAdjusted ? 6 : 8)),
          
                  // Celebrity Endorsement - Only show if space allows
                  if (product.celebrityEndorsement != null && !isVeryCompactHeight)
                    Flexible(
                      flex: 2,
                      child: _buildCelebrityEndorsement(isVerySmall, isSmall, isMedium, isLarge, isCompactHeightAdjusted),
                    ),
          
                  // Spacer to push price and rating to bottom
                  const Spacer(),
                  
                  // Price and Rating Section - Always visible
                  _buildPriceAndRatingSection(currentPrice, hasDiscount, isVerySmall, isSmall, isMedium, isLarge),
                ],
              );
            },
          ),
        );
      },
    );
  }

  double _getNameFontSize(bool isVerySmall, bool isSmall, bool isMedium, bool isLarge, bool isCompactHeight) {
    if (isVerySmall && isCompactHeight) return 11;
    if (isVerySmall) return 13;
    if (isSmall) return 14;
    if (isMedium) return 16;
    return 18; // Large screens
  }

  Widget _buildCelebrityEndorsement(bool isVerySmall, bool isSmall, bool isMedium, bool isLarge, bool isCompactHeight) {
    final endorsement = product.celebrityEndorsement!;
    
    // Calculate avatar size based on screen size
    double avatarSize;
    if (isVerySmall && isCompactHeight) {
      avatarSize = 20;
    } else if (isVerySmall) {
      avatarSize = 24;
    } else if (isSmall) {
      avatarSize = 28;
    } else if (isMedium) {
      avatarSize = 32;
    } else {
      avatarSize = 36; // Large screens
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
        children: [
          Container(
          width: avatarSize,
          height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppConstants.accentColor,
              width: isVerySmall ? 1 : 1.5,
              ),
            boxShadow: isLarge && !isCompactHeight ? [
                BoxShadow(
                  color: AppConstants.accentColor.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
              ),
            ] : null,
            ),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: endorsement.celebrityImage,
                fit: BoxFit.cover,
              memCacheWidth: (avatarSize * 2).toInt(),
              memCacheHeight: (avatarSize * 2).toInt(),
              placeholder: (context, url) => Container(
                      color: AppConstants.borderColor.withOpacity(0.3),
                ),
                errorWidget: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppConstants.accentColor.withOpacity(0.6),
                          AppConstants.accentColor.withOpacity(0.3),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        endorsement.celebrityName.isNotEmpty 
                            ? endorsement.celebrityName[0].toUpperCase() 
                            : 'C',
                        style: TextStyle(
                        fontSize: _getCelebrityInitialFontSize(isVerySmall, isSmall, isMedium, isLarge),
                          fontWeight: FontWeight.bold,
                          color: AppConstants.surfaceColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        SizedBox(width: isVerySmall ? 6 : 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
              children: [
              if (!isCompactHeight)
                Text(
                  'Picked by',
                  style: TextStyle(
                    fontSize: _getCelebrityLabelFontSize(isVerySmall, isSmall, isMedium, isLarge),
                    color: AppConstants.textSecondary,
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                  ),
                ),
                Text(
                  endorsement.celebrityName,
              style: TextStyle(
                  fontSize: _getCelebrityNameFontSize(isVerySmall, isSmall, isMedium, isLarge, isCompactHeight),
                color: AppConstants.accentColor,
                fontWeight: FontWeight.w600,
                    height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
    );
  }

  double _getCelebrityInitialFontSize(bool isVerySmall, bool isSmall, bool isMedium, bool isLarge) {
    if (isVerySmall) return 8;
    if (isSmall) return 10;
    if (isMedium) return 12;
    return 14; // Large screens
  }

  double _getCelebrityLabelFontSize(bool isVerySmall, bool isSmall, bool isMedium, bool isLarge) {
    if (isVerySmall) return 9;
    if (isSmall) return 10;
    if (isMedium) return 11;
    return 12; // Large screens
  }

  double _getCelebrityNameFontSize(bool isVerySmall, bool isSmall, bool isMedium, bool isLarge, bool isCompactHeight) {
    if (isVerySmall && isCompactHeight) return 9;
    if (isVerySmall) return 11;
    if (isSmall) return 12;
    if (isMedium) return 14;
    return 16; // Large screens
  }

  Widget _buildPriceAndRatingSection(double currentPrice, bool hasDiscount, bool isVerySmall, bool isSmall, bool isMedium, bool isLarge) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Price on the left
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formatPrice(currentPrice),
          style: TextStyle(
                  fontSize: _getPriceFontSize(isVerySmall, isSmall, isMedium, isLarge),
            fontWeight: FontWeight.bold,
            color: AppConstants.textPrimary,
                  height: 1.0,
          ),
                overflow: TextOverflow.ellipsis,
        ),
              if (hasDiscount && !isVerySmall)
          Text(
            formatPrice(product.price),
            style: TextStyle(
                    fontSize: _getDiscountPriceFontSize(isVerySmall, isSmall, isMedium, isLarge),
              color: AppConstants.textSecondary,
              decoration: TextDecoration.lineThrough,
              decorationColor: AppConstants.textSecondary,
                    height: 1.0,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        
        // Rating on the right - aligned to center of price text
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isVerySmall ? 6 : 8,
            vertical: isVerySmall ? 3 : 4,
          ),
          decoration: BoxDecoration(
            color: AppConstants.accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star_rounded,
                size: isVerySmall ? 14 : 16,
                color: AppConstants.accentColor,
              ),
              const SizedBox(width: 2),
              Text(
                product.rating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: isVerySmall ? 11 : 13,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.accentColor,
            ),
          ),
        ],
          ),
        ),
      ],
    );
  }

  double _getPriceFontSize(bool isVerySmall, bool isSmall, bool isMedium, bool isLarge) {
    if (isVerySmall) return 13;
    if (isSmall) return 15;
    if (isMedium) return 17;
    return 20; // Large screens
  }

  double _getDiscountPriceFontSize(bool isVerySmall, bool isSmall, bool isMedium, bool isLarge) {
    if (isVerySmall) return 10;
    if (isSmall) return 12;
    if (isMedium) return 14;
    return 16; // Large screens
  }
} 
