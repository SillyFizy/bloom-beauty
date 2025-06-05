import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/category_provider.dart';
import '../../constants/app_constants.dart';
import '../../widgets/category/category_selector.dart';
import '../../widgets/product/enhanced_product_card.dart';
import 'product_detail_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({Key? key}) : super(key: key);

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize category provider when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().initialize();
    });
  }

  // Helper function to navigate to product detail
  Future<void> _navigateToProductDetail(BuildContext context, Product product) async {
    try {
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error navigating to product detail: $e');
    }
  }

  void _showSortOptions(BuildContext context, CategoryProvider provider, bool isSmallScreen) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sort By',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            
            ...SortOption.values.map((option) => _buildSortOption(
              context,
              provider,
              option,
              _getSortOptionLabel(option),
              _getSortOptionIcon(option),
              isSmallScreen,
            )),
            
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Show filter options
  void _showFilterOptions(BuildContext context, CategoryProvider provider, bool isSmallScreen) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => Consumer<CategoryProvider>(
        builder: (context, categoryProvider, child) => Container(
          width: MediaQuery.of(context).size.width, // Full width from beginning of screen
          height: MediaQuery.of(context).size.height * 0.7, // Increased height for better space
          decoration: const BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header with drag handle
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppConstants.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // Title and Clear All
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter Products',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 20 : 22,
                        fontWeight: FontWeight.w700,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        categoryProvider.clearFilters();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        backgroundColor: AppConstants.accentColor.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'Clear All',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 15,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // Scrollable Filter Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price Range Filter
                      _buildResponsivePriceFilter(categoryProvider, isSmallScreen),
                      
                      SizedBox(height: isSmallScreen ? 20 : 24),
                      
                      // Rating Filter
                      _buildResponsiveRatingFilter(categoryProvider, isSmallScreen),
                      
                      SizedBox(height: isSmallScreen ? 16 : 20),
                    ],
                  ),
                ),
              ),
              
              // Fixed Apply Button at Bottom
              Container(
                padding: EdgeInsets.fromLTRB(
                  isSmallScreen ? 16 : 20,
                  isSmallScreen ? 12 : 16,
                  isSmallScreen ? 16 : 20,
                  MediaQuery.of(context).padding.bottom + (isSmallScreen ? 12 : 16),
                ),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceColor,
                  border: Border(
                    top: BorderSide(
                      color: AppConstants.borderColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.accentColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 16 : 18,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'Apply Filters (${categoryProvider.filteredProducts.length} products)',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Responsive Price Range Filter
  Widget _buildResponsivePriceFilter(CategoryProvider provider, bool isSmallScreen) {
    final priceRange = provider.availablePriceRange;
    final minPrice = priceRange['min'] ?? 0;
    final maxPrice = priceRange['max'] ?? 1000000;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              Icons.attach_money_rounded,
              color: AppConstants.accentColor,
              size: isSmallScreen ? 22 : 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Price Range',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textPrimary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        
        // Current selection display
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 16, 
            vertical: isSmallScreen ? 10 : 12,
          ),
          decoration: BoxDecoration(
            color: AppConstants.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppConstants.accentColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${provider.minPrice.toInt()} IQD',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 15,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 12, 
                  vertical: isSmallScreen ? 2 : 4,
                ),
                decoration: BoxDecoration(
                  color: AppConstants.accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'to',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '${provider.maxPrice.toInt()} IQD',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 15,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        
        // Range Slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: isSmallScreen ? 4 : 6,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: isSmallScreen ? 10 : 12),
            overlayShape: RoundSliderOverlayShape(overlayRadius: isSmallScreen ? 16 : 20),
            rangeThumbShape: RoundRangeSliderThumbShape(enabledThumbRadius: isSmallScreen ? 10 : 12),
          ),
          child: RangeSlider(
            values: RangeValues(
              provider.minPrice.clamp(minPrice, maxPrice),
              provider.maxPrice.clamp(minPrice, maxPrice),
            ),
            min: minPrice,
            max: maxPrice,
            divisions: 20,
            activeColor: AppConstants.accentColor,
            inactiveColor: AppConstants.borderColor.withValues(alpha: 0.3),
            onChanged: (RangeValues values) {
              provider.updatePriceRange(values.start, values.end);
            },
          ),
        ),
        
        // Min/Max labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${minPrice.toInt()} IQD',
                style: TextStyle(
                  fontSize: isSmallScreen ? 11 : 13,
                  color: AppConstants.textSecondary,
                ),
              ),
              Text(
                '${maxPrice.toInt()} IQD',
                style: TextStyle(
                  fontSize: isSmallScreen ? 11 : 13,
                  color: AppConstants.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Responsive Rating Filter (matching celebrity picks design)
  Widget _buildResponsiveRatingFilter(CategoryProvider provider, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              Icons.star_rounded,
              color: AppConstants.accentColor,
              size: isSmallScreen ? 22 : 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Minimum Rating',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textPrimary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        
        // Rating Buttons (exactly like celebrity picks screen)
        Wrap(
          spacing: isSmallScreen ? 8 : 12,
          runSpacing: isSmallScreen ? 8 : 12,
          children: [
            _buildCategoryRatingButton(provider, 0, 'All', isSmallScreen),
            _buildCategoryRatingButton(provider, 1, '1+ ⭐', isSmallScreen),
            _buildCategoryRatingButton(provider, 2, '2+ ⭐', isSmallScreen),
            _buildCategoryRatingButton(provider, 3, '3+ ⭐', isSmallScreen),
            _buildCategoryRatingButton(provider, 4, '4+ ⭐', isSmallScreen),
            _buildCategoryRatingButton(provider, 5, '5 ⭐', isSmallScreen),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryRatingButton(CategoryProvider provider, double rating, String label, bool isSmallScreen) {
    final isSelected = provider.minRating == rating;
    
    return GestureDetector(
      onTap: () => provider.updateRatingFilter(rating),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 16,
          vertical: isSmallScreen ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppConstants.accentColor 
              : AppConstants.accentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 24),
          border: Border.all(
            color: AppConstants.accentColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 13 : 15,
            fontWeight: FontWeight.w600,
            color: isSelected 
                ? Colors.white 
                : AppConstants.accentColor,
          ),
        ),
      ),
    );
  }

  Widget _buildSortOption(
    BuildContext context,
    CategoryProvider provider,
    SortOption option,
    String label,
    IconData icon,
    bool isSmallScreen,
  ) {
    final isSelected = provider.selectedSortOption == option;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppConstants.accentColor : AppConstants.textSecondary,
        size: isSmallScreen ? 20 : 22,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: isSmallScreen ? 14 : 16,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? AppConstants.accentColor : AppConstants.textPrimary,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: AppConstants.accentColor,
              size: isSmallScreen ? 20 : 22,
            )
          : null,
      onTap: () {
        provider.updateSortOption(option);
        Navigator.pop(context);
      },
    );
  }

  String _getSortOptionLabel(SortOption option) {
    switch (option) {
      case SortOption.newest:
        return 'Newest First';
      case SortOption.priceAscending:
        return 'Price: Low to High';
      case SortOption.priceDescending:
        return 'Price: High to Low';
      case SortOption.rating:
        return 'Highest Rated';
      case SortOption.popularity:
        return 'Most Popular';
      case SortOption.name:
        return 'Name A-Z';
    }
  }

  IconData _getSortOptionIcon(SortOption option) {
    switch (option) {
      case SortOption.newest:
        return Icons.fiber_new_rounded;
      case SortOption.priceAscending:
        return Icons.trending_up_rounded;
      case SortOption.priceDescending:
        return Icons.trending_down_rounded;
      case SortOption.rating:
        return Icons.star_rounded;
      case SortOption.popularity:
        return Icons.local_fire_department_rounded;
      case SortOption.name:
        return Icons.sort_by_alpha_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine responsive layout
        final screenWidth = constraints.maxWidth;
        final isSmallScreen = screenWidth < 600;
        final isMediumScreen = screenWidth >= 600 && screenWidth < 900;
        final isLargeScreen = screenWidth >= 900;
        
        // Grid configuration based on screen size
        final crossAxisCount = isSmallScreen ? 2 : (isMediumScreen ? 3 : 4);
        final childAspectRatio = isSmallScreen ? 0.68 : (isMediumScreen ? 0.70 : 0.72);
        
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Categories',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            elevation: 0,
            backgroundColor: AppConstants.surfaceColor,
            foregroundColor: AppConstants.textPrimary,
            actions: [
              Consumer<CategoryProvider>(
                builder: (context, categoryProvider, child) {
                  final hasActiveFilters = categoryProvider.minPrice > 0 ||
                                          categoryProvider.maxPrice < categoryProvider.availablePriceRange['max']! ||
                                          categoryProvider.minRating > 0;

                  return Row(
                    children: [
                      // Sort button
                      IconButton(
                        onPressed: () => _showSortOptions(context, categoryProvider, isSmallScreen),
                        icon: Icon(
                          Icons.sort_rounded,
                          color: AppConstants.textPrimary,
                          size: isSmallScreen ? 22 : 24,
                        ),
                        tooltip: 'Sort',
                      ),
                      
                      // Filter button with indicator
                      Stack(
                        children: [
                          IconButton(
                            onPressed: () => _showFilterOptions(context, categoryProvider, isSmallScreen),
                            icon: Icon(
                              hasActiveFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
                              color: hasActiveFilters ? AppConstants.accentColor : AppConstants.textPrimary,
                              size: isSmallScreen ? 22 : 24,
                            ),
                            tooltip: 'Filter',
                          ),
                          if (hasActiveFilters)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppConstants.accentColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          backgroundColor: AppConstants.backgroundColor,
          body: Consumer<CategoryProvider>(
            builder: (context, categoryProvider, child) {
              // Handle loading state
              if (categoryProvider.isLoading) {
                return _buildLoadingState(isSmallScreen);
              }

              // Handle error state
              if (categoryProvider.hasError) {
                return _buildErrorState(categoryProvider.error!, isSmallScreen);
              }

              return CustomScrollView(
                slivers: [
                  // Category Selector
                  SliverToBoxAdapter(
                    child: CategorySelector(isSmallScreen: isSmallScreen),
                  ),
                  
                  // Products Grid
                  _buildProductsGrid(
                    categoryProvider,
                    crossAxisCount,
                    childAspectRatio,
                    isSmallScreen,
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLoadingState(bool isSmallScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppConstants.accentColor,
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Text(
            'Loading products...',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: AppConstants.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, bool isSmallScreen) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: isSmallScreen ? 48 : 64,
              color: AppConstants.errorColor,
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              'Failed to load products',
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmallScreen ? 6 : 8),
            Text(
              error,
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 14,
                color: AppConstants.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
            ElevatedButton(
              onPressed: () => context.read<CategoryProvider>().refresh(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.accentColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 20 : 24,
                  vertical: isSmallScreen ? 10 : 12,
                ),
              ),
              child: Text(
                'Try Again',
                style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsGrid(
    CategoryProvider categoryProvider,
    int crossAxisCount,
    double childAspectRatio,
    bool isSmallScreen,
  ) {
    final products = categoryProvider.filteredProducts;

    if (products.isEmpty) {
      return SliverFillRemaining(
        child: _buildEmptyState(isSmallScreen),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: isSmallScreen ? 8 : 12,
          mainAxisSpacing: isSmallScreen ? 8 : 12,
          childAspectRatio: childAspectRatio,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final product = products[index];
            return EnhancedProductCard(
              product: product,
              isSmallScreen: isSmallScreen,
              onTap: () => _navigateToProductDetail(context, product),
              onFavorite: () {
                // TODO: Implement favorite functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Favorite feature coming soon!'),
                    backgroundColor: AppConstants.accentColor,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              isFavorite: false, // TODO: Implement favorite state
            );
          },
          childCount: products.length,
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isSmallScreen) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: isSmallScreen ? 64 : 80,
              color: AppConstants.textSecondary.withValues(alpha: 0.5),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              'No products found',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.w600,
                color: AppConstants.textSecondary,
              ),
            ),
            SizedBox(height: isSmallScreen ? 6 : 8),
            Text(
              'Try adjusting your filters or search criteria',
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 14,
                color: AppConstants.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
            ElevatedButton(
              onPressed: () => context.read<CategoryProvider>().clearFilters(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.accentColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 20 : 24,
                  vertical: isSmallScreen ? 10 : 12,
                ),
              ),
              child: Text(
                'Clear Filters',
                style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
