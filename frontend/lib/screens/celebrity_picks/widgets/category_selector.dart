import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../providers/celebrity_picks_provider.dart';

class CategorySelector extends StatelessWidget {
  final bool isSmallScreen;

  const CategorySelector({
    super.key,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CelebrityPicksProvider>(
      builder: (context, provider, child) {
        final categories = provider.categories;
        
        if (categories.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Browse by Category',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Browse Mode Toggle Dropdown
                  PopupMenuButton<BrowseMode>(
                    onSelected: (BrowseMode mode) {
                      provider.switchBrowseMode(mode);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppConstants.surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppConstants.borderColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_drop_down,
                        color: AppConstants.textPrimary,
                        size: isSmallScreen ? 28 : 32,
                      ),
                    ),
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem<BrowseMode>(
                        value: BrowseMode.celebrity,
                        child: Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: provider.browseMode == BrowseMode.celebrity 
                                  ? AppConstants.accentColor 
                                  : AppConstants.textSecondary,
                              size: isSmallScreen ? 18 : 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Browse by Celebrity',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: provider.browseMode == BrowseMode.celebrity 
                                    ? FontWeight.w600 
                                    : FontWeight.w500,
                                color: provider.browseMode == BrowseMode.celebrity 
                                    ? AppConstants.accentColor 
                                    : AppConstants.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem<BrowseMode>(
                        value: BrowseMode.category,
                        child: Row(
                          children: [
                            Icon(
                              Icons.category_rounded,
                              color: provider.browseMode == BrowseMode.category 
                                  ? AppConstants.accentColor 
                                  : AppConstants.textSecondary,
                              size: isSmallScreen ? 18 : 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Browse by Category',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: provider.browseMode == BrowseMode.category 
                                    ? FontWeight.w600 
                                    : FontWeight.w500,
                                color: provider.browseMode == BrowseMode.category 
                                    ? AppConstants.accentColor 
                                    : AppConstants.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: isSmallScreen ? 100 : 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length + 1, // +1 for "All" option
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // "All" option
                      return _buildCategoryItem(
                        context,
                        provider,
                        null,
                        'All',
                        'https://images.unsplash.com/photo-1556228453-efd6c1ff04f6?w=150&h=150&fit=crop',
                        isSmallScreen,
                      );
                    }
                    
                    final category = categories[index - 1];
                    return _buildCategoryItem(
                      context,
                      provider,
                      category.id,
                      category.name,
                      category.imageUrl,
                      isSmallScreen,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryItem(
    BuildContext context,
    CelebrityPicksProvider provider,
    String? categoryId,
    String displayName,
    String imageUrl,
    bool isSmallScreen,
  ) {
    final isSelected = provider.selectedCategoryId == categoryId;
    final size = isSmallScreen ? 65.0 : 75.0;
    
    return GestureDetector(
      onTap: () => provider.selectCategory(categoryId),
      child: Container(
        width: isSmallScreen ? 85 : 95,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            AnimatedContainer(
              duration: AppConstants.shortAnimation,
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected 
                      ? AppConstants.accentColor 
                      : AppConstants.borderColor.withValues(alpha: 0.3),
                  width: isSelected ? 3 : 2,
                ),
                boxShadow: isSelected 
                    ? [
                        BoxShadow(
                          color: AppConstants.accentColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ] 
                    : [],
              ),
              child: ClipOval(
                child: categoryId == null
                    ? _buildAllOption(isSmallScreen)
                    : _buildCategoryImage(imageUrl, displayName, isSmallScreen),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              displayName,
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected 
                    ? AppConstants.accentColor 
                    : AppConstants.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllOption(bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppConstants.accentColor.withValues(alpha: 0.8),
            AppConstants.favoriteColor.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.apps_rounded,
          color: AppConstants.surfaceColor,
          size: isSmallScreen ? 30 : 35,
        ),
      ),
    );
  }

  Widget _buildCategoryImage(String imageUrl, String name, bool isSmallScreen) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppConstants.favoriteColor.withValues(alpha: 0.6),
                AppConstants.favoriteColor.withValues(alpha: 0.3),
              ],
            ),
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'C',
              style: TextStyle(
                fontSize: isSmallScreen ? 24 : 30,
                fontWeight: FontWeight.bold,
                color: AppConstants.surfaceColor,
              ),
            ),
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          decoration: BoxDecoration(
            color: AppConstants.borderColor.withValues(alpha: 0.3),
          ),
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      (loadingProgress.expectedTotalBytes ?? 1)
                  : null,
              color: AppConstants.accentColor,
              strokeWidth: 2,
            ),
          ),
        );
      },
    );
  }
} 