import 'product_model.dart';

class Celebrity {
  final String id;
  final String name;
  final String image;
  final String testimonial;
  final Map<String, String> socialMediaLinks;
  final List<Product> recommendedProducts;
  final List<Product> morningRoutineProducts;
  final List<Product> eveningRoutineProducts;
  final String bio;
  final String profession;

  Celebrity({
    required this.id,
    required this.name,
    required this.image,
    required this.testimonial,
    required this.socialMediaLinks,
    required this.recommendedProducts,
    required this.morningRoutineProducts,
    required this.eveningRoutineProducts,
    required this.bio,
    required this.profession,
  });

  // Get the celebrity's pick product (first recommended product)
  Product? getCelebrityPickProduct() {
    return recommendedProducts.isNotEmpty ? recommendedProducts.first : null;
  }

  factory Celebrity.fromJson(Map<String, dynamic> json) {
    return Celebrity(
      id: json['id'],
      name: json['name'],
      image: json['image'],
      testimonial: json['testimonial'],
      socialMediaLinks: Map<String, String>.from(json['socialMediaLinks'] ?? {}),
      recommendedProducts: json['recommendedProducts'] != null
          ? (json['recommendedProducts'] as List)
              .map((p) => Product.fromJson(p))
              .toList()
          : [],
      morningRoutineProducts: json['morningRoutineProducts'] != null
          ? (json['morningRoutineProducts'] as List)
              .map((p) => Product.fromJson(p))
              .toList()
          : [],
      eveningRoutineProducts: json['eveningRoutineProducts'] != null
          ? (json['eveningRoutineProducts'] as List)
              .map((p) => Product.fromJson(p))
              .toList()
          : [],
      bio: json['bio'] ?? '',
      profession: json['profession'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'testimonial': testimonial,
      'socialMediaLinks': socialMediaLinks,
      'recommendedProducts': recommendedProducts.map((p) => p.toJson()).toList(),
      'morningRoutineProducts': morningRoutineProducts.map((p) => p.toJson()).toList(),
      'eveningRoutineProducts': eveningRoutineProducts.map((p) => p.toJson()).toList(),
      'bio': bio,
      'profession': profession,
    };
  }
} 