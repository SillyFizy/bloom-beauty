import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/product_model.dart';
import '../models/cart_item_model.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  static const String _cartStorageKey = 'cart_items';

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice => _items.fold(
      0.0, (sum, item) => sum + (item.product.getCurrentPrice() * item.quantity));

  bool get isEmpty => _items.isEmpty;

  // Initialize cart from local storage
  Future<void> loadCartFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_cartStorageKey);
      
      if (cartJson != null) {
        final List<dynamic> cartList = json.decode(cartJson);
        _items.clear();
        _items.addAll(cartList.map((item) => CartItem.fromJson(item)).toList());
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading cart from storage: $e');
    }
  }

  // Save cart to local storage
  Future<void> _saveCartToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = json.encode(_items.map((item) => item.toJson()).toList());
      await prefs.setString(_cartStorageKey, cartJson);
    } catch (e) {
      debugPrint('Error saving cart to storage: $e');
    }
  }

  // Generate unique cart item ID that includes variant information
  String _generateCartItemId(Product product, ProductVariant? variant) {
    final baseId = product.id;
    final variantId = variant?.id ?? 'default';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${baseId}_${variantId}_$timestamp';
  }

  void addItem(Product product, int quantity, {ProductVariant? variant}) {
    // Ensure we have consistent variant identification
    final variantId = variant?.id; // null for default, actual ID for variants
    
    final existingItemIndex = _items.indexWhere((item) =>
        item.product.id == product.id &&
        item.selectedVariant == variantId);

    if (existingItemIndex >= 0) {
      // Update existing item quantity
      _items[existingItemIndex] = CartItem(
        id: _items[existingItemIndex].id,
        product: product,
        quantity: _items[existingItemIndex].quantity + quantity,
        selectedVariant: variantId,
      );
    } else {
      // Add new item with unique ID that incorporates variant information
      _items.add(CartItem(
        id: _generateCartItemId(product, variant),
        product: product,
        quantity: quantity,
        selectedVariant: variantId,
      ));
    }

    _saveCartToStorage();
    notifyListeners();
  }

  void addMultipleItems(Product product, Map<String, int> variantQuantities) {
    for (var entry in variantQuantities.entries) {
      if (entry.value > 0) {
        ProductVariant? variant;
        
        // Handle default variant case explicitly
        if (entry.key != 'default') {
          try {
          variant = product.variants.firstWhere((v) => v.id == entry.key);
          } catch (e) {
            debugPrint('Warning: Variant ${entry.key} not found for product ${product.id}');
            continue; // Skip this variant if not found
          }
        }
        // For 'default' case, variant remains null
        
        addItem(product, entry.value, variant: variant);
      }
    }
  }

  void removeItem(String itemId) {
    final itemToRemove = _items.firstWhere(
      (item) => item.id == itemId,
      orElse: () => throw Exception('Cart item with ID $itemId not found'),
    );
    
    debugPrint('Removing cart item: ${itemToRemove.id} - ${itemToRemove.product.name} (Variant: ${itemToRemove.selectedVariant ?? 'default'})');
    
    _items.removeWhere((item) => item.id == itemId);
    _saveCartToStorage();
    notifyListeners();
  }

  void updateItemQuantity(String itemId, int quantity) {
    final itemIndex = _items.indexWhere((item) => item.id == itemId);
    if (itemIndex >= 0) {
      if (quantity <= 0) {
        removeItem(itemId);
      } else {
        _items[itemIndex] = CartItem(
          id: _items[itemIndex].id,
          product: _items[itemIndex].product,
          quantity: quantity,
          selectedVariant: _items[itemIndex].selectedVariant,
        );
      _saveCartToStorage();
      notifyListeners();
      }
    }
  }

  void clearCart() {
    _items.clear();
    _saveCartToStorage();
    notifyListeners();
  }

  CartItem? findItem(String productId, {String? variantId}) {
    try {
      return _items.firstWhere((item) =>
          item.product.id == productId &&
          item.selectedVariant == variantId);
    } catch (e) {
      return null;
    }
  }

  // Debug method to log cart contents
  void debugPrintCart() {
    debugPrint('=== CART CONTENTS ===');
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      debugPrint('[$i] ID: ${item.id}');
      debugPrint('    Product: ${item.product.name} (${item.product.id})');
      debugPrint('    Variant: ${item.selectedVariant ?? 'default'}');
      debugPrint('    Quantity: ${item.quantity}');
      debugPrint('    ---');
    }
    debugPrint('Total items: ${_items.length}');
    debugPrint('====================');
  }

  // Method to remove all variants of a specific product (if needed)
  void removeAllVariantsOfProduct(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    _saveCartToStorage();
    notifyListeners();
  }

  // Method to get all variants of a product in the cart
  List<CartItem> getProductVariantsInCart(String productId) {
    return _items.where((item) => item.product.id == productId).toList();
  }
} 