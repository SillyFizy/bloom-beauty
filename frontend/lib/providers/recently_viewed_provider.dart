import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/product_model.dart';

class RecentlyViewedProvider with ChangeNotifier {
  static const String _storageKey = 'recently_viewed_products';
  static const int _maxItems = 10; // Maximum number of items to store
  
  List<Product> _recentlyViewedProducts = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Product> get recentlyViewedProducts => _recentlyViewedProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasItems => _recentlyViewedProducts.isNotEmpty;
  int get itemCount => _recentlyViewedProducts.length;

  /// Initialize the provider by loading data from storage
  Future<void> initialize() async {
    await loadFromStorage();
  }

  /// Load recently viewed products from local storage
  Future<void> loadFromStorage() async {
    try {
      _setLoading(true);
      _clearError();

      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      List<Product> newProducts = [];
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        newProducts = jsonList
            .map((json) => Product.fromJson(json))
            .toList();
      }
      
      // Only update and notify if data actually changed
      if (_recentlyViewedProducts.length != newProducts.length ||
          !_productsEqual(_recentlyViewedProducts, newProducts)) {
        _recentlyViewedProducts = newProducts;
      }
      
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load recently viewed products: $e');
      _setLoading(false);
    }
  }

  /// Helper method to compare two product lists
  bool _productsEqual(List<Product> list1, List<Product> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) return false;
    }
    return true;
  }

  /// Save recently viewed products to local storage
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(
        _recentlyViewedProducts.map((product) => product.toJson()).toList(),
      );
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      debugPrint('Failed to save recently viewed products: $e');
    }
  }

  /// Add a product to recently viewed list
  Future<void> addProduct(Product product) async {
    try {
      // Remove the product if it already exists to avoid duplicates
      _recentlyViewedProducts.removeWhere((p) => p.id == product.id);
      
      // Add the product to the beginning of the list
      _recentlyViewedProducts.insert(0, product);
      
      // Keep only the latest items (limit the list size)
      if (_recentlyViewedProducts.length > _maxItems) {
        _recentlyViewedProducts = _recentlyViewedProducts.take(_maxItems).toList();
      }
      
      // Save to storage and notify listeners
      await _saveToStorage();
      notifyListeners();
    } catch (e) {
      _setError('Failed to add product to recently viewed: $e');
    }
  }

  /// Remove a product from recently viewed list
  Future<void> removeProduct(String productId) async {
    try {
      _recentlyViewedProducts.removeWhere((product) => product.id == productId);
      await _saveToStorage();
      notifyListeners();
    } catch (e) {
      _setError('Failed to remove product from recently viewed: $e');
    }
  }

  /// Clear all recently viewed products
  Future<void> clearAll() async {
    try {
      _recentlyViewedProducts.clear();
      await _saveToStorage();
      notifyListeners();
    } catch (e) {
      _setError('Failed to clear recently viewed products: $e');
    }
  }

  /// Get recently viewed products with limit
  List<Product> getRecentlyViewed({int? limit}) {
    if (limit != null && limit < _recentlyViewedProducts.length) {
      return _recentlyViewedProducts.take(limit).toList();
    }
    return _recentlyViewedProducts;
  }

  /// Check if a product is in recently viewed list
  bool isProductRecentlyViewed(String productId) {
    return _recentlyViewedProducts.any((product) => product.id == productId);
  }

  /// Refresh the recently viewed list
  Future<void> refresh() async {
    await loadFromStorage();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
} 