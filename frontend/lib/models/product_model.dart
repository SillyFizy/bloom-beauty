class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? discountPrice;
  final List<String> images;
  final String categoryId;
  final String brand;
  final double rating;
  final int reviewCount;
  final bool isInStock;
  final List<String> ingredients;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.discountPrice,
    required this.images,
    required this.categoryId,
    required this.brand,
    required this.rating,
    required this.reviewCount,
    required this.isInStock,
    required this.ingredients,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: json['price'].toDouble(),
      discountPrice: json['discount_price']?.toDouble(),
      images: List<String>.from(json['images']),
      categoryId: json['category_id'],
      brand: json['brand'],
      rating: json['rating'].toDouble(),
      reviewCount: json['review_count'],
      isInStock: json['is_in_stock'],
      ingredients: List<String>.from(json['ingredients']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'discount_price': discountPrice,
      'images': images,
      'category_id': categoryId,
      'brand': brand,
      'rating': rating,
      'review_count': reviewCount,
      'is_in_stock': isInStock,
      'ingredients': ingredients,
    };
  }
}
