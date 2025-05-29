import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/cart/cart_item_widget.dart';
import '../../widgets/common/custom_button.dart';
import '../../utils/formatters.dart';
import '../../constants/app_constants.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> cartItems = [
    {
      'id': '1',
      'imageUrl': 'image1.jpg',
      'name': 'Hydrating Face Cream',
      'brand': 'BeautyBrand',
      'price': 24.99,
      'quantity': 2,
    },
    {
      'id': '2',
      'imageUrl': 'image2.jpg',
      'name': 'Matte Lipstick',
      'brand': 'ColorCo',
      'price': 19.99,
      'quantity': 1,
    },
    {
      'id': '3',
      'imageUrl': 'image3.jpg',
      'name': 'Vitamin C Serum',
      'brand': 'VitaminPlus',
      'price': 34.99,
      'quantity': 1,
    },
  ];

  double get subtotal {
    return cartItems.fold(0.0, (sum, item) => 
        sum + (item['price'] * item['quantity']));
  }

  double get shipping => 5.99;
  double get tax => subtotal * 0.08;
  double get total => subtotal + shipping + tax;

  void _incrementQuantity(String id) {
    setState(() {
      final index = cartItems.indexWhere((item) => item['id'] == id);
      if (index != -1) {
        cartItems[index]['quantity']++;
      }
    });
  }

  void _decrementQuantity(String id) {
    setState(() {
      final index = cartItems.indexWhere((item) => item['id'] == id);
      if (index != -1 && cartItems[index]['quantity'] > 1) {
        cartItems[index]['quantity']--;
      }
    });
  }

  void _removeItem(String id) {
    setState(() {
      cartItems.removeWhere((item) => item['id'] == id);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Item removed from cart'),
        backgroundColor: AppConstants.errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
          if (cartItems.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  cartItems.clear();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cart cleared'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              child: const Text('Clear All'),
            ),
        ],
      ),
      body: cartItems.isEmpty ? _buildEmptyCart() : _buildCartContent(),
      bottomNavigationBar: cartItems.isNotEmpty ? _buildCheckoutSection() : null,
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: AppConstants.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some products to get started',
            style: TextStyle(
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.goNamed('products'),
            child: const Text('Start Shopping'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent() {
    return Column(
      children: [
        // Cart header
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Icon(
                Icons.shopping_cart,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '${cartItems.length} item${cartItems.length != 1 ? 's' : ''} in cart',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        
        // Cart items
        Expanded(
          child: ListView.builder(
            itemCount: cartItems.length,
            itemBuilder: (context, index) {
              final item = cartItems[index];
              return CartItemWidget(
                imageUrl: item['imageUrl'],
                name: item['name'],
                brand: item['brand'],
                price: item['price'],
                quantity: item['quantity'],
                onIncrement: () => _incrementQuantity(item['id']),
                onDecrement: () => _decrementQuantity(item['id']),
                onRemove: () => _removeItem(item['id']),
              );
            },
          ),
        ),
        
        // Order summary
        _buildOrderSummary(),
      ],
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Subtotal', Formatters.formatPrice(subtotal)),
          _buildSummaryRow('Shipping', Formatters.formatPrice(shipping)),
          _buildSummaryRow('Tax', Formatters.formatPrice(tax)),
          const Divider(),
          _buildSummaryRow(
            'Total',
            Formatters.formatPrice(total),
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal 
                  ? Theme.of(context).colorScheme.onSurface
                  : AppConstants.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
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

  Widget _buildCheckoutSection() {
    return Container(
      padding: const EdgeInsets.all(16),
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
                const Text(
                  'Total:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  Formatters.formatPrice(total),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Proceed to Checkout',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Checkout'),
                    content: const Text('Checkout feature coming soon!'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'),
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
