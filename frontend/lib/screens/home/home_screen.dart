import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../models/product_model.dart';
import '../../constants/app_constants.dart';
import '../../widgets/product/celebrity_pick_card.dart';
import '../../widgets/common/wishlist_button.dart';
import '../../widgets/common/optimized_image.dart';
import '../../providers/product_provider.dart';
import '../../providers/celebrity_provider.dart';
import '../../providers/app_providers.dart';
import '../products/product_detail_screen.dart';
import '../celebrity_picks/celebrity_picks_screen.dart';
import 'package:intl/intl.dart';
// not being used currently
// import 'package:go_router/go_router.dart';
// import '../../widgets/product/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive =>
      true; // Keep the state alive to prevent re-initialization
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  static bool _hasInitialized = false; // Global flag to track initialization

  // Sample data for banner
  final List<String> _bannerImages = [
    'Cosmetics Collection 1',
    'Cosmetics Collection 2',
    'Cosmetics Collection 3',
  ];

  @override
  void initState() {
    super.initState();
    // Load data when screen initializes, with proper routing support
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only load data if not already initialized
      if (!_hasInitialized) {
        debugPrint('HomeScreen: First time initialization');
        _loadData();
        _hasInitialized = true;
      } else {
        debugPrint('HomeScreen: Already initialized, using cached data');
      }
    });
  }

  void _loadData() {
    final productProvider = context.read<ProductProvider>();
    final celebrityProvider = context.read<CelebrityProvider>();

    // Only initialize if providers don't have cached data
    debugPrint('HomeScreen: Checking if data needs loading...');
    debugPrint(
        'HomeScreen: ProductProvider isInitialized: ${productProvider.isInitialized}');
    debugPrint(
        'HomeScreen: CelebrityProvider has data: ${celebrityProvider.celebrities.isNotEmpty}');

    // Double-check with provider state and data availability
    final productNeedsInit = !productProvider.isInitialized ||
        productProvider.products.isEmpty ||
        productProvider.newArrivals.isEmpty ||
        productProvider.bestsellingProducts.isEmpty ||
        productProvider.trendingProducts.isEmpty;

    final celebrityNeedsInit = celebrityProvider.celebrities.isEmpty;

    if (productNeedsInit) {
      debugPrint('HomeScreen: Product data missing, initializing...');
      productProvider.initialize();
    } else {
      debugPrint(
          'HomeScreen: Product data already cached, skipping initialization');
    }

    if (celebrityNeedsInit) {
      debugPrint('HomeScreen: Celebrity data missing, initializing...');
      celebrityProvider.initialize();
    } else {
      debugPrint(
          'HomeScreen: Celebrity data already cached, skipping initialization');
    }
  }

  Future<void> _refreshData() async {
    final productProvider = context.read<ProductProvider>();
    final celebrityProvider = context.read<CelebrityProvider>();

    debugPrint(
        'HomeScreen: Manual refresh triggered - resetting initialization flag');
    _hasInitialized = false; // Reset flag to allow fresh initialization

    await Future.wait([
      productProvider.refreshAllData(),
      celebrityProvider
          .initialize(), // Celebrity provider doesn't have refreshAllData yet
    ]);

    _hasInitialized = true; // Set flag back after refresh
  }

  // Helper function to format price in IQD
  String _formatPrice(double price) {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(price)} IQD';
  }

  // Helper function to navigate to product with only ID - simplified approach
  Future<void> _navigateToProductWithProvider(
    BuildContext context,
    Product product, {
    String? celebrityName,
    String? celebrityImage,
    String? testimonial,
  }) async {
    try {
      final productProvider = context.read<ProductProvider>();

      // Add to recently viewed using the current product data
      await productProvider.addToRecentlyViewed(product);

      // Navigate to product detail using GoRouter with only the ID
      // Product detail screen will fetch fresh data from backend
      if (context.mounted) {
        context.pushNamed('product-detail', pathParameters: {
          'productId': product.id,
        });
      }
    } catch (e) {
      debugPrint('Error navigating to product: $e');
      // Even if adding to recently viewed fails, still navigate
      if (context.mounted) {
        context.pushNamed('product-detail', pathParameters: {
          'productId': product.id,
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine screen size
        final isSmallScreen = constraints.maxWidth < 600;
        final isMediumScreen =
            constraints.maxWidth >= 600 && constraints.maxWidth < 900;

        return Scaffold(
          backgroundColor: AppConstants.backgroundColor,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              color: AppConstants.accentColor,
              backgroundColor: Colors.white,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(isSmallScreen),

                    // Banner Section
                    _buildBannerSection(isSmallScreen),

                    // Celebrity Beauty Picks
                    _buildCelebritySection(isSmallScreen, isMediumScreen),

                    // New Arrivals
                    _buildNewArrivalsSection(isSmallScreen, isMediumScreen),

                    // Bestselling Skincare
                    _buildBestsellingSection(isSmallScreen, isMediumScreen),

                    // Trending Makeup
                    _buildTrendingSection(isSmallScreen, isMediumScreen),

                    const SizedBox(height: 40), // Bottom padding for nav bar
                  ],
                ),
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
            style: GoogleFonts.corinthia(
              fontSize: isSmallScreen ? 42 : 50,
              fontWeight: FontWeight.w700,
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
            itemCount: _bannerImages.length,
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
                child: Stack(
                  children: [
                    Center(
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
                            _bannerImages[index],
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 18 : 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Page indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _bannerImages.length,
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

  Widget _buildCelebritySection(bool isSmallScreen, bool isMediumScreen) {
    return CelebrityConsumer(
      builder: (context, celebrityProvider, child) {
        // Handle loading state
        if (celebrityProvider.isLoading) {
          return _buildLoadingSection(
              'Loading Celebrity Picks...', isSmallScreen);
        }

        // Handle error state
        if (celebrityProvider.hasError) {
          return _buildErrorSection(
            'Failed to load celebrity picks',
            () => celebrityProvider.refresh(),
            isSmallScreen,
          );
        }

        // Get celebrity picks data
        final celebrityPicks = celebrityProvider.celebrityPicks;

        if (celebrityPicks.isEmpty) {
          return _buildEmptySection(
              'No celebrity picks available', isSmallScreen);
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
                    // Animated title section
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          isSmallScreen ? 12 : 16,
                          isSmallScreen ? 24 : 32,
                          isSmallScreen ? 12 : 16,
                          isSmallScreen ? 16 : 20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutBack,
                        transform: Matrix4.identity()
                          ..scale(value)
                          ..rotateZ(-0.01 * (1 - value)),
                        child: Row(
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutBack,
                              builder: (context, starValue, child) {
                                return Transform.scale(
                                  scale: starValue,
                                  child: Transform.rotate(
                                    angle: (1 - starValue) * 0.3,
                                    child: Container(
                                      padding:
                                          EdgeInsets.all(isSmallScreen ? 6 : 8),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            AppConstants.accentColor
                                                .withValues(alpha: 0.1),
                                            AppConstants.favoriteColor
                                                .withValues(alpha: 0.1),
                                          ],
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.star_rounded,
                                        color: AppConstants.accentColor,
                                        size: isSmallScreen ? 16 : 20,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(width: isSmallScreen ? 8 : 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0.0, end: 1.0),
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, textValue, child) {
                                      return Transform.translate(
                                        offset: Offset(15 * (1 - textValue), 0),
                                        child: Opacity(
                                          opacity: textValue,
                                          child: Text(
                                            'CELEBRITY PICKS',
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 16 : 18,
                                              fontWeight: FontWeight.bold,
                                              color: AppConstants.textPrimary,
                                              letterSpacing:
                                                  isSmallScreen ? 0.8 : 1.2,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 4),
                                  TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0.0, end: 1.0),
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, subtitleValue, child) {
                                      return Transform.translate(
                                        offset:
                                            Offset(20 * (1 - subtitleValue), 0),
                                        child: Opacity(
                                          opacity: subtitleValue * 0.7,
                                          child: Text(
                                            'Handpicked by your favorite stars',
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 11 : 13,
                                              color: AppConstants.textSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            // View All Button
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOutCubic,
                              builder: (context, buttonValue, child) {
                                return Transform.translate(
                                  offset: Offset(30 * (1 - buttonValue), 0),
                                  child: Opacity(
                                    opacity: buttonValue,
                                    child: GestureDetector(
                                      onTap: null, // Disabled for now
                                      // onTap: () {
                                      //   Navigator.push(
                                      //     context,
                                      //     MaterialPageRoute(
                                      //       builder: (context) =>
                                      //           const CelebrityPicksScreen(),
                                      //     ),
                                      //   );
                                      // },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isSmallScreen ? 12 : 16,
                                          vertical: isSmallScreen ? 6 : 8,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppConstants.textSecondary
                                                  .withValues(alpha: 0.1),
                                              AppConstants.textSecondary
                                                  .withValues(alpha: 0.05),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: AppConstants.textSecondary
                                                .withValues(alpha: 0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'View All',
                                              style: TextStyle(
                                                fontSize:
                                                    isSmallScreen ? 12 : 14,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    AppConstants.textSecondary,
                                              ),
                                            ),
                                            SizedBox(
                                                width: isSmallScreen ? 4 : 6),
                                            Icon(
                                              Icons.arrow_forward_ios,
                                              size: isSmallScreen ? 12 : 14,
                                              color: AppConstants.textSecondary,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Enhanced horizontal scrolling list with responsive sizing
                    SizedBox(
                      height: isSmallScreen ? 280 : 300,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 12 : 16),
                        itemCount: celebrityPicks.length,
                        itemBuilder: (context, index) {
                          final pick = celebrityPicks[index];
                          return TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            duration:
                                Duration(milliseconds: 250 + (index * 50)),
                            curve: Curves.easeOutCubic,
                            builder: (context, itemValue, child) {
                              return Transform.translate(
                                offset: Offset(0, 30 * (1 - itemValue)),
                                child: Opacity(
                                  opacity: itemValue,
                                  child: Container(
                                    width: isSmallScreen ? 180 : 200,
                                    margin: EdgeInsets.only(
                                        right: isSmallScreen ? 12 : 16),
                                    child: CelebrityPickCard(
                                      product: pick['product'] as Product,
                                      celebrityName: pick['name'] as String,
                                      celebrityImage: pick['image'] as String,
                                      testimonial:
                                          pick['testimonial'] as String?,
                                      socialMediaLinks: pick['socialMediaLinks']
                                              as Map<String, String>? ??
                                          {},
                                      recommendedProducts:
                                          pick['recommendedProducts']
                                                  as List<Product>? ??
                                              [],
                                      morningRoutineProducts:
                                          pick['morningRoutineProducts']
                                                  as List<Product>? ??
                                              [],
                                      eveningRoutineProducts:
                                          pick['eveningRoutineProducts']
                                                  as List<Product>? ??
                                              [],
                                      index: index,
                                      onTap: null, // Disabled for now
                                      // onTap: () async {
                                      //   await _navigateToProductWithProvider(
                                      //     context,
                                      //     pick['product'] as Product,
                                      //     celebrityName: pick['name'] as String,
                                      //     celebrityImage:
                                      //         pick['image'] as String,
                                      //     testimonial:
                                      //         pick['testimonial'] as String?,
                                      //   );
                                      // },
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

  Widget _buildNewArrivalsSection(bool isSmallScreen, bool isMediumScreen) {
    return ProductConsumer(
      builder: (context, productProvider, child) {
        // Handle loading state
        if (productProvider.isLoading) {
          return _buildLoadingSection('Loading New Arrivals...', isSmallScreen);
        }

        // Handle error state
        if (productProvider.hasError) {
          return _buildErrorSection(
            'Failed to load new arrivals',
            () => productProvider.loadNewArrivals(),
            isSmallScreen,
          );
        }

        // Get new arrivals data
        final newArrivals = productProvider.newArrivals;

        if (newArrivals.isEmpty) {
          return _buildEmptySection('No new arrivals available', isSmallScreen);
        }

        // Calculate grid columns based on screen size
        int crossAxisCount;
        double childAspectRatio;

        if (isSmallScreen) {
          crossAxisCount = 2;
          childAspectRatio = 0.7;
        } else if (isMediumScreen) {
          crossAxisCount = 3;
          childAspectRatio = 0.75;
        } else {
          crossAxisCount = 4;
          childAspectRatio = 0.8;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                  isSmallScreen ? 12 : 16,
                  isSmallScreen ? 24 : 32,
                  isSmallScreen ? 12 : 16,
                  isSmallScreen ? 12 : 16),
              child: Text(
                'NEW ARRIVALS',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.accentColor,
                  letterSpacing: isSmallScreen ? 0.8 : 1.2,
                ),
              ),
            ),
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: isSmallScreen ? 8 : 12,
                  mainAxisSpacing: isSmallScreen ? 8 : 12,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: newArrivals.length,
                itemBuilder: (context, index) {
                  final product = newArrivals[index];
                  return _buildNewArrivalCard(product, isSmallScreen);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNewArrivalCard(Product product, bool isSmallScreen) {
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
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with favorite button and beauty points
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  // Product image
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      color: AppConstants.backgroundColor,
                    ),
                    child: product.images.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: OptimizedImage(
                              imageUrl: product.images.first,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.spa_outlined,
                              size: isSmallScreen ? 32 : 40,
                              color: AppConstants.accentColor
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                  ),
                  Positioned(
                    top: isSmallScreen ? 6 : 8,
                    left: isSmallScreen ? 6 : 8,
                    child: WishlistButton(
                      product: product,
                      size: isSmallScreen ? 14 : 18,
                      heroTag: 'new_arrivals_wishlist_${product.id}',
                    ),
                  ),
                  // Beauty Points positioned at bottom-right of image
                  Positioned(
                    bottom: isSmallScreen ? 6 : 8,
                    right: isSmallScreen ? 6 : 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            AppConstants.favoriteColor.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.stars_rounded,
                            size: isSmallScreen ? 12 : 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '+${product.beautyPoints}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 10 : 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
                padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name and brand
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product name
                          Text(
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
                          // Brand name directly under product name
                          if (product.brand.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              product.brand,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 11 : 12,
                                fontWeight: FontWeight.w500,
                                color: AppConstants.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Price on the left
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (product.discountPrice != null) ...[
                                Text(
                                  _formatPrice(product.price),
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 11 : 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppConstants.textSecondary,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                Text(
                                  _formatPrice(product.discountPrice!),
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 13 : 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppConstants.errorColor,
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  _formatPrice(product.price),
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 13 : 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppConstants.textPrimary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Rating on the right
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                AppConstants.accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                size: isSmallScreen ? 14 : 16,
                                color: AppConstants.accentColor,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                product.rating.toString(),
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 14,
                                  color: AppConstants.accentColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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
      ),
    );
  }

  Widget _buildBestsellingSection(bool isSmallScreen, bool isMediumScreen) {
    return ProductConsumer(
      builder: (context, productProvider, child) {
        // Handle loading state
        if (productProvider.isLoading) {
          return _buildLoadingSection(
              'Loading Bestselling Products...', isSmallScreen);
        }

        // Handle error state
        if (productProvider.hasError) {
          return _buildErrorSection(
            'Failed to load bestselling products',
            () => productProvider.loadBestsellingProducts(),
            isSmallScreen,
          );
        }

        // Get bestselling products data
        final bestsellingProducts = productProvider.bestsellingProducts;

        if (bestsellingProducts.isEmpty) {
          return _buildEmptySection(
              'No bestselling products available', isSmallScreen);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                  isSmallScreen ? 12 : 16,
                  isSmallScreen ? 24 : 32,
                  isSmallScreen ? 12 : 16,
                  isSmallScreen ? 12 : 16),
              child: Text(
                'BESTSELLING PRODUCTS',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.accentColor,
                  letterSpacing: isSmallScreen ? 0.8 : 1.2,
                ),
              ),
            ),
            SizedBox(
              height: isSmallScreen ? 240 : 260,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding:
                    EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
                itemCount: bestsellingProducts.length,
                physics: const BouncingScrollPhysics(),
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: true,
                itemBuilder: (context, index) {
                  if (index < 0 || index >= bestsellingProducts.length) {
                    return const SizedBox.shrink();
                  }
                  final product = bestsellingProducts[index];
                  return _buildHorizontalProductCard(
                      product, isSmallScreen, index, 'bestselling');
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTrendingSection(bool isSmallScreen, bool isMediumScreen) {
    return ProductConsumer(
      builder: (context, productProvider, child) {
        // Handle loading state
        if (productProvider.isLoading) {
          return _buildLoadingSection(
              'Loading Trending Products...', isSmallScreen);
        }

        // Handle error state
        if (productProvider.hasError) {
          return _buildErrorSection(
            'Failed to load trending products',
            () => productProvider.loadTrendingProducts(),
            isSmallScreen,
          );
        }

        // Get trending products data
        final trendingProducts = productProvider.trendingProducts;

        if (trendingProducts.isEmpty) {
          return _buildEmptySection(
              'No trending products available', isSmallScreen);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                  isSmallScreen ? 12 : 16,
                  isSmallScreen ? 24 : 32,
                  isSmallScreen ? 12 : 16,
                  isSmallScreen ? 12 : 16),
              child: Text(
                'TRENDING PRODUCTS',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.accentColor,
                  letterSpacing: isSmallScreen ? 0.8 : 1.2,
                ),
              ),
            ),
            SizedBox(
              height: isSmallScreen ? 240 : 260,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding:
                    EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
                itemCount: trendingProducts.length,
                physics: const BouncingScrollPhysics(),
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: true,
                itemBuilder: (context, index) {
                  if (index < 0 || index >= trendingProducts.length) {
                    return const SizedBox.shrink();
                  }
                  final product = trendingProducts[index];
                  return _buildHorizontalProductCard(
                      product, isSmallScreen, index, 'trending');
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHorizontalProductCard(
      Product product, bool isSmallScreen, int index, String section) {
    // Validate product data
    if (product.name.isEmpty) {
      return const SizedBox.shrink();
    }

    // Ensure valid dimensions
    final cardWidth = (isSmallScreen ? 160.0 : 180.0).clamp(100.0, 300.0);
    final marginRight = (isSmallScreen ? 12.0 : 16.0).clamp(8.0, 24.0);

    return ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 100,
          maxWidth: 300,
          minHeight: 150,
          maxHeight: 400,
        ),
        child: GestureDetector(
          onTap: () async {
            await _navigateToProductWithProvider(context, product);
          },
          child: Container(
            width: cardWidth,
            margin: EdgeInsets.only(right: marginRight),
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
                // Image with favorite button and beauty points
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          color: AppConstants.backgroundColor,
                        ),
                        child: product.images.isNotEmpty
                            ? ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: OptimizedImage(
                                  imageUrl: product.images.first,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Center(
                                child: Icon(
                                  Icons.spa_outlined,
                                  size: isSmallScreen ? 32 : 40,
                                  color: AppConstants.accentColor
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                      ),
                      Positioned(
                        top: isSmallScreen ? 6 : 8,
                        left: isSmallScreen ? 6 : 8,
                        child: WishlistButton(
                          product: product,
                          size: isSmallScreen ? 14 : 18,
                          heroTag:
                              'horizontal_wishlist_${section}_${product.id}_$index',
                        ),
                      ),
                      // Beauty Points positioned at bottom-right of image
                      Positioned(
                        bottom: isSmallScreen ? 6 : 8,
                        right: isSmallScreen ? 6 : 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppConstants.favoriteColor
                                .withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.stars_rounded,
                                size: isSmallScreen ? 12 : 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '+${product.beautyPoints}',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 10 : 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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
                    padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product name and brand
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product name
                              Text(
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
                              // Brand name directly under product name
                              if (product.brand.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  product.brand,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 11 : 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppConstants.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Price on the left
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (product.discountPrice != null) ...[
                                    Text(
                                      _formatPrice(product.price),
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 11 : 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppConstants.textSecondary,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                    Text(
                                      _formatPrice(product.discountPrice!),
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 13 : 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppConstants.errorColor,
                                      ),
                                    ),
                                  ] else ...[
                                    Text(
                                      _formatPrice(product.price),
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 13 : 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppConstants.textPrimary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Rating on the right
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppConstants.accentColor
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: isSmallScreen ? 14 : 16,
                                    color: AppConstants.accentColor,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    product.rating.toString(),
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 12 : 14,
                                      color: AppConstants.accentColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
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
          ),
        ));
  }

  Widget _buildLoadingSection(String message, bool isSmallScreen) {
    return Container(
      height: isSmallScreen ? 200 : 250,
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16,
        vertical: isSmallScreen ? 16 : 24,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: AppConstants.accentColor,
              strokeWidth: 3,
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              message,
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: AppConstants.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorSection(
      String message, VoidCallback onRetry, bool isSmallScreen) {
    return Container(
      height: isSmallScreen ? 200 : 250,
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16,
        vertical: isSmallScreen ? 16 : 24,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: isSmallScreen ? 40 : 48,
              color: AppConstants.errorColor,
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              message,
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: AppConstants.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.accentColor,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16 : 20,
                  vertical: isSmallScreen ? 8 : 12,
                ),
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySection(String message, bool isSmallScreen) {
    return Container(
      height: isSmallScreen ? 200 : 250,
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16,
        vertical: isSmallScreen ? 16 : 24,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.spa_outlined,
              size: isSmallScreen ? 40 : 48,
              color: AppConstants.textSecondary.withValues(alpha: 0.5),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              message,
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: AppConstants.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
