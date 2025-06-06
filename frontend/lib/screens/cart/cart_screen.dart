import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../widgets/cart/cart_item_widget.dart';
import '../../widgets/common/custom_button.dart';
import '../../utils/formatters.dart';
import '../checkout/checkout_screen.dart';
import '../../constants/app_constants.dart';
import '../../providers/cart_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  
  double get shipping => 5.99;

  void _clearCart() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.clearCart();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cart cleared'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine screen size
        final isSmallScreen = constraints.maxWidth < 600;
        final isMediumScreen = constraints.maxWidth >= 600 && constraints.maxWidth < 900;
        
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Shopping Cart',
              style: TextStyle(fontSize: isSmallScreen ? 18 : 20),
            ),
            actions: [
              Consumer<CartProvider>(
                builder: (context, cart, child) {
                  return cart.isEmpty ? const SizedBox.shrink() : TextButton(
                    onPressed: _clearCart,
                    child: Text(
                      'Clear All',
                      style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Consumer<CartProvider>(
            builder: (context, cart, child) {
              return cart.isEmpty 
                  ? _buildEmptyCart(isSmallScreen) 
                  : _buildCartContent(cart, isSmallScreen);
            },
          ),
          bottomNavigationBar: Consumer<CartProvider>(
            builder: (context, cart, child) {
              if (cart.isEmpty) return const SizedBox.shrink();
              return _buildCheckoutSection(cart, isSmallScreen);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyCart(bool isSmallScreen) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: isSmallScreen ? 80 : 100,
              color: AppConstants.textSecondary,
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.w600,
                color: AppConstants.textSecondary,
              ),
            ),
            SizedBox(height: isSmallScreen ? 6 : 8),
            Text(
              'Add some products to get started',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: AppConstants.textSecondary,
              ),
            ),
            SizedBox(height: isSmallScreen ? 20 : 24),
            ElevatedButton(
              onPressed: () => context.goNamed('categories'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 20 : 24,
                  vertical: isSmallScreen ? 12 : 16,
                ),
              ),
              child: Text(
                'Start Shopping',
                style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartContent(CartProvider cart, bool isSmallScreen) {
    final subtotal = cart.totalPrice;
    final total = subtotal + shipping;

    return Column(
      children: [
        // Cart header
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Icon(
                Icons.shopping_cart,
                color: Theme.of(context).colorScheme.primary,
                size: isSmallScreen ? 20 : 24,
              ),
              SizedBox(width: isSmallScreen ? 6 : 8),
              Text(
                '${cart.items.length} item${cart.items.length != 1 ? 's' : ''} in cart',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        
        // Cart items
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 12,
              vertical: isSmallScreen ? 4 : 8,
            ),
            itemCount: cart.items.length,
            itemBuilder: (context, index) {
              final item = cart.items[index];
              final variant = item.selectedVariant != null 
                  ? item.product.variants.firstWhere(
                      (v) => v.id == item.selectedVariant,
                      orElse: () => item.product.variants.first,
                    )
                  : null;
              
              return Padding(
                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 4 : 6),
                child: CartItemWidget(
                  imageUrl: 'image_placeholder.jpg',
                  name: item.product.name,
                  brand: item.product.brand,
                  price: item.product.getCurrentPrice(),
                  quantity: item.quantity,
                  variant: variant?.name ?? (item.selectedVariant == null ? null : 'Unknown Variant'),
                  beautyPoints: item.product.beautyPoints,
                  onIncrement: () {
                    cart.updateItemQuantity(item.id, item.quantity + 1);
                  },
                  onDecrement: () {
                    if (item.quantity > 1) {
                      cart.updateItemQuantity(item.id, item.quantity - 1);
                    }
                  },
                  onRemove: () {
                    // Debug information
                    debugPrint('Removing cart item - ID: ${item.id}, Product: ${item.product.name}, Variant: ${item.selectedVariant ?? 'default'}');
                    
                    // Show which specific variant is being removed
                    final variantText = variant?.name ?? 'Default';
                    final productName = item.product.name;
                    
                    cart.removeItem(item.id);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Removed $productName${variant != null ? ' ($variantText)' : ''} from cart'),
                        backgroundColor: AppConstants.errorColor,
                        duration: const Duration(seconds: 3),
                        behavior: SnackBarBehavior.floating,
                        action: SnackBarAction(
                          label: 'UNDO',
                          textColor: AppConstants.surfaceColor,
                          onPressed: () {
                            // Re-add the item
                            cart.addItem(
                              item.product, 
                              item.quantity, 
                              variant: variant
                            );
                          },
                        ),
                      ),
                    );
                    
                    // Debug: Print current cart state after removal
                    cart.debugPrintCart();
                  },
                ),
              );
            },
          ),
        ),
        
        // Order summary
        _buildOrderSummary(subtotal, total, isSmallScreen),
      ],
    );
  }

  Widget _buildOrderSummary(double subtotal, double total, bool isSmallScreen) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        return Container(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: isSmallScreen ? 8 : 12),
              _buildSummaryRow('Subtotal', Formatters.formatPrice(subtotal), isSmallScreen),
              _buildSummaryRow('Shipping', Formatters.formatPrice(shipping), isSmallScreen),
              const Divider(),
              _buildSummaryRow(
                'Total',
                Formatters.formatPrice(total),
                isSmallScreen,
                isTotal: true,
              ),
              SizedBox(height: isSmallScreen ? 8 : 12),
              // Beauty Points section
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                decoration: BoxDecoration(
                  color: AppConstants.favoriteColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppConstants.favoriteColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.stars_rounded,
                      color: AppConstants.favoriteColor,
                      size: isSmallScreen ? 20 : 24,
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Beauty Points',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 13 : 14,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.favoriteColor,
                            ),
                          ),
                          Text(
                            'You will earn ${cart.totalBeautyPoints} points',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
                              color: AppConstants.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '+${cart.totalBeautyPoints}',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.favoriteColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isSmallScreen, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 3 : 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? (isSmallScreen ? 15 : 16) : (isSmallScreen ? 13 : 14),
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal 
                    ? Theme.of(context).colorScheme.onSurface
                    : AppConstants.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
          Flexible(
            flex: 3,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: isTotal ? (isSmallScreen ? 15 : 16) : (isSmallScreen ? 13 : 14),
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                  color: isTotal 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 1,
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSection(CartProvider cart, bool isSmallScreen) {
    final subtotal = cart.totalPrice;
    final total = subtotal + shipping;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  flex: 2,
                  child: Text(
                    'Total:',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Flexible(
                  flex: 3,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      Formatters.formatPrice(total),
                      style: TextStyle(
                        fontSize: isSmallScreen ? 18 : 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      maxLines: 1,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            CustomButton(
              text: 'Proceed to Checkout',
              onPressed: cart.isEmpty
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CheckoutScreen(),
                        ),
                      );
                    },
            ),
          ],
        ),
      ),
    );
  }
}
