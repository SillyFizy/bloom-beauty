import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';
import '../../../models/product_model.dart';

class CelebrityPicksProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onWishlistTap;
  final String Function(double) formatPrice;
  final bool isSmallScreen;

  const CelebrityPicksProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onWishlistTap,
    required this.formatPrice,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
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
            // Product Image with Rating and Wishlist
            Expanded(
              flex: 4,
              child: _buildImageSection(hasDiscount),
            ),
            
            // Product Details
            Expanded(
              flex: 3,
              child: _buildDetailsSection(currentPrice, hasDiscount),
            ),
          ],
        ),
      ),
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
              left: 8,
              child: _buildDiscountBadge(),
            ),
          
          // Rating Badge
          Positioned(
            bottom: 8,
            right: 8,
            child: _buildRatingBadge(),
          ),
          
          // Wishlist Button
          Positioned(
            top: 8,
            right: 8,
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
    
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppConstants.favoriteColor.withValues(alpha: 0.3),
                AppConstants.favoriteColor.withValues(alpha: 0.1),
              ],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.spa_outlined,
              size: isSmallScreen ? 32 : 40,
              color: AppConstants.textSecondary.withValues(alpha: 0.5),
            ),
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          decoration: BoxDecoration(
            color: AppConstants.borderColor.withValues(alpha: 0.3),
          ),
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      (loadingProgress.expectedTotalBytes ?? 1)
                  : null,
              color: AppConstants.accentColor,
              strokeWidth: 2,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDiscountBadge() {
    final discountPercent = ((product.price - (product.discountPrice ?? product.price)) / product.price * 100).round();
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 6 : 8,
        vertical: isSmallScreen ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: AppConstants.errorColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '-$discountPercent%',
        style: TextStyle(
          fontSize: isSmallScreen ? 10 : 12,
          fontWeight: FontWeight.bold,
          color: AppConstants.surfaceColor,
        ),
      ),
    );
  }

  Widget _buildRatingBadge() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 6 : 8,
        vertical: isSmallScreen ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: AppConstants.textPrimary.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: isSmallScreen ? 12 : 14,
            color: AppConstants.accentColor,
          ),
          const SizedBox(width: 2),
          Text(
            product.rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: isSmallScreen ? 10 : 12,
              fontWeight: FontWeight.bold,
              color: AppConstants.surfaceColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistButton() {
    return GestureDetector(
      onTap: onWishlistTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppConstants.textSecondary.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.favorite_border_rounded,
          size: isSmallScreen ? 16 : 18,
          color: AppConstants.favoriteColor,
        ),
      ),
    );
  }

  Widget _buildDetailsSection(double currentPrice, bool hasDiscount) {
    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Name
          Expanded(
            child: Text(
              product.name,
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 14,
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimary,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          const SizedBox(height: 6),
          
          // Celebrity Endorsement
          if (product.celebrityEndorsement != null)
            _buildCelebrityEndorsement(),
          
          const SizedBox(height: 6),
          
          // Price Section - Aligned to the right
          Align(
            alignment: Alignment.centerRight,
            child: _buildPriceSection(currentPrice, hasDiscount),
          ),
        ],
      ),
    );
  }

  Widget _buildCelebrityEndorsement() {
    final endorsement = product.celebrityEndorsement!;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: isSmallScreen ? 22 : 24,
            height: isSmallScreen ? 22 : 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppConstants.accentColor,
                width: 1,
              ),
            ),
            child: ClipOval(
              child: Image.network(
                endorsement.celebrityImage,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppConstants.accentColor.withValues(alpha: 0.6),
                          AppConstants.accentColor.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        endorsement.celebrityName.isNotEmpty 
                            ? endorsement.celebrityName[0].toUpperCase() 
                            : 'C',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 13,
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
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Picked by ${endorsement.celebrityName}',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 13,
                color: AppConstants.accentColor,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(double currentPrice, bool hasDiscount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formatPrice(currentPrice),
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.bold,
            color: AppConstants.textPrimary,
          ),
        ),
        if (hasDiscount) ...[
          const SizedBox(width: 6),
          Text(
            formatPrice(product.price),
            style: TextStyle(
              fontSize: isSmallScreen ? 11 : 13,
              color: AppConstants.textSecondary,
              decoration: TextDecoration.lineThrough,
              decorationColor: AppConstants.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
} 