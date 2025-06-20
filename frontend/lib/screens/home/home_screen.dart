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

    final celebrityNeedsInit = celebrityProvider.celebrities.isEmpty ||
        celebrityProvider.celebrityPicks.isEmpty;

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
      celebrityProvider.loadCelebrities(forceRefresh: true),
      celebrityProvider.loadCelebrityPicks(forceRefresh: true),
    ]);

    _hasInitialized = true; // Set flag back after refresh
  }

  // Helper function to format price in IQD
  String _formatPrice(double price) {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(price)} IQD';
  }

  // Helper function to navigate to product with error handling and validation
  Future<void> _navigateToProductWithProvider(
    BuildContext context,
    Product product, {
    String? celebrityName,
    String? celebrityImage,
    String? testimonial,
  }) async {
    try {
      // Validate product data
      if (product.id.isEmpty) {
        throw Exception('Invalid product ID');
      }

      if (product.name.isEmpty) {
        throw Exception('Invalid product name');
      }

      final productProvider = context.read<ProductProvider>();

      // Try to add to recently viewed, but don't fail navigation if it fails
      try {
        await productProvider.addToRecentlyViewed(product);
        debugPrint(
            'HomeScreen: Added product ${product.name} to recently viewed');
      } catch (e) {
        debugPrint(
            'HomeScreen: Warning - Failed to add to recently viewed: $e');
        // Continue with navigation even if this fails
      }

      // ✅ ENHANCED ERROR HANDLING FOR PRODUCT NAVIGATION
      try {
        // First check if product details can be loaded
        await productProvider.getProductDetail(product.id);

        // If successful, navigate to product detail
        if (context.mounted) {
          debugPrint(
              'HomeScreen: Navigated to product detail for ${product.name}');
          // ✅ CRITICAL FIX: Use proper GoRouter navigation with pathParameters
          context.pushNamed('product-detail', pathParameters: {
            'productId': product.id,
          }, extra: {
            'product': product,
            'celebrityName': celebrityName,
            'celebrityImage': celebrityImage,
            'testimonial': testimonial,
          });
        }
      } catch (e) {
        // ✅ HANDLE 404 AND OTHER API ERRORS GRACEFULLY
        debugPrint('HomeScreen: Product detail error: $e');

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'This product is currently unavailable. Please try again later.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.orange[600],
              duration: Duration(seconds: 3),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('HomeScreen: Navigation error: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to open product. Please try again.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red[600],
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Helper function to navigate to celebrity profile
  Future<void> _navigateToCelebrity(
    BuildContext context, {
    String? celebrityName,
    int? celebrityId,
  }) async {
    try {
      debugPrint(
          'HomeScreen: Navigating to celebrity - name: $celebrityName, id: $celebrityId');

      if (celebrityName == null && celebrityId == null) {
        throw Exception('Missing celebrity name or ID');
      }

      // ✅ CRITICAL FIX: Check context BEFORE starting async operations
      if (!context.mounted) {
        debugPrint(
            'HomeScreen: Context not mounted at start, aborting navigation');
        return;
      }

      final celebrityProvider = context.read<CelebrityProvider>();

      // ✅ ENHANCED CELEBRITY NAVIGATION
      try {
        // If we have celebrity name, find by name first
        if (celebrityName != null) {
          await celebrityProvider.selectCelebrity(celebrityName);
        }
        // Otherwise use ID
        else if (celebrityId != null) {
          await celebrityProvider.selectCelebrityById(celebrityId);
        }

        // ✅ CRITICAL FIX: Check context IMMEDIATELY after async operation
        if (!context.mounted) {
          debugPrint(
              'HomeScreen: Context unmounted after celebrity loading, aborting navigation');
          return;
        }

        // Verify celebrity was loaded successfully
        if (celebrityProvider.selectedCelebrity == null) {
          throw Exception('Celebrity not found');
        }

        debugPrint(
            'HomeScreen: Celebrity loaded successfully - ${celebrityProvider.selectedCelebrity!.name}');

        // ✅ CRITICAL FIX: Navigate IMMEDIATELY while context is still mounted
        debugPrint('HomeScreen: Navigating to celebrity screen...');
        debugPrint(
            'HomeScreen: Current route before navigation: ${GoRouterState.of(context).uri}');

        try {
          // ✅ USE GOROUTER FOR CONSISTENT NAVIGATION
          context.pushNamed('celebrity');
          debugPrint('HomeScreen: context.pushNamed called successfully');

          // Add a small delay to check if navigation actually happened
          Future.delayed(Duration(milliseconds: 100), () {
            if (context.mounted) {
              debugPrint(
                  'HomeScreen: Post-navigation route check: ${GoRouterState.of(context).uri}');
            }
          });

          debugPrint('HomeScreen: Celebrity navigation completed');
        } catch (navError) {
          debugPrint('HomeScreen: Navigation error: $navError');

          // Try alternative navigation if GoRouter fails
          debugPrint('HomeScreen: Attempting fallback navigation...');
          if (context.mounted) {
            try {
              context.push('/celebrity');
              debugPrint('HomeScreen: Fallback navigation successful');
            } catch (fallbackError) {
              debugPrint(
                  'HomeScreen: Fallback navigation also failed: $fallbackError');
            }
          }
        }
      } catch (e) {
        debugPrint('HomeScreen: Celebrity loading error: $e');

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Unable to load celebrity profile. Please try again.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.orange[600],
              duration: Duration(seconds: 3),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('HomeScreen: Celebrity navigation error: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to open celebrity profile. Please try again.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red[600],
            duration: Duration(seconds: 3),
          ),
        );
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
    return Consumer<CelebrityProvider>(
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
            () => celebrityProvider.loadCelebrityPicks(forceRefresh: true),
            isSmallScreen,
          );
        }

        // Get celebrity picks data
        final celebrityPicks = celebrityProvider.celebrityPicks;

        if (celebrityPicks.isEmpty) {
          return _buildEmptySection(
              'No celebrity picks available', isSmallScreen);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Padding(
              padding: EdgeInsets.fromLTRB(
                  isSmallScreen ? 12 : 16,
                  isSmallScreen ? 24 : 32,
                  isSmallScreen ? 12 : 16,
                  isSmallScreen ? 16 : 20),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppConstants.accentColor.withValues(alpha: 0.1),
                          AppConstants.favoriteColor.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.star_rounded,
                      color: AppConstants.accentColor,
                      size: isSmallScreen ? 16 : 20,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CELEBRITY PICKS',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.textPrimary,
                            letterSpacing: isSmallScreen ? 0.8 : 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Handpicked by your favorite stars',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 13,
                            color: AppConstants.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CelebrityPicksScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 16,
                        vertical: isSmallScreen ? 6 : 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppConstants.accentColor.withValues(alpha: 0.1),
                            AppConstants.accentColor.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              AppConstants.accentColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View All',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.accentColor,
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 4 : 6),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: isSmallScreen ? 12 : 14,
                            color: AppConstants.accentColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Horizontal scroll list with CelebrityPickCard
            SizedBox(
              height: isSmallScreen ? 280 : 320,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding:
                    EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
                itemCount: celebrityPicks.length,
                itemBuilder: (context, index) {
                  final celebrityPick = celebrityPicks[index];

                  try {
                    // Extract product data from the celebrity pick
                    final productData =
                        celebrityPick['product'] as Map<String, dynamic>?;
                    if (productData == null) {
                      throw Exception('Invalid product data');
                    }

                    // Convert to Product model
                    final product = Product.fromJson(productData);

                    // Extract celebrity data from the pick
                    final celebrityName =
                        celebrityPick['name'] as String? ?? 'Celebrity';
                    final celebrityImage =
                        celebrityPick['image'] as String? ?? '';
                    final testimonial =
                        celebrityPick['testimonial'] as String? ??
                            'Amazing product!';
                    // Extract celebrity ID - CRITICAL for navigation
                    final celebrityId = celebrityPick['id'] as int? ??
                        celebrityPick['celebrity_id'] as int?;

                    // Convert social media links to Map<String, String>
                    final socialMediaLinksRaw =
                        celebrityPick['social_media_links']
                                as Map<String, dynamic>? ??
                            {};
                    final socialMediaLinks = socialMediaLinksRaw
                        .map((key, value) => MapEntry(key, value.toString()));

                    // Convert product lists to List<Product>
                    final recommendedProductsRaw =
                        (celebrityPick['recommended_products'] as List?)
                                ?.cast<Map<String, dynamic>>() ??
                            [];
                    final recommendedProducts = recommendedProductsRaw
                        .map((productData) => Product.fromJson(productData))
                        .toList();

                    final morningRoutineProductsRaw =
                        (celebrityPick['morning_routine_products'] as List?)
                                ?.cast<Map<String, dynamic>>() ??
                            [];
                    final morningRoutineProducts = morningRoutineProductsRaw
                        .map((productData) => Product.fromJson(productData))
                        .toList();

                    final eveningRoutineProductsRaw =
                        (celebrityPick['evening_routine_products'] as List?)
                                ?.cast<Map<String, dynamic>>() ??
                            [];
                    final eveningRoutineProducts = eveningRoutineProductsRaw
                        .map((productData) => Product.fromJson(productData))
                        .toList();

                    return Container(
                      width: isSmallScreen ? 200 : 240,
                      margin: EdgeInsets.only(right: isSmallScreen ? 12 : 16),
                      child: CelebrityPickCard(
                        product: product,
                        celebrityName: celebrityName,
                        celebrityImage: celebrityImage,
                        testimonial: testimonial,
                        index: index,
                        socialMediaLinks: socialMediaLinks,
                        recommendedProducts: recommendedProducts,
                        morningRoutineProducts: morningRoutineProducts,
                        eveningRoutineProducts: eveningRoutineProducts,
                        celebrityId:
                            celebrityId, // CRITICAL: Pass celebrity ID for navigation
                        onTap: () async {
                          await _navigateToProductWithProvider(
                              context, product);
                        },
                        // CRITICAL: Add celebrity tap callback for navigation
                        onCelebrityTap: () async {
                          await _navigateToCelebrity(context,
                              celebrityName: celebrityName,
                              celebrityId: celebrityId);
                        },
                      ),
                    );
                  } catch (e) {
                    debugPrint(
                        'HomeScreen: Error building celebrity pick card at index $index: $e');
                    // Return a placeholder on error
                    return Container(
                      width: isSmallScreen ? 200 : 240,
                      margin: EdgeInsets.only(right: isSmallScreen ? 12 : 16),
                      child: const Card(
                        child: Center(
                          child: Text('Unable to load pick'),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
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
    // Validate product data
    if (product.name.isEmpty) {
      return const SizedBox.shrink();
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 120,
        maxWidth: 350,
        minHeight: 180,
        maxHeight: 450,
      ),
      child: GestureDetector(
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
                        size: isSmallScreen ? 16 : 20,
                        heroTag: 'new_arrivals_wishlist_${product.id}',
                      ),
                    ),
                    // Beauty Points positioned at bottom-right of image (matching other sections)
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
              // Product details (matching trending/bestselling style)
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

                          // Rating on the right (matching other sections)
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

  Widget _buildCelebrityPickCard(Product product, bool isSmallScreen) {
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
            // Image with favorite button and celebrity pick badge
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
                    top: 8,
                    right: 8,
                    child: WishlistButton(
                      product: product,
                      size: isSmallScreen ? 20 : 24,
                    ),
                  ),
                  // Celebrity pick badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 6 : 8,
                        vertical: isSmallScreen ? 2 : 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppConstants.favoriteColor,
                            AppConstants.favoriteColor.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            size: isSmallScreen ? 10 : 12,
                            color: Colors.white,
                          ),
                          SizedBox(width: isSmallScreen ? 2 : 4),
                          Text(
                            'PICK',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 9 : 11,
                              fontWeight: FontWeight.bold,
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
                    // Product name
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Price and rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (product.discountPrice != null &&
                                product.discountPrice! < product.price)
                              Text(
                                _formatPrice(product.price),
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 10 : 12,
                                  color: AppConstants.textSecondary,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            Text(
                              _formatPrice(
                                  product.discountPrice ?? product.price),
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.accentColor,
                              ),
                            ),
                          ],
                        ),
                        // Rating
                        if (product.rating > 0)
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                size: isSmallScreen ? 12 : 14,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                product.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 10 : 12,
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
