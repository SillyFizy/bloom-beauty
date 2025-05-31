import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../widgets/cart/cart_item_widget.dart';
import '../../widgets/common/custom_button.dart';
import '../../utils/formatters.dart';
import '../../constants/app_constants.dart';
import '../../providers/cart_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  
  double get shipping => 5.99;
  double get taxRate => 0.08;

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
    final tax = subtotal * taxRate;
    final total = subtotal + shipping + tax;

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
                  variant: variant?.name,
                  onIncrement: () {
                    cart.updateItemQuantity(item.id, item.quantity + 1);
                  },
                  onDecrement: () {
                    if (item.quantity > 1) {
                      cart.updateItemQuantity(item.id, item.quantity - 1);
                    }
                  },
                  onRemove: () {
                    cart.removeItem(item.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Item removed from cart'),
                        backgroundColor: AppConstants.errorColor,
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        
        // Order summary
        _buildOrderSummary(subtotal, tax, total, isSmallScreen),
      ],
    );
  }

  Widget _buildOrderSummary(double subtotal, double tax, double total, bool isSmallScreen) {
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
          _buildSummaryRow('Tax', Formatters.formatPrice(tax), isSmallScreen),
          const Divider(),
          _buildSummaryRow(
            'Total',
            Formatters.formatPrice(total),
            isSmallScreen,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isSmallScreen, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 3 : 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? (isSmallScreen ? 15 : 16) : (isSmallScreen ? 13 : 14),
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal 
                  ? Theme.of(context).colorScheme.onSurface
                  : AppConstants.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? (isSmallScreen ? 15 : 16) : (isSmallScreen ? 13 : 14),
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSection(CartProvider cart, bool isSmallScreen) {
    final subtotal = cart.totalPrice;
    final tax = subtotal * taxRate;
    final total = subtotal + shipping + tax;

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
                Text(
                  'Total:',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  Formatters.formatPrice(total),
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            CustomButton(
              text: 'Proceed to Checkout',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(
                      'Checkout',
                      style: TextStyle(fontSize: isSmallScreen ? 18 : 20),
                    ),
                    content: Text(
                      'Checkout feature coming soon!',
                      style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'OK',
                          style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                        ),
                      ),
                    ],
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
