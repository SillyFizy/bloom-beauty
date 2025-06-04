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
import 'widgets/filter_section.dart';
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
                    
                    // Filter Section
                    SliverToBoxAdapter(
                      child: CelebrityPicksFilterSection(
                        isSmallScreen: isSmallScreen,
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
} 