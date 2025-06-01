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
      'socialMediaLinks': {
        'instagram': 'https://instagram.com/emmastone',
        'facebook': 'https://facebook.com/EmmaStoneOfficial',
      },
      'recommendedProducts': [
        _bestsellingProducts[0], // Anti-aging Serum
        _newArrivals[0], // Retinol Night Cream
      ],
      'morningRoutineProducts': [
        _bestsellingProducts[0], // Anti-aging Serum
        _bestsellingProducts[1], // Aloe Vera Gel
        _newArrivals[1], // Sunscreen SPF 50
      ],
      'eveningRoutineProducts': [
        _newArrivals[0], // Retinol Night Cream
        _bestsellingProducts[2], // Vitamin C Brightening Mask
        _trendingProducts[0], // Hydrating Toner
      ],
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
      'socialMediaLinks': {
        'instagram': 'https://instagram.com/badgalriri',
        'facebook': 'https://facebook.com/rihanna',
        'snapchat': 'https://snapchat.com/add/rihanna',
      },
      'recommendedProducts': [
        _bestsellingProducts[1], // Aloe Vera Gel
        _bestsellingProducts[2], // Vitamin C Brightening Mask
      ],
      'morningRoutineProducts': [
        _trendingProducts[1], // Charcoal Face Wash
        _bestsellingProducts[1], // Aloe Vera Gel
        _newArrivals[1], // Sunscreen SPF 50
      ],
      'eveningRoutineProducts': [
        _trendingProducts[1], // Charcoal Face Wash
        _bestsellingProducts[2], // Vitamin C Brightening Mask
        _newArrivals[0], // Retinol Night Cream
        _trendingProducts[0], // Hydrating Toner
      ],
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
      'socialMediaLinks': {
        'instagram': 'https://instagram.com/zendaya',
        'snapchat': 'https://snapchat.com/add/zendayaa',
      },
      'recommendedProducts': [
        _newArrivals[1], // Sunscreen SPF 50
        _trendingProducts[0], // Hydrating Toner
      ],
      'morningRoutineProducts': [
        _trendingProducts[0], // Hydrating Toner
        _bestsellingProducts[0], // Anti-aging Serum
        _newArrivals[1], // Sunscreen SPF 50
      ],
      'eveningRoutineProducts': [
        _trendingProducts[1], // Charcoal Face Wash
        _trendingProducts[0], // Hydrating Toner
        _bestsellingProducts[0], // Anti-aging Serum
      ],
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
      'socialMediaLinks': {
        'instagram': 'https://instagram.com/selenagomez',
        'facebook': 'https://facebook.com/Selena',
        'snapchat': 'https://snapchat.com/add/selenagomez',
      },
      'recommendedProducts': [
        _bestsellingProducts[2], // Vitamin C Brightening Mask
        _trendingProducts[1], // Charcoal Face Wash
      ],
      'morningRoutineProducts': [
        _trendingProducts[1], // Charcoal Face Wash
        _bestsellingProducts[2], // Vitamin C Brightening Mask
        _bestsellingProducts[1], // Aloe Vera Gel
        _newArrivals[1], // Sunscreen SPF 50
      ],
      'eveningRoutineProducts': [
        _trendingProducts[1], // Charcoal Face Wash
        _bestsellingProducts[0], // Anti-aging Serum
        _newArrivals[0], // Retinol Night Cream
      ],
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
      'socialMediaLinks': {
        'instagram': 'https://instagram.com/kimkardashian',
        'facebook': 'https://facebook.com/KimKardashian',
        'snapchat': 'https://snapchat.com/add/kimkardashian',
      },
      'recommendedProducts': [
        _bestsellingProducts[0], // Anti-aging Serum
        _newArrivals[0], // Retinol Night Cream
      ],
      'morningRoutineProducts': [
        _trendingProducts[1], // Charcoal Face Wash
        _bestsellingProducts[0], // Anti-aging Serum
        _bestsellingProducts[1], // Aloe Vera Gel
        _newArrivals[1], // Sunscreen SPF 50
      ],
      'eveningRoutineProducts': [
        _trendingProducts[1], // Charcoal Face Wash
        _newArrivals[0], // Retinol Night Cream
        _trendingProducts[0], // Hydrating Toner
      ],
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
      'socialMediaLinks': {
        'instagram': 'https://instagram.com/taylorswift',
        'facebook': 'https://facebook.com/TaylorSwift',
      },
      'recommendedProducts': [
        _trendingProducts[0], // Hydrating Toner
        _bestsellingProducts[1], // Aloe Vera Gel
      ],
      'morningRoutineProducts': [
        _trendingProducts[0], // Hydrating Toner
        _bestsellingProducts[1], // Aloe Vera Gel
        _newArrivals[1], // Sunscreen SPF 50
      ],
      'eveningRoutineProducts': [
        _trendingProducts[1], // Charcoal Face Wash
        _bestsellingProducts[2], // Vitamin C Brightening Mask
        _newArrivals[0], // Retinol Night Cream
      ],
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
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine screen size
        final isSmallScreen = constraints.maxWidth < 600;
        final isMediumScreen = constraints.maxWidth >= 600 && constraints.maxWidth < 900;
        
        return Scaffold(
          backgroundColor: AppConstants.backgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
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
                    : AppConstants.textSecondary.withOpacity(0.3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCelebritySection(bool isSmallScreen, bool isMediumScreen) {
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
                    isSmallScreen ? 16 : 20
                  ),
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
                                  padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
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
                                          letterSpacing: isSmallScreen ? 0.8 : 1.2,
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
                    padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
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
                                width: isSmallScreen ? 180 : 200,
                                margin: EdgeInsets.only(right: isSmallScreen ? 12 : 16),
                                child: CelebrityPickCard(
                                  product: pick['product'] as Product,
                                  celebrityName: pick['name'] as String,
                                  celebrityImage: pick['image'] as String,
                                  testimonial: pick['testimonial'] as String?,
                                  socialMediaLinks: pick['socialMediaLinks'] as Map<String, String>? ?? {},
                                  recommendedProducts: pick['recommendedProducts'] as List<Product>? ?? [],
                                  morningRoutineProducts: pick['morningRoutineProducts'] as List<Product>? ?? [],
                                  eveningRoutineProducts: pick['eveningRoutineProducts'] as List<Product>? ?? [],
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

  Widget _buildNewArrivalsSection(bool isSmallScreen, bool isMediumScreen) {
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
            isSmallScreen ? 12 : 16
          ),
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
          padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: isSmallScreen ? 8 : 12,
              mainAxisSpacing: isSmallScreen ? 8 : 12,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: _newArrivals.length,
            itemBuilder: (context, index) {
              final product = _newArrivals[index];
              return _buildNewArrivalCard(product, isSmallScreen);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNewArrivalCard(Product product, bool isSmallScreen) {
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
                        size: isSmallScreen ? 32 : 40,
                        color: AppConstants.accentColor.withOpacity(0.5),
                      ),
                    ),
                  ),
                  Positioned(
                    top: isSmallScreen ? 6 : 8,
                    right: isSmallScreen ? 6 : 8,
                    child: Container(
                      width: isSmallScreen ? 28 : 32,
                      height: isSmallScreen ? 28 : 32,
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
                        size: isSmallScreen ? 14 : 18,
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

  Widget _buildBestsellingSection(bool isSmallScreen, bool isMediumScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            isSmallScreen ? 12 : 16, 
            isSmallScreen ? 24 : 32, 
            isSmallScreen ? 12 : 16, 
            isSmallScreen ? 12 : 16
          ),
          child: Text(
            'BESTSELLING SKINCARE',
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
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
            itemCount: _bestsellingProducts.length,
            itemBuilder: (context, index) {
              final product = _bestsellingProducts[index];
              return _buildHorizontalProductCard(product, isSmallScreen);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingSection(bool isSmallScreen, bool isMediumScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            isSmallScreen ? 12 : 16, 
            isSmallScreen ? 24 : 32, 
            isSmallScreen ? 12 : 16, 
            isSmallScreen ? 12 : 16
          ),
          child: Text(
            'TRENDING MAKEUP',
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
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
            itemCount: _trendingProducts.length,
            itemBuilder: (context, index) {
              final product = _trendingProducts[index];
              return _buildHorizontalProductCard(product, isSmallScreen);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalProductCard(Product product, bool isSmallScreen) {
    return GestureDetector(
      onTap: () {
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
                        size: isSmallScreen ? 32 : 40,
                        color: AppConstants.accentColor.withOpacity(0.5),
                      ),
                    ),
                  ),
                  Positioned(
                    top: isSmallScreen ? 6 : 8,
                    right: isSmallScreen ? 6 : 8,
                    child: Container(
                      width: isSmallScreen ? 28 : 32,
                      height: isSmallScreen ? 28 : 32,
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
                        size: isSmallScreen ? 14 : 18,
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
