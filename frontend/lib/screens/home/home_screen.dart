import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../constants/app_constants.dart';
import '../../widgets/product/celebrity_pick_card.dart';
// not being used currently
// import 'package:go_router/go_router.dart';
// import '../../widgets/product/product_card.dart';



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;

  // Sample data for banner
  final List<String> _bannerImages = [
    'Cosmetics Collection 1',
    'Cosmetics Collection 2', 
    'Cosmetics Collection 3',
  ];

  // Celebrity picks data with products
  List<Map<String, dynamic>> get _celebrityPicks => [
    {
      'name': 'Emma Stone',
      'image': 'emma.jpg',
      'testimonial': 'This serum transformed my skin overnight!',
      'product': Product(
        id: 'cp1',
        name: 'Glow Serum',
        description: 'Radiance boosting serum',
        price: 85.00,
        images: ['glow_serum.jpg'],
        categoryId: '1',
        brand: 'LuxeBrand',
        rating: 4.8,
        reviewCount: 156,
        isInStock: true,
        ingredients: ['Vitamin C', 'Niacinamide'],
      ),
    },
    {
      'name': 'Rihanna',
      'image': 'rihanna.jpg',
      'testimonial': 'Perfect for my everyday glow',
      'product': Product(
        id: 'cp2',
        name: 'Fenty Cream',
        description: 'Moisturizing face cream',
        price: 65.00,
        images: ['fenty_cream.jpg'],
        categoryId: '1',
        brand: 'Fenty Beauty',
        rating: 4.9,
        reviewCount: 203,
        isInStock: true,
        ingredients: ['Shea Butter', 'Hyaluronic Acid'],
      ),
    },
    {
      'name': 'Zendaya',
      'image': 'zendaya.jpg',
      'testimonial': 'Love how natural this makes my skin look',
      'product': Product(
        id: 'cp3',
        name: 'Natural Foundation',
        description: 'Light coverage foundation',
        price: 45.00,
        images: ['foundation.jpg'],
        categoryId: '2',
        brand: 'Z Beauty',
        rating: 4.7,
        reviewCount: 89,
        isInStock: true,
        ingredients: ['Mineral Powder', 'SPF 30'],
      ),
    },
    {
      'name': 'Selena Gomez',
      'image': 'selena.jpg',
      'testimonial': 'This lipstick is my go-to for every occasion',
      'product': Product(
        id: 'cp4',
        name: 'Rare Lipstick',
        description: 'Long-lasting matte lipstick',
        price: 28.00,
        images: ['rare_lipstick.jpg'],
        categoryId: '3',
        brand: 'Rare Beauty',
        rating: 4.8,
        reviewCount: 312,
        isInStock: true,
        ingredients: ['Vitamin E', 'Jojoba Oil'],
      ),
    },
    {
      'name': 'Kim Kardashian',
      'image': 'kim.jpg',
      'testimonial': 'The contouring power is incredible',
      'product': Product(
        id: 'cp5',
        name: 'Contour Kit',
        description: 'Professional contouring palette',
        price: 72.00,
        images: ['contour_kit.jpg'],
        categoryId: '2',
        brand: 'KKW Beauty',
        rating: 4.6,
        reviewCount: 167,
        isInStock: true,
        ingredients: ['Mica', 'Silica'],
      ),
    },
    {
      'name': 'Taylor Swift',
      'image': 'taylor.jpg',
      'testimonial': 'Perfect red for my signature look',
      'product': Product(
        id: 'cp6',
        name: 'Red Lip Classic',
        description: 'Classic red lipstick',
        price: 32.00,
        images: ['red_lipstick.jpg'],
        categoryId: '3',
        brand: 'Swift Beauty',
        rating: 4.9,
        reviewCount: 245,
        isInStock: true,
        ingredients: ['Vitamin C', 'Aloe Vera'],
      ),
    },
  ];

  // Product data
  List<Product> get _newArrivals => [
    Product(
      id: '1',
      name: 'Hydrating Serum',
      description: 'Advanced hydrating serum',
      price: 50.000,
      images: ['serum1.jpg'],
      categoryId: '1',
      brand: 'LuxeBrand',
      rating: 4.9,
      reviewCount: 128,
      isInStock: true,
      ingredients: ['Hyaluronic Acid'],
    ),
    Product(
      id: '2', 
      name: 'Hydrating Serum',
      description: 'Premium hydrating serum',
      price: 50.000,
      images: ['serum2.jpg'],
      categoryId: '1',
      brand: 'LuxeBrand',
      rating: 4.9,
      reviewCount: 89,
      isInStock: true,
      ingredients: ['Vitamin C'],
    ),
    Product(
      id: '3',
      name: 'Hydrating Serum', 
      description: 'Professional hydrating serum',
      price: 50.000,
      images: ['serum3.jpg'],
      categoryId: '1',
      brand: 'LuxeBrand',
      rating: 4.9,
      reviewCount: 203,
      isInStock: true,
      ingredients: ['Peptides'],
    ),
    Product(
      id: '4',
      name: 'Hydrating Serum',
      description: 'Intensive hydrating serum',
      price: 50.000,
      images: ['serum4.jpg'],
      categoryId: '1',
      brand: 'LuxeBrand',
      rating: 4.9,
      reviewCount: 67,
      isInStock: true,
      ingredients: ['Retinol'],
    ),
  ];

  List<Map<String, dynamic>> get _bestsellingProducts => [
    {'name': 'Anti-aging\nSerum', 'price': 85.00, 'image': 'antiaging.jpg'},
    {'name': 'Aloe Vera\nGel', 'price': 25.00, 'image': 'aloevera.jpg'},
    {'name': 'Moisturizing\nLotion', 'price': 35.00, 'image': 'moisturizer.jpg'},
  ];

  List<Map<String, dynamic>> get _trendingProducts => [
    {'name': 'Vibrant\nLipstick', 'price': 20.00, 'image': 'lipstick.jpg'},
    {'name': 'Eyeshadow\nPalette', 'price': 40.00, 'image': 'eyeshadow.jpg'},
    {'name': 'Long-lasting\nMascara', 'price': 30.00, 'image': 'mascara.jpg'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              
              // Banner Section
              _buildBannerSection(),
              
              // Celebrity Beauty Picks
              _buildCelebritySection(),
              
              // New Arrivals
              _buildNewArrivalsSection(),
              
              // Bestselling Skincare
              _buildBestsellingSection(),
              
              // Trending Makeup
              _buildTrendingSection(),
              
              const SizedBox(height: 40), // Bottom padding for nav bar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Bloom Beauty',
            style: TextStyle(
              fontSize: 24,
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
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerSection() {
    return Column(
      children: [
        Container(
          height: 200,
          margin: const EdgeInsets.symmetric(horizontal: 16),
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
                      Colors.pink.withOpacity(0.8),
                      Colors.purple.withOpacity(0.8),
                      Colors.orange.withOpacity(0.8),
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
                            size: 60,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _bannerImages[index],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
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
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentBannerIndex == index
                    ? AppConstants.accentColor
                    : AppConstants.textSecondary.withOpacity(0.3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCelebritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
          child: Row(
            children: [
              Icon(
                Icons.star_rounded,
                color: AppConstants.accentColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'CELEBRITY PICKS',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        
        // Horizontal scrolling list
        SizedBox(
          height: 280, // Fixed height for the cards
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _celebrityPicks.length,
            itemBuilder: (context, index) {
              final pick = _celebrityPicks[index];
              return Container(
                width: 200, // Fixed width for each card
                margin: const EdgeInsets.only(right: 16),
                child: CelebrityPickCard(
                  product: pick['product'] as Product,
                  celebrityName: pick['name'] as String,
                  celebrityImage: pick['image'] as String,
                  testimonial: pick['testimonial'] as String?,
                  index: index,
                  onTap: () {
                    _showCelebrityPickDetails(context, pick);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showCelebrityPickDetails(BuildContext context, Map<String, dynamic> pick) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: AppConstants.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Celebrity info header
                          Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppConstants.accentColor,
                                      AppConstants.favoriteColor,
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    (pick['name'] as String)[0],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pick['name'] as String,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppConstants.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Celebrity Pick',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppConstants.accentColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Testimonial
                          if (pick['testimonial'] != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppConstants.backgroundColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppConstants.accentColor.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.format_quote,
                                    color: AppConstants.accentColor,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    pick['testimonial'] as String,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontStyle: FontStyle.italic,
                                      color: AppConstants.textPrimary,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          
                          // Product details
                          Text(
                            'Recommended Product',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.textPrimary,
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Product card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppConstants.surfaceColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppConstants.borderColor,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        gradient: LinearGradient(
                                          colors: [
                                            AppConstants.accentColor.withValues(alpha: 0.1),
                                            AppConstants.favoriteColor.withValues(alpha: 0.1),
                                          ],
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.spa_outlined,
                                        color: AppConstants.accentColor,
                                        size: 30,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            (pick['product'] as Product).name,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppConstants.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            (pick['product'] as Product).brand,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: AppConstants.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '\$${(pick['product'] as Product).price.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: AppConstants.accentColor,
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
                          
                          const SizedBox(height: 32),
                          
                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Added ${(pick['product'] as Product).name} to cart!'),
                                        backgroundColor: AppConstants.successColor,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.shopping_cart_outlined),
                                  label: const Text('Add to Cart'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppConstants.accentColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppConstants.borderColor),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Added to favorites!'),
                                      ),
                                    );
                                  },
                                  icon: Icon(
                                    Icons.favorite_border,
                                    color: AppConstants.favoriteColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 32), // Extra bottom padding
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewArrivalsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
          child: Text(
            'NEW ARRIVALS',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.accentColor,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: _newArrivals.length,
            itemBuilder: (context, index) {
              final product = _newArrivals[index];
              return _buildNewArrivalCard(product);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNewArrivalCard(Product product) {
    return Container(
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
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        'IQD ${product.price.toStringAsFixed(3)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                      const Spacer(),
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
    );
  }

  Widget _buildBestsellingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
          child: Text(
            'BESTSELLING SKINCARE',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.accentColor,
              letterSpacing: 1.2,
            ),
          ),
        ),
        SizedBox(
          height: 180, // Increased height to prevent overflow
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _bestsellingProducts.length,
            itemBuilder: (context, index) {
              final product = _bestsellingProducts[index];
              return _buildHorizontalProductCard(product);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
          child: Text(
            'TRENDING MAKEUP',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.accentColor,
              letterSpacing: 1.2,
            ),
          ),
        ),
        SizedBox(
          height: 180, // Increased height to prevent overflow
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _trendingProducts.length,
            itemBuilder: (context, index) {
              final product = _trendingProducts[index];
              return _buildHorizontalProductCard(product);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalProductCard(Map<String, dynamic> product) {
    return Container(
      width: 140, // Increased width for better layout
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image container
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppConstants.backgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.spa_outlined,
                  size: 40,
                  color: AppConstants.accentColor.withOpacity(0.5),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Product details
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product name
                Text(
                  product['name'],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const Spacer(),
                
                // Price
                Text(
                  '\$${product['price'].toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 15,
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
}
