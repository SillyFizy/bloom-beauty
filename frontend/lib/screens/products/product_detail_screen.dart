import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../constants/app_constants.dart';
import '../../providers/cart_provider.dart';
import '../../providers/celebrity_provider.dart';
import '../celebrity/celebrity_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late PageController _imagePageController;
  ProductVariant? _selectedVariant;
  int _currentImageIndex = 0;
  
  // Track quantities for each variant (starting from 0)
  Map<String, int> _variantQuantities = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _imagePageController = PageController();
    
    // Initialize variant quantities properly
    if (widget.product.variants.isNotEmpty) {
      _selectedVariant = widget.product.variants.first;
      // Initialize all variant quantities to 0
      for (var variant in widget.product.variants) {
        _variantQuantities[variant.id] = 0;
      }
    } else {
      // For products without variants, use default key
      _variantQuantities['default'] = 0;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _imagePageController.dispose();
    super.dispose();
  }

  String _formatPrice(double price) {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(price)} IQD';
  }

  List<String> get _currentImages {
    return widget.product.getCurrentImages(_selectedVariant);
  }

  void _updateVariantQuantity(String variantId, int newQuantity) {
    if (newQuantity >= 0 && newQuantity <= 99) {
      setState(() {
        _variantQuantities[variantId] = newQuantity;
        // Only update selected variant if the product has variants and it's not the default case
        if (newQuantity > 0 && variantId != 'default' && widget.product.variants.isNotEmpty) {
          _selectedVariant = widget.product.variants.firstWhere((v) => v.id == variantId);
          _currentImageIndex = 0;
          _imagePageController.animateToPage(
            0,
            duration: AppConstants.shortAnimation,
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  // Calculate total price for all selected variants
  double get _totalPrice {
    double total = 0;
    for (var entry in _variantQuantities.entries) {
      final variantId = entry.key;
      final quantity = entry.value;
      if (quantity > 0) {
        if (variantId == 'default') {
          total += widget.product.price * quantity;
        } else {
          final variant = widget.product.variants.firstWhere((v) => v.id == variantId);
          total += widget.product.getCurrentPrice(variant) * quantity;
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
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    
    // Add all selected variants to cart
    cartProvider.addMultipleItems(widget.product, _variantQuantities);
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $_totalQuantity item${_totalQuantity > 1 ? 's' : ''} to cart'),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine screen size
        final isSmallScreen = constraints.maxWidth < 600;
        final isMediumScreen = constraints.maxWidth >= 600 && constraints.maxWidth < 900;
        
        return Scaffold(
          backgroundColor: AppConstants.backgroundColor,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // App bar
              SliverAppBar(
                backgroundColor: AppConstants.backgroundColor,
                elevation: 0,
                pinned: false,
                floating: true,
                leading: _buildActionButton(
                  icon: Icons.arrow_back_ios,
                  onPressed: () => Navigator.pop(context),
                  isSmallScreen: isSmallScreen,
                ),
                actions: [
                  _buildActionButton(
                    icon: Icons.favorite_border,
                    onPressed: () {},
                    isSmallScreen: isSmallScreen,
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 12),
                  _buildActionButton(
                    icon: Icons.share,
                    onPressed: () {},
                    isSmallScreen: isSmallScreen,
                  ),
                  SizedBox(width: isSmallScreen ? 16 : 20),
                ],
              ),
              
              // Scrollable image section
              SliverToBoxAdapter(
                child: _buildImageSection(isSmallScreen),
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
                      if (widget.product.celebrityEndorsement != null)
                        _buildCelebrityEndorsement(isSmallScreen),
                      SizedBox(height: isSmallScreen ? 20 : 24),
                      _buildTabSection(isSmallScreen),
                      SizedBox(height: isSmallScreen ? 80 : 100), // Space for bottom bar
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: (widget.product.variants.isEmpty || _totalQuantity > 0) 
              ? _buildBottomBar(isSmallScreen) 
              : null,
        );
      },
    );
  }

  Widget _buildActionButton({
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
          color: AppConstants.borderColor.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppConstants.textSecondary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppConstants.surfaceColor,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
            ),
            child: Center(
              child: Icon(
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
    final imageHeight = isSmallScreen ? screenHeight * 0.4 : screenHeight * 0.45;
    
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
          // Main Image with PageView
          Expanded(
            child: PageView.builder(
              controller: _imagePageController,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
              itemCount: _currentImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.fromLTRB(
                    isSmallScreen ? 20 : 30, 
                    isSmallScreen ? 20 : 30, 
                    isSmallScreen ? 20 : 30, 
                    isSmallScreen ? 16 : 20
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: AppConstants.surfaceColor,
                    border: Border.all(
                      color: AppConstants.borderColor,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppConstants.textSecondary.withOpacity(0.15),
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
            ),
          ),
          
          // Image Indicators
          if (_currentImages.length > 1)
            Container(
              height: isSmallScreen ? 50 : 60,
              padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 20 : 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _currentImages.length,
                  (index) => Container(
                    width: isSmallScreen ? 6 : 8,
                    height: isSmallScreen ? 6 : 8,
                    margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 3 : 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentImageIndex == index
                          ? AppConstants.accentColor
                          : AppConstants.textSecondary.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductInfo(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.product.name,
            style: TextStyle(
              fontSize: isSmallScreen ? 20 : 26,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.product.brand,
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
                    index < widget.product.rating.floor()
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: AppConstants.accentColor,
                    size: isSmallScreen ? 16 : 20,
                  );
                }),
              ),
              const SizedBox(width: 12),
              Text(
                widget.product.rating.toString(),
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 16,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${widget.product.reviewCount} reviews)',
                style: TextStyle(
                  fontSize: isSmallScreen ? 10 : 14,
                  color: AppConstants.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCelebrityEndorsement(bool isSmallScreen) {
    final endorsement = widget.product.celebrityEndorsement!;
    
    return GestureDetector(
      onTap: () async {
        final celebrityData = await _getCelebrityData(endorsement.celebrityName);
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CelebrityScreen(
                celebrityName: endorsement.celebrityName,
                celebrityImage: endorsement.celebrityImage,
                testimonial: endorsement.testimonial,
                socialMediaLinks: celebrityData['socialMediaLinks'] as Map<String, String>,
                recommendedProducts: celebrityData['recommendedProducts'] as List<Product>,
                morningRoutineProducts: celebrityData['morningRoutineProducts'] as List<Product>,
                eveningRoutineProducts: celebrityData['eveningRoutineProducts'] as List<Product>,
              ),
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
              AppConstants.favoriteColor.withOpacity(0.08),
              AppConstants.accentColor.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppConstants.favoriteColor.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppConstants.favoriteColor.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppConstants.favoriteColor,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.favoriteColor.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: AppConstants.surfaceColor,
                backgroundImage: NetworkImage(endorsement.celebrityImage),
                onBackgroundImageError: (exception, stackTrace) {},
                child: endorsement.celebrityImage.isEmpty ? 
                  Icon(
                    Icons.star_rounded,
                    color: AppConstants.favoriteColor,
                    size: 24,
                  ) : null,
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Picked by',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 13,
                      color: AppConstants.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    endorsement.celebrityName,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.favoriteColor,
                    ),
                  ),
                ],
              ),
            ),
            
            Icon(
              Icons.star_rounded,
              color: AppConstants.favoriteColor,
              size: isSmallScreen ? 16 : 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantSelector(bool isSmallScreen) {
    if (widget.product.variants.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 20 : 30, 
        vertical: isSmallScreen ? 12 : 16
      ),
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
            children: widget.product.variants.asMap().entries.map((entry) {
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
                        isSmallScreen ? 40 : 45, // Extra bottom padding for quantity controls
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
                                ? AppConstants.accentColor.withOpacity(0.3)
                                : AppConstants.textSecondary.withOpacity(0.05),
                            blurRadius: isSelected ? 12 : 4,
                            offset: isSelected ? const Offset(0, 4) : const Offset(0, 2),
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
                                    ? AppConstants.surfaceColor.withOpacity(0.9)
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
                              onTap: () => _updateVariantQuantity(variant.id, 1),
                              child: Container(
                                width: isSmallScreen ? 40 : 44,
                                height: isSmallScreen ? 40 : 44,
                                decoration: BoxDecoration(
                                  color: AppConstants.accentColor,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppConstants.accentColor.withOpacity(0.3),
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
                                    color: AppConstants.accentColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () => _updateVariantQuantity(variant.id, variantQuantity - 1),
                                    child: Container(
                                      width: isSmallScreen ? 24 : 28,
                                      height: isSmallScreen ? 24 : 28,
                                      decoration: BoxDecoration(
                                        color: AppConstants.surfaceColor.withOpacity(0.2),
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
                                    padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 10),
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
                                        ? () => _updateVariantQuantity(variant.id, variantQuantity + 1) 
                                        : null,
                                    child: Container(
                                      width: isSmallScreen ? 24 : 28,
                                      height: isSmallScreen ? 24 : 28,
                                      decoration: BoxDecoration(
                                        color: variantQuantity < 99 
                                            ? AppConstants.surfaceColor.withOpacity(0.2) 
                                            : AppConstants.surfaceColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.add,
                                        color: variantQuantity < 99 
                                            ? AppConstants.surfaceColor 
                                            : AppConstants.surfaceColor.withOpacity(0.5),
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
        // Tab Bar - now integrated with main content
        Container(
          margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 20 : 30),
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppConstants.borderColor.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppConstants.textSecondary.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            dividerColor: Colors.transparent,
            indicatorColor: AppConstants.accentColor,
            indicatorWeight: 3,
            indicatorPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 12),
            labelColor: AppConstants.accentColor,
            unselectedLabelColor: AppConstants.textSecondary,
            labelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 13 : 15,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: isSmallScreen ? 13 : 15,
            ),
            tabs: const [
              Tab(text: 'Description'),
              Tab(text: 'Ingredients'),
              Tab(text: 'Reviews'),
            ],
          ),
        ),
        
        SizedBox(height: isSmallScreen ? 16 : 20),
        
        // Tab Content - now part of main screen without container
        AnimatedBuilder(
          animation: _tabController,
          builder: (context, child) {
            switch (_tabController.index) {
              case 0:
                return _buildDescriptionContent(isSmallScreen);
              case 1:
                return _buildIngredientsContent(isSmallScreen);
              case 2:
                return _buildReviewsContent(isSmallScreen);
              default:
                return _buildDescriptionContent(isSmallScreen);
            }
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionContent(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 20 : 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product Description',
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Text(
            widget.product.description,
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: AppConstants.textSecondary,
              height: 1.6,
            ),
          ),
          SizedBox(height: isSmallScreen ? 20 : 24),
          
          Text(
            'Key Benefits',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBenefitItem('Long-lasting formula', isSmallScreen),
              _buildBenefitItem('Gentle on sensitive skin', isSmallScreen),
              _buildBenefitItem('Professional-grade results', isSmallScreen),
              _buildBenefitItem('Dermatologist tested & approved', isSmallScreen),
              _buildBenefitItem('Cruelty-free and vegan formula', isSmallScreen),
              _buildBenefitItem('Suitable for all skin types', isSmallScreen),
            ],
          ),
          SizedBox(height: isSmallScreen ? 20 : 24),
          
          Text(
            'How to Use',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            decoration: BoxDecoration(
              color: AppConstants.backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppConstants.borderColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              'Apply evenly to clean, dry skin. For best results, use twice daily - morning and evening. Allow to absorb completely before applying other products. Always use sunscreen during the day when using this product.',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: AppConstants.textSecondary,
                height: 1.6,
              ),
            ),
          ),
          SizedBox(height: isSmallScreen ? 20 : 24),
          
          Text(
            'Important Cautions',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.orange.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: isSmallScreen ? 20 : 24,
                ),
                SizedBox(width: isSmallScreen ? 12 : 16),
                Expanded(
                  child: Text(
                    'For external use only. Avoid contact with eyes. If irritation occurs, discontinue use immediately. Keep out of reach of children. Store in a cool, dry place.',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
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

  Widget _buildIngredientsContent(bool isSmallScreen) {
    // Extended ingredients list for demonstration
    final List<String> displayIngredients = widget.product.ingredients.isNotEmpty 
        ? widget.product.ingredients 
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
                    color: AppConstants.borderColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: isSmallScreen ? 6 : 8,
                      height: isSmallScreen ? 6 : 8,
                      decoration: BoxDecoration(
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
              color: Colors.green.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.green.withOpacity(0.2),
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
    if (widget.product.reviews.isEmpty) {
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
                  color: AppConstants.borderColor.withOpacity(0.3),
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
                      color: AppConstants.accentColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppConstants.accentColor.withOpacity(0.2),
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
            itemCount: widget.product.reviews.length,
            separatorBuilder: (context, index) => SizedBox(height: isSmallScreen ? 12 : 16),
            itemBuilder: (context, index) {
              final review = widget.product.reviews[index];
              return Container(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                decoration: BoxDecoration(
                  color: AppConstants.backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppConstants.borderColor.withOpacity(0.3),
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
                            review.userName.isNotEmpty ? review.userName[0].toUpperCase() : 'U',
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
    final hasVariants = widget.product.variants.isNotEmpty;
    
    return Container(
      padding: EdgeInsets.fromLTRB(
        isSmallScreen ? 16 : 20, 
        isSmallScreen ? 12 : 16, 
        isSmallScreen ? 16 : 20, 
        isSmallScreen ? 12 : 16
      ),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        border: Border(
          top: BorderSide(
            color: AppConstants.borderColor,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppConstants.textSecondary.withOpacity(0.1),
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
        shadowColor: AppConstants.accentColor.withOpacity(0.3),
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
              color: AppConstants.surfaceColor.withOpacity(0.2),
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
            color: AppConstants.accentColor.withOpacity(0.3),
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
                      ? () => _updateVariantQuantity('default', currentQuantity - 1)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: isSmallScreen ? 28 : 32,
                    height: isSmallScreen ? 28 : 32,
                    decoration: BoxDecoration(
                      color: currentQuantity > 0 
                          ? AppConstants.surfaceColor.withOpacity(0.2)
                          : AppConstants.surfaceColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.remove,
                      size: isSmallScreen ? 16 : 18,
                      color: currentQuantity > 0 
                          ? AppConstants.surfaceColor
                          : AppConstants.surfaceColor.withOpacity(0.5),
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
                      ? () => _updateVariantQuantity('default', currentQuantity + 1)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: isSmallScreen ? 28 : 32,
                    height: isSmallScreen ? 28 : 32,
                    decoration: BoxDecoration(
                      color: currentQuantity < 99 
                          ? AppConstants.surfaceColor.withOpacity(0.2)
                          : AppConstants.surfaceColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.add,
                      size: isSmallScreen ? 16 : 18,
                      color: currentQuantity < 99 
                          ? AppConstants.surfaceColor
                          : AppConstants.surfaceColor.withOpacity(0.5),
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
                          : AppConstants.surfaceColor.withOpacity(0.7),
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
              _formatPrice(widget.product.price * currentQuantity),
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
          color: AppConstants.borderColor.withOpacity(0.3),
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