class ProductVariant {
  final String id;
  final String name;
  final String color;
  final List<String> images;
  final double? priceAdjustment; // Additional price for this variant

  ProductVariant({
    required this.id,
    required this.name,
    required this.color,
    required this.images,
    this.priceAdjustment,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'],
      name: json['name'],
      color: json['color'],
      images: List<String>.from(json['images']),
      priceAdjustment: json['price_adjustment']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'images': images,
      'price_adjustment': priceAdjustment,
    };
  }
}

class ProductReview {
  final String id;
  final String userId;
  final String userName;
  final String userImage;
  final double rating;
  final String comment;
  final DateTime date;

  ProductReview({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.rating,
    required this.comment,
    required this.date,
  });

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    return ProductReview(
      id: json['id'],
      userId: json['user_id'],
      userName: json['user_name'],
      userImage: json['user_image'],
      rating: json['rating'].toDouble(),
      comment: json['comment'],
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_image': userImage,
      'rating': rating,
      'comment': comment,
      'date': date.toIso8601String(),
    };
  }
}

class CelebrityEndorsement {
  final String celebrityName;
  final String celebrityImage;
  final String? testimonial;

  CelebrityEndorsement({
    required this.celebrityName,
    required this.celebrityImage,
    this.testimonial,
  });

  factory CelebrityEndorsement.fromJson(Map<String, dynamic> json) {
    return CelebrityEndorsement(
      celebrityName: json['celebrity_name'],
      celebrityImage: json['celebrity_image'],
      testimonial: json['testimonial'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'celebrity_name': celebrityName,
      'celebrity_image': celebrityImage,
      'testimonial': testimonial,
    };
  }
}

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
  final int beautyPoints;
  final List<ProductVariant> variants;
  final List<ProductReview> reviews;
  final CelebrityEndorsement? celebrityEndorsement;

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
    required this.beautyPoints,
    this.variants = const [],
    this.reviews = const [],
    this.celebrityEndorsement,
  });

  // Get current price based on selected variant
  double getCurrentPrice([ProductVariant? selectedVariant]) {
    double basePrice = discountPrice ?? price;
    if (selectedVariant?.priceAdjustment != null) {
      basePrice += selectedVariant!.priceAdjustment!;
    }
    return basePrice;
  }

  // Get current images based on selected variant
  List<String> getCurrentImages([ProductVariant? selectedVariant]) {
    if (selectedVariant != null && selectedVariant.images.isNotEmpty) {
      return selectedVariant.images;
    }
    return images;
  }

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
      beautyPoints: json['beauty_points'] ?? 0,
      variants: json['variants'] != null
          ? (json['variants'] as List)
              .map((v) => ProductVariant.fromJson(v))
              .toList()
          : [],
      reviews: json['reviews'] != null
          ? (json['reviews'] as List)
              .map((r) => ProductReview.fromJson(r))
              .toList()
          : [],
      celebrityEndorsement: json['celebrity_endorsement'] != null
          ? CelebrityEndorsement.fromJson(json['celebrity_endorsement'])
          : null,
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
      'beauty_points': beautyPoints,
      'variants': variants.map((v) => v.toJson()).toList(),
      'reviews': reviews.map((r) => r.toJson()).toList(),
      'celebrity_endorsement': celebrityEndorsement?.toJson(),
    };
  }
}
