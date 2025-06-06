import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../providers/cart_provider.dart';
import '../../utils/formatters.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  // Form controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _notesController = TextEditingController();
  
  // State variables
  String _selectedPaymentMethod = 'cash_on_delivery';
  bool _isProcessing = false;
  
  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _processOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    // Simulate order processing
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });

      // Show success dialog
      _showOrderSuccessDialog();
    }
  }

  void _showOrderSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text('Order Placed!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your order has been placed successfully.',
              style: TextStyle(
                fontSize: 16,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Consumer<CartProvider>(
              builder: (context, cart, child) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppConstants.favoriteColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppConstants.favoriteColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.stars_rounded,
                        color: AppConstants.favoriteColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Beauty Points Earned',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppConstants.favoriteColor,
                              ),
                            ),
                            Text(
                              '+${cart.totalBeautyPoints} points added to your account',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppConstants.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              'You will receive a confirmation call within 24 hours.',
              style: TextStyle(
                fontSize: 14,
                color: AppConstants.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Clear cart and navigate to home
              context.read<CartProvider>().clearCart();
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close checkout screen
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
            child: Text(
              'Continue Shopping',
              style: TextStyle(
                color: AppConstants.accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        
        return Scaffold(
          backgroundColor: AppConstants.backgroundColor,
          appBar: AppBar(
            backgroundColor: AppConstants.surfaceColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: AppConstants.textPrimary,
                size: isSmallScreen ? 20 : 24,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Checkout',
              style: TextStyle(
                fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),
            centerTitle: false,
          ),
          body: Consumer<CartProvider>(
            builder: (context, cart, child) {
              return Column(
                children: [
                  // Main content
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        controller: _scrollController,
                        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                        children: [
                          // Contact Information Section
                          _buildSectionCard(
                            'Contact Information',
                            Icons.person_outline,
                            isSmallScreen,
                            [
                              _buildTextField(
                                controller: _nameController,
                                label: 'Full Name',
                                icon: Icons.person,
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'Name is required';
                                  }
                                  return null;
                                },
                                isSmallScreen: isSmallScreen,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _phoneController,
                                label: 'Phone Number',
                                icon: Icons.phone,
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'Phone number is required';
                                  }
                                  return null;
                                },
                                isSmallScreen: isSmallScreen,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _emailController,
                                label: 'Email (Optional)',
                                icon: Icons.email,
                                keyboardType: TextInputType.emailAddress,
                                isSmallScreen: isSmallScreen,
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Delivery Address Section
                          _buildSectionCard(
                            'Delivery Address',
                            Icons.location_on_outlined,
                            isSmallScreen,
                            [
                              _buildTextField(
                                controller: _cityController,
                                label: 'City',
                                icon: Icons.location_city,
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'City is required';
                                  }
                                  return null;
                                },
                                isSmallScreen: isSmallScreen,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _addressController,
                                label: 'Full Address',
                                icon: Icons.home,
                                maxLines: 3,
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'Address is required';
                                  }
                                  return null;
                                },
                                isSmallScreen: isSmallScreen,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _notesController,
                                label: 'Delivery Notes (Optional)',
                                icon: Icons.note,
                                maxLines: 2,
                                hintText: 'Building number, floor, special instructions...',
                                isSmallScreen: isSmallScreen,
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Payment Method Section
                          _buildPaymentMethodSection(isSmallScreen),
                          
                          const SizedBox(height: 24),
                          
                          // Order Summary Section
                          _buildOrderSummarySection(cart, isSmallScreen),
                          
                          const SizedBox(height: 100), // Space for bottom button
                        ],
                      ),
                    ),
                  ),
                  
                  // Checkout Button
                  _buildCheckoutButton(cart, isSmallScreen),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSectionCard(String title, IconData icon, bool isSmallScreen, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppConstants.textSecondary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: AppConstants.accentColor,
                  size: isSmallScreen ? 20 : 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isSmallScreen,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: AppConstants.accentColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppConstants.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppConstants.borderColor.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppConstants.accentColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppConstants.errorColor),
        ),
        filled: true,
        fillColor: AppConstants.backgroundColor,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 16,
          vertical: isSmallScreen ? 12 : 16,
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection(bool isSmallScreen) {
    return _buildSectionCard(
      'Payment Method',
      Icons.payment_outlined,
      isSmallScreen,
      [
        Container(
          decoration: BoxDecoration(
            color: AppConstants.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppConstants.borderColor.withOpacity(0.5),
            ),
          ),
          child: RadioListTile<String>(
            value: 'cash_on_delivery',
            groupValue: _selectedPaymentMethod,
            onChanged: (value) {
              setState(() {
                _selectedPaymentMethod = value!;
              });
            },
            title: Row(
              children: [
                Icon(
                  Icons.money,
                  color: AppConstants.accentColor,
                  size: isSmallScreen ? 20 : 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Cash on Delivery',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w500,
                    color: AppConstants.textPrimary,
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(left: 32, top: 4),
              child: Text(
                'Pay when you receive your order',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  color: AppConstants.textSecondary,
                ),
              ),
            ),
            activeColor: AppConstants.accentColor,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummarySection(CartProvider cart, bool isSmallScreen) {
    final subtotal = cart.totalPrice;
    const shipping = 5000.0; // 5,000 IQD shipping
    final total = subtotal + shipping;

    return _buildSectionCard(
      'Order Summary',
      Icons.receipt_outlined,
      isSmallScreen,
      [
        // Items summary
        Text(
          '${cart.itemCount} item${cart.itemCount == 1 ? '' : 's'} in your order',
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            color: AppConstants.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        
        // Price breakdown
        _buildSummaryRow('Subtotal', Formatters.formatPrice(subtotal), isSmallScreen),
        _buildSummaryRow('Shipping', Formatters.formatPrice(shipping), isSmallScreen),
        
        const Divider(height: 32),
        
        _buildSummaryRow(
          'Total',
          Formatters.formatPrice(total),
          isSmallScreen,
          isTotal: true,
        ),
        
        const SizedBox(height: 16),
        
        // Beauty Points
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            color: AppConstants.favoriteColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppConstants.favoriteColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.stars_rounded,
                color: AppConstants.favoriteColor,
                size: isSmallScreen ? 20 : 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Beauty Points',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.favoriteColor,
                      ),
                    ),
                    Text(
                      'You will earn ${cart.totalBeautyPoints} points with this order',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '+${cart.totalBeautyPoints}',
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.favoriteColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isSmallScreen, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? (isSmallScreen ? 16 : 18) : (isSmallScreen ? 14 : 16),
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? AppConstants.textPrimary : AppConstants.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? (isSmallScreen ? 16 : 18) : (isSmallScreen ? 14 : 16),
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: AppConstants.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutButton(CartProvider cart, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: AppConstants.textSecondary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: isSmallScreen ? 50 : 56,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _processOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.accentColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isProcessing
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Place Order',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
} 