import 'product_model.dart';

/// Celebrity model representing celebrity endorsers and their associated products
class Celebrity {
  final int id;
  final String firstName;
  final String lastName;
  final String? image;
  final String? testimonial;
  final Map<String, String> socialMediaLinks;
  final List<Product> recommendedProducts;
  final List<Product> morningRoutineProducts;
  final List<Product> eveningRoutineProducts;
  final String? bio;
  final String? profession;
  final int followerCount;
  final bool isVerified;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int totalPromotions;
  final int featuredPromotionsCount;

  Celebrity({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.image,
    this.testimonial,
    required this.socialMediaLinks,
    required this.recommendedProducts,
    required this.morningRoutineProducts,
    required this.eveningRoutineProducts,
    this.bio,
    this.profession,
    this.followerCount = 0,
    this.isVerified = false,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.totalPromotions = 0,
    this.featuredPromotionsCount = 0,
  });

  /// Getter to maintain compatibility with existing UI code
  String get name => '$firstName $lastName'.trim();
  String get fullName => name;

  /// Create Celebrity from JSON - updated for backend API
  factory Celebrity.fromJson(Map<String, dynamic> json) {
    return Celebrity(
      id: json['id'] as int,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      image: json['image'] as String?,
      testimonial: json['testimonial'] as String?,
      socialMediaLinks:
          Map<String, String>.from(json['social_media_links'] ?? {}),
      bio: json['bio'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      totalPromotions: json['total_promotions'] as int? ?? 0,
      featuredPromotionsCount: json['featured_promotions_count'] as int? ?? 0,
      // These will be populated by separate API calls
      recommendedProducts: [],
      morningRoutineProducts: [],
      eveningRoutineProducts: [],
      profession: null,
      followerCount: 0,
      isVerified: false,
    );
  }

  /// Convert Celebrity to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'full_name': name,
      'image': image,
      'testimonial': testimonial,
      'social_media_links': socialMediaLinks,
      'bio': bio,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'total_promotions': totalPromotions,
      'featured_promotions_count': featuredPromotionsCount,
      'recommended_products':
          recommendedProducts.map((product) => product.toJson()).toList(),
      'morning_routine_products':
          morningRoutineProducts.map((product) => product.toJson()).toList(),
      'evening_routine_products':
          eveningRoutineProducts.map((product) => product.toJson()).toList(),
      'profession': profession,
      'follower_count': followerCount,
      'is_verified': isVerified,
    };
  }

  /// Create a copy of Celebrity with updated fields
  Celebrity copyWith({
    int? id,
    String? firstName,
    String? lastName,
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
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? totalPromotions,
    int? featuredPromotionsCount,
  }) {
    return Celebrity(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      image: image ?? this.image,
      testimonial: testimonial ?? this.testimonial,
      socialMediaLinks: socialMediaLinks ?? this.socialMediaLinks,
      recommendedProducts: recommendedProducts ?? this.recommendedProducts,
      morningRoutineProducts:
          morningRoutineProducts ?? this.morningRoutineProducts,
      eveningRoutineProducts:
          eveningRoutineProducts ?? this.eveningRoutineProducts,
      bio: bio ?? this.bio,
      profession: profession ?? this.profession,
      followerCount: followerCount ?? this.followerCount,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalPromotions: totalPromotions ?? this.totalPromotions,
      featuredPromotionsCount:
          featuredPromotionsCount ?? this.featuredPromotionsCount,
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
    return allProducts
        .where((product) => product.categoryId == categoryId)
        .toList();
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

  /// Compatibility getter for lastUpdated
  DateTime? get lastUpdated => updatedAt;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Celebrity &&
        other.id == id &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.image == image &&
        other.testimonial == testimonial &&
        other.followerCount == followerCount &&
        other.isVerified == isVerified;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        firstName.hashCode ^
        lastName.hashCode ^
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

/// Statistics model for celebrity analytics
class CelebrityStatistics {
  final int totalCelebrities;
  final int totalProducts;
  final double averageProductsPerCelebrity;
  final Map<String, int> socialMediaPlatforms;

  CelebrityStatistics({
    required this.totalCelebrities,
    required this.totalProducts,
    required this.averageProductsPerCelebrity,
    required this.socialMediaPlatforms,
  });
}
