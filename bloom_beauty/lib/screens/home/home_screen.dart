import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/product/product_card.dart';
import '../../models/product_model.dart';
import '../../constants/app_constants.dart';

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

  // Celebrity picks data
  final List<Map<String, String>> _celebrities = [
    {'name': 'Emma', 'image': 'emma.jpg'},
    {'name': 'Rihanna', 'image': 'rihanna.jpg'},
    {'name': 'Zendaya', 'image': 'zendaya.jpg'},
    {'name': 'Selena\nGomez', 'image': 'selena.jpg'},
    {'name': 'Kim\nKardashian', 'image': 'kim.jpg'},
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
              
              const SizedBox(height: 100), // Bottom padding for nav bar
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
          child: Text(
            'CELEBRITY BEAUTY PICKS',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _celebrities.length,
            itemBuilder: (context, index) {
              final celebrity = _celebrities[index];
              return Container(
                width: 80,
                margin: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppConstants.accentColor.withOpacity(0.8),
                            AppConstants.favoriteColor.withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          celebrity['name']!.split('\n')[0][0],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      celebrity['name']!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppConstants.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
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
          height: 160,
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
          height: 160,
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
      width: 120,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: AppConstants.backgroundColor,
            ),
            child: Center(
              child: Icon(
                Icons.spa_outlined,
                size: 30,
                color: AppConstants.accentColor.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product['name'],
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppConstants.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '\$${product['price'].toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
