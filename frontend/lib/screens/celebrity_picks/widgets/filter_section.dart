import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../constants/app_constants.dart';
import '../../../providers/celebrity_picks_provider.dart';

class CelebrityPicksFilterSection extends StatefulWidget {
  final bool isSmallScreen;

  const CelebrityPicksFilterSection({
    super.key,
    required this.isSmallScreen,
  });

  @override
  State<CelebrityPicksFilterSection> createState() => _CelebrityPicksFilterSectionState();
}

class _CelebrityPicksFilterSectionState extends State<CelebrityPicksFilterSection> {
  bool _isExpanded = false;

  String _getSortOptionText(CelebrityPicksSortOption option) {
    switch (option) {
      case CelebrityPicksSortOption.newest:
        return 'Newest';
      case CelebrityPicksSortOption.mostPopular:
        return 'Most Popular';
      case CelebrityPicksSortOption.priceLowToHigh:
        return 'Price: Low to High';
      case CelebrityPicksSortOption.priceHighToLow:
        return 'Price: High to Low';
      case CelebrityPicksSortOption.highestRated:
        return 'Highest Rated';
    }
  }

  String _formatPrice(double price) {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(price)} IQD';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CelebrityPicksProvider>(
      builder: (context, provider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              // Sort and Filter Toggle Row
              Row(
                children: [
                  // Sort Dropdown
                  Expanded(
                    flex: 2,
                    child: _buildSortDropdown(provider),
                  ),
                  const SizedBox(width: 12),
                  
                  // Filter Toggle Button
                  _buildFilterToggle(),
                ],
              ),
              
              // Expandable Filter Section
              AnimatedContainer(
                duration: AppConstants.mediumAnimation,
                curve: Curves.easeInOut,
                child: _isExpanded 
                    ? Container(
                        margin: const EdgeInsets.only(top: 16),
                        child: _buildFilterContent(provider),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortDropdown(CelebrityPicksProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.borderColor.withValues(alpha: 0.3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CelebrityPicksSortOption>(
          value: provider.sortOption,
          onChanged: (option) {
            if (option != null) {
              provider.changeSortOption(option);
            }
          },
          items: CelebrityPicksSortOption.values.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(
                _getSortOptionText(option),
                style: TextStyle(
                  fontSize: widget.isSmallScreen ? 14 : 16,
                  color: AppConstants.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: AppConstants.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterToggle() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isExpanded 
              ? AppConstants.accentColor 
              : AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isExpanded 
                ? AppConstants.accentColor 
                : AppConstants.borderColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune,
              color: _isExpanded 
                  ? AppConstants.surfaceColor 
                  : AppConstants.textPrimary,
              size: widget.isSmallScreen ? 18 : 20,
            ),
            const SizedBox(width: 6),
            Text(
              'Filters',
              style: TextStyle(
                fontSize: widget.isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: _isExpanded 
                    ? AppConstants.surfaceColor 
                    : AppConstants.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterContent(CelebrityPicksProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.borderColor.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppConstants.textSecondary.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Price Range Filter
            _buildPriceFilter(provider),
            const SizedBox(height: 16),
            
            // Rating Filter
            _buildRatingFilter(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceFilter(CelebrityPicksProvider provider) {
    final minPrice = provider.getMinPrice();
    final maxPrice = provider.getMaxPrice();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Price Range',
          style: TextStyle(
            fontSize: widget.isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.w600,
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        RangeSlider(
          values: RangeValues(
            provider.minPriceFilter.clamp(minPrice, maxPrice),
            provider.maxPriceFilter.clamp(minPrice, maxPrice),
          ),
          min: minPrice,
          max: maxPrice,
          divisions: 20,
          activeColor: AppConstants.accentColor,
          inactiveColor: AppConstants.borderColor.withValues(alpha: 0.3),
          onChanged: (values) {
            provider.applyPriceFilter(values.start, values.end);
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                _formatPrice(provider.minPriceFilter),
                style: TextStyle(
                  fontSize: widget.isSmallScreen ? 12 : 14,
                  color: AppConstants.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Text(
                _formatPrice(provider.maxPriceFilter),
                style: TextStyle(
                  fontSize: widget.isSmallScreen ? 12 : 14,
                  color: AppConstants.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingFilter(CelebrityPicksProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Minimum Rating',
          style: TextStyle(
            fontSize: widget.isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.w600,
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(5, (index) {
              final rating = index + 1.0;
              final isSelected = provider.minRatingFilter >= rating;
              
              return GestureDetector(
                onTap: () {
                  provider.applyRatingFilter(isSelected && rating == provider.minRatingFilter ? 0 : rating);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                    color: isSelected 
                        ? AppConstants.accentColor 
                        : AppConstants.textSecondary.withValues(alpha: 0.4),
                    size: widget.isSmallScreen ? 24 : 28,
                  ),
                ),
              );
            }),
          ),
        ),
        if (provider.minRatingFilter > 0) ...[
          const SizedBox(height: 4),
          Text(
            '${provider.minRatingFilter.toInt()}+ stars',
            style: TextStyle(
              fontSize: widget.isSmallScreen ? 12 : 14,
              color: AppConstants.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
} 