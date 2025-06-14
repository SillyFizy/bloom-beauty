import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../providers/wishlist_provider.dart';
import '../../models/product_model.dart';
import '../../widgets/common/wishlist_button.dart';
import '../products/product_detail_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  String _searchQuery = '';
  WishlistSortOption _sortOption = WishlistSortOption.newest;

  String _formatPrice(double price) {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(price)} IQD';
  }

  Future<void> _navigateToProduct(Product product) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );
  }

  void _showSortOptions() {
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
const Text(

              'Sort By',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...WishlistSortOption.values.map((option) => ListTile(
              leading: Icon(
                _getSortIcon(option),
                color: _sortOption == option ? AppConstants.accentColor : AppConstants.textSecondary,
              ),
              title: Text(
                _getSortLabel(option),
                style: TextStyle(
                  fontWeight: _sortOption == option ? FontWeight.w600 : FontWeight.w500,
                  color: _sortOption == option ? AppConstants.accentColor : AppConstants.textPrimary,
                ),
              ),
              trailing: _sortOption == option
? const Icon(Icons.check_circle, color: AppConstants.accentColor)

                  : null,
              onTap: () {
                setState(() {
                  _sortOption = option;
                });
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        
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
              'My Wishlist',
              style: TextStyle(
                fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),
            centerTitle: false,
            actions: [
              Consumer<WishlistProvider>(
                builder: (context, wishlistProvider, child) {
                  if (wishlistProvider.isEmpty) return const SizedBox.shrink();
                  
                  return Row(
                    children: [
                      IconButton(
                        onPressed: _showSortOptions,
                        icon: Icon(
                          Icons.sort_rounded,
                          color: AppConstants.textPrimary,
                          size: isSmallScreen ? 22 : 24,
                        ),
                        tooltip: 'Sort',
                      ),
                      PopupMenuButton(
                        icon: Icon(
                          Icons.more_vert,
                          color: AppConstants.textPrimary,
                          size: isSmallScreen ? 22 : 24,
                        ),
                        itemBuilder: (context) => [
const PopupMenuItem(

                            value: 'clear',
                            child: Row(
                              children: [
                                Icon(Icons.clear_all, color: AppConstants.errorColor),
SizedBox(width: 8),

                                Text('Clear Wishlist'),
                              ],
                            ),
                          ),
const PopupMenuItem(

                            value: 'refresh',
                            child: Row(
                              children: [
                                Icon(Icons.refresh, color: AppConstants.accentColor),
SizedBox(width: 8),

                                Text('Refresh'),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) async {
                          switch (value) {
                            case 'clear':
                              _showClearConfirmation(wishlistProvider);
                              break;
                            case 'refresh':
                              await wishlistProvider.refresh();
                              break;
                          }
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          body: Consumer<WishlistProvider>(
            builder: (context, wishlistProvider, child) {
              if (wishlistProvider.isLoading) {
                return _buildLoadingState(isSmallScreen);
              }

              if (wishlistProvider.hasError) {
                return _buildErrorState(wishlistProvider.error!, isSmallScreen);
              }

              if (wishlistProvider.isEmpty) {
                return _buildEmptyState(isSmallScreen);
              }

              // Get sorted products
              final products = _getSortedProducts(wishlistProvider);
              final filteredProducts = _getFilteredProducts(products);

              return Column(
                children: [
                  // Search bar
                  if (wishlistProvider.itemCount > 3)
                    _buildSearchBar(isSmallScreen),
                  
                  // Wishlist count
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 16 : 20,
                      vertical: isSmallScreen ? 8 : 12,
                    ),
                    color: AppConstants.surfaceColor,
                    child: Text(
                      '${filteredProducts.length} item${filteredProducts.length == 1 ? '' : 's'} in wishlist',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        color: AppConstants.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  // Products list
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: wishlistProvider.refresh,
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 16 : 20,
                          vertical: isSmallScreen ? 8 : 12,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return _buildWishlistItem(product, wishlistProvider, isSmallScreen);
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      color: AppConstants.surfaceColor,
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search wishlist...',
prefixIcon: const Icon(Icons.search, color: AppConstants.textSecondary),

          filled: true,
          fillColor: AppConstants.backgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 16,
            vertical: isSmallScreen ? 8 : 12,
          ),
        ),
      ),
    );
  }

  Widget _buildWishlistItem(Product product, WishlistProvider wishlistProvider, bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppConstants.textSecondary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToProduct(product),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              Container(
                width: isSmallScreen ? 80 : 100,
                height: isSmallScreen ? 80 : 100,
                decoration: BoxDecoration(
                  color: AppConstants.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppConstants.borderColor.withOpacity(0.3),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.spa_outlined,
                    size: isSmallScreen ? 32 : 40,
                    color: AppConstants.accentColor.withOpacity(0.5),
                  ),
                ),
              ),
              
              SizedBox(width: isSmallScreen ? 12 : 16),
              
              // Product details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 15 : 17,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimary,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: isSmallScreen ? 4 : 6),
                    
                    Text(
                      product.brand,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13 : 15,
                        color: AppConstants.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    SizedBox(height: isSmallScreen ? 8 : 12),
                    
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < product.rating.floor()
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: AppConstants.accentColor,
                              size: isSmallScreen ? 14 : 16,
                            );
                          }),
                        ),
                        SizedBox(width: isSmallScreen ? 6 : 8),
                        Text(
                          product.rating.toString(),
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 14,
                            color: AppConstants.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: isSmallScreen ? 8 : 12),
                    
                    // Beauty Points section
                    if (product.beautyPoints > 0) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.stars_rounded,
                            color: AppConstants.favoriteColor,
                            size: isSmallScreen ? 14 : 16,
                          ),
                          SizedBox(width: isSmallScreen ? 4 : 6),
                          Text(
                            '+${product.beautyPoints} Beauty Points',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              color: AppConstants.favoriteColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 12),
                    ],
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatPrice(product.price),
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.textPrimary,
                          ),
                        ),
                        
                        WishlistButton(
                          product: product,
                          size: isSmallScreen ? 20 : 24,
                          heroTag: 'wishlist_screen_${product.id}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isSmallScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
const CircularProgressIndicator(color: AppConstants.accentColor),

          SizedBox(height: isSmallScreen ? 16 : 20),
          Text(
            'Loading your wishlist...',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
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
              'Something went wrong',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 22,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
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
                context.read<WishlistProvider>().refresh();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.accentColor,
                foregroundColor: AppConstants.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: isSmallScreen ? 80 : 100,
              color: AppConstants.textSecondary.withOpacity(0.5),
            ),
            SizedBox(height: isSmallScreen ? 24 : 32),
            Text(
              'Your wishlist is empty',
              style: TextStyle(
                fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              'Add products you love to your wishlist by tapping the heart icon',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: AppConstants.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmallScreen ? 32 : 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.accentColor,
                foregroundColor: AppConstants.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 24 : 32,
                  vertical: isSmallScreen ? 12 : 16,
                ),
              ),
              child: Text(
                'Start Shopping',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearConfirmation(WishlistProvider wishlistProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
title: const Text(
          'Clear Wishlist',
          style: TextStyle(color: AppConstants.textPrimary),
        ),
        content: const Text(

          'Are you sure you want to remove all items from your wishlist?',
          style: TextStyle(color: AppConstants.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
child: const Text(

              'Cancel',
              style: TextStyle(color: AppConstants.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await wishlistProvider.clearWishlist();
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  List<Product> _getSortedProducts(WishlistProvider provider) {
    switch (_sortOption) {
      case WishlistSortOption.newest:
        return provider.products;
      case WishlistSortOption.oldest:
        return provider.productsOldestFirst;
      case WishlistSortOption.name:
        return provider.productsSortedByName;
      case WishlistSortOption.priceLow:
        return provider.products..sort((a, b) => a.price.compareTo(b.price));
      case WishlistSortOption.priceHigh:
        return provider.products..sort((a, b) => b.price.compareTo(a.price));
    }
  }

  List<Product> _getFilteredProducts(List<Product> products) {
    if (_searchQuery.isEmpty) return products;
    
    return products.where((product) {
      final query = _searchQuery.toLowerCase();
      return product.name.toLowerCase().contains(query) ||
             product.brand.toLowerCase().contains(query) ||
             product.description.toLowerCase().contains(query);
    }).toList();
  }

  String _getSortLabel(WishlistSortOption option) {
    switch (option) {
      case WishlistSortOption.newest:
        return 'Newest First';
      case WishlistSortOption.oldest:
        return 'Oldest First';
      case WishlistSortOption.name:
        return 'Name A-Z';
      case WishlistSortOption.priceLow:
        return 'Price: Low to High';
      case WishlistSortOption.priceHigh:
        return 'Price: High to Low';
    }
  }

  IconData _getSortIcon(WishlistSortOption option) {
    switch (option) {
      case WishlistSortOption.newest:
        return Icons.fiber_new_rounded;
      case WishlistSortOption.oldest:
        return Icons.access_time_rounded;
      case WishlistSortOption.name:
        return Icons.sort_by_alpha_rounded;
      case WishlistSortOption.priceLow:
        return Icons.trending_up_rounded;
      case WishlistSortOption.priceHigh:
        return Icons.trending_down_rounded;
    }
  }
}

enum WishlistSortOption {
  newest,
  oldest,
  name,
  priceLow,
  priceHigh,
} 
