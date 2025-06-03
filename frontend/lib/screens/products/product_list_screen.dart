import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/app_providers.dart';
import '../../constants/app_constants.dart';
import 'product_detail_screen.dart';
import 'package:intl/intl.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({Key? key}) : super(key: key);

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  @override
  void initState() {
    super.initState();
    // Load products when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  String _formatPrice(double price) {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(price)} IQD';
  }

  // Helper function to navigate to product with provider pattern
  Future<void> _navigateToProductWithProvider(BuildContext context, Product product) async {
    try {
      final productProvider = context.read<ProductProvider>();
      final freshProduct = await productProvider.getProductById(product.id);
      
      if (freshProduct != null) {
        // Add to recently viewed
        await productProvider.addToRecentlyViewed(freshProduct);
        
        // Navigate to product detail
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: freshProduct),
            ),
          );
        }
      } else {
        // Fallback to original product if service fails
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          );
        }
      }
    } catch (e) {
      // Error handling - fallback to original product
      debugPrint('Error fetching fresh product data: $e');
      if (context.mounted) {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            onPressed: () {
              // Show filter options
              _showFilterOptions();
            },
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            onPressed: () {
              // Show sort options
              _showSortOptions();
            },
            icon: const Icon(Icons.sort),
          ),
        ],
      ),
      body: ProductConsumer(
        builder: (context, productProvider, child) {
          // Handle loading state
          if (productProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Handle error state
          if (productProvider.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppConstants.errorColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load products',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    productProvider.error ?? 'Unknown error occurred',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppConstants.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => productProvider.loadProducts(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Get products data
          final products = productProvider.filteredProducts.isNotEmpty 
              ? productProvider.filteredProducts 
              : productProvider.products;

          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.spa_outlined,
                    size: 64,
                    color: AppConstants.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No products available',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.7,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _buildProductCard(product);
            },
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () async {
        await _navigateToProductWithProvider(context, product);
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with favorite button
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      color: AppConstants.backgroundColor,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.spa_outlined,
                        size: 40,
                        color: AppConstants.accentColor.withOpacity(0.5),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.favorite_border,
                        size: 18,
                        color: AppConstants.favoriteColor,
                      ),
                    ),
                  ),
                  if (!product.isInStock)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppConstants.errorColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Out of Stock',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Product details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product.brand,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppConstants.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatPrice(product.price),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 14,
                              color: AppConstants.accentColor,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              product.rating.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppConstants.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${product.reviewCount})',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppConstants.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterOptions() {
    // TODO: Implement filter options
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filter options coming soon!')),
    );
  }

  void _showSortOptions() {
    // TODO: Implement sort options
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sort options coming soon!')),
    );
  }
}
