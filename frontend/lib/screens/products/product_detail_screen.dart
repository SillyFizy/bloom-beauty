import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/product_model.dart';
import '../../constants/app_constants.dart';
import '../../providers/cart_provider.dart';
import '../../providers/celebrity_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/common/wishlist_button.dart';
import '../../widgets/common/optimized_image.dart';
import '../celebrity/celebrity_screen.dart';
import '../celebrity_picks/celebrity_picks_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId; // Always use product ID to fetch from backend

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with TickerProviderStateMixin {
  // TabController not needed since we only show description
  // late TabController _tabController;
  late PageController _imagePageController;
  late ScrollController _scrollController;
  late AnimationController _headerAnimationController;
  late Animation<double> _headerAnimation;
  ProductVariant? _selectedVariant;
  int _currentImageIndex = 0;
  bool _showStickyHeader = false;

  // State for fetching product from backend
  Product? _product;
  bool _isLoading = false;
  String? _error;

  // Celebrity data for featured products
  Map<String, dynamic>? _celebrityData;
  bool _isLoadingCelebrity = false;

  // Track quantities for each variant (starting from 0)
  final Map<String, int> _variantQuantities = {};

  // Always use fetched product
  Product? get currentProduct => _product;

  @override
  void initState() {
    super.initState();

    // TabController removed - no tabs needed since we only show description
    // _tabController = TabController(length: 1, vsync: this);
    _imagePageController = PageController();
    _scrollController = ScrollController();

    // Initialize header animation controller
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _headerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeInOutCubic,
    ));

    // Add scroll listener for sticky header
    _scrollController.addListener(_onScroll);

    // Always fetch product from backend using slug
    _fetchProductDetail();
  }

  void _fetchProductDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);
      final product = await productProvider.getProductDetail(widget.productId);

      if (mounted) {
        setState(() {
          _product = product;
          _isLoading = false;
        });

        if (product != null) {
          _initializeProduct();
          // If product is featured, fetch celebrity data
          if (product.isFeatured) {
            _fetchCelebrityData();
          }
        } else {
          setState(() {
            _error = 'Product not found';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load product: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _initializeProduct() {
    if (currentProduct == null) return;

    // Initialize variant quantities properly
    if (currentProduct!.variants.isNotEmpty) {
      _selectedVariant = currentProduct!.variants.first;
      // Initialize all variant quantities to 0
      for (var variant in currentProduct!.variants) {
        _variantQuantities[variant.id] = 0;
      }
    } else {
      // For products without variants, use default key
      _variantQuantities['default'] = 0;
    }
  }

  void _fetchCelebrityData() async {
    if (currentProduct == null || !currentProduct!.isFeatured) return;

    setState(() {
      _isLoadingCelebrity = true;
    });

    try {
      final celebrityProvider =
          Provider.of<CelebrityProvider>(context, listen: false);

      // Get featured celebrity picks to find which celebrity features this product
      final celebrityPicks =
          await celebrityProvider.getFeaturedCelebrityPicks();

      print(
          'DEBUG: Fetching celebrity data for product: ${currentProduct!.id}');
      print('DEBUG: Found ${celebrityPicks.length} celebrity picks');

      // If no celebrity picks found, try alternative approach
      if (celebrityPicks.isEmpty) {
        print('DEBUG: No celebrity picks found, product might not be featured');
        setState(() {
          _celebrityData = null;
          _isLoadingCelebrity = false;
        });
        return;
      }

      // Find the celebrity who features this product
      for (var pick in celebrityPicks) {
        final product = pick['product'] as Map<String, dynamic>?;
        final celebrity = pick['celebrity'] as Map<String, dynamic>?;

        // Try multiple matching strategies for product identification
        bool isMatchingProduct = false;

        if (product != null) {
          // Strategy 1: Match by slug
          if (product['slug'] == currentProduct!.id) {
            isMatchingProduct = true;
            print('DEBUG: Product matched by slug: ${product['slug']}');
          }
          // Strategy 2: Match by ID (as string)
          else if (product['id'].toString() == currentProduct!.id) {
            isMatchingProduct = true;
            print('DEBUG: Product matched by ID: ${product['id']}');
          }
          // Strategy 3: Match by name (case insensitive)
          else if (product['name'] != null &&
              currentProduct!.name.isNotEmpty &&
              product['name'].toString().toLowerCase().trim() ==
                  currentProduct!.name.toLowerCase().trim()) {
            isMatchingProduct = true;
            print('DEBUG: Product matched by name: ${product['name']}');
          }
        }

        if (isMatchingProduct) {
          // Found the celebrity data for this product
          print('DEBUG: Found celebrity for product ${currentProduct!.id}:');
          print('DEBUG: Pick data structure: ${pick.keys.toList()}');
          print('DEBUG: Product data: $product');
          print('DEBUG: Celebrity data: $celebrity');

          // Extract celebrity name - try multiple sources with priority
          String celebrityName = 'Celebrity';
          String? celebrityImage;
          int? celebrityId;

          // Priority 1: Direct celebrity object with combined name
          if (celebrity != null) {
            if (celebrity['first_name'] != null &&
                celebrity['last_name'] != null) {
              final firstName = celebrity['first_name'].toString().trim();
              final lastName = celebrity['last_name'].toString().trim();
              if (firstName.isNotEmpty && lastName.isNotEmpty) {
                celebrityName = '$firstName $lastName';
                print('DEBUG: Using celebrity first/last name: $celebrityName');
              }
            }
            // Priority 2: Celebrity name field
            else if (celebrity['name'] != null &&
                celebrity['name'].toString().trim().isNotEmpty) {
              celebrityName = celebrity['name'].toString().trim();
              print('DEBUG: Using celebrity name field: $celebrityName');
            }
            // Priority 3: Celebrity full_name field
            else if (celebrity['full_name'] != null &&
                celebrity['full_name'].toString().trim().isNotEmpty) {
              celebrityName = celebrity['full_name'].toString().trim();
              print('DEBUG: Using celebrity full_name: $celebrityName');
            }
          }

          // Priority 4: Pick name (fallback)
          if (celebrityName == 'Celebrity' &&
              pick['name'] != null &&
              pick['name'].toString().trim().isNotEmpty) {
            celebrityName = pick['name'].toString().trim();
            print('DEBUG: Using pick name as fallback: $celebrityName');
          }

          // Extract celebrity image with priority
          // Priority 1: Celebrity object image
          if (celebrity != null &&
              celebrity['image'] != null &&
              celebrity['image'].toString().trim().isNotEmpty) {
            celebrityImage = celebrity['image'].toString().trim();
            print('DEBUG: Using celebrity image: $celebrityImage');
          }
          // Priority 2: Pick image (fallback)
          else if (pick['image'] != null &&
              pick['image'].toString().trim().isNotEmpty) {
            celebrityImage = pick['image'].toString().trim();
            print('DEBUG: Using pick image as fallback: $celebrityImage');
          }

          // Extract celebrity ID
          if (celebrity != null && celebrity['id'] != null) {
            try {
              celebrityId = int.parse(celebrity['id'].toString());
              print('DEBUG: Using celebrity ID: $celebrityId');
            } catch (e) {
              print('DEBUG: Error parsing celebrity ID: $e');
            }
          }

          print('DEBUG: Final celebrity data:');
          print('  Name: $celebrityName');
          print('  Image: $celebrityImage');
          print('  ID: $celebrityId');

          setState(() {
            _celebrityData = {
              'celebrity_name': celebrityName,
              'celebrity_image': celebrityImage,
              'celebrity_id': celebrityId,
            };
            _isLoadingCelebrity = false;
          });
          return;
        }
      }

      // If no specific celebrity found, use generic data
      setState(() {
        _celebrityData = {
          'celebrity_name': 'Celebrity',
          'celebrity_image': null,
          'celebrity_id': null,
        };
        _isLoadingCelebrity = false;
      });
    } catch (e) {
      print('DEBUG: Error fetching celebrity data: $e');
      setState(() {
        _isLoadingCelebrity = false;
        _celebrityData =
            null; // Set to null instead of generic data to hide badge
      });
    }
  }

  @override
  void dispose() {
    // _tabController.dispose(); // Commented out since TabController is not used
    _imagePageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Calculate scroll threshold for smooth transition
    const threshold = 120.0; // Show sticky header after scrolling past 120px

    final shouldShow =
        _scrollController.hasClients && _scrollController.offset > threshold;

    if (shouldShow != _showStickyHeader) {
      setState(() {
        _showStickyHeader = shouldShow;
      });

      if (shouldShow) {
        _headerAnimationController.forward();
      } else {
        _headerAnimationController.reverse();
      }
    }
  }

  String _formatPrice(double price) {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(price)} IQD';
  }

  List<String> get _currentImages {
    if (currentProduct == null) return [];
    return currentProduct!.getCurrentImages(_selectedVariant);
  }

  void _updateVariantQuantity(String variantId, int newQuantity) {
    if (currentProduct == null || newQuantity < 0 || newQuantity > 99) return;

    setState(() {
      _variantQuantities[variantId] = newQuantity;
      // Only update selected variant if the product has variants and it's not the default case
      if (newQuantity > 0 &&
          variantId != 'default' &&
          currentProduct!.variants.isNotEmpty) {
        _selectedVariant =
            currentProduct!.variants.firstWhere((v) => v.id == variantId);
        _currentImageIndex = 0;
        _imagePageController.animateToPage(
          0,
          duration: AppConstants.shortAnimation,
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // Calculate total price for all selected variants
  double get _totalPrice {
    if (currentProduct == null) return 0.0;

    double total = 0;
    for (var entry in _variantQuantities.entries) {
      final variantId = entry.key;
      final quantity = entry.value;
      if (quantity > 0) {
        if (variantId == 'default') {
          total += currentProduct!.price * quantity;
        } else {
          final variant =
              currentProduct!.variants.firstWhere((v) => v.id == variantId);
          total += currentProduct!.getCurrentPrice(variant) * quantity;
        }
      }
    }
    return total;
  }

  // Get total quantity across all variants
  int get _totalQuantity {
    return _variantQuantities.values.fold(0, (sum, quantity) => sum + quantity);
  }

  void _addToCart() {
    if (currentProduct == null) return;

    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // Add all selected variants to cart
    cartProvider.addMultipleItems(currentProduct!, _variantQuantities);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Added $_totalQuantity item${_totalQuantity > 1 ? 's' : ''} to cart'),
        backgroundColor: AppConstants.successColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    // Reset quantities after adding to cart
    setState(() {
      for (var key in _variantQuantities.keys) {
        _variantQuantities[key] = 0;
      }
    });
  }

  // Helper method to get celebrity data using CelebrityProvider
  Future<Map<String, dynamic>> _getCelebrityData(String celebrityName) async {
    final celebrityProvider = context.read<CelebrityProvider>();
    return await celebrityProvider.getCelebrityDataForProduct(celebrityName);
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show error state
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Error'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  _fetchProductDetail();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Show not found state
    if (currentProduct == null) {
      return Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Product Not Found'),
        ),
        body: const Center(
          child: Text(
            'Product not found',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine screen size
        final isSmallScreen = constraints.maxWidth < 600;

        return Scaffold(
          backgroundColor: AppConstants.backgroundColor,
          body: Stack(
            children: [
              // Main content
              CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Remove the SliverAppBar completely to eliminate top space

                  // Image section with scrollable buttons
                  SliverToBoxAdapter(
                    child: Stack(
                      children: [
                        _buildImageSection(isSmallScreen),
                        // Action buttons that scroll with content - positioned higher
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 16,
                          left: 16,
                          right: 16,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildTransparentActionButton(
                                icon: Icons.arrow_back_ios,
                                onPressed: () => Navigator.pop(context),
                                isSmallScreen: isSmallScreen,
                              ),
                              Row(
                                children: [
                                  FloatingWishlistButton(
                                    product: currentProduct!,
                                  ),
                                  SizedBox(width: isSmallScreen ? 8 : 12),
                                  _buildTransparentActionButton(
                                    icon: Icons.share,
                                    onPressed: () {},
                                    isSmallScreen: isSmallScreen,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content section
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppConstants.surfaceColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          _buildProductInfo(isSmallScreen),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          _buildVariantSelector(isSmallScreen),
                          if (currentProduct!.isFeatured)
                            _buildCelebrityFeaturedBadge(isSmallScreen),
                          SizedBox(height: isSmallScreen ? 20 : 24),
                          _buildTabSection(isSmallScreen),
                          SizedBox(
                              height: isSmallScreen
                                  ? 80
                                  : 100), // Space for bottom bar
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Sticky header - always positioned correctly at top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _headerAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, -100 * (1 - _headerAnimation.value)),
                      child: Opacity(
                        opacity: _headerAnimation.value,
                        child: _buildStickyHeader(isSmallScreen),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          bottomNavigationBar:
              (currentProduct!.variants.isEmpty || _totalQuantity > 0)
                  ? _buildBottomBar(isSmallScreen)
                  : null,
        );
      },
    );
  }

  Widget _buildTransparentActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isSmallScreen,
  }) {
    return Container(
      width: isSmallScreen ? 44 : 52,
      height: isSmallScreen ? 44 : 52,
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
        border: Border.all(
          color: AppConstants.borderColor.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppConstants.textSecondary.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.05),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
            splashColor: AppConstants.primaryColor.withValues(alpha: 0.1),
            highlightColor: AppConstants.primaryColor.withValues(alpha: 0.05),
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Center(
                child: icon == Icons.arrow_back_ios
                    ? Container(
                        padding: EdgeInsets.only(left: isSmallScreen ? 2 : 3),
                        child: Icon(
                          Icons.arrow_back_ios,
                          color: AppConstants.textPrimary,
                          size: isSmallScreen ? 20 : 24,
                        ),
                      )
                    : Icon(
                        icon,
                        color: AppConstants.textPrimary,
                        size: isSmallScreen ? 20 : 24,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStickyHeader(bool isSmallScreen) {
    return Container(
      height: MediaQuery.of(context).padding.top + (isSmallScreen ? 68 : 76),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: AppConstants.textSecondary.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppConstants.textSecondary.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Enhanced backdrop effect
          Container(
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor.withValues(alpha: 0.90),
              border: Border(
                bottom: BorderSide(
                  color: AppConstants.borderColor.withValues(alpha: 0.1),
                  width: 0.5,
                ),
              ),
            ),
          ),

          // Header content
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStickyActionButton(
                  icon: Icons.arrow_back_ios,
                  onPressed: () => Navigator.pop(context),
                  isSmallScreen: isSmallScreen,
                ),

                // Product name in center
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      currentProduct!.name,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                Row(
                  children: [
                    Container(
                      width: isSmallScreen ? 44 : 52,
                      height: isSmallScreen ? 44 : 52,
                      decoration: BoxDecoration(
                        color: AppConstants.surfaceColor,
                        borderRadius:
                            BorderRadius.circular(isSmallScreen ? 14 : 16),
                        border: Border.all(
                          color:
                              AppConstants.borderColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppConstants.textSecondary
                                .withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: WishlistButton(
                          product: currentProduct!,
                          size: isSmallScreen ? 20 : 24,
                          showBackground: false,
                          showShadow: false,
                          heroTag:
                              'sticky_header_wishlist_${currentProduct!.id}',
                        ),
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    _buildStickyActionButton(
                      icon: Icons.share,
                      onPressed: () {},
                      isSmallScreen: isSmallScreen,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isSmallScreen,
  }) {
    return Container(
      width: isSmallScreen ? 44 : 52,
      height: isSmallScreen ? 44 : 52,
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
        border: Border.all(
          color: AppConstants.borderColor.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppConstants.textSecondary.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Center(
              child: icon == Icons.arrow_back_ios
                  ? Container(
                      padding: EdgeInsets.only(left: isSmallScreen ? 2 : 3),
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: AppConstants.textPrimary,
                        size: isSmallScreen ? 20 : 24,
                      ),
                    )
                  : Icon(
                      icon,
                      color: AppConstants.textPrimary,
                      size: isSmallScreen ? 20 : 24,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(bool isSmallScreen) {
    final screenHeight = MediaQuery.of(context).size.height;
    final imageHeight =
        isSmallScreen ? screenHeight * 0.4 : screenHeight * 0.45;

    return Container(
      height: imageHeight,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppConstants.backgroundColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // Reduced top spacing - just enough for floating buttons
          SizedBox(height: MediaQuery.of(context).padding.top + 60),

          // Main Image with PageView
          Expanded(
            child: _currentImages.isNotEmpty
                ? PageView.builder(
                    controller: _imagePageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemCount: _currentImages.length,
                    itemBuilder: (context, index) {
                      final imageUrl = _currentImages[index];
                      return Container(
                        margin: EdgeInsets.fromLTRB(
                            isSmallScreen ? 20 : 30,
                            isSmallScreen ? 10 : 15,
                            isSmallScreen ? 20 : 30,
                            isSmallScreen ? 16 : 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: AppConstants.surfaceColor,
                          border: Border.all(
                            color: AppConstants.borderColor,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppConstants.textSecondary
                                  .withValues(alpha: 0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: AspectRatio(
                            aspectRatio: 1.0,
                            child: imageUrl.isNotEmpty
                                ? _buildRobustImage(imageUrl, isSmallScreen)
                                : Container(
                                    color: AppConstants.surfaceColor,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.image_outlined,
                                            size: isSmallScreen ? 60 : 80,
                                            color: AppConstants.accentColor,
                                          ),
                                          SizedBox(
                                              height: isSmallScreen ? 12 : 16),
                                          Text(
                                            'Product Image ${index + 1}',
                                            style: TextStyle(
                                              color: AppConstants.textSecondary,
                                              fontSize: isSmallScreen ? 12 : 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    margin: EdgeInsets.fromLTRB(
                        isSmallScreen ? 20 : 30,
                        isSmallScreen ? 10 : 15,
                        isSmallScreen ? 20 : 30,
                        isSmallScreen ? 16 : 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: AppConstants.surfaceColor,
                      border: Border.all(
                        color: AppConstants.borderColor,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppConstants.textSecondary
                              .withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: Container(
                          color: AppConstants.surfaceColor,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_outlined,
                                  size: isSmallScreen ? 60 : 80,
                                  color: AppConstants.accentColor,
                                ),
                                SizedBox(height: isSmallScreen ? 12 : 16),
                                Text(
                                  'No Image Available',
                                  style: TextStyle(
                                    color: AppConstants.textSecondary,
                                    fontSize: isSmallScreen ? 12 : 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),

          // Image Indicators
          if (_currentImages.length > 1)
            Container(
              height: isSmallScreen ? 50 : 60,
              padding:
                  EdgeInsets.symmetric(horizontal: isSmallScreen ? 20 : 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _currentImages.length,
                  (index) => Container(
                    width: isSmallScreen ? 6 : 8,
                    height: isSmallScreen ? 6 : 8,
                    margin:
                        EdgeInsets.symmetric(horizontal: isSmallScreen ? 3 : 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentImageIndex == index
                          ? AppConstants.accentColor
                          : AppConstants.textSecondary.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRobustImage(String imageUrl, bool isSmallScreen) {
    // Use optimized ProductDetailImage for better mobile performance
    return ProductDetailImage(
      imageUrl: imageUrl,
      isSmallScreen: isSmallScreen,
      fallbackUrls: _getFallbackImageUrls(),
    );
  }

  List<String> _getFallbackImageUrls() {
    // Return full URLs for fallback images optimized for mobile
    return [
      '${AppConstants.baseUrl}/media/products/tiana-eyeshadow-palette_1_product_33_20250507_195811.jpg',
      '${AppConstants.baseUrl}/media/products/riding-solo-single-shadow_1_product_312_20250508_214207.jpg',
      '${AppConstants.baseUrl}/media/products/flawless-stay-liquid-foundation_6_product_167_20250508_161948.jpg',
      '${AppConstants.baseUrl}/media/products/lesdomakeup-mi-vida-lip-trio_1_product_239_20250508_204511.jpg',
      '${AppConstants.baseUrl}/media/products/yerimua-bad-lip-duo_1_product_350_20250508_220246.jpg',
      '${AppConstants.baseUrl}/media/products/volumizing-mascara_1_product_456_20250509_205844.jpg',
    ];
  }

  Widget _buildProductInfo(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            currentProduct!.name,
            style: TextStyle(
              fontSize: isSmallScreen ? 20 : 26,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currentProduct!.brand,
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: AppConstants.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < currentProduct!.rating.floor()
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: AppConstants.accentColor,
                    size: isSmallScreen ? 16 : 20,
                  );
                }),
              ),
              const SizedBox(width: 12),
              Text(
                currentProduct!.rating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 16,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${currentProduct!.reviewCount} reviews)',
                style: TextStyle(
                  fontSize: isSmallScreen ? 10 : 14,
                  color: AppConstants.textSecondary,
                ),
              ),
            ],
          ),

          // Beauty Points section (always show, even if 0)
          const SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12 : 16,
              vertical: isSmallScreen ? 8 : 10,
            ),
            decoration: BoxDecoration(
              color: AppConstants.favoriteColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppConstants.favoriteColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.stars_rounded,
                  color: AppConstants.favoriteColor,
                  size: isSmallScreen ? 18 : 22,
                ),
                SizedBox(width: isSmallScreen ? 6 : 8),
                Text(
                  'Earn ${currentProduct!.beautyPoints} Beauty Points',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.favoriteColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCelebrityFeaturedBadge(bool isSmallScreen) {
    // Show loading state while fetching celebrity data
    if (_isLoadingCelebrity) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppConstants.favoriteColor.withValues(alpha: 0.08),
              AppConstants.accentColor.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppConstants.favoriteColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppConstants.surfaceColor,
                border: Border.all(
                  color: AppConstants.favoriteColor,
                  width: 2,
                ),
              ),
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppConstants.favoriteColor),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Loading celebrity info...',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w500,
                  color: AppConstants.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final celebrityName = _celebrityData?['celebrity_name'] ?? 'Celebrity';
    final celebrityImage = _celebrityData?['celebrity_image'];
    final celebrityId = _celebrityData?['celebrity_id'];

    return GestureDetector(
      onTap: () async {
        // Navigate to celebrity profile if we have celebrity ID
        if (celebrityId != null) {
          try {
            final celebrityProvider =
                Provider.of<CelebrityProvider>(context, listen: false);
            await celebrityProvider.selectCelebrityById(celebrityId);

            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CelebrityScreen(),
                ),
              );
            }
          } catch (e) {
            print('DEBUG: Error navigating to celebrity profile: $e');
            // Fallback to celebrity picks screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CelebrityPicksScreen(),
              ),
            );
          }
        } else {
          // No celebrity ID, navigate to celebrity picks screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CelebrityPicksScreen(),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppConstants.favoriteColor.withValues(alpha: 0.08),
              AppConstants.accentColor.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppConstants.favoriteColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppConstants.favoriteColor.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Celebrity Image or Star Icon
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppConstants.favoriteColor,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.favoriteColor.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: AppConstants.surfaceColor,
                backgroundImage:
                    celebrityImage != null && celebrityImage.isNotEmpty
                        ? NetworkImage('${AppConstants.baseUrl}$celebrityImage')
                        : null,
                child: celebrityImage == null || celebrityImage.isEmpty
                    ? const Icon(
                        Icons.star_rounded,
                        color: AppConstants.favoriteColor,
                        size: 24,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Featured by',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 13,
                      color: AppConstants.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    celebrityName,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.favoriteColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantSelector(bool isSmallScreen) {
    if (currentProduct!.variants.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 20 : 30,
          vertical: isSmallScreen ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette_outlined,
                color: AppConstants.accentColor,
                size: isSmallScreen ? 16 : 20,
              ),
              SizedBox(width: isSmallScreen ? 6 : 8),
              Text(
                'Available Options',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Wrap(
            spacing: isSmallScreen ? 8 : 12,
            runSpacing: isSmallScreen ? 8 : 12,
            children: currentProduct!.variants.asMap().entries.map((entry) {
              final ProductVariant variant = entry.value;
              final bool isSelected = _selectedVariant?.id == variant.id;
              final int variantQuantity = _variantQuantities[variant.id] ?? 0;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedVariant = variant;
                    _currentImageIndex = 0;
                    if (!_variantQuantities.containsKey(variant.id)) {
                      _variantQuantities[variant.id] = 0;
                    }
                  });
                  _imagePageController.animateToPage(
                    0,
                    duration: AppConstants.shortAnimation,
                    curve: Curves.easeInOut,
                  );
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedContainer(
                      duration: AppConstants.mediumAnimation,
                      curve: Curves.easeInOut,
                      constraints: BoxConstraints(
                        minWidth: isSmallScreen ? 140 : 160,
                        minHeight: isSmallScreen ? 100 : 110,
                      ),
                      padding: EdgeInsets.fromLTRB(
                        isSmallScreen ? 16 : 20,
                        isSmallScreen ? 16 : 20,
                        isSmallScreen ? 16 : 20,
                        isSmallScreen
                            ? 40
                            : 45, // Extra bottom padding for quantity controls
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppConstants.accentColor
                            : AppConstants.backgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppConstants.accentColor
                              : AppConstants.borderColor,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? AppConstants.accentColor
                                    .withValues(alpha: 0.3)
                                : AppConstants.textSecondary
                                    .withValues(alpha: 0.05),
                            blurRadius: isSelected ? 12 : 4,
                            offset: isSelected
                                ? const Offset(0, 4)
                                : const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            variant.name,
                            style: TextStyle(
                              color: isSelected
                                  ? AppConstants.surfaceColor
                                  : AppConstants.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 13 : 15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (variant.color != 'Standard') ...[
                            SizedBox(height: isSmallScreen ? 4 : 6),
                            Text(
                              variant.color,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 11 : 13,
                                color: isSelected
                                    ? AppConstants.surfaceColor
                                        .withValues(alpha: 0.9)
                                    : AppConstants.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Quantity controls positioned at bottom right
                    Positioned(
                      bottom: isSmallScreen ? 8 : 10,
                      right: isSmallScreen ? 8 : 10,
                      child: variantQuantity == 0
                          ? GestureDetector(
                              onTap: () =>
                                  _updateVariantQuantity(variant.id, 1),
                              child: Container(
                                width: isSmallScreen ? 40 : 44,
                                height: isSmallScreen ? 40 : 44,
                                decoration: BoxDecoration(
                                  color: AppConstants.accentColor,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppConstants.accentColor
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.add,
                                  color: AppConstants.surfaceColor,
                                  size: isSmallScreen ? 24 : 28,
                                ),
                              ),
                            )
                          : Container(
                              constraints: BoxConstraints(
                                minWidth: isSmallScreen ? 90 : 100,
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 8 : 10,
                                vertical: isSmallScreen ? 6 : 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppConstants.accentColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppConstants.accentColor
                                        .withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () => _updateVariantQuantity(
                                        variant.id, variantQuantity - 1),
                                    child: Container(
                                      width: isSmallScreen ? 24 : 28,
                                      height: isSmallScreen ? 24 : 28,
                                      decoration: BoxDecoration(
                                        color: AppConstants.surfaceColor
                                            .withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.remove,
                                        color: AppConstants.surfaceColor,
                                        size: isSmallScreen ? 16 : 18,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: isSmallScreen ? 8 : 10),
                                    child: Text(
                                      variantQuantity.toString(),
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 16 : 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppConstants.surfaceColor,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: variantQuantity < 99
                                        ? () => _updateVariantQuantity(
                                            variant.id, variantQuantity + 1)
                                        : null,
                                    child: Container(
                                      width: isSmallScreen ? 24 : 28,
                                      height: isSmallScreen ? 24 : 28,
                                      decoration: BoxDecoration(
                                        color: variantQuantity < 99
                                            ? AppConstants.surfaceColor
                                                .withValues(alpha: 0.2)
                                            : AppConstants.surfaceColor
                                                .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.add,
                                        color: variantQuantity < 99
                                            ? AppConstants.surfaceColor
                                            : AppConstants.surfaceColor
                                                .withValues(alpha: 0.5),
                                        size: isSmallScreen ? 16 : 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab Bar - Commented out as per requirements (no tabs needed)
        // Container(
        //   margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 20 : 30),
        //   decoration: BoxDecoration(
        //     color: AppConstants.surfaceColor,
        //     borderRadius: BorderRadius.circular(16),
        //     border: Border.all(
        //       color: AppConstants.borderColor.withValues(alpha: 0.3),
        //       width: 1,
        //     ),
        //     boxShadow: [
        //       BoxShadow(
        //         color: AppConstants.textSecondary.withValues(alpha: 0.05),
        //         blurRadius: 8,
        //         offset: const Offset(0, 2),
        //       ),
        //     ],
        //   ),
        //   child: TabBar(
        //     controller: _tabController,
        //     dividerColor: Colors.transparent,
        //     indicatorColor: AppConstants.accentColor,
        //     indicatorWeight: 3,
        //     indicatorPadding:
        //         EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 12),
        //     labelColor: AppConstants.accentColor,
        //     unselectedLabelColor: AppConstants.textSecondary,
        //     labelStyle: TextStyle(
        //       fontWeight: FontWeight.bold,
        //       fontSize: isSmallScreen ? 13 : 15,
        //     ),
        //     unselectedLabelStyle: TextStyle(
        //       fontWeight: FontWeight.w500,
        //       fontSize: isSmallScreen ? 13 : 15,
        //     ),
        //     tabs: const [
        //       Tab(text: 'Description'),
        //       // Commented out as per requirements - only show description
        //       // Tab(text: 'Ingredients'),
        //       // Tab(text: 'Reviews'),
        //     ],
        //   ),
        // ),

        // SizedBox(height: isSmallScreen ? 16 : 20),

        // Enhanced description content with better styling
        _buildImprovedDescriptionContent(isSmallScreen),

        // Commented out ingredients and reviews content as per requirements
        // AnimatedBuilder(
        //   animation: _tabController,
        //   builder: (context, child) {
        //     switch (_tabController.index) {
        //       case 0:
        //         return _buildDescriptionContent(isSmallScreen);
        //       case 1:
        //         return _buildIngredientsContent(isSmallScreen);
        //       case 2:
        //         return _buildReviewsContent(isSmallScreen);
        //       default:
        //         return _buildDescriptionContent(isSmallScreen);
        //     }
        //   },
        // ),
      ],
    );
  }

  Widget _buildImprovedDescriptionContent(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description Header with gradient background
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppConstants.accentColor.withValues(alpha: 0.1),
                  AppConstants.accentColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppConstants.accentColor.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppConstants.accentColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: isSmallScreen ? 18 : 20,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 12 : 16),
                    Text(
                      'Product Description',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 16 : 20),

                // Enhanced description text with better typography
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color:
                            AppConstants.textSecondary.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    currentProduct!.description.isNotEmpty
                        ? currentProduct!.description
                        : 'Discover the exceptional quality and craftsmanship of this premium beauty product. Carefully formulated with the finest ingredients to deliver outstanding results.',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 15 : 17,
                      color: AppConstants.textPrimary,
                      height: 1.7,
                      letterSpacing: 0.3,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ),
              ],
            ),
          ),

          // Commented out sections as per requirements
          // SizedBox(height: isSmallScreen ? 24 : 32),

          // // Key Benefits Section
          // Container(
          //   width: double.infinity,
          //   padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
          //   decoration: BoxDecoration(
          //     color: AppConstants.backgroundColor,
          //     borderRadius: BorderRadius.circular(20),
          //     border: Border.all(
          //       color: AppConstants.borderColor.withValues(alpha: 0.3),
          //       width: 1,
          //     ),
          //   ),
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       Row(
          //         children: [
          //           Icon(
          //             Icons.star_outline,
          //             color: AppConstants.accentColor,
          //             size: isSmallScreen ? 20 : 24,
          //           ),
          //           SizedBox(width: isSmallScreen ? 8 : 12),
          //           Text(
          //             'Key Benefits',
          //             style: TextStyle(
          //               fontSize: isSmallScreen ? 18 : 20,
          //               fontWeight: FontWeight.bold,
          //               color: AppConstants.textPrimary,
          //             ),
          //           ),
          //         ],
          //       ),
          //       SizedBox(height: isSmallScreen ? 16 : 20),
          //       Column(
          //         children: [
          //           _buildBenefitItem('Long-lasting formula', isSmallScreen),
          //           _buildBenefitItem('Gentle on sensitive skin', isSmallScreen),
          //           _buildBenefitItem('Professional-grade results', isSmallScreen),
          //           _buildBenefitItem('Dermatologist tested & approved', isSmallScreen),
          //           _buildBenefitItem('Cruelty-free and vegan formula', isSmallScreen),
          //           _buildBenefitItem('Suitable for all skin types', isSmallScreen),
          //         ],
          //       ),
          //     ],
          //   ),
          // ),

          // SizedBox(height: isSmallScreen ? 24 : 32),

          // // How to Use Section
          // Container(
          //   width: double.infinity,
          //   padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
          //   decoration: BoxDecoration(
          //     color: Colors.blue.withValues(alpha: 0.05),
          //     borderRadius: BorderRadius.circular(20),
          //     border: Border.all(
          //       color: Colors.blue.withValues(alpha: 0.2),
          //       width: 1,
          //     ),
          //   ),
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       Row(
          //         children: [
          //           Icon(
          //             Icons.help_outline,
          //             color: Colors.blue,
          //             size: isSmallScreen ? 20 : 24,
          //           ),
          //           SizedBox(width: isSmallScreen ? 8 : 12),
          //           Text(
          //             'How to Use',
          //             style: TextStyle(
          //               fontSize: isSmallScreen ? 18 : 20,
          //               fontWeight: FontWeight.bold,
          //               color: AppConstants.textPrimary,
          //             ),
          //           ),
          //         ],
          //       ),
          //       SizedBox(height: isSmallScreen ? 16 : 20),
          //       Text(
          //         'Apply evenly to clean, dry skin. For best results, use twice daily - morning and evening. Allow to absorb completely before applying other products. Always use sunscreen during the day when using this product.',
          //         style: TextStyle(
          //           fontSize: isSmallScreen ? 15 : 17,
          //           color: AppConstants.textPrimary,
          //           height: 1.6,
          //           letterSpacing: 0.2,
          //         ),
          //         textAlign: TextAlign.justify,
          //       ),
          //     ],
          //   ),
          // ),

          // SizedBox(height: isSmallScreen ? 24 : 32),

          // // Important Cautions Section
          // Container(
          //   width: double.infinity,
          //   padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
          //   decoration: BoxDecoration(
          //     color: Colors.orange.withValues(alpha: 0.05),
          //     borderRadius: BorderRadius.circular(20),
          //     border: Border.all(
          //       color: Colors.orange.withValues(alpha: 0.3),
          //       width: 1.5,
          //     ),
          //   ),
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       Row(
          //         children: [
          //           Icon(
          //             Icons.warning_amber_rounded,
          //             color: Colors.orange,
          //             size: isSmallScreen ? 20 : 24,
          //           ),
          //           SizedBox(width: isSmallScreen ? 8 : 12),
          //           Text(
          //             'Important Cautions',
          //             style: TextStyle(
          //               fontSize: isSmallScreen ? 18 : 20,
          //               fontWeight: FontWeight.bold,
          //               color: AppConstants.textPrimary,
          //             ),
          //           ),
          //         ],
          //       ),
          //       SizedBox(height: isSmallScreen ? 16 : 20),
          //       Text(
          //         'For external use only. Avoid contact with eyes. If irritation occurs, discontinue use immediately. Keep out of reach of children. Store in a cool, dry place.',
          //         style: TextStyle(
          //           fontSize: isSmallScreen ? 15 : 17,
          //           color: AppConstants.textPrimary,
          //           height: 1.6,
          //           letterSpacing: 0.2,
          //         ),
          //         textAlign: TextAlign.justify,
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildIngredientsContent(bool isSmallScreen) {
    // Extended ingredients list for demonstration
    final List<String> displayIngredients =
        currentProduct!.ingredients.isNotEmpty
            ? currentProduct!.ingredients
            : [
                'Aqua (Water)',
                'Glycerin',
                'Sodium Hyaluronate',
                'Niacinamide',
                'Retinol',
                'Vitamin E (Tocopheryl Acetate)',
                'Aloe Barbadensis Leaf Extract',
                'Chamomilla Recutita (Matricaria) Flower Extract',
                'Panthenol (Pro-Vitamin B5)',
                'Ceramide NP',
                'Peptide Complex',
                'Argan Oil',
                'Jojoba Oil',
                'Green Tea Extract',
                'Vitamin C (Ascorbic Acid)',
                'Collagen',
                'Elastin',
                'Shea Butter',
                'Cocoa Butter',
                'Rosehip Oil'
              ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 20 : 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Full Ingredients List',
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),

          // Ingredients grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isSmallScreen ? 1 : 2,
              crossAxisSpacing: isSmallScreen ? 8 : 12,
              mainAxisSpacing: isSmallScreen ? 8 : 12,
              childAspectRatio: isSmallScreen ? 8 : 6,
            ),
            itemCount: displayIngredients.length,
            itemBuilder: (context, index) {
              final ingredient = displayIngredients[index];
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16,
                  vertical: isSmallScreen ? 8 : 12,
                ),
                decoration: BoxDecoration(
                  color: AppConstants.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppConstants.borderColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: isSmallScreen ? 6 : 8,
                      height: isSmallScreen ? 6 : 8,
                      decoration: const BoxDecoration(
                        color: AppConstants.accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    Expanded(
                      child: Text(
                        ingredient,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 13 : 15,
                          color: AppConstants.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          SizedBox(height: isSmallScreen ? 20 : 24),

          Container(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.verified_rounded,
                  color: Colors.green,
                  size: isSmallScreen ? 20 : 24,
                ),
                SizedBox(width: isSmallScreen ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ingredient Safety',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 10),
                      Text(
                        'All ingredients are carefully selected and tested for safety. This product is free from parabens, sulfates, and artificial fragrances. Suitable for sensitive skin.',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          color: AppConstants.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsContent(bool isSmallScreen) {
    if (currentProduct!.reviews.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 20 : 30),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 32 : 40),
              decoration: BoxDecoration(
                color: AppConstants.backgroundColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppConstants.borderColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: isSmallScreen ? 48 : 64,
                    color: AppConstants.textSecondary,
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 20),
                  Text(
                    'No Reviews Yet',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 18 : 20,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 8 : 12),
                  Text(
                    'Be the first to share your experience with this product',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 20 : 24),
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    decoration: BoxDecoration(
                      color: AppConstants.accentColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppConstants.accentColor.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Reviews help other customers make informed decisions. Your feedback matters and helps us improve our products.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13 : 15,
                        color: AppConstants.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 20 : 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer Reviews',
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: currentProduct!.reviews.length,
            separatorBuilder: (context, index) =>
                SizedBox(height: isSmallScreen ? 12 : 16),
            itemBuilder: (context, index) {
              final review = currentProduct!.reviews[index];
              return Container(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                decoration: BoxDecoration(
                  color: AppConstants.backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppConstants.borderColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: isSmallScreen ? 20 : 24,
                          backgroundColor: AppConstants.accentColor,
                          child: Text(
                            review.userName.isNotEmpty
                                ? review.userName[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              color: AppConstants.surfaceColor,
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 14 : 16,
                            ),
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 12 : 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                review.userName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isSmallScreen ? 15 : 17,
                                  color: AppConstants.textPrimary,
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 4 : 6),
                              Row(
                                children: List.generate(5, (starIndex) {
                                  return Icon(
                                    starIndex < review.rating.floor()
                                        ? Icons.star_rounded
                                        : Icons.star_border_rounded,
                                    size: isSmallScreen ? 16 : 18,
                                    color: AppConstants.accentColor,
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    Text(
                      review.comment,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        color: AppConstants.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isSmallScreen) {
    // Check if product has variants
    final hasVariants = currentProduct!.variants.isNotEmpty;

    return Container(
      padding: EdgeInsets.fromLTRB(
          isSmallScreen ? 16 : 20,
          isSmallScreen ? 12 : 16,
          isSmallScreen ? 16 : 20,
          isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        border: const Border(
          top: BorderSide(
            color: AppConstants.borderColor,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppConstants.textSecondary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        child: hasVariants
            ? _buildVariantCartButton(isSmallScreen)
            : _buildNoVariantCartButton(isSmallScreen),
      ),
    );
  }

  // For products with variants (existing behavior)
  Widget _buildVariantCartButton(bool isSmallScreen) {
    return ElevatedButton(
      onPressed: _totalQuantity > 0 ? _addToCart : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConstants.accentColor,
        foregroundColor: AppConstants.surfaceColor,
        elevation: 8,
        shadowColor: AppConstants.accentColor.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 16 : 20,
          vertical: isSmallScreen ? 12 : 16,
        ),
      ),
      child: Row(
        children: [
          // Quantity on left
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 10,
              vertical: isSmallScreen ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$_totalQuantity',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: AppConstants.surfaceColor,
              ),
            ),
          ),

          // "Add to Cart" text in middle
          Expanded(
            child: Text(
              'Add to Cart',
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: AppConstants.surfaceColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Total price on right
          Text(
            _formatPrice(_totalPrice),
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.surfaceColor,
            ),
          ),
        ],
      ),
    );
  }

  // For products without variants (with integrated quantity controls)
  Widget _buildNoVariantCartButton(bool isSmallScreen) {
    final currentQuantity = _variantQuantities['default'] ?? 0;

    return Container(
      height: isSmallScreen ? 48 : 56,
      decoration: BoxDecoration(
        color: AppConstants.accentColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppConstants.accentColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Quantity controls on the left
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 12,
              vertical: isSmallScreen ? 6 : 8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Decrease button
                InkWell(
                  onTap: currentQuantity > 0
                      ? () =>
                          _updateVariantQuantity('default', currentQuantity - 1)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: isSmallScreen ? 28 : 32,
                    height: isSmallScreen ? 28 : 32,
                    decoration: BoxDecoration(
                      color: currentQuantity > 0
                          ? AppConstants.surfaceColor.withValues(alpha: 0.2)
                          : AppConstants.surfaceColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.remove,
                      color: AppConstants.surfaceColor,
                      size: isSmallScreen ? 16 : 18,
                    ),
                  ),
                ),

                // Quantity display
                Container(
                  width: isSmallScreen ? 36 : 40,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 8 : 10,
                    vertical: isSmallScreen ? 4 : 6,
                  ),
                  child: Text(
                    '$currentQuantity',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.surfaceColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Increase button
                InkWell(
                  onTap: currentQuantity < 99
                      ? () =>
                          _updateVariantQuantity('default', currentQuantity + 1)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: isSmallScreen ? 28 : 32,
                    height: isSmallScreen ? 28 : 32,
                    decoration: BoxDecoration(
                      color: currentQuantity < 99
                          ? AppConstants.surfaceColor.withValues(alpha: 0.2)
                          : AppConstants.surfaceColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.add,
                      color: currentQuantity < 99
                          ? AppConstants.surfaceColor
                          : AppConstants.surfaceColor.withValues(alpha: 0.5),
                      size: isSmallScreen ? 16 : 18,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // "Add to Cart" button in the middle
          Expanded(
            child: InkWell(
              onTap: currentQuantity > 0 ? _addToCart : null,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16,
                ),
                child: Center(
                  child: Text(
                    currentQuantity > 0 ? 'Add to Cart' : 'Select Quantity',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: currentQuantity > 0
                          ? AppConstants.surfaceColor
                          : AppConstants.surfaceColor.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Total price on the right
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12 : 16,
              vertical: isSmallScreen ? 6 : 8,
            ),
            child: Text(
              _formatPrice(currentProduct!.price * currentQuantity),
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: AppConstants.surfaceColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String benefit, bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: isSmallScreen ? 4 : 6),
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.borderColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: AppConstants.successColor,
            size: isSmallScreen ? 18 : 20,
          ),
          SizedBox(width: isSmallScreen ? 12 : 16),
          Expanded(
            child: Text(
              benefit,
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: AppConstants.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
