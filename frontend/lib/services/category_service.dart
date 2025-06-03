import '../models/category_model.dart';

class CategoryService {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  /// Get all available categories
  Future<List<Category>> getAllCategories() async {
    // Simulating async operation
    await Future.delayed(const Duration(milliseconds: 100));
    
    return [
      Category(
        id: '1',
        name: 'Skincare',
        description: 'Premium skincare products for healthy, glowing skin',
        imageUrl: 'https://images.unsplash.com/photo-1556228453-efd6c1ff04f6?w=400&h=400&fit=crop',
      ),
      Category(
        id: '2',
        name: 'Makeup',
        description: 'Professional makeup products for all occasions',
        imageUrl: 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=400&h=400&fit=crop',
      ),
      Category(
        id: '3',
        name: 'Lipstick',
        description: 'Luxurious lipsticks in various shades and finishes',
        imageUrl: 'https://images.unsplash.com/photo-1586297135537-94bc9ba060aa?w=400&h=400&fit=crop',
      ),
    ];
  }

  /// Get category by ID
  Future<Category?> getCategoryById(String categoryId) async {
    final categories = await getAllCategories();
    try {
      return categories.firstWhere((category) => category.id == categoryId);
    } catch (e) {
      return null;
    }
  }

  /// Get popular categories (for display purposes)
  Future<List<Category>> getPopularCategories() async {
    return await getAllCategories();
  }
} 