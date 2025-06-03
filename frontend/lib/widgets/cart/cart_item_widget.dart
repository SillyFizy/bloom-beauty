import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';

class CartItemWidget extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String brand;
  final double price;
  final int quantity;
  final String? variant;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback? onRemove;

  const CartItemWidget({
    Key? key,
    required this.imageUrl,
    required this.name,
    required this.brand,
    required this.price,
    required this.quantity,
    this.variant,
    this.onIncrement,
    this.onDecrement,
    this.onRemove,
  }) : super(key: key);

  String _formatPrice(double price) {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(price)} IQD';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 400;
        final isMediumScreen = constraints.maxWidth >= 400 && constraints.maxWidth < 600;
        
        return Card(
          margin: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 8 : 12, 
            vertical: isSmallScreen ? 4 : 6
          ),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
            child: Row(
              children: [
                // Product Image
                Container(
                  width: isSmallScreen ? 60 : (isMediumScreen ? 70 : 80),
                  height: isSmallScreen ? 60 : (isMediumScreen ? 70 : 80),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppConstants.backgroundColor,
                    border: Border.all(
                      color: AppConstants.borderColor,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.image,
                    size: isSmallScreen ? 24 : (isMediumScreen ? 32 : 40),
                    color: AppConstants.textSecondary,
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
                      
                      // Product Name
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 13 : (isMediumScreen ? 14 : 16),
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      // Variant (if exists)
                      if (variant != null && variant!.isNotEmpty) ...[
                        SizedBox(height: isSmallScreen ? 2 : 4),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 6 : 8, 
                            vertical: isSmallScreen ? 2 : 4
                          ),
                          decoration: BoxDecoration(
                            color: AppConstants.accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                            border: Border.all(
                              color: AppConstants.accentColor.withOpacity(0.3),
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
                                style: TextStyle(
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
                                style: TextStyle(
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
                                  style: TextStyle(
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
                              style: TextStyle(
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
                                  style: TextStyle(
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
                          color: AppConstants.errorColor.withOpacity(0.1),
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
                          borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
                          border: Border.all(
                            color: AppConstants.borderColor,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Decrease Button
                            Container(
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
                                horizontal: isSmallScreen ? 2 : 4
                              ),
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
                            Container(
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
}
