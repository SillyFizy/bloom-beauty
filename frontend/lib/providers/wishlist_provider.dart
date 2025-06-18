import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/product_model.dart';
import '../models/wishlist_item_model.dart';
import '../services/api_service.dart';

class WishlistProvider extends ChangeNotifier {
  final List<WishlistItem> _items = [];
  static const String _wishlistStorageKey = 'wishlist_items';
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Getters
  List<WishlistItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.length;
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get isInitialized => _isInitialized;

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

  // Initialize wishlist from storage and sync with backend
  Future<void> loadWishlistFromStorage() async {
    if (_isInitialized) return;

    try {
      _setLoading(true);
      _clearError();

      // Load from local storage first for immediate UI update
      final prefs = await SharedPreferences.getInstance();
      final wishlistJson = prefs.getString(_wishlistStorageKey);

      if (wishlistJson != null) {
        final List<dynamic> wishlistList = json.decode(wishlistJson);
        _items.clear();
        _items.addAll(
            wishlistList.map((item) => WishlistItem.fromJson(item)).toList());
        debugPrint('Loaded ${_items.length} items from local storage');
        notifyListeners(); // Update UI immediately with local data
      }

      // Then sync with backend for fresh data
      await _syncWithBackend();
      _isInitialized = true;
    } catch (e) {
      _setError('Error loading wishlist: $e');
      debugPrint('Error loading wishlist: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Backend synchronization method
  Future<void> _syncWithBackend() async {
    try {
      // Get wishlist from backend
      final response = await ApiService.getWishlist();
      final List<dynamic> backendItems =
          response['results'] ?? response['data'] ?? [];

      if (backendItems.isNotEmpty) {
        // Convert backend response to wishlist items
        final List<WishlistItem> newItems = [];

        for (final item in backendItems) {
          try {
            // Backend might return different structure
            final productData = item['product'] ?? item;
            final product = Product.fromJson(productData);
            final wishlistItem = WishlistItem.fromProduct(product);
            newItems.add(wishlistItem);
          } catch (e) {
            debugPrint('Error parsing wishlist item: $e');
            continue;
          }
        }

        // Update local wishlist with backend data
        _items.clear();
        _items.addAll(newItems);

        // Save updated data to local storage
        await _saveWishlistToStorage();

        debugPrint('Synced ${_items.length} items from backend');
      }

      notifyListeners();
    } catch (e) {
      // Don't throw error on sync failure - local data is still valid
      debugPrint('Backend sync failed (using local data): $e');
    }
  }

  // Save wishlist to local storage
  Future<void> _saveWishlistToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wishlistJson =
          json.encode(_items.map((item) => item.toJson()).toList());
      await prefs.setString(_wishlistStorageKey, wishlistJson);
      debugPrint('Saved ${_items.length} items to local storage');
    } catch (e) {
      debugPrint('Error saving wishlist to storage: $e');
      // Don't throw error here as it shouldn't block the UI operation
    }
  }

  // Add product to wishlist with backend sync
  Future<bool> addToWishlist(Product product) async {
    try {
      // Check if already in wishlist
      if (isInWishlist(product.id)) {
        debugPrint('Product ${product.name} is already in wishlist');
        return false;
      }

      // Optimistic update - add to local list first
      final wishlistItem = WishlistItem.fromProduct(product);
      _items.add(wishlistItem);
      notifyListeners(); // Update UI immediately

      // Try to sync with backend
      try {
        await ApiService.addToWishlist(product.id);
        debugPrint('Added ${product.name} to backend wishlist');
      } catch (e) {
        debugPrint('Backend add failed (keeping local): $e');
        // Keep the item locally even if backend fails
      }

      // Save to local storage
      await _saveWishlistToStorage();

      debugPrint('Added ${product.name} to wishlist');
      return true;
    } catch (e) {
      // Remove from local list if there was an error
      _items.removeWhere((item) => item.product.id == product.id);
      _setError('Error adding to wishlist: $e');
      debugPrint('Error adding to wishlist: $e');
      notifyListeners();
      return false;
    }
  }

  // Remove product from wishlist with backend sync
  Future<bool> removeFromWishlist(String productId) async {
    final removedItems =
        _items.where((item) => item.product.id == productId).toList();

    try {
      final initialLength = _items.length;

      // Optimistic update - remove from local list first
      _items.removeWhere((item) => item.product.id == productId);
      notifyListeners(); // Update UI immediately

      if (_items.length < initialLength) {
        // Try to sync with backend
        try {
          await ApiService.removeFromWishlist(productId);
          debugPrint('Removed product $productId from backend wishlist');
        } catch (e) {
          debugPrint('Backend remove failed (keeping local change): $e');
          // Keep the local change even if backend fails
        }

        // Save to local storage
        await _saveWishlistToStorage();

        debugPrint('Removed product $productId from wishlist');
        return true;
      } else {
        debugPrint('Product $productId not found in wishlist');
        return false;
      }
    } catch (e) {
      // Restore removed items if there was an error
      for (final item in removedItems) {
        if (!_items.contains(item)) {
          _items.add(item);
        }
      }
      _setError('Error removing from wishlist: $e');
      debugPrint('Error removing from wishlist: $e');
      notifyListeners();
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

  // Clear entire wishlist with backend sync
  Future<void> clearWishlist() async {
    try {
      final oldItems = List<WishlistItem>.from(_items);

      // Optimistic update
      _items.clear();
      notifyListeners();

      // Try to clear on backend (bulk operation might not be available)
      try {
        for (final item in oldItems) {
          await ApiService.removeFromWishlist(item.product.id);
        }
        debugPrint('Cleared wishlist on backend');
      } catch (e) {
        debugPrint('Backend clear failed (keeping local change): $e');
      }

      await _saveWishlistToStorage();
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
    return _items
        .where((item) => item.product.categoryId == categoryId)
        .toList();
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

  // Refresh wishlist (reload from storage and sync with backend)
  Future<void> refresh() async {
    _isInitialized = false; // Force re-initialization
    await loadWishlistFromStorage();
  }

  // Force sync with backend (public method)
  Future<void> syncWithBackend() async {
    try {
      _setLoading(true);
      _clearError();
      await _syncWithBackend();
    } catch (e) {
      _setError('Error syncing with backend: $e');
      debugPrint('Error syncing with backend: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Clear cache and reinitialize
  Future<void> clearCache() async {
    _items.clear();
    _isInitialized = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_wishlistStorageKey);
    notifyListeners();
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
      final importedItems =
          itemsData.map((item) => WishlistItem.fromJson(item)).toList();

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
