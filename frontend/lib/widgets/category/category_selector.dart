import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../constants/app_constants.dart';
import '../../providers/category_provider.dart';

class CategorySelector extends StatelessWidget {
  final bool isSmallScreen;

  const CategorySelector({
    super.key,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryProvider>(
      builder: (context, provider, child) {
        final categories = provider.categories;
        
        if (categories.isEmpty && !provider.isLoading) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Browse Categories',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              
              if (provider.isLoading)
                _buildLoadingSkeleton()
              else
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

  Widget _buildLoadingSkeleton() {
    return SizedBox(
      height: isSmallScreen ? 100 : 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        itemBuilder: (context, index) {
          return Container(
            width: isSmallScreen ? 85 : 95,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: isSmallScreen ? 65.0 : 75.0,
                    height: isSmallScreen ? 65.0 : 75.0,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: isSmallScreen ? 50 : 60,
                    height: 12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryItem(
    BuildContext context,
    CategoryProvider provider,
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
                fontSize: isSmallScreen ? 11 : 12,
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
          colors: [
            AppConstants.accentColor.withValues(alpha: 0.1),
            AppConstants.accentColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.grid_view_rounded,
          size: isSmallScreen ? 28 : 32,
          color: AppConstants.accentColor,
        ),
      ),
    );
  }

  Widget _buildCategoryImage(String imageUrl, String displayName, bool isSmallScreen) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      memCacheWidth: isSmallScreen ? 130 : 150,
      memCacheHeight: isSmallScreen ? 130 : 150,
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          color: Colors.white,
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: AppConstants.backgroundColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.category_outlined,
                size: isSmallScreen ? 20 : 24,
                color: AppConstants.textSecondary,
              ),
              const SizedBox(height: 2),
              Text(
                displayName.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
