import 'product_model.dart';

/// Celebrity model representing celebrity endorsers and their associated products
class Celebrity {
  final String id;
  final String name;
  final String image;
  final String? testimonial;
  final Map<String, String> socialMediaLinks;
  final List<Product> recommendedProducts;
  final List<Product> morningRoutineProducts;
  final List<Product> eveningRoutineProducts;
  final String? bio;
  final String? profession;
  final int followerCount;
  final bool isVerified;
  final DateTime? lastUpdated;

  Celebrity({
    required this.id,
    required this.name,
    required this.image,
    this.testimonial,
    required this.socialMediaLinks,
    required this.recommendedProducts,
    required this.morningRoutineProducts,
    required this.eveningRoutineProducts,
    this.bio,
    this.profession,
    this.followerCount = 0,
    this.isVerified = false,
    this.lastUpdated,
  });

  /// Create Celebrity from JSON
  factory Celebrity.fromJson(Map<String, dynamic> json) {
    return Celebrity(
      id: json['id'] as String,
      name: json['name'] as String,
      image: json['image'] as String,
      testimonial: json['testimonial'] as String?,
      socialMediaLinks: Map<String, String>.from(json['socialMediaLinks'] ?? {}),
      recommendedProducts: (json['recommendedProducts'] as List<dynamic>?)
          ?.map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      morningRoutineProducts: (json['morningRoutineProducts'] as List<dynamic>?)
          ?.map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      eveningRoutineProducts: (json['eveningRoutineProducts'] as List<dynamic>?)
          ?.map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      bio: json['bio'] as String?,
      profession: json['profession'] as String?,
      followerCount: json['followerCount'] as int? ?? 0,
      isVerified: json['isVerified'] as bool? ?? false,
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
    );
  }

  /// Convert Celebrity to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'testimonial': testimonial,
      'socialMediaLinks': socialMediaLinks,
      'recommendedProducts': recommendedProducts.map((product) => product.toJson()).toList(),
      'morningRoutineProducts': morningRoutineProducts.map((product) => product.toJson()).toList(),
      'eveningRoutineProducts': eveningRoutineProducts.map((product) => product.toJson()).toList(),
      'bio': bio,
      'profession': profession,
      'followerCount': followerCount,
      'isVerified': isVerified,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  /// Create a copy of Celebrity with updated fields
  Celebrity copyWith({
    String? id,
    String? name,
    String? image,
    String? testimonial,
    Map<String, String>? socialMediaLinks,
    List<Product>? recommendedProducts,
    List<Product>? morningRoutineProducts,
    List<Product>? eveningRoutineProducts,
    String? bio,
    String? profession,
    int? followerCount,
    bool? isVerified,
    DateTime? lastUpdated,
  }) {
    return Celebrity(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      testimonial: testimonial ?? this.testimonial,
      socialMediaLinks: socialMediaLinks ?? this.socialMediaLinks,
      recommendedProducts: recommendedProducts ?? this.recommendedProducts,
      morningRoutineProducts: morningRoutineProducts ?? this.morningRoutineProducts,
      eveningRoutineProducts: eveningRoutineProducts ?? this.eveningRoutineProducts,
      bio: bio ?? this.bio,
      profession: profession ?? this.profession,
      followerCount: followerCount ?? this.followerCount,
      isVerified: isVerified ?? this.isVerified,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Get all products associated with this celebrity
  List<Product> get allProducts {
    final allProducts = <String, Product>{};
    
    // Add recommended products
    for (final product in recommendedProducts) {
      allProducts[product.id] = product;
    }
    
    // Add morning routine products
    for (final product in morningRoutineProducts) {
      allProducts[product.id] = product;
    }
    
    // Add evening routine products
    for (final product in eveningRoutineProducts) {
      allProducts[product.id] = product;
    }
    
    return allProducts.values.toList();
  }

  /// Get total number of products associated with this celebrity
  int get totalProductCount => allProducts.length;

  /// Check if celebrity has products in a specific category
  bool hasProductsInCategory(String categoryId) {
    return allProducts.any((product) => product.categoryId == categoryId);
  }

  /// Get products by category
  List<Product> getProductsByCategory(String categoryId) {
    return allProducts.where((product) => product.categoryId == categoryId).toList();
  }

  /// Get top rated products
  List<Product> get topRatedProducts {
    final products = List<Product>.from(allProducts);
    products.sort((a, b) => b.rating.compareTo(a.rating));
    return products.take(3).toList();
  }

  /// Check if celebrity has social media presence on specific platform
  bool hasSocialMediaPlatform(String platform) {
    return socialMediaLinks.containsKey(platform.toLowerCase());
  }

  /// Get formatted follower count
  String get formattedFollowerCount {
    if (followerCount >= 1000000) {
      return '${(followerCount / 1000000).toStringAsFixed(1)}M';
    } else if (followerCount >= 1000) {
      return '${(followerCount / 1000).toStringAsFixed(1)}K';
    } else {
      return followerCount.toString();
    }
  }

  /// Get the celebrity's pick product (first recommended product)
  Product? getCelebrityPickProduct() {
    if (recommendedProducts.isNotEmpty) {
      return recommendedProducts.first;
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Celebrity &&
        other.id == id &&
        other.name == name &&
        other.image == image &&
        other.testimonial == testimonial &&
        other.followerCount == followerCount &&
        other.isVerified == isVerified;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        image.hashCode ^
        testimonial.hashCode ^
        followerCount.hashCode ^
        isVerified.hashCode;
  }

  @override
  String toString() {
    return 'Celebrity(id: $id, name: $name, followerCount: $followerCount, isVerified: $isVerified, totalProducts: $totalProductCount)';
  }
} 
