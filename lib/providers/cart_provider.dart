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

  void addItem(Product product, int quantity, {ProductVariant? variant}) {
    final existingItemIndex = _items.indexWhere((item) =>
        item.product.id == product.id &&
        item.selectedVariant == variant?.id);

    if (existingItemIndex >= 0) {
      // Update existing item quantity
      _items[existingItemIndex] = CartItem(
        id: _items[existingItemIndex].id,
        product: product,
        quantity: _items[existingItemIndex].quantity + quantity,
        selectedVariant: variant?.id,
      );
    } else {
      // Add new item
      _items.add(CartItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        product: product,
        quantity: quantity,
        selectedVariant: variant?.id,
      ));
    }

    _saveCartToStorage();
    notifyListeners();
  }

  void addMultipleItems(
      Product product, Map<String, int> variantQuantities) {
    for (var entry in variantQuantities.entries) {
      if (entry.value > 0) {
        ProductVariant? variant;
        if (entry.key != 'default') {
          variant = product.variants.firstWhere((v) => v.id == entry.key);
        }
        addItem(product, entry.value, variant: variant);
      }
    }
  }

  void removeItem(String itemId) {
    _items.removeWhere((item) => item.id == itemId);
    _saveCartToStorage();
    notifyListeners();
  }

  void updateItemQuantity(String itemId, int quantity) {
    final itemIndex = _items.indexWhere((item) => item.id == itemId);
    if (itemIndex >= 0) {
      if (quantity <= 0) {
        _items.removeAt(itemIndex);
      } else {
        _items[itemIndex] = CartItem(
          id: _items[itemIndex].id,
          product: _items[itemIndex].product,
          quantity: quantity,
          selectedVariant: _items[itemIndex].selectedVariant,
        );
      }
      _saveCartToStorage();
      notifyListeners();
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
} 