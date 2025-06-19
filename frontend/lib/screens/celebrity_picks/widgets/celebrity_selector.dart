import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../providers/celebrity_picks_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class CelebritySelector extends StatelessWidget {
  final bool isSmallScreen;

  const CelebritySelector({
    super.key,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CelebrityPicksProvider>(
      builder: (context, provider, child) {
        final celebrities = provider.celebrities;

        if (celebrities.isEmpty) {
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
                    'Browse by Celebrity',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
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
                    offset: const Offset(0, 8),
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 8 : 10,
                        vertical: isSmallScreen ? 6 : 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppConstants.accentColor.withOpacity(0.1),
                            AppConstants.accentColor.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppConstants.accentColor.withOpacity(0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppConstants.accentColor.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            color: AppConstants.accentColor,
                            size: isSmallScreen ? 18 : 20,
                          ),
                          SizedBox(width: isSmallScreen ? 4 : 6),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppConstants.accentColor,
                            size: isSmallScreen ? 20 : 22,
                          ),
                        ],
                      ),
                    ),
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem<BrowseMode>(
                        value: BrowseMode.celebrity,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          decoration: BoxDecoration(
                            color: provider.browseMode == BrowseMode.celebrity
                                ? AppConstants.accentColor.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.star_rounded,
                                color:
                                    provider.browseMode == BrowseMode.celebrity
                                        ? AppConstants.accentColor
                                        : AppConstants.textSecondary,
                                size: isSmallScreen ? 18 : 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Browse by Celebrity',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: provider.browseMode ==
                                          BrowseMode.celebrity
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: provider.browseMode ==
                                          BrowseMode.celebrity
                                      ? AppConstants.accentColor
                                      : AppConstants.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      PopupMenuItem<BrowseMode>(
                        value: BrowseMode.category,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          decoration: BoxDecoration(
                            color: provider.browseMode == BrowseMode.category
                                ? AppConstants.accentColor.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.category_rounded,
                                color:
                                    provider.browseMode == BrowseMode.category
                                        ? AppConstants.accentColor
                                        : AppConstants.textSecondary,
                                size: isSmallScreen ? 18 : 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Browse by Category',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight:
                                      provider.browseMode == BrowseMode.category
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                  color:
                                      provider.browseMode == BrowseMode.category
                                          ? AppConstants.accentColor
                                          : AppConstants.textPrimary,
                                ),
                              ),
                            ],
                          ),
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
                  itemCount: celebrities.length + 1, // +1 for "All" option
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // "All" option
                      return _buildCelebrityItem(
                        context,
                        provider,
                        null,
                        'All',
                        'https://images.unsplash.com/photo-1586297135537-94bc9ba060aa?w=150&h=150&fit=crop&crop=face',
                        isSmallScreen,
                      );
                    }

                    final celebrity = celebrities[index - 1];
                    return _buildCelebrityItem(
                      context,
                      provider,
                      celebrity.name,
                      celebrity.name,
                      celebrity.image ?? '',
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

  Widget _buildCelebrityItem(
    BuildContext context,
    CelebrityPicksProvider provider,
    String? celebrityId,
    String displayName,
    String imageUrl,
    bool isSmallScreen,
  ) {
    final isSelected = provider.selectedCelebrityId == celebrityId;
    final size = isSmallScreen ? 65.0 : 75.0;

    return GestureDetector(
      onTap: () => provider.selectCelebrity(celebrityId),
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
                      : AppConstants.borderColor.withOpacity(0.3),
                  width: isSelected ? 3 : 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppConstants.accentColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: ClipOval(
                child: celebrityId == null
                    ? _buildAllOption(isSmallScreen)
                    : _buildCelebrityImage(
                        imageUrl, displayName, isSmallScreen),
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
            AppConstants.accentColor.withOpacity(0.8),
            AppConstants.favoriteColor.withOpacity(0.6),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.star_rounded,
          color: AppConstants.surfaceColor,
          size: isSmallScreen ? 30 : 35,
        ),
      ),
    );
  }

  Widget _buildCelebrityImage(
      String imageUrl, String name, bool isSmallScreen) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      memCacheWidth: isSmallScreen ? 130 : 150,
      memCacheHeight: isSmallScreen ? 130 : 150,
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: AppConstants.borderColor.withOpacity(0.3),
        highlightColor: AppConstants.surfaceColor,
        child: Container(
          decoration: BoxDecoration(
            color: AppConstants.borderColor.withOpacity(0.3),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppConstants.favoriteColor.withOpacity(0.6),
              AppConstants.favoriteColor.withOpacity(0.3),
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
      ),
    );
  }
}
