import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../constants/app_constants.dart';
import '../../widgets/product/celebrity_pick_card.dart';
import '../products/product_detail_screen.dart';
import 'package:intl/intl.dart';
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

  // Helper function to format price in IQD
  String _formatPrice(double price) {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(price)} IQD';
  }

  // Celebrity picks data with products
  List<Map<String, dynamic>> get _celebrityPicks => [
    {
      'name': 'Emma Stone',
      'image': 'emma.jpg',
      'testimonial': 'This serum transformed my skin overnight!',
      'product': Product(
        id: 'cp1',
        name: 'Glow Serum',
        description: 'Radiance boosting serum with vitamin C and niacinamide for luminous, healthy-looking skin.',
        price: 85000.00,
        images: ['glow_serum.jpg'],
        categoryId: '1',
        brand: 'LuxeBrand',
        rating: 4.8,
        reviewCount: 156,
        isInStock: true,
        ingredients: ['Vitamin C', 'Niacinamide', 'Hyaluronic Acid'],
        beautyPoints: 85,
        variants: [
          ProductVariant(
            id: 'cp1v1',
            name: 'Morning Glow',
            color: 'Light Orange',
            images: ['glow_serum.jpg', 'glow_serum_morning.jpg'],
          ),
          ProductVariant(
            id: 'cp1v2',
            name: 'Evening Glow',
            color: 'Deep Orange',
            images: ['glow_serum_evening.jpg'],
            priceAdjustment: 15000.00,
          ),
        ],
        reviews: [
          ProductReview(
            id: 'cp1r1',
            userId: 'u9',
            userName: 'Amal Hussain',
            userImage: 'user9.jpg',
            rating: 5.0,
            comment: 'Just like Emma said, amazing results!',
            date: DateTime.now().subtract(Duration(days: 3)),
          ),
        ],
        celebrityEndorsement: CelebrityEndorsement(
          celebrityName: 'Emma Stone',
          celebrityImage: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&h=150&fit=crop&crop=face',
          testimonial: 'This serum transformed my skin overnight!',
        ),
      ),
    },
    {
      'name': 'Rihanna',
      'image': 'rihanna.jpg',
      'testimonial': 'Perfect for my everyday glow',
      'product': Product(
        id: 'cp2',
        name: 'Fenty Cream',
        description: 'Moisturizing face cream that provides all-day hydration and a natural glow.',
        price: 65000.00,
        images: ['fenty_cream.jpg'],
        categoryId: '1',
        brand: 'Fenty Beauty',
        rating: 4.9,
        reviewCount: 203,
        isInStock: true,
        ingredients: ['Shea Butter', 'Hyaluronic Acid', 'Ceramides'],
        beautyPoints: 65,
        variants: [
          ProductVariant(
            id: 'cp2v1',
            name: 'Day Cream',
            color: 'White',
            images: ['fenty_cream.jpg'],
          ),
          ProductVariant(
            id: 'cp2v2',
            name: 'Night Cream',
            color: 'Ivory',
            images: ['fenty_cream_night.jpg'],
            priceAdjustment: 10000.00,
          ),
        ],
        reviews: [
          ProductReview(
            id: 'cp2r1',
            userId: 'u10',
            userName: 'Leila Mahmoud',
            userImage: 'user10.jpg',
            rating: 4.8,
            comment: 'Gives me that Rihanna glow!',
            date: DateTime.now().subtract(Duration(days: 7)),
          ),
        ],
        celebrityEndorsement: CelebrityEndorsement(
          celebrityName: 'Rihanna',
          celebrityImage: 'https://images.unsplash.com/photo-1601455763557-db1bea8a9a5a?w=150&h=150&fit=crop&crop=face',
          testimonial: 'Perfect for my everyday glow',
        ),
      ),
    },
    {
      'name': 'Zendaya',
      'image': 'zendaya.jpg',
      'testimonial': 'Love how natural this makes my skin look',
      'product': Product(
        id: 'cp3',
        name: 'Natural Foundation',
        description: 'Light coverage foundation with natural finish and SPF protection.',
        price: 45000.00,
        images: ['foundation.jpg'],
        categoryId: '2',
        brand: 'Z Beauty',
        rating: 4.7,
        reviewCount: 89,
        isInStock: true,
        ingredients: ['Mineral Powder', 'SPF 30', 'Vitamin E'],
        beautyPoints: 45,
        variants: [
          ProductVariant(
            id: 'cp3v1',
            name: 'Light',
            color: 'Beige',
            images: ['foundation_light.jpg'],
          ),
          ProductVariant(
            id: 'cp3v2',
            name: 'Medium',
            color: 'Medium Beige',
            images: ['foundation_medium.jpg'],
          ),
          ProductVariant(
            id: 'cp3v3',
            name: 'Deep',
            color: 'Deep Beige',
            images: ['foundation_deep.jpg'],
          ),
        ],
        reviews: [
          ProductReview(
            id: 'cp3r1',
            userId: 'u11',
            userName: 'Maya Karim',
            userImage: 'user11.jpg',
            rating: 4.5,
            comment: 'Perfect natural coverage, just like Zendaya!',
            date: DateTime.now().subtract(Duration(days: 4)),
          ),
        ],
        celebrityEndorsement: CelebrityEndorsement(
          celebrityName: 'Zendaya',
          celebrityImage: 'https://images.unsplash.com/photo-1502823403499-6ccfcf4fb453?w=150&h=150&fit=crop&crop=face',
          testimonial: 'Love how natural this makes my skin look',
        ),
      ),
    },
    {
      'name': 'Selena Gomez',
      'image': 'selena.jpg',
      'testimonial': 'This lipstick is my go-to for every occasion',
      'product': Product(
        id: 'cp4',
        name: 'Rare Lipstick',
        description: 'Long-lasting matte lipstick with comfortable wear and rich color payoff.',
        price: 28000.00,
        images: ['rare_lipstick.jpg'],
        categoryId: '3',
        brand: 'Rare Beauty',
        rating: 4.8,
        reviewCount: 312,
        isInStock: true,
        ingredients: ['Vitamin E', 'Jojoba Oil', 'Shea Butter'],
        beautyPoints: 28,
        variants: [
          ProductVariant(
            id: 'cp4v1',
            name: 'Nude Rose',
            color: 'Pink',
            images: ['rare_lipstick_nude.jpg'],
          ),
          ProductVariant(
            id: 'cp4v2',
            name: 'Berry Bold',
            color: 'Berry',
            images: ['rare_lipstick_berry.jpg'],
          ),
          ProductVariant(
            id: 'cp4v3',
            name: 'Classic Red',
            color: 'Red',
            images: ['rare_lipstick_red.jpg'],
          ),
        ],
        reviews: [
          ProductReview(
            id: 'cp4r1',
            userId: 'u12',
            userName: 'Nadia Salem',
            userImage: 'user12.jpg',
            rating: 5.0,
            comment: 'Love this lipstick! So comfortable to wear.',
            date: DateTime.now().subtract(Duration(days: 1)),
          ),
        ],
        celebrityEndorsement: CelebrityEndorsement(
          celebrityName: 'Selena Gomez',
          celebrityImage: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&h=150&fit=crop&crop=face',
          testimonial: 'This lipstick is my go-to for every occasion',
        ),
      ),
    },
    {
      'name': 'Kim Kardashian',
      'image': 'kim.jpg',
      'testimonial': 'The contouring power is incredible',
      'product': Product(
        id: 'cp5',
        name: 'Contour Kit',
        description: 'Professional contouring palette with blendable shades for sculpting and defining.',
        price: 72000.00,
        images: ['contour_kit.jpg'],
        categoryId: '2',
        brand: 'KKW Beauty',
        rating: 4.6,
        reviewCount: 167,
        isInStock: true,
        ingredients: ['Mica', 'Silica', 'Vitamin E'],
        beautyPoints: 72,
        variants: [
          ProductVariant(
            id: 'cp5v1',
            name: 'Light/Medium',
            color: 'Light Brown',
            images: ['contour_kit_light.jpg'],
          ),
          ProductVariant(
            id: 'cp5v2',
            name: 'Medium/Dark',
            color: 'Dark Brown',
            images: ['contour_kit_dark.jpg'],
          ),
        ],
        reviews: [
          ProductReview(
            id: 'cp5r1',
            userId: 'u13',
            userName: 'Rana Nasser',
            userImage: 'user13.jpg',
            rating: 4.7,
            comment: 'Great for sculpting, just like Kim showed!',
            date: DateTime.now().subtract(Duration(days: 9)),
          ),
        ],
        celebrityEndorsement: CelebrityEndorsement(
          celebrityName: 'Kim Kardashian',
          celebrityImage: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
          testimonial: 'The contouring power is incredible',
        ),
      ),
    },
    {
      'name': 'Taylor Swift',
      'image': 'taylor.jpg',
      'testimonial': 'Perfect red for my signature look',
      'product': Product(
        id: 'cp6',
        name: 'Red Lip Classic',
        description: 'Classic red lipstick with creamy texture and long-lasting color.',
        price: 32000.00,
        images: ['red_lipstick.jpg'],
        categoryId: '3',
        brand: 'Swift Beauty',
        rating: 4.9,
        reviewCount: 245,
        isInStock: true,
        ingredients: ['Vitamin C', 'Aloe Vera', 'Cocoa Butter'],
        beautyPoints: 32,
        variants: [
          ProductVariant(
            id: 'cp6v1',
            name: 'Cherry Red',
            color: 'Bright Red',
            images: ['red_lipstick.jpg'],
          ),
          ProductVariant(
            id: 'cp6v2',
            name: 'Wine Red',
            color: 'Deep Red',
            images: ['red_lipstick_wine.jpg'],
          ),
        ],
        reviews: [
          ProductReview(
            id: 'cp6r1',
            userId: 'u14',
            userName: 'Hala Rashid',
            userImage: 'user14.jpg',
            rating: 5.0,
            comment: 'This red is iconic, just like Taylor!',
            date: DateTime.now().subtract(Duration(days: 6)),
          ),
        ],
        celebrityEndorsement: CelebrityEndorsement(
          celebrityName: 'Taylor Swift',
          celebrityImage: 'https://images.unsplash.com/photo-1494790108755-2616c04a5821?w=150&h=150&fit=crop&crop=face',
          testimonial: 'Perfect red for my signature look',
        ),
      ),
    },
  ];

  // Product data
  List<Product> get _newArrivals => [
    Product(
      id: 'na1',
      name: 'Retinol Night Cream',
      description: 'Advanced night cream with retinol to reduce signs of aging and improve skin texture overnight.',
      price: 95000.00,
      images: ['retinol.jpg'],
      categoryId: '1',
      brand: 'NightGlow',
      rating: 4.9,
      reviewCount: 67,
      isInStock: true,
      ingredients: ['Retinol', 'Ceramides', 'Niacinamide', 'Peptides'],
      beautyPoints: 95,
      variants: [
        ProductVariant(
          id: 'v11',
          name: '0.25% Retinol',
          color: 'Light Purple',
          images: ['retinol_025.jpg'],
        ),
        ProductVariant(
          id: 'v12',
          name: '0.5% Retinol',
          color: 'Dark Purple',
          images: ['retinol_05.jpg'],
          priceAdjustment: 20000.00,
        ),
      ],
      reviews: [
        ProductReview(
          id: 'r7',
          userId: 'u7',
          userName: 'Rana Khalil',
          userImage: 'user7.jpg',
          rating: 5.0,
          comment: 'Best night cream I have ever used!',
          date: DateTime.now().subtract(Duration(days: 2)),
        ),
      ],
    ),
    Product(
      id: 'na2',
      name: 'Sunscreen SPF 50',
      description: 'Broad-spectrum sunscreen with SPF 50+ protection. Lightweight, non-greasy formula perfect for daily use.',
      price: 42000.00,
      images: ['sunscreen.jpg'],
      categoryId: '1',
      brand: 'SunShield',
      rating: 4.6,
      reviewCount: 201,
      isInStock: true,
      ingredients: ['Zinc Oxide', 'Titanium Dioxide', 'Vitamin E'],
      beautyPoints: 42,
      variants: [
        ProductVariant(
          id: 'v13',
          name: 'Tinted',
          color: 'Beige',
          images: ['sunscreen_tinted.jpg'],
        ),
        ProductVariant(
          id: 'v14',
          name: 'Clear',
          color: 'White',
          images: ['sunscreen_clear.jpg'],
        ),
      ],
      reviews: [
        ProductReview(
          id: 'r8',
          userId: 'u8',
          userName: 'Dina Farouk',
          userImage: 'user8.jpg',
          rating: 4.5,
          comment: 'Great protection without white cast.',
          date: DateTime.now().subtract(Duration(days: 6)),
        ),
      ],
    ),
  ];

  List<Product> get _bestsellingProducts => [
    Product(
      id: 'bs1',
      name: 'Anti-aging Serum',
      description: 'Premium anti-aging serum with retinol and hyaluronic acid. This powerful serum targets fine lines, wrinkles, and age spots while providing deep hydration for youthful-looking skin.',
      price: 85000.00, // Price in IQD
      images: ['antiaging.jpg'],
      categoryId: '1',
      brand: 'AgeLess',
      rating: 4.8,
      reviewCount: 245,
      isInStock: true,
      ingredients: ['Retinol', 'Hyaluronic Acid', 'Vitamin C', 'Peptides'],
      beautyPoints: 85,
      variants: [
        ProductVariant(
          id: 'v1',
          name: '30ml',
          color: 'Standard',
          images: ['antiaging.jpg', 'antiaging_2.jpg'],
        ),
        ProductVariant(
          id: 'v2',
          name: '50ml',
          color: 'Standard',
          images: ['antiaging_50ml.jpg', 'antiaging_50ml_2.jpg'],
          priceAdjustment: 25000.00,
        ),
      ],
      reviews: [
        ProductReview(
          id: 'r1',
          userId: 'u1',
          userName: 'Sarah Ahmed',
          userImage: 'user1.jpg',
          rating: 5.0,
          comment: 'Amazing results! My skin looks so much younger.',
          date: DateTime.now().subtract(Duration(days: 5)),
        ),
        ProductReview(
          id: 'r2',
          userId: 'u2',
          userName: 'Fatima Ali',
          userImage: 'user2.jpg',
          rating: 4.5,
          comment: 'Great product, noticed difference in 2 weeks.',
          date: DateTime.now().subtract(Duration(days: 12)),
        ),
      ],
      celebrityEndorsement: CelebrityEndorsement(
        celebrityName: 'Yasmin Abdulaziz',
        celebrityImage: 'yasmin.jpg',
        testimonial: 'This serum transformed my skin routine completely!',
      ),
    ),
    Product(
      id: 'bs2',
      name: 'Aloe Vera Gel',
      description: 'Soothing aloe vera gel perfect for sensitive skin and after-sun care. Contains 99% pure aloe vera extract for maximum healing and hydration.',
      price: 25000.00,
      images: ['aloevera.jpg'],
      categoryId: '1',
      brand: 'NatureCare',
      rating: 4.6,
      reviewCount: 189,
      isInStock: true,
      ingredients: ['Aloe Vera Extract', 'Hyaluronic Acid', 'Vitamin E'],
      beautyPoints: 25,
      variants: [
        ProductVariant(
          id: 'v3',
          name: 'Original',
          color: 'Clear',
          images: ['aloevera.jpg', 'aloevera_2.jpg'],
        ),
        ProductVariant(
          id: 'v4',
          name: 'With Cucumber',
          color: 'Light Green',
          images: ['aloevera_cucumber.jpg', 'aloevera_cucumber_2.jpg'],
          priceAdjustment: 5000.00,
        ),
      ],
      reviews: [
        ProductReview(
          id: 'r3',
          userId: 'u3',
          userName: 'Nour Hassan',
          userImage: 'user3.jpg',
          rating: 4.5,
          comment: 'Very soothing, perfect for sensitive skin.',
          date: DateTime.now().subtract(Duration(days: 8)),
        ),
      ],
    ),
    Product(
      id: 'bs3',
      name: 'Vitamin C Brightening Mask',
      description: 'Illuminating face mask with vitamin C and niacinamide to brighten dull skin and even out skin tone.',
      price: 45000.00,
      images: ['vitaminc.jpg'],
      categoryId: '1',
      brand: 'GlowLab',
      rating: 4.7,
      reviewCount: 156,
      isInStock: true,
      ingredients: ['Vitamin C', 'Niacinamide', 'Arbutin', 'Kojic Acid'],
      beautyPoints: 45,
      variants: [
        ProductVariant(
          id: 'v5',
          name: 'Single Use',
          color: 'Orange',
          images: ['vitaminc.jpg'],
        ),
        ProductVariant(
          id: 'v6',
          name: '5-Pack',
          color: 'Orange',
          images: ['vitaminc_5pack.jpg'],
          priceAdjustment: 125000.00,
        ),
      ],
      reviews: [
        ProductReview(
          id: 'r4',
          userId: 'u4',
          userName: 'Layla Mohammed',
          userImage: 'user4.jpg',
          rating: 5.0,
          comment: 'My skin is glowing after just one use!',
          date: DateTime.now().subtract(Duration(days: 3)),
        ),
      ],
    ),
  ];

  List<Product> get _trendingProducts => [
    Product(
      id: 'tr1',
      name: 'Hydrating Toner',
      description: 'Alcohol-free hydrating toner that balances pH and prepares skin for better product absorption.',
      price: 35000.00,
      images: ['toner.jpg'],
      categoryId: '1',
      brand: 'HydraFresh',
      rating: 4.5,
      reviewCount: 89,
      isInStock: true,
      ingredients: ['Rose Water', 'Hyaluronic Acid', 'Glycerin'],
      beautyPoints: 35,
      variants: [
        ProductVariant(
          id: 'v7',
          name: 'Rose',
          color: 'Pink',
          images: ['toner_rose.jpg'],
        ),
        ProductVariant(
          id: 'v8',
          name: 'Green Tea',
          color: 'Green',
          images: ['toner_greentea.jpg'],
        ),
      ],
      reviews: [
        ProductReview(
          id: 'r5',
          userId: 'u5',
          userName: 'Maryam Omar',
          userImage: 'user5.jpg',
          rating: 4.0,
          comment: 'Nice toner, not too harsh on my skin.',
          date: DateTime.now().subtract(Duration(days: 7)),
        ),
      ],
      celebrityEndorsement: CelebrityEndorsement(
        celebrityName: 'Haifa Wehbe',
        celebrityImage: 'haifa.jpg',
        testimonial: 'Perfect toner for my daily skincare routine!',
      ),
    ),
    Product(
      id: 'tr2',
      name: 'Charcoal Face Wash',
      description: 'Deep cleansing charcoal face wash that removes impurities and excess oil while being gentle on skin.',
      price: 28000.00,
      images: ['charcoal.jpg'],
      categoryId: '1',
      brand: 'PureClean',
      rating: 4.4,
      reviewCount: 134,
      isInStock: true,
      ingredients: ['Activated Charcoal', 'Salicylic Acid', 'Tea Tree Oil'],
      beautyPoints: 28,
      variants: [
        ProductVariant(
          id: 'v9',
          name: 'Regular',
          color: 'Black',
          images: ['charcoal.jpg'],
        ),
        ProductVariant(
          id: 'v10',
          name: 'Sensitive',
          color: 'Gray',
          images: ['charcoal_sensitive.jpg'],
          priceAdjustment: 7000.00,
        ),
      ],
      reviews: [
        ProductReview(
          id: 'r6',
          userId: 'u6',
          userName: 'Zeinab Saleh',
          userImage: 'user6.jpg',
          rating: 4.5,
          comment: 'Really cleans my pores well.',
          date: DateTime.now().subtract(Duration(days: 4)),
        ),
      ],
    ),
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
                  padding: const EdgeInsets.fromLTRB(16, 32, 16, 20),
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
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        AppConstants.accentColor.withOpacity(0.1),
                                        AppConstants.favoriteColor.withOpacity(0.1),
                                      ],
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.star_rounded,
                                    color: AppConstants.accentColor,
                                    size: 20,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
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
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppConstants.textPrimary,
                                          letterSpacing: 1.2,
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
                                    offset: Offset(20 * (1 - subtitleValue), 0),
                                    child: Opacity(
                                      opacity: subtitleValue * 0.7,
                                      child: Text(
                                        'Handpicked by your favorite stars',
                                        style: TextStyle(
                                          fontSize: 13,
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
                      ],
                    ),
                  ),
                ),
                
                // Enhanced horizontal scrolling list with faster animations
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _celebrityPicks.length,
                    itemBuilder: (context, index) {
                      final pick = _celebrityPicks[index];
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
                                width: 200,
                                margin: const EdgeInsets.only(right: 16),
                                child: CelebrityPickCard(
                                  product: pick['product'] as Product,
                                  celebrityName: pick['name'] as String,
                                  celebrityImage: pick['image'] as String,
                                  testimonial: pick['testimonial'] as String?,
                                  index: index,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProductDetailScreen(
                                          product: pick['product'] as Product,
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
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              product: product,
            ),
          ),
        );
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        product.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textPrimary,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatPrice(product.price),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: 12,
                              color: AppConstants.accentColor,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                product.rating.toString(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppConstants.textSecondary,
                                ),
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

  Widget _buildHorizontalProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              product: product,
            ),
          ),
        );
      },
      child: Container(
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
                    product.name,
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
                    _formatPrice(product.price),
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
      ),
    );
  }
}
