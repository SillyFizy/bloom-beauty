import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';
import '../../models/product_model.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final bool isSmallScreen;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: [
          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Container with Favorite Button
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
decoration: const BoxDecoration(

                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(AppConstants.borderRadius),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppConstants.backgroundColor,
                            AppConstants.borderColor,
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppConstants.accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(30),
                            ),
child: const Icon(

                              Icons.spa_outlined,
                              size: 30,
                              color: AppConstants.accentColor,
                            ),
                          ),
                          const SizedBox(height: 8),
const Text(

                            'Beauty Product',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppConstants.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Favorite Button
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () {},
icon: const Icon(

                            Icons.favorite,
                            color: AppConstants.favoriteColor,
                            size: 18,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    
                    // Discount Badge
                    if (product.discountPrice != null)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppConstants.errorColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${((product.price - product.discountPrice!) / product.price * 100).round()}% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Product Details
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Brand
                      Text(
                        product.brand.toUpperCase(),
style: const TextStyle(

                          fontSize: 9,
                          color: AppConstants.textSecondary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      
                      // Product Name
                      Expanded(
                        child: Text(
                          product.name,
style: const TextStyle(

                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.textPrimary,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      // Rating
                      Row(
                        children: [
const Icon(

                            Icons.star,
                            size: 12,
                            color: AppConstants.accentColor,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            product.rating.toString(),
style: const TextStyle(

                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppConstants.textSecondary,
                            ),
                          ),
                          const Spacer(),
const Icon(

                            Icons.add_shopping_cart_outlined,
                            size: 14,
                            color: AppConstants.accentColor,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 6),
                      
                      // Price
                      Row(
                        children: [
                          if (product.discountPrice != null) ...[
                            Text(
                              '\$${product.discountPrice!.toStringAsFixed(2)}',
style: const TextStyle(

                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.accentColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '\$${product.price.toStringAsFixed(2)}',
style: const TextStyle(

                                fontSize: 11,
                                decoration: TextDecoration.lineThrough,
                                color: AppConstants.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ] else ...[
                            Text(
                              '\$${product.price.toStringAsFixed(2)}',
style: const TextStyle(

                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.textPrimary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
