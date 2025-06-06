import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../models/product_model.dart';
import '../../constants/app_constants.dart';
import '../../providers/celebrity_picks_provider.dart';
import '../../providers/product_provider.dart';
import '../products/product_detail_screen.dart';
import 'widgets/celebrity_selector.dart';
import 'widgets/category_selector.dart';
import 'widgets/product_card.dart';
import 'widgets/search_bar.dart';

class CelebrityPicksScreen extends StatefulWidget {
  const CelebrityPicksScreen({super.key});

  @override
  State<CelebrityPicksScreen> createState() => _CelebrityPicksScreenState();
}

class _CelebrityPicksScreenState extends State<CelebrityPicksScreen> {
  late ScrollController _scrollController;
  late TextEditingController _searchController;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _searchController = TextEditingController();
    
    // Add scroll listener for infinite scroll
    _scrollController.addListener(_onScroll);
    
    // Initialize the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CelebrityPicksProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      // Load more products when near the bottom
      context.read<CelebrityPicksProvider>().loadMoreProducts();
    }
  }

  void _onSearchChanged(String query) {
    // Debounce search to avoid too many API calls
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      context.read<CelebrityPicksProvider>().searchProducts(query);
    });
  }

  String _formatPrice(double price) {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(price)} IQD';
  }

  Future<void> _navigateToProduct(Product product) async {
    try {
      final productProvider = context.read<ProductProvider>();
      final freshProduct = await productProvider.getProductById(product.id);
      
      if (freshProduct != null) {
        await productProvider.addToRecentlyViewed(freshProduct);
        
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: freshProduct),
            ),
          );
        }
      } else {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error navigating to product: $e');
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        
        // Determine grid columns
        int crossAxisCount = 2; // Default for mobile
        if (constraints.maxWidth >= 1200) {
          crossAxisCount = 4; // Large screens
        } else if (constraints.maxWidth >= 600) {
          crossAxisCount = 3; // Tablets
        }

        return Scaffold(
          backgroundColor: AppConstants.backgroundColor,
          appBar: AppBar(
            backgroundColor: AppConstants.surfaceColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: AppConstants.textPrimary,
                size: isSmallScreen ? 20 : 24,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Celebrity Picks',
              style: TextStyle(
                fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),
            centerTitle: false,
            actions: [
              Consumer<CelebrityPicksProvider>(
                builder: (context, celebrityProvider, child) {
                  final hasActiveFilters = celebrityProvider.minPriceFilter > celebrityProvider.getMinPrice() ||
                                          celebrityProvider.maxPriceFilter < celebrityProvider.getMaxPrice() ||
                                          celebrityProvider.minRatingFilter > 0;

                  return Row(
                    children: [
                      // Sort button
                      IconButton(
                        onPressed: () => _showSortOptions(context, celebrityProvider, isSmallScreen),
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
                            onPressed: () => _showFilterOptions(context, celebrityProvider, isSmallScreen),
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
          body: Consumer<CelebrityPicksProvider>(
            builder: (context, provider, child) {
              // Handle loading state
              if (provider.isLoading) {
                return _buildLoadingState(crossAxisCount, isSmallScreen);
              }

              // Handle error state
              if (provider.hasError) {
                return _buildErrorState(provider.error!, isSmallScreen);
              }

              return RefreshIndicator(
                onRefresh: provider.refresh,
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // Search Bar
                    SliverToBoxAdapter(
                      child: CelebrityPicksSearchBar(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        onClear: () {
                          _searchController.clear();
                          provider.clearSearch();
                        },
                      ),
                    ),
                    
                    // Celebrity Selector or Category Selector
                    SliverToBoxAdapter(
                      child: Consumer<CelebrityPicksProvider>(
                        builder: (context, provider, child) {
                          return provider.browseMode == BrowseMode.celebrity
                              ? CelebritySelector(
                                  isSmallScreen: isSmallScreen,
                                )
                              : CategorySelector(
                                  isSmallScreen: isSmallScreen,
                                );
                        },
                      ),
                    ),
                    
                    // Products Grid
                    _buildProductsGrid(provider, crossAxisCount, isSmallScreen),
                    
                    // Loading indicator for infinite scroll
                    if (provider.isLoadingMore)
                      SliverToBoxAdapter(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppConstants.accentColor,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProductsGrid(CelebrityPicksProvider provider, int crossAxisCount, bool isSmallScreen) {
    if (provider.displayProducts.isEmpty) {
      return SliverToBoxAdapter(
        child: _buildEmptyState(isSmallScreen),
      );
    }

    // Improved aspect ratios for better card sizing
    double childAspectRatio;
    if (crossAxisCount == 2) {
      // Mobile: 2 columns - taller cards for better content display
      childAspectRatio = isSmallScreen ? 0.65 : 0.7;
    } else if (crossAxisCount == 3) {
      // Tablet: 3 columns - balanced aspect ratio
      childAspectRatio = 0.75;
    } else {
      // Desktop: 4 columns - slightly taller cards
      childAspectRatio = 0.8;
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 20,
        vertical: 16,
      ),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: isSmallScreen ? 12 : 16,
          mainAxisSpacing: isSmallScreen ? 16 : 20,
          childAspectRatio: childAspectRatio,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final product = provider.displayProducts[index];
            return CelebrityPicksProductCard(
              product: product,
              onTap: () => _navigateToProduct(product),
              onWishlistTap: () => provider.toggleWishlist(product.id),
              formatPrice: _formatPrice,
              isSmallScreen: isSmallScreen,
            );
          },
          childCount: provider.displayProducts.length,
        ),
      ),
    );
  }

  Widget _buildLoadingState(int crossAxisCount, bool isSmallScreen) {
    // Use the same aspect ratio calculation as the main grid
    double childAspectRatio;
    if (crossAxisCount == 2) {
      childAspectRatio = isSmallScreen ? 0.65 : 0.7;
    } else if (crossAxisCount == 3) {
      childAspectRatio = 0.75;
    } else {
      childAspectRatio = 0.8;
    }

    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      child: Column(
        children: [
          // Search bar skeleton
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: AppConstants.borderColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          const SizedBox(height: 16),
          
          // Celebrity selector skeleton
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) {
                return Container(
                  width: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppConstants.borderColor.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppConstants.borderColor.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          
          // Product grid skeleton
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: isSmallScreen ? 12 : 16,
                mainAxisSpacing: isSmallScreen ? 16 : 20,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: 8,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppConstants.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppConstants.borderColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppConstants.borderColor.withValues(alpha: 0.3),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                decoration: BoxDecoration(
                                  color: AppConstants.borderColor.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                              Container(
                                    width: 28,
                                    height: 28,
                                decoration: BoxDecoration(
                                  color: AppConstants.borderColor.withValues(alpha: 0.3),
                                      shape: BoxShape.circle,
                                ),
                              ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      height: 12,
                                decoration: BoxDecoration(
                                  color: AppConstants.borderColor.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, bool isSmallScreen) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: isSmallScreen ? 64 : 80,
              color: AppConstants.errorColor,
            ),
            SizedBox(height: isSmallScreen ? 16 : 24),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 22,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            Text(
              error,
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: AppConstants.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmallScreen ? 24 : 32),
            ElevatedButton(
              onPressed: () {
                context.read<CelebrityPicksProvider>().refresh();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.accentColor,
                foregroundColor: AppConstants.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 24 : 32,
                  vertical: isSmallScreen ? 12 : 16,
                ),
              ),
              child: Text(
                'Try Again',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 32 : 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: isSmallScreen ? 64 : 80,
            color: AppConstants.textSecondary.withValues(alpha: 0.5),
          ),
          SizedBox(height: isSmallScreen ? 16 : 24),
          Text(
            'No products found',
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 22,
              fontWeight: FontWeight.bold,
              color: AppConstants.textSecondary,
            ),
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Text(
            'Try adjusting your filters or search terms',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: AppConstants.textSecondary.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isSmallScreen ? 24 : 32),
          ElevatedButton(
            onPressed: () {
              _searchController.clear();
              final provider = context.read<CelebrityPicksProvider>();
              provider.clearSearch();
              provider.selectCelebrity(null);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.accentColor,
              foregroundColor: AppConstants.surfaceColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 24 : 32,
                vertical: isSmallScreen ? 12 : 16,
              ),
            ),
            child: Text(
              'Clear Filters',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show sort options (matching category screen implementation)
  void _showSortOptions(BuildContext context, CelebrityPicksProvider provider, bool isSmallScreen) {
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
            
            ...CelebrityPicksSortOption.values.map((option) => _buildSortOption(
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

  /// Show filter options (matching category screen implementation exactly)
  void _showFilterOptions(BuildContext context, CelebrityPicksProvider provider, bool isSmallScreen) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => Consumer<CelebrityPicksProvider>(
        builder: (context, celebrityProvider, child) => Container(
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
                        celebrityProvider.clearFilters();
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
                      _buildResponsivePriceFilter(celebrityProvider, isSmallScreen),
                      
                      SizedBox(height: isSmallScreen ? 20 : 24),
                      
                      // Rating Filter
                      _buildResponsiveRatingFilter(celebrityProvider, isSmallScreen),
                      
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
                      'Apply Filters (${celebrityProvider.filteredProducts.length} products)',
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

  Widget _buildSortOption(
    BuildContext context,
    CelebrityPicksProvider provider,
    CelebrityPicksSortOption option,
    String label,
    IconData icon,
    bool isSmallScreen,
  ) {
    final isSelected = provider.sortOption == option;
    
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
        provider.changeSortOption(option);
        Navigator.pop(context);
      },
    );
  }

  /// Responsive Price Range Filter (matching category screen)
  Widget _buildResponsivePriceFilter(CelebrityPicksProvider provider, bool isSmallScreen) {
    final minPrice = provider.getMinPrice();
    final maxPrice = provider.getMaxPrice();
    
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
                  '${provider.minPriceFilter.toInt()} IQD',
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
                  '${provider.maxPriceFilter.toInt()} IQD',
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
        
        SizedBox(height: isSmallScreen ? 16 : 20),
        
        // Price Range Slider
        Container(
          padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 16),
          child: Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: isSmallScreen ? 4 : 6,
                  thumbShape: RoundSliderThumbShape(
                    enabledThumbRadius: isSmallScreen ? 10 : 12,
                  ),
                  overlayShape: RoundSliderOverlayShape(
                    overlayRadius: isSmallScreen ? 18 : 22,
                  ),
                  activeTrackColor: AppConstants.accentColor,
                  inactiveTrackColor: AppConstants.borderColor.withValues(alpha: 0.3),
                  thumbColor: AppConstants.accentColor,
                  overlayColor: AppConstants.accentColor.withValues(alpha: 0.2),
                ),
                child: RangeSlider(
                  values: RangeValues(
                    provider.minPriceFilter.clamp(minPrice, maxPrice),
                    provider.maxPriceFilter.clamp(minPrice, maxPrice),
                  ),
                  min: minPrice,
                  max: maxPrice,
                  divisions: 20,
                  onChanged: (values) {
                    provider.applyPriceFilter(values.start, values.end);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Responsive Rating Filter (matching category screen)
  Widget _buildResponsiveRatingFilter(CelebrityPicksProvider provider, bool isSmallScreen) {
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
        
        // Rating Buttons (exactly like category screen)
        Wrap(
          spacing: isSmallScreen ? 8 : 12,
          runSpacing: isSmallScreen ? 8 : 12,
          children: [
            _buildRatingButton(provider, 0, 'All', isSmallScreen),
            _buildRatingButton(provider, 1, '1+ ⭐', isSmallScreen),
            _buildRatingButton(provider, 2, '2+ ⭐', isSmallScreen),
            _buildRatingButton(provider, 3, '3+ ⭐', isSmallScreen),
            _buildRatingButton(provider, 4, '4+ ⭐', isSmallScreen),
            _buildRatingButton(provider, 5, '5 ⭐', isSmallScreen),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingButton(CelebrityPicksProvider provider, double rating, String label, bool isSmallScreen) {
    final isSelected = provider.minRatingFilter == rating;
    
    return GestureDetector(
      onTap: () => provider.applyRatingFilter(rating),
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

  String _getSortOptionLabel(CelebrityPicksSortOption option) {
    switch (option) {
      case CelebrityPicksSortOption.newest:
        return 'Newest First';
      case CelebrityPicksSortOption.priceLowToHigh:
        return 'Price: Low to High';
      case CelebrityPicksSortOption.priceHighToLow:
        return 'Price: High to Low';
      case CelebrityPicksSortOption.highestRated:
        return 'Highest Rated';
      case CelebrityPicksSortOption.mostPopular:
        return 'Most Popular';
    }
  }

  IconData _getSortOptionIcon(CelebrityPicksSortOption option) {
    switch (option) {
      case CelebrityPicksSortOption.newest:
        return Icons.fiber_new_rounded;
      case CelebrityPicksSortOption.priceLowToHigh:
        return Icons.trending_up_rounded;
      case CelebrityPicksSortOption.priceHighToLow:
        return Icons.trending_down_rounded;
      case CelebrityPicksSortOption.highestRated:
        return Icons.star_rounded;
      case CelebrityPicksSortOption.mostPopular:
        return Icons.local_fire_department_rounded;
    }
  }
} 