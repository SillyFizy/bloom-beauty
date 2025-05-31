import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../constants/app_constants.dart';
import '../../providers/cart_provider.dart';
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
  int get _currentQuantity => _variantQuantities[_selectedVariant?.id ?? 'default'] ?? 0;
  
  // Get total quantity across all variants
  int get _totalQuantity {
    return _variantQuantities.values.fold(0, (sum, quantity) => sum + quantity);
  }

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

  void _updateQuantity(int newQuantity) {
    if (newQuantity >= 0 && newQuantity <= 99) {
      setState(() {
        final currentVariantId = _selectedVariant?.id ?? 'default';
        _variantQuantities[currentVariantId] = newQuantity;
      });
    }
  }

  void _incrementQuantity() {
    final newQuantity = _currentQuantity + 1;
    if (newQuantity <= 99) {
      _updateQuantity(newQuantity);
    }
  }

  void _decrementQuantity() {
    final newQuantity = _currentQuantity - 1;
    if (newQuantity >= 0) {
      _updateQuantity(newQuantity);
    }
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

  // Helper method to get celebrity data including social media links
  Map<String, dynamic> _getCelebrityData(String celebrityName) {
    // Celebrity data with social media links (only show these in celebrity screen)
    final Map<String, Map<String, dynamic>> celebrityData = {
      'Emma Stone': {
        'socialMediaLinks': {
          'instagram': 'https://instagram.com/emmastone',
          'facebook': 'https://facebook.com/EmmaStoneOfficial',
        },
        'recommendedProducts': <Product>[], // Will be populated with real products
      },
      'Rihanna': {
        'socialMediaLinks': {
          'instagram': 'https://instagram.com/badgalriri',
          'facebook': 'https://facebook.com/rihanna',
          'snapchat': 'https://snapchat.com/add/rihanna',
        },
        'recommendedProducts': <Product>[], 
      },
      'Zendaya': {
        'socialMediaLinks': {
          'instagram': 'https://instagram.com/zendaya',
          'snapchat': 'https://snapchat.com/add/zendayaa',
        },
        'recommendedProducts': <Product>[], 
      },
      'Selena Gomez': {
        'socialMediaLinks': {
          'instagram': 'https://instagram.com/selenagomez',
          'facebook': 'https://facebook.com/Selena',
          'snapchat': 'https://snapchat.com/add/selenagomez',
        },
        'recommendedProducts': <Product>[], 
      },
      'Kim Kardashian': {
        'socialMediaLinks': {
          'instagram': 'https://instagram.com/kimkardashian',
          'facebook': 'https://facebook.com/KimKardashian',
          'snapchat': 'https://snapchat.com/add/kimkardashian',
        },
        'recommendedProducts': <Product>[], 
      },
      'Taylor Swift': {
        'socialMediaLinks': {
          'instagram': 'https://instagram.com/taylorswift',
          'facebook': 'https://facebook.com/TaylorSwift',
        },
        'recommendedProducts': <Product>[], 
      },
    };

    return celebrityData[celebrityName] ?? {
      'socialMediaLinks': <String, String>{},
      'recommendedProducts': <Product>[],
    };
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine screen size
        final isSmallScreen = constraints.maxWidth < 600;
        final isMediumScreen = constraints.maxWidth >= 600 && constraints.maxWidth < 900;
        
        final screenHeight = MediaQuery.of(context).size.height;
        final imageHeight = isSmallScreen 
            ? screenHeight * 0.35 
            : (isMediumScreen ? screenHeight * 0.38 : screenHeight * 0.4);
        
        return Scaffold(
          backgroundColor: AppConstants.backgroundColor,
          body: Column(
            children: [
              // Fixed Image Section at Top
              Container(
                height: imageHeight,
                child: Stack(
                  children: [
                    _buildImageSection(isSmallScreen),
                    _buildAppBarOverlay(isSmallScreen),
                  ],
                ),
              ),
              
              // Scrollable Content Below
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
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
                        SizedBox(height: isSmallScreen ? 20 : 24),
                        _buildProductInfo(isSmallScreen),
                        if (widget.product.celebrityEndorsement != null)
                          _buildCelebrityEndorsement(isSmallScreen),
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        _buildVariantSelector(isSmallScreen),
                        SizedBox(height: isSmallScreen ? 6 : 8),
                        _buildQuantitySelector(isSmallScreen),
                        SizedBox(height: isSmallScreen ? 20 : 24),
                        _buildTabSection(isSmallScreen),
                        SizedBox(height: isSmallScreen ? 80 : 100), // Space for bottom bar
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(isSmallScreen),
        );
      },
    );
  }

  Widget _buildAppBarOverlay(bool isSmallScreen) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildActionButton(
              icon: Icons.arrow_back_ios,
              onPressed: () => Navigator.pop(context),
              isSmallScreen: isSmallScreen,
            ),
            Row(
              children: [
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isSmallScreen,
  }) {
    return Container(
      width: isSmallScreen ? 40 : 48,
      height: isSmallScreen ? 40 : 48,
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppConstants.borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppConstants.textSecondary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: AppConstants.textPrimary,
          size: isSmallScreen ? 16 : 20,
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildImageSection(bool isSmallScreen) {
    return Container(
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
                    isSmallScreen ? 60 : 80, 
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
    final celebrityData = _getCelebrityData(endorsement.celebrityName);
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CelebrityScreen(
              celebrityName: endorsement.celebrityName,
              celebrityImage: endorsement.celebrityImage,
              testimonial: endorsement.testimonial,
              socialMediaLinks: celebrityData['socialMediaLinks'] as Map<String, String>,
              recommendedProducts: celebrityData['recommendedProducts'] as List<Product>,
            ),
          ),
        );
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
                child: AnimatedContainer(
                  duration: AppConstants.mediumAnimation,
                  curve: Curves.easeInOut,
                  constraints: BoxConstraints(
                    minWidth: isSmallScreen ? 100 : 120,
                    minHeight: isSmallScreen ? 60 : 70,
                  ),
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
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
                    children: [
                      Text(
                        variant.name,
                        style: TextStyle(
                          color: isSelected
                              ? AppConstants.surfaceColor
                              : AppConstants.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 12 : 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (variant.color != 'Standard') ...[
                        SizedBox(height: isSmallScreen ? 4 : 6),
                        Text(
                          variant.color,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10 : 12,
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
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector(bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 20 : 30, 
        vertical: isSmallScreen ? 12 : 16
      ),
      padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppConstants.borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppConstants.textSecondary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.tune,
                color: AppConstants.accentColor,
                size: isSmallScreen ? 16 : 20,
              ),
              SizedBox(width: isSmallScreen ? 6 : 8),
              Expanded(
                child: Text(
                  'Quantity: ${_selectedVariant?.name ?? 'Product'}',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: isSmallScreen ? 16 : 20),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildQuantityButton(
                Icons.remove,
                _currentQuantity > 0 ? _decrementQuantity : null,
                _currentQuantity <= 0,
                isSmallScreen,
              ),
              Container(
                width: isSmallScreen ? 70 : 80,
                height: isSmallScreen ? 45 : 50,
                margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _currentQuantity > 0 ? AppConstants.accentColor : AppConstants.borderColor,
                    width: _currentQuantity > 0 ? 2 : 1,
                  ),
                  boxShadow: _currentQuantity > 0 ? [
                    BoxShadow(
                      color: AppConstants.accentColor.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Center(
                  child: Text(
                    _currentQuantity.toString(),
                    style: TextStyle(
                      fontSize: isSmallScreen ? 18 : 22,
                      fontWeight: FontWeight.bold,
                      color: _currentQuantity > 0 ? AppConstants.accentColor : AppConstants.textSecondary,
                    ),
                  ),
                ),
              ),
              _buildQuantityButton(
                Icons.add,
                _currentQuantity < 99 ? _incrementQuantity : null,
                _currentQuantity >= 99,
                isSmallScreen,
              ),
            ],
          ),
          
          SizedBox(height: isSmallScreen ? 16 : 20),
          
          // Show current price with variant adjustment
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 16 : 20, 
              vertical: isSmallScreen ? 12 : 16
            ),
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppConstants.accentColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Price:',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textSecondary,
                  ),
                ),
                Text(
                  _formatPrice(widget.product.getCurrentPrice(_selectedVariant)),
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.accentColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback? onPressed, bool isDisabled, bool isSmallScreen) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: AppConstants.shortAnimation,
        width: isSmallScreen ? 45 : 50,
        height: isSmallScreen ? 45 : 50,
        decoration: BoxDecoration(
          color: isDisabled
              ? AppConstants.backgroundColor
              : AppConstants.accentColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDisabled
                ? AppConstants.borderColor
                : AppConstants.accentColor,
            width: 1,
          ),
          boxShadow: isDisabled ? null : [
            BoxShadow(
              color: AppConstants.accentColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isDisabled
              ? AppConstants.textSecondary
              : AppConstants.surfaceColor,
          size: isSmallScreen ? 18 : 20,
        ),
      ),
    );
  }

  Widget _buildTabSection(bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 20 : 30, 
        vertical: isSmallScreen ? 16 : 20
      ),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppConstants.borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppConstants.textSecondary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tab Bar
          Container(
            height: isSmallScreen ? 50 : 60,
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border(
                bottom: BorderSide(
                  color: AppConstants.borderColor,
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicatorColor: AppConstants.accentColor,
              indicatorWeight: 3,
              labelColor: AppConstants.accentColor,
              unselectedLabelColor: AppConstants.textSecondary,
              labelStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 12 : 14,
              ),
              unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: isSmallScreen ? 12 : 14,
              ),
              tabs: const [
                Tab(text: 'Description'),
                Tab(text: 'Ingredients'),
                Tab(text: 'Reviews'),
              ],
            ),
          ),
          
          // Tab Content
          SizedBox(
            height: isSmallScreen ? 200 : 250,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDescriptionTab(isSmallScreen),
                _buildIngredientsTab(isSmallScreen),
                _buildReviewsTab(isSmallScreen),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionTab(bool isSmallScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Text(
            widget.product.description,
            style: TextStyle(
              fontSize: isSmallScreen ? 13 : 15,
              color: AppConstants.textSecondary,
              height: 1.6,
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          Text(
            'Benefits',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBenefitItem('Long-lasting formula', isSmallScreen),
              _buildBenefitItem('Gentle on skin', isSmallScreen),
              _buildBenefitItem('Professional results', isSmallScreen),
              _buildBenefitItem('Dermatologist tested', isSmallScreen),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String benefit, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 4 : 6),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: AppConstants.successColor,
            size: isSmallScreen ? 16 : 18,
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
          Expanded(
            child: Text(
              benefit,
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 14,
                color: AppConstants.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsTab(bool isSmallScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Key Ingredients',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          if (widget.product.ingredients.isNotEmpty)
            ...widget.product.ingredients.map((ingredient) => Padding(
              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 4 : 6),
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
                        fontSize: isSmallScreen ? 13 : 14,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList()
          else
            Text(
              'No ingredients listed',
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 14,
                color: AppConstants.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab(bool isSmallScreen) {
    if (widget.product.reviews.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.rate_review_outlined,
                size: isSmallScreen ? 48 : 64,
                color: AppConstants.textSecondary,
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              Text(
                'No reviews yet',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textSecondary,
                ),
              ),
              SizedBox(height: isSmallScreen ? 6 : 8),
              Text(
                'Be the first to review this product',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  color: AppConstants.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      itemCount: widget.product.reviews.length,
      itemBuilder: (context, index) {
        final review = widget.product.reviews[index];
        return Container(
          margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            color: AppConstants.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppConstants.borderColor,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: isSmallScreen ? 16 : 20,
                    backgroundColor: AppConstants.accentColor,
                    child: Text(
                      review.userName.isNotEmpty ? review.userName[0].toUpperCase() : 'U',
                      style: TextStyle(
                        color: AppConstants.surfaceColor,
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.userName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 13 : 14,
                            color: AppConstants.textPrimary,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 2 : 4),
                        Row(
                          children: List.generate(5, (starIndex) {
                            return Icon(
                              starIndex < review.rating.floor()
                                  ? Icons.star
                                  : Icons.star_border,
                              size: isSmallScreen ? 12 : 14,
                              color: AppConstants.accentColor,
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 8 : 12),
              Text(
                review.comment,
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  color: AppConstants.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isSmallScreen ? 20 : 30, 
        isSmallScreen ? 16 : 20, 
        isSmallScreen ? 20 : 30, 
        isSmallScreen ? 16 : 20
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
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _totalQuantity > 0 ? _addToCart : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _totalQuantity > 0 
                      ? AppConstants.accentColor 
                      : AppConstants.backgroundColor,
                  foregroundColor: AppConstants.surfaceColor,
                  elevation: _totalQuantity > 0 ? 8 : 0,
                  shadowColor: AppConstants.accentColor.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: _totalQuantity > 0 
                          ? AppConstants.accentColor 
                          : AppConstants.borderColor,
                      width: 1,
                    ),
                  ),
                  padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 16 : 20),
                ),
                child: Text(
                  _totalQuantity > 0 
                      ? 'Add to Cart ($_totalQuantity)'
                      : 'Select Quantity',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: _totalQuantity > 0 
                        ? AppConstants.surfaceColor 
                        : AppConstants.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 