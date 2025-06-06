import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/product_model.dart';
import '../models/wishlist_item_model.dart';

class WishlistProvider extends ChangeNotifier {
  final List<WishlistItem> _items = [];
  static const String _wishlistStorageKey = 'wishlist_items';
  bool _isLoading = false;
  String? _error;

  // Getters
  List<WishlistItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.length;
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;

  // Check if a product is in wishlist
  bool isInWishlist(String productId) {
    return _items.any((item) => item.product.id == productId);
  }

  // Get wishlist item by product ID
  WishlistItem? getWishlistItem(String productId) {
    try {
      return _items.firstWhere((item) => item.product.id == productId);
    } catch (e) {
      return null;
    }
  }

  // Get products sorted by date added (newest first)
  List<Product> get products {
    final sortedItems = List<WishlistItem>.from(_items)
      ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    return sortedItems.map((item) => item.product).toList();
  }

  // Get products sorted by date added (oldest first)
  List<Product> get productsOldestFirst {
    final sortedItems = List<WishlistItem>.from(_items)
      ..sort((a, b) => a.dateAdded.compareTo(b.dateAdded));
    return sortedItems.map((item) => item.product).toList();
  }

  // Get products sorted by name
  List<Product> get productsSortedByName {
    final sortedItems = List<WishlistItem>.from(_items)
      ..sort((a, b) => a.product.name.compareTo(b.product.name));
    return sortedItems.map((item) => item.product).toList();
  }

  // Initialize wishlist from local storage
  Future<void> loadWishlistFromStorage() async {
    try {
      _setLoading(true);
      _clearError();
      
      final prefs = await SharedPreferences.getInstance();
      final wishlistJson = prefs.getString(_wishlistStorageKey);
      
      if (wishlistJson != null) {
        final List<dynamic> wishlistList = json.decode(wishlistJson);
        _items.clear();
        _items.addAll(
          wishlistList.map((item) => WishlistItem.fromJson(item)).toList()
        );
        debugPrint('Loaded ${_items.length} items from wishlist storage');
      }
    } catch (e) {
      _setError('Error loading wishlist from storage: $e');
      debugPrint('Error loading wishlist from storage: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Save wishlist to local storage
  Future<void> _saveWishlistToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wishlistJson = json.encode(_items.map((item) => item.toJson()).toList());
      await prefs.setString(_wishlistStorageKey, wishlistJson);
      debugPrint('Saved ${_items.length} items to wishlist storage');
    } catch (e) {
      debugPrint('Error saving wishlist to storage: $e');
      // Don't throw error here as it shouldn't block the UI operation
    }
  }

  // Add product to wishlist
  Future<bool> addToWishlist(Product product) async {
    try {
      // Check if already in wishlist
      if (isInWishlist(product.id)) {
        debugPrint('Product ${product.name} is already in wishlist');
        return false;
      }

      // Add to wishlist
      final wishlistItem = WishlistItem.fromProduct(product);
      _items.add(wishlistItem);
      
      // Save to storage
      await _saveWishlistToStorage();
      
      // Notify listeners
      notifyListeners();
      
      debugPrint('Added ${product.name} to wishlist');
      return true;
    } catch (e) {
      _setError('Error adding to wishlist: $e');
      debugPrint('Error adding to wishlist: $e');
      return false;
    }
  }

  // Remove product from wishlist
  Future<bool> removeFromWishlist(String productId) async {
    try {
      final initialLength = _items.length;
      _items.removeWhere((item) => item.product.id == productId);
      
      if (_items.length < initialLength) {
        // Save to storage
        await _saveWishlistToStorage();
        
        // Notify listeners
        notifyListeners();
        
        debugPrint('Removed product $productId from wishlist');
        return true;
      } else {
        debugPrint('Product $productId not found in wishlist');
        return false;
      }
    } catch (e) {
      _setError('Error removing from wishlist: $e');
      debugPrint('Error removing from wishlist: $e');
      return false;
    }
  }

  // Toggle product in wishlist
  Future<bool> toggleWishlist(Product product) async {
    if (isInWishlist(product.id)) {
      return await removeFromWishlist(product.id);
    } else {
      return await addToWishlist(product);
    }
  }

  // Clear entire wishlist
  Future<void> clearWishlist() async {
    try {
      _items.clear();
      await _saveWishlistToStorage();
      notifyListeners();
      debugPrint('Cleared entire wishlist');
    } catch (e) {
      _setError('Error clearing wishlist: $e');
      debugPrint('Error clearing wishlist: $e');
    }
  }

  // Get wishlist count for a specific category
  int getWishlistCountByCategory(String categoryId) {
    return _items.where((item) => item.product.categoryId == categoryId).length;
  }

  // Get wishlist items by category
  List<WishlistItem> getWishlistItemsByCategory(String categoryId) {
    return _items.where((item) => item.product.categoryId == categoryId).toList();
  }

  // Search wishlist items
  List<WishlistItem> searchWishlist(String query) {
    if (query.isEmpty) return _items;
    
    final lowerQuery = query.toLowerCase();
    return _items.where((item) {
      return item.product.name.toLowerCase().contains(lowerQuery) ||
             item.product.brand.toLowerCase().contains(lowerQuery) ||
             item.product.description.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Refresh wishlist (useful for backend sync)
  Future<void> refresh() async {
    await loadWishlistFromStorage();
  }

  // Future: Sync with backend
  Future<void> syncWithBackend() async {
    // TODO: Implement backend synchronization
    // This method is ready for backend integration
    try {
      _setLoading(true);
      _clearError();
      
      // Example implementation:
      // 1. Get user's wishlist from backend
      // 2. Merge with local wishlist
      // 3. Upload local changes to backend
      // 4. Update local storage with merged data
      
      debugPrint('Backend sync not yet implemented');
    } catch (e) {
      _setError('Error syncing with backend: $e');
      debugPrint('Error syncing with backend: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Debug method to log wishlist contents
  void debugPrintWishlist() {
    debugPrint('=== WISHLIST CONTENTS ===');
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      debugPrint('[$i] ID: ${item.id}');
      debugPrint('    Product: ${item.product.name} (${item.product.id})');
      debugPrint('    Date Added: ${item.dateAdded}');
      debugPrint('    ---');
    }
    debugPrint('Total items: ${_items.length}');
    debugPrint('========================');
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  // Export wishlist data (for backup or sharing)
  Map<String, dynamic> exportWishlistData() {
    return {
      'items': _items.map((item) => item.toJson()).toList(),
      'exportDate': DateTime.now().toIso8601String(),
      'itemCount': _items.length,
    };
  }

  // Import wishlist data (for restore)
  Future<bool> importWishlistData(Map<String, dynamic> data) async {
    try {
      final List<dynamic> itemsData = data['items'] as List<dynamic>;
      final importedItems = itemsData.map((item) => WishlistItem.fromJson(item)).toList();
      
      _items.clear();
      _items.addAll(importedItems);
      
      await _saveWishlistToStorage();
      notifyListeners();
      
      debugPrint('Imported ${_items.length} items to wishlist');
      return true;
    } catch (e) {
      _setError('Error importing wishlist data: $e');
      debugPrint('Error importing wishlist data: $e');
      return false;
    }
  }
} 