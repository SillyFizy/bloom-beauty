import 'package:flutter/material.dart';
import '../../providers/app_providers.dart';
import '../../constants/app_constants.dart';
import '../products/product_detail_screen.dart';
import '../../widgets/product/celebrity_pick_card.dart';
import 'package:intl/intl.dart';

/// Example of how the Home Screen should be refactored to use Service Providers
/// This demonstrates the proper separation of concerns with services handling data
/// and providers managing state, while components only handle UI logic
class HomeScreenExample extends StatefulWidget {
  const HomeScreenExample({super.key});

  @override
  State<HomeScreenExample> createState() => _HomeScreenExampleState();
}

class _HomeScreenExampleState extends State<HomeScreenExample> {
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  /// Initialize data using service providers
  Future<void> _initializeData() async {
    // Initialize providers if not already done
    if (!AppProviders.areProvidersInitialized(context)) {
      await AppProviders.initializeProviders(context);
    }
  }

  /// Helper function to format price in IQD
  String _formatPrice(double price) {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(price)} IQD';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final isMediumScreen = constraints.maxWidth >= 600 && constraints.maxWidth < 900;
        
        return Scaffold(
          backgroundColor: AppConstants.backgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isSmallScreen),
                  _buildBannerSection(isSmallScreen),
                  _buildCelebritySection(isSmallScreen, isMediumScreen),
                  _buildNewArrivalsSection(isSmallScreen, isMediumScreen),
                  _buildBestsellingSection(isSmallScreen, isMediumScreen),
                  _buildTrendingSection(isSmallScreen, isMediumScreen),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Bloom Beauty',
            style: TextStyle(
              fontSize: isSmallScreen ? 20 : 24,
              fontWeight: FontWeight.w600,
              color: AppConstants.accentColor,
            ),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon!')),
              );
            },
            icon: Icon(
              Icons.notifications_outlined,
              color: AppConstants.accentColor,
              size: isSmallScreen ? 24 : 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerSection(bool isSmallScreen) {
    final bannerImages = [
      'Cosmetics Collection 1',
      'Cosmetics Collection 2', 
      'Cosmetics Collection 3',
    ];

    return Column(
      children: [
        Container(
          height: isSmallScreen ? 220 : 280,
          margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppConstants.backgroundColor,
          ),
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (index) {
              setState(() {
                _currentBannerIndex = index;
              });
            },
            itemCount: bannerImages.length,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Colors.pink.withValues(alpha: 0.8),
                      Colors.purple.withValues(alpha: 0.8),
                      Colors.orange.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.spa_outlined,
                        size: isSmallScreen ? 60 : 80,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        bannerImages[index],
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 18 : 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            bannerImages.length,
            (index) => Container(
              width: isSmallScreen ? 6 : 8,
              height: isSmallScreen ? 6 : 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentBannerIndex == index
                    ? AppConstants.accentColor
                    : AppConstants.textSecondary.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Celebrity section using Celebrity Provider
  Widget _buildCelebritySection(bool isSmallScreen, bool isMediumScreen) {
    return CelebrityConsumer(
      builder: (context, celebrityProvider, child) {
        if (celebrityProvider.isLoading) {
          return _buildLoadingSection('Loading Celebrity Picks...', isSmallScreen);
        }

        if (celebrityProvider.hasError) {
          return _buildErrorSection(
            'Failed to load celebrity picks', 
            () => celebrityProvider.refresh(),
            isSmallScreen,
          );
        }

        final celebrityPicks = celebrityProvider.celebrityPicks;

        if (celebrityPicks.isEmpty) {
          return _buildEmptySection('No celebrity picks available', isSmallScreen);
        }

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(
                      'CELEBRITY PICKS',
                      'Handpicked by your favorite stars',
                      isSmallScreen,
                    ),
                    SizedBox(
                      height: isSmallScreen ? 280 : 300,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
                        itemCount: celebrityPicks.length,
                        itemBuilder: (context, index) {
                          final pick = celebrityPicks[index];
                          return TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            duration: Duration(milliseconds: 250 + (index * 50)),
                            curve: Curves.easeOutCubic,
                            builder: (context, itemValue, child) {
                              return Transform.translate(
                                offset: Offset(0, 30 * (1 - itemValue)),
                                child: Opacity(
                                  opacity: itemValue,
                                  child: Container(
                                    width: isSmallScreen ? 180 : 200,
                                    margin: EdgeInsets.only(right: isSmallScreen ? 12 : 16),
                                    child: CelebrityPickCard(
                                      product: pick['product'],
                                      celebrityName: pick['name'],
                                      celebrityImage: pick['image'],
                                      testimonial: pick['testimonial'],
                                      socialMediaLinks: pick['socialMediaLinks'] ?? {},
                                      recommendedProducts: pick['recommendedProducts'] ?? [],
                                      morningRoutineProducts: pick['morningRoutineProducts'] ?? [],
                                      eveningRoutineProducts: pick['eveningRoutineProducts'] ?? [],
                                      index: index,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ProductDetailScreen(
                                              product: pick['product'],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// New arrivals section using Product Provider
  Widget _buildNewArrivalsSection(bool isSmallScreen, bool isMediumScreen) {
    return ProductConsumer(
      builder: (context, productProvider, child) {
        if (productProvider.isLoading) {
          return _buildLoadingSection('Loading New Arrivals...', isSmallScreen);
        }

        final newArrivals = productProvider.newArrivals;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('NEW ARRIVALS', '', isSmallScreen),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isSmallScreen ? 2 : isMediumScreen ? 3 : 4,
                  crossAxisSpacing: isSmallScreen ? 8 : 12,
                  mainAxisSpacing: isSmallScreen ? 8 : 12,
                  childAspectRatio: isSmallScreen ? 0.7 : isMediumScreen ? 0.75 : 0.8,
                ),
                itemCount: newArrivals.length,
                itemBuilder: (context, index) {
                  final product = newArrivals[index];
                  return _buildProductCard(product, isSmallScreen);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// Bestselling section using Product Provider
  Widget _buildBestsellingSection(bool isSmallScreen, bool isMediumScreen) {
    return ProductConsumer(
      builder: (context, productProvider, child) {
        final bestsellingProducts = productProvider.bestsellingProducts;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('BESTSELLING SKINCARE', '', isSmallScreen),
            SizedBox(
              height: isSmallScreen ? 240 : 260,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
                itemCount: bestsellingProducts.length,
                itemBuilder: (context, index) {
                  final product = bestsellingProducts[index];
                  return _buildHorizontalProductCard(product, isSmallScreen);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// Trending section using Product Provider
  Widget _buildTrendingSection(bool isSmallScreen, bool isMediumScreen) {
    return ProductConsumer(
      builder: (context, productProvider, child) {
        final trendingProducts = productProvider.trendingProducts;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('TRENDING MAKEUP', '', isSmallScreen),
            SizedBox(
              height: isSmallScreen ? 240 : 260,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
                itemCount: trendingProducts.length,
                itemBuilder: (context, index) {
                  final product = trendingProducts[index];
                  return _buildHorizontalProductCard(product, isSmallScreen);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// Helper widgets

  Widget _buildSectionTitle(String title, String subtitle, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isSmallScreen ? 12 : 16, 
        isSmallScreen ? 24 : 32, 
        isSmallScreen ? 12 : 16, 
        isSmallScreen ? 16 : 20
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
              letterSpacing: isSmallScreen ? 0.8 : 1.2,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: isSmallScreen ? 11 : 13,
                color: AppConstants.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingSection(String message, bool isSmallScreen) {
    return Container(
      height: isSmallScreen ? 200 : 250,
      margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppConstants.accentColor),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: AppConstants.textSecondary,
                fontSize: isSmallScreen ? 14 : 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorSection(String message, VoidCallback onRetry, bool isSmallScreen) {
    return Container(
      height: isSmallScreen ? 200 : 250,
      margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: isSmallScreen ? 48 : 64,
              color: AppConstants.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: AppConstants.textSecondary,
                fontSize: isSmallScreen ? 14 : 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySection(String message, bool isSmallScreen) {
    return Container(
      height: isSmallScreen ? 200 : 250,
      margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: AppConstants.textSecondary,
            fontSize: isSmallScreen ? 14 : 16,
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(product, bool isSmallScreen) {
    return GestureDetector(
      onTap: () {
        // Add to recently viewed when tapping product
        context.productProvider.addToRecentlyViewed(product);
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image placeholder
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  color: AppConstants.backgroundColor,
                ),
                child: Center(
                  child: Icon(
                    Icons.spa_outlined,
                    size: isSmallScreen ? 32 : 40,
                    color: AppConstants.accentColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            // Product details
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 13 : 15,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textPrimary,
                          height: 1.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatPrice(product.price),
                          style: TextStyle(
                            fontSize: isSmallScreen ? 13 : 15,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: isSmallScreen ? 12 : 14,
                              color: AppConstants.accentColor,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              product.rating.toString(),
                              style: TextStyle(
                                fontSize: isSmallScreen ? 11 : 13,
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

  Widget _buildHorizontalProductCard(product, bool isSmallScreen) {
    return GestureDetector(
      onTap: () {
        // Add to recently viewed when tapping product
        context.productProvider.addToRecentlyViewed(product);
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        width: isSmallScreen ? 160 : 180,
        margin: EdgeInsets.only(right: isSmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image placeholder
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  color: AppConstants.backgroundColor,
                ),
                child: Center(
                  child: Icon(
                    Icons.spa_outlined,
                    size: isSmallScreen ? 32 : 40,
                    color: AppConstants.accentColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            // Product details
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 13 : 15,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textPrimary,
                          height: 1.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatPrice(product.price),
                          style: TextStyle(
                            fontSize: isSmallScreen ? 13 : 15,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: isSmallScreen ? 12 : 14,
                              color: AppConstants.accentColor,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              product.rating.toString(),
                              style: TextStyle(
                                fontSize: isSmallScreen ? 11 : 13,
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
} 
