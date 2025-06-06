 
import 'product_model.dart';

class WishlistItem {
  final String id;
  final Product product;
  final DateTime dateAdded;

  WishlistItem({
    required this.id,
    required this.product,
    required this.dateAdded,
  });

  // Factory constructor for creating from JSON (for local storage and API)
  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      id: json['id'] as String,
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      dateAdded: DateTime.parse(json['dateAdded'] as String),
    );
  }

  // Convert to JSON for storage and API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'dateAdded': dateAdded.toIso8601String(),
    };
  }

  // Factory constructor for creating from product
  factory WishlistItem.fromProduct(Product product) {
    return WishlistItem(
      id: _generateId(product.id),
      product: product,
      dateAdded: DateTime.now(),
    );
  }

  // Generate unique ID for wishlist item
  static String _generateId(String productId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${productId}_$timestamp';
  }

  // Equality and hashCode for Set operations
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WishlistItem &&
        other.product.id == product.id;
  }

  @override
  int get hashCode => product.id.hashCode;

  @override
  String toString() {
    return 'WishlistItem(id: $id, productId: ${product.id}, productName: ${product.name}, dateAdded: $dateAdded)';
  }

  // Copy with method for updates
  WishlistItem copyWith({
    String? id,
    Product? product,
    DateTime? dateAdded,
  }) {
    return WishlistItem(
      id: id ?? this.id,
      product: product ?? this.product,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }
} 
