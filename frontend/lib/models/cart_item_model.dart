import 'product_model.dart';

class CartItem {
  final String id;
  final Product product;
  final int quantity;
  final String? selectedVariant;

  CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    this.selectedVariant,
  });

  double get totalPrice => product.discountPrice != null 
    ? (product.discountPrice! * quantity) 
    : (product.price * quantity);

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      product: Product.fromJson(json['product']),
      quantity: json['quantity'],
      selectedVariant: json['selected_variant'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'quantity': quantity,
      'selected_variant': selectedVariant,
    };
  }
}
