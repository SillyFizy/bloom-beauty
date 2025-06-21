import '../models/category_model.dart';
import 'api_service.dart';

class CategoryService {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  /// Get all available categories from backend
  Future<List<Category>> getAllCategories() async {
    try {
      final response = await ApiService.get('/products/categories/');

      // Handle different response formats
      List<dynamic> categoriesJson;
      if (response['results'] != null) {
        // Paginated response
        categoriesJson = response['results'] as List<dynamic>;
      } else if (response['data'] != null) {
        // Data wrapped response
        categoriesJson = response['data'] as List<dynamic>;
      } else {
        // Fallback - empty list
        categoriesJson = [];
      }

      return categoriesJson
          .map((json) => Category.fromJson(json as Map<String, dynamic>))
          .where(
              (category) => category.isActive) // Only return active categories
          .toList();
    } catch (e) {
      // Log error for debugging
      print('Error fetching categories: $e');

      // Return empty list on error to prevent app crashes
      // In production, you might want to show an error state
      return [];
    }
  }

  /// Get category by ID from backend
  Future<Category?> getCategoryById(int categoryId) async {
    try {
      final response =
          await ApiService.get('/products/categories/$categoryId/');
      return Category.fromJson(response);
    } catch (e) {
      print('Error fetching category by ID: $e');
      return null;
    }
  }

  /// Get popular categories (same as all categories for now)
  Future<List<Category>> getPopularCategories() async {
    return await getAllCategories();
  }

  /// Get categories with parent-child relationships
  Future<List<Category>> getCategoriesWithHierarchy() async {
    try {
      final allCategories = await getAllCategories();

      // Filter to get only parent categories (no parent_id)
      final parentCategories =
          allCategories.where((category) => category.parentId == null).toList();

      // For each parent category, find its subcategories
      for (final parent in parentCategories) {
        final subcategories = allCategories
            .where((category) => category.parentId == parent.id)
            .toList();

        if (subcategories.isNotEmpty) {
          // Create a new Category instance with subcategories
          final index = parentCategories.indexOf(parent);
          parentCategories[index] = Category(
            id: parent.id,
            name: parent.name,
            description: parent.description,
            imageUrl: parent.imageUrl,
            parentId: parent.parentId,
            parentName: parent.parentName,
    
            isActive: parent.isActive,
            createdAt: parent.createdAt,
            updatedAt: parent.updatedAt,
            subcategories: subcategories,
          );
        }
      }

      return parentCategories;
    } catch (e) {
      print('Error fetching categories with hierarchy: $e');
      return [];
    }
  }
} 
