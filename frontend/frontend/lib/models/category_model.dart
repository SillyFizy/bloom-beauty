class Category {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final List<Category>? subcategories;

  Category({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    this.subcategories,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['image_url'],
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
      'image_url': imageUrl,
      'subcategories': subcategories?.map((e) => e.toJson()).toList(),
    };
  }
}
