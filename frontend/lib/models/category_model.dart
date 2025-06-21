class Category {
  final int id;
  final String name;
  final String description;
  final String imageUrl;
  final int? parentId;
  final String? parentName;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Category>? subcategories;

  Category({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    this.parentId,
    this.parentName,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.subcategories,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image'] ?? _getPlaceholderImage(json['name'] ?? ''),
      parentId: json['parent'],
      parentName: json['parent_name'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      subcategories: json['subcategories'] != null
          ? (json['subcategories'] as List)
              .map((e) => Category.fromJson(e))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': imageUrl,
      'parent': parentId,
      'parent_name': parentName,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'subcategories': subcategories?.map((e) => e.toJson()).toList(),
    };
  }

  // Generate placeholder image URL from backend media folder
  static String _getPlaceholderImage(String categoryName) {
    // Use different placeholder images based on category name
    final imageMap = {
      'skincare':
          '/media/products/tiana-eyeshadow-palette_1_product_33_20250507_195811.jpg',
      'makeup':
          '/media/products/yerimua-shadow-and-face-palette_1_product_353_20250508_220529.jpg',
      'lipstick':
          '/media/products/yerimua-bad-lip-duo_1_product_350_20250508_220246.jpg',
      'mascara':
          '/media/products/volumizing-mascara_1_product_456_20250509_205844.jpg',
      'eyeshadow':
          '/media/products/tease-me-shadow-palette_1_product_460_20250509_210720.jpg',
      'blush':
          '/media/products/stay-blushing-cute-lip-and-cheek-balm_1_product_299_20250508_213502.jpg',
      'palette':
          '/media/products/sand-snatchural-palette_1_product_445_20250509_204951.jpg',
    };

    final lowerName = categoryName.toLowerCase();
    for (final key in imageMap.keys) {
      if (lowerName.contains(key)) {
        return imageMap[key]!;
      }
    }

    // Default placeholder
    return '/media/products/tiana-eyeshadow-palette_1_product_33_20250507_195811.jpg';
  }
}
