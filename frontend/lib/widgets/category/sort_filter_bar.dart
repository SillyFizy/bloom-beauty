import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../providers/category_provider.dart';

class SortFilterBar extends StatelessWidget {
  final bool isSmallScreen;

  const SortFilterBar({
    super.key,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isSmallScreen ? 8 : 12,
          ),
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            border: Border(
              bottom: BorderSide(
                color: AppConstants.borderColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Results count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${provider.filteredProducts.length} Products',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    if (provider.selectedCategory != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'in ${provider.selectedCategory!.name}',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 12,
                          color: AppConstants.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Sort button
              _buildSortButton(context, provider),
              
              SizedBox(width: isSmallScreen ? 8 : 12),
              
              // Filter button
              _buildFilterButton(context, provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortButton(BuildContext context, CategoryProvider provider) {
    return InkWell(
      onTap: () => _showSortOptions(context, provider),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 10 : 12,
          vertical: isSmallScreen ? 6 : 8,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppConstants.borderColor.withValues(alpha: 0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sort_rounded,
              size: isSmallScreen ? 16 : 18,
              color: AppConstants.textSecondary,
            ),
            SizedBox(width: isSmallScreen ? 4 : 6),
            Text(
              'Sort',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                fontWeight: FontWeight.w500,
                color: AppConstants.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context, CategoryProvider provider) {
    final hasActiveFilters = !provider.selectedFilters.contains(FilterOption.all) ||
                            provider.minPrice > 0 ||
                            provider.maxPrice < 1000000 ||
                            provider.minRating > 0;

    return InkWell(
      onTap: () => _showFilterOptions(context, provider),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 10 : 12,
          vertical: isSmallScreen ? 6 : 8,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasActiveFilters 
                ? AppConstants.accentColor
                : AppConstants.borderColor.withValues(alpha: 0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: hasActiveFilters 
              ? AppConstants.accentColor.withValues(alpha: 0.1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasActiveFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
              size: isSmallScreen ? 16 : 18,
              color: hasActiveFilters ? AppConstants.accentColor : AppConstants.textSecondary,
            ),
            SizedBox(width: isSmallScreen ? 4 : 6),
            Text(
              'Filter',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                fontWeight: FontWeight.w500,
                color: hasActiveFilters ? AppConstants.accentColor : AppConstants.textSecondary,
              ),
            ),
            if (hasActiveFilters) ...[
              SizedBox(width: isSmallScreen ? 3 : 4),
              Container(
                width: isSmallScreen ? 6 : 8,
                height: isSmallScreen ? 6 : 8,
decoration: const BoxDecoration(

                  color: AppConstants.accentColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSortOptions(BuildContext context, CategoryProvider provider) {
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
            )),
            
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showFilterOptions(BuildContext context, CategoryProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 18 : 20,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      provider.clearFilters();
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Clear All',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13 : 14,
                        color: AppConstants.accentColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Filter options
                    Text(
                      'Product Type',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    ...FilterOption.values.map((option) => _buildFilterOption(
                      provider,
                      option,
                      _getFilterOptionLabel(option),
                    )),
                    
                    const SizedBox(height: 24),
                    
                    // Price range
                    Text(
                      'Price Range',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPriceRangeSlider(provider),
                    
                    const SizedBox(height: 24),
                    
                    // Rating filter
                    Text(
                      'Minimum Rating',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRatingFilter(provider),
                  ],
                ),
              ),
            ],
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

  Widget _buildFilterOption(CategoryProvider provider, FilterOption option, String label) {
    final isSelected = provider.selectedFilters.contains(option);
    
    return CheckboxListTile(
      title: Text(
        label,
        style: TextStyle(
          fontSize: isSmallScreen ? 14 : 16,
          color: AppConstants.textPrimary,
        ),
      ),
      value: isSelected,
      activeColor: AppConstants.accentColor,
      onChanged: (value) => provider.toggleFilter(option),
      dense: true,
    );
  }

  Widget _buildPriceRangeSlider(CategoryProvider provider) {
    final priceRange = provider.availablePriceRange;
    final minPrice = priceRange['min'] ?? 0;
    final maxPrice = priceRange['max'] ?? 1000000;
    
    return Column(
      children: [
        RangeSlider(
          values: RangeValues(
            provider.minPrice.clamp(minPrice, maxPrice),
            provider.maxPrice.clamp(minPrice, maxPrice),
          ),
          min: minPrice,
          max: maxPrice,
          divisions: 20,
          activeColor: AppConstants.accentColor,
          inactiveColor: AppConstants.borderColor,
          onChanged: (RangeValues values) {
            provider.updatePriceRange(values.start, values.end);
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${provider.minPrice.toInt()} IQD',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  color: AppConstants.textSecondary,
                ),
              ),
              Text(
                '${provider.maxPrice.toInt()} IQD',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  color: AppConstants.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingFilter(CategoryProvider provider) {
    return Column(
      children: [
        Slider(
          value: provider.minRating,
          min: 0,
          max: 5,
          divisions: 5,
          activeColor: AppConstants.accentColor,
          inactiveColor: AppConstants.borderColor,
          onChanged: (value) => provider.updateRatingFilter(value),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0 stars',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  color: AppConstants.textSecondary,
                ),
              ),
              Text(
                '${provider.minRating.toStringAsFixed(1)} stars+',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  color: AppConstants.textSecondary,
                ),
              ),
              Text(
                '5 stars',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  color: AppConstants.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
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

  String _getFilterOptionLabel(FilterOption option) {
    switch (option) {
      case FilterOption.all:
        return 'All Products';
      case FilterOption.inStock:
        return 'In Stock';
      case FilterOption.discounted:
        return 'On Sale';
      case FilterOption.celebrityPicks:
        return 'Celebrity Picks';
      case FilterOption.featured:
        return 'Featured';
      case FilterOption.newArrivals:
        return 'New Arrivals';
      case FilterOption.bestselling:
        return 'Best Selling';
      case FilterOption.trending:
        return 'Trending';
    }
  }
} 
