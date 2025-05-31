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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final imageHeight = screenHeight * 0.4; // Reduced from 0.45 for cleaner layout
    
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: Column(
        children: [
          // Fixed Image Section at Top
          Container(
            height: imageHeight,
            child: Stack(
              children: [
                _buildImageSection(),
                _buildAppBarOverlay(),
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
                    const SizedBox(height: 24),
                    _buildProductInfo(),
                    if (widget.product.celebrityEndorsement != null)
                      _buildCelebrityEndorsement(),
                    const SizedBox(height: 16),
                    _buildVariantSelector(),
                    const SizedBox(height: 8),
                    _buildQuantitySelector(),
                    const SizedBox(height: 24),
                    _buildTabSection(),
                    const SizedBox(height: 100), // Space for bottom bar
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildAppBarOverlay() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildActionButton(
              icon: Icons.arrow_back_ios,
              onPressed: () => Navigator.pop(context),
            ),
            Row(
              children: [
                _buildActionButton(
                  icon: Icons.favorite_border,
                  onPressed: () {},
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  icon: Icons.share,
                  onPressed: () {},
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
  }) {
    return Container(
      width: 48,
      height: 48,
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
          size: 20,
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildImageSection() {
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
                  margin: const EdgeInsets.fromLTRB(30, 80, 30, 20),
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
                                size: 80,
                                color: AppConstants.accentColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Product Image ${index + 1}',
                                style: TextStyle(
                                  color: AppConstants.textSecondary,
                                  fontSize: 14,
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
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_currentImages.length, (index) {
                          return GestureDetector(
                            onTap: () {
                              _imagePageController.animateToPage(
                                index,
                                duration: AppConstants.shortAnimation,
                                curve: Curves.easeInOut,
                              );
                            },
                            child: AnimatedContainer(
                              duration: AppConstants.shortAnimation,
                              width: 48,
                              height: 48,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: AppConstants.surfaceColor,
                                border: Border.all(
                                  color: _currentImageIndex == index
                                      ? AppConstants.accentColor
                                      : AppConstants.borderColor,
                                  width: _currentImageIndex == index ? 3 : 1,
                                ),
                                boxShadow: _currentImageIndex == index
                                    ? [
                                        BoxShadow(
                                          color: AppConstants.accentColor.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                Icons.image,
                                size: 20,
                                color: _currentImageIndex == index
                                    ? AppConstants.accentColor
                                    : AppConstants.textSecondary,
                              ),
                            ),
                          );
                        }),
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

  Widget _buildProductInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.product.name,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.product.brand,
            style: TextStyle(
              fontSize: 16,
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
                    size: 20,
                  );
                }),
              ),
              const SizedBox(width: 12),
              Text(
                widget.product.rating.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${widget.product.reviewCount} reviews)',
                style: TextStyle(
                  fontSize: 14,
                  color: AppConstants.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCelebrityEndorsement() {
    final endorsement = widget.product.celebrityEndorsement!;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CelebrityScreen(
              celebrityName: endorsement.celebrityName,
              celebrityImage: endorsement.celebrityImage,
              testimonial: endorsement.testimonial,
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
                      fontSize: 13,
                      color: AppConstants.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    endorsement.celebrityName,
                    style: TextStyle(
                      fontSize: 16,
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
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantSelector() {
    if (widget.product.variants.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette_outlined,
                color: AppConstants.accentColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Available Options',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
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
                  constraints: const BoxConstraints(
                    minWidth: 120,
                    minHeight: 70,
                  ),
                  padding: const EdgeInsets.all(16),
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
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (variant.color != 'Standard') ...[
                        const SizedBox(height: 6),
                        Text(
                          variant.color,
                          style: TextStyle(
                            fontSize: 12,
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

  Widget _buildQuantitySelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
      padding: const EdgeInsets.all(24),
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
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Quantity: ${_selectedVariant?.name ?? 'Product'}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildQuantityButton(
                Icons.remove,
                _currentQuantity > 0 ? _decrementQuantity : null,
                _currentQuantity <= 0,
              ),
              Container(
                width: 80,
                height: 50,
                margin: const EdgeInsets.symmetric(horizontal: 20),
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
                      fontSize: 22,
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback? onPressed, bool isDisabled) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDisabled ? AppConstants.backgroundColor : AppConstants.accentColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDisabled ? AppConstants.borderColor : AppConstants.accentColor,
          width: 1,
        ),
        boxShadow: !isDisabled ? [
          BoxShadow(
            color: AppConstants.accentColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isDisabled ? AppConstants.textSecondary : AppConstants.surfaceColor,
          size: 18,
        ),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildTabSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppConstants.backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppConstants.borderColor,
                width: 1,
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppConstants.accentColor,
              unselectedLabelColor: AppConstants.textSecondary,
              indicatorColor: AppConstants.accentColor,
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorWeight: 3,
              indicatorPadding: const EdgeInsets.symmetric(horizontal: 20),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Description'),
                Tab(text: 'Reviews'),
                Tab(text: 'Ingredients'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            constraints: const BoxConstraints(
              minHeight: 200,
              maxHeight: 400,
            ),
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppConstants.borderColor,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppConstants.textSecondary.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDescriptionTab(),
                _buildReviewsTab(),
                _buildIngredientsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Text(
        widget.product.description,
        style: TextStyle(
          fontSize: 16,
          height: 1.6,
          color: AppConstants.textPrimary,
        ),
      ),
    );
  }

  Widget _buildReviewsTab() {
    if (widget.product.reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 48,
              color: AppConstants.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: TextStyle(
                fontSize: 16,
                color: AppConstants.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to review this product!',
              style: TextStyle(
                fontSize: 14,
                color: AppConstants.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: widget.product.reviews.length,
      itemBuilder: (context, index) {
        final review = widget.product.reviews[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppConstants.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppConstants.borderColor,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppConstants.accentColor.withOpacity(0.2),
                    child: Icon(
                      Icons.person,
                      color: AppConstants.accentColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.userName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy').format(review.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppConstants.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (starIndex) {
                      return Icon(
                        starIndex < review.rating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: AppConstants.accentColor,
                        size: 16,
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                review.comment,
                style: TextStyle(
                  fontSize: 14,
                  color: AppConstants.textPrimary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIngredientsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: widget.product.ingredients.map((ingredient) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppConstants.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppConstants.accentColor,
                width: 1,
              ),
            ),
            child: Text(
              ingredient,
              style: TextStyle(
                fontSize: 14,
                color: AppConstants.accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(30, 20, 30, 20),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        border: Border.all(
          color: AppConstants.borderColor,
          width: 1,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stock status and current quantity info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppConstants.backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppConstants.borderColor,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedVariant?.name ?? widget.product.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Current Quantity: $_currentQuantity',
                          style: TextStyle(
                            fontSize: 14,
                            color: _currentQuantity > 0 ? AppConstants.accentColor : AppConstants.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: widget.product.isInStock
                          ? AppConstants.successColor.withOpacity(0.1)
                          : AppConstants.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: widget.product.isInStock
                            ? AppConstants.successColor
                            : AppConstants.errorColor,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.product.isInStock
                              ? Icons.check_circle_outline_rounded
                              : Icons.cancel_outlined,
                          size: 16,
                          color: widget.product.isInStock 
                              ? AppConstants.successColor 
                              : AppConstants.errorColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.product.isInStock ? 'In Stock' : 'Out of Stock',
                          style: TextStyle(
                            color: widget.product.isInStock 
                                ? AppConstants.successColor 
                                : AppConstants.errorColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Add to Cart button only
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (widget.product.isInStock && _totalQuantity > 0) ? _addToCart : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_totalQuantity > 0) ? AppConstants.accentColor : AppConstants.textSecondary,
                  foregroundColor: AppConstants.surfaceColor,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _totalQuantity > 0 ? 'Add to Cart ($_totalQuantity)' : 'Add to Cart',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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