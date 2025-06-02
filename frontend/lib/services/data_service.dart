import '../models/product_model.dart';
import '../models/celebrity_model.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  // Lazy initialization
  List<Product>? _products;
  List<Celebrity>? _celebrities;

  List<Product> getAllProducts() {
    return _products ??= _generateProducts();
  }

  List<Celebrity> getAllCelebrities() {
    return _celebrities ??= _generateCelebrities();
  }

  List<Product> getProductsByCategory(String categoryId) {
    return getAllProducts().where((product) => product.categoryId == categoryId).toList();
  }

  List<Product> getBestsellingProducts() {
    return getAllProducts().where((product) => product.rating >= 4.5).toList();
  }

  List<Product> getNewArrivals() {
    // Return last 4 products as new arrivals
    final products = getAllProducts();
    return products.skip(products.length > 4 ? products.length - 4 : 0).toList();
  }

  List<Product> getTrendingProducts() {
    return getAllProducts().where((product) => product.reviewCount > 100).toList();
  }

  Celebrity? getCelebrityByName(String name) {
    try {
      return getAllCelebrities().firstWhere((celebrity) => celebrity.name == name);
    } catch (e) {
      return null;
    }
  }

  List<Map<String, dynamic>> getCelebrityPicks() {
    final celebrities = getAllCelebrities();
    return celebrities.map((celebrity) {
      return {
        'name': celebrity.name,
        'image': celebrity.image,
        'testimonial': celebrity.testimonial,
        'socialMediaLinks': celebrity.socialMediaLinks,
        'recommendedProducts': celebrity.recommendedProducts,
        'morningRoutineProducts': celebrity.morningRoutineProducts,
        'eveningRoutineProducts': celebrity.eveningRoutineProducts,
        'product': celebrity.getCelebrityPickProduct(),
      };
    }).toList();
  }

  Product? getProductById(String id) {
    try {
      return getAllProducts().firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> getCelebrityDataForProduct(String celebrityName) {
    final celebrity = getCelebrityByName(celebrityName);
    if (celebrity == null) {
      return {
        'socialMediaLinks': <String, String>{},
        'recommendedProducts': <Product>[],
        'morningRoutineProducts': <Product>[],
        'eveningRoutineProducts': <Product>[],
      };
    }

    return {
      'socialMediaLinks': celebrity.socialMediaLinks,
      'recommendedProducts': celebrity.recommendedProducts,
      'morningRoutineProducts': celebrity.morningRoutineProducts,
      'eveningRoutineProducts': celebrity.eveningRoutineProducts,
    };
  }

  List<Product> _generateProducts() {
    return [
      // Product 1
      Product(
        id: '1',
        name: 'Anti-aging Serum',
        description: 'Advanced anti-aging serum with retinol and hyaluronic acid for youthful, radiant skin.',
        price: 125000.00,
        images: ['anti_aging_serum.jpg'],
        categoryId: '1',
        brand: 'LuxeBrand',
        rating: 4.8,
        reviewCount: 234,
        isInStock: true,
        ingredients: ['Retinol', 'Hyaluronic Acid', 'Vitamin E'],
        beautyPoints: 125,
        variants: [
          ProductVariant(
            id: '1v1',
            name: 'Regular Strength',
            color: 'Standard',
            images: ['anti_aging_serum.jpg'],
          ),
          ProductVariant(
            id: '1v2',
            name: 'Extra Strength',
            color: 'Standard',
            images: ['anti_aging_serum_extra.jpg'],
            priceAdjustment: 25000.00,
          ),
        ],
        reviews: [
          ProductReview(
            id: '1r1',
            userId: 'u1',
            userName: 'Sarah Ahmed',
            userImage: 'user1.jpg',
            rating: 5.0,
            comment: 'Amazing results after just 2 weeks!',
            date: DateTime.now().subtract(Duration(days: 5)),
          ),
        ],
        celebrityEndorsement: CelebrityEndorsement(
          celebrityName: 'Emma Stone',
          celebrityImage: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&h=150&fit=crop&crop=face',
          testimonial: 'This serum transformed my skin overnight!',
        ),
      ),

      // Product 2
      Product(
        id: '2',
        name: 'Aloe Vera Gel',
        description: 'Pure aloe vera gel for soothing and hydrating sensitive skin.',
        price: 35000.00,
        images: ['aloe_vera_gel.jpg'],
        categoryId: '1',
        brand: 'NaturalCare',
        rating: 4.6,
        reviewCount: 189,
        isInStock: true,
        ingredients: ['Aloe Vera Extract', 'Glycerin', 'Panthenol'],
        beautyPoints: 35,
        variants: [
          ProductVariant(
            id: '2v1',
            name: '100ml',
            color: 'Standard',
            images: ['aloe_vera_gel.jpg'],
          ),
          ProductVariant(
            id: '2v2',
            name: '200ml',
            color: 'Standard',
            images: ['aloe_vera_gel_200ml.jpg'],
            priceAdjustment: 15000.00,
          ),
        ],
        reviews: [],
      ),

      // Product 3
      Product(
        id: '3',
        name: 'Vitamin C Brightening Mask',
        description: 'Brightening face mask with vitamin C and citrus extracts for glowing skin.',
        price: 55000.00,
        images: ['vitamin_c_mask.jpg'],
        categoryId: '1',
        brand: 'GlowCo',
        rating: 4.7,
        reviewCount: 156,
        isInStock: true,
        ingredients: ['Vitamin C', 'Citrus Extract', 'Clay'],
        beautyPoints: 55,
        variants: [],
        reviews: [],
      ),

      // Product 4
      Product(
        id: '4',
        name: 'Retinol Night Cream',
        description: 'Rich night cream with retinol and peptides for overnight skin renewal.',
        price: 95000.00,
        images: ['retinol_cream.jpg'],
        categoryId: '1',
        brand: 'LuxeBrand',
        rating: 4.9,
        reviewCount: 201,
        isInStock: true,
        ingredients: ['Retinol', 'Peptides', 'Shea Butter'],
        beautyPoints: 95,
        variants: [],
        reviews: [],
        celebrityEndorsement: CelebrityEndorsement(
          celebrityName: 'Rihanna',
          celebrityImage: 'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=150&h=150&fit=crop&crop=face',
          testimonial: 'Perfect for my nighttime routine!',
        ),
      ),

      // Product 5
      Product(
        id: '5',
        name: 'Sunscreen SPF 50',
        description: 'Broad-spectrum sunscreen with SPF 50 for maximum UV protection.',
        price: 45000.00,
        images: ['sunscreen.jpg'],
        categoryId: '1',
        brand: 'SunShield',
        rating: 4.5,
        reviewCount: 178,
        isInStock: true,
        ingredients: ['Zinc Oxide', 'Titanium Dioxide', 'Vitamin E'],
        beautyPoints: 45,
        variants: [],
        reviews: [],
      ),

      // Product 6
      Product(
        id: '6',
        name: 'Hydrating Toner',
        description: 'Alcohol-free hydrating toner with rose water and hyaluronic acid.',
        price: 42000.00,
        images: ['toner.jpg'],
        categoryId: '1',
        brand: 'PureBeauty',
        rating: 4.4,
        reviewCount: 134,
        isInStock: true,
        ingredients: ['Rose Water', 'Hyaluronic Acid', 'Glycerin'],
        beautyPoints: 42,
        variants: [],
        reviews: [],
      ),

      // Product 7
      Product(
        id: '7',
        name: 'Charcoal Face Wash',
        description: 'Deep cleansing face wash with activated charcoal for oily skin.',
        price: 38000.00,
        images: ['charcoal_wash.jpg'],
        categoryId: '1',
        brand: 'CleanCo',
        rating: 4.3,
        reviewCount: 167,
        isInStock: true,
        ingredients: ['Activated Charcoal', 'Salicylic Acid', 'Tea Tree Oil'],
        beautyPoints: 38,
        variants: [],
        reviews: [],
      ),

      // Product 8
      Product(
        id: '8',
        name: 'Glow Serum',
        description: 'Radiance boosting serum with vitamin C and niacinamide.',
        price: 85000.00,
        images: ['glow_serum.jpg'],
        categoryId: '1',
        brand: 'LuxeBrand',
        rating: 4.8,
        reviewCount: 156,
        isInStock: true,
        ingredients: ['Vitamin C', 'Niacinamide', 'Hyaluronic Acid'],
        beautyPoints: 85,
        variants: [],
        reviews: [],
        celebrityEndorsement: CelebrityEndorsement(
          celebrityName: 'Zendaya',
          celebrityImage: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150&h=150&fit=crop&crop=face',
          testimonial: 'Gives me that natural glow!',
        ),
      ),

      // Product 9
      Product(
        id: '9',
        name: 'Luminous Foundation',
        description: 'Medium coverage foundation with a natural luminous finish.',
        price: 75000.00,
        images: ['foundation.jpg'],
        categoryId: '2',
        brand: 'MakeupPro',
        rating: 4.6,
        reviewCount: 198,
        isInStock: true,
        ingredients: ['Hyaluronic Acid', 'Vitamin E', 'SPF 15'],
        beautyPoints: 75,
        variants: [
          ProductVariant(
            id: '9v1',
            name: 'Fair',
            color: 'Light Beige',
            images: ['foundation_fair.jpg'],
          ),
          ProductVariant(
            id: '9v2',
            name: 'Medium',
            color: 'Medium Beige',
            images: ['foundation_medium.jpg'],
          ),
          ProductVariant(
            id: '9v3',
            name: 'Dark',
            color: 'Deep Beige',
            images: ['foundation_dark.jpg'],
          ),
        ],
        reviews: [],
      ),

      // Product 10
      Product(
        id: '10',
        name: 'Natural Glow Tinted Moisturizer',
        description: 'Light coverage tinted moisturizer for a natural everyday look.',
        price: 52000.00,
        images: ['tinted_moisturizer.jpg'],
        categoryId: '2',
        brand: 'NaturalGlow',
        rating: 4.4,
        reviewCount: 143,
        isInStock: true,
        ingredients: ['Hyaluronic Acid', 'SPF 20', 'Vitamin C'],
        beautyPoints: 52,
        variants: [],
        reviews: [],
        celebrityEndorsement: CelebrityEndorsement(
          celebrityName: 'Selena Gomez',
          celebrityImage: 'https://images.unsplash.com/photo-1567532939604-b6b5b0db2604?w=150&h=150&fit=crop&crop=face',
          testimonial: 'Perfect for my no-makeup makeup days!',
        ),
      ),

      // Product 11
      Product(
        id: '11',
        name: 'Matte Lipstick Collection',
        description: 'Long-lasting matte lipstick in various bold shades.',
        price: 35000.00,
        images: ['matte_lipstick.jpg'],
        categoryId: '3',
        brand: 'ColorCo',
        rating: 4.7,
        reviewCount: 176,
        isInStock: true,
        ingredients: ['Vitamin E', 'Jojoba Oil', 'Carnauba Wax'],
        beautyPoints: 35,
        variants: [
          ProductVariant(
            id: '11v1',
            name: 'Ruby Red',
            color: 'Deep Red',
            images: ['lipstick_ruby.jpg'],
          ),
          ProductVariant(
            id: '11v2',
            name: 'Berry Crush',
            color: 'Dark Berry',
            images: ['lipstick_berry.jpg'],
          ),
          ProductVariant(
            id: '11v3',
            name: 'Nude Rose',
            color: 'Nude Pink',
            images: ['lipstick_nude.jpg'],
          ),
        ],
        reviews: [],
      ),

      // Product 12
      Product(
        id: '12',
        name: 'Contour & Highlight Kit',
        description: 'Professional contour and highlight palette for sculpting.',
        price: 68000.00,
        images: ['contour_kit.jpg'],
        categoryId: '2',
        brand: 'ProMakeup',
        rating: 4.5,
        reviewCount: 156,
        isInStock: true,
        ingredients: ['Mica', 'Talc', 'Vitamin E'],
        beautyPoints: 68,
        variants: [],
        reviews: [],
        celebrityEndorsement: CelebrityEndorsement(
          celebrityName: 'Kim Kardashian',
          celebrityImage: 'https://images.unsplash.com/photo-1615109398623-88346a601842?w=150&h=150&fit=crop&crop=face',
          testimonial: 'Essential for creating that perfect contour!',
        ),
      ),

      // Product 13
      Product(
        id: '13',
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
            id: '13v1',
            name: 'Cherry Red',
            color: 'Bright Red',
            images: ['red_lipstick.jpg'],
          ),
          ProductVariant(
            id: '13v2',
            name: 'Wine Red',
            color: 'Deep Red',
            images: ['red_lipstick_wine.jpg'],
          ),
        ],
        reviews: [],
        celebrityEndorsement: CelebrityEndorsement(
          celebrityName: 'Taylor Swift',
          celebrityImage: 'https://images.unsplash.com/photo-1494790108755-2616c04a5821?w=150&h=150&fit=crop&crop=face',
          testimonial: 'Perfect red for my signature look',
        ),
      ),
    ];
  }

  List<Celebrity> _generateCelebrities() {
    final products = getAllProducts();
    
    return [
      Celebrity(
        id: '1',
        name: 'Emma Stone',
        image: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&h=150&fit=crop&crop=face',
        testimonial: 'This serum transformed my skin overnight!',
        socialMediaLinks: {
          'instagram': 'https://instagram.com/emmastone',
          'facebook': 'https://facebook.com/EmmaStoneOfficial',
        },
        recommendedProducts: [
          products.firstWhere((p) => p.id == '1'), // Anti-aging Serum
          products.firstWhere((p) => p.id == '4'), // Retinol Night Cream
        ],
        morningRoutineProducts: [
          products.firstWhere((p) => p.id == '1'), // Anti-aging Serum
          products.firstWhere((p) => p.id == '2'), // Aloe Vera Gel
          products.firstWhere((p) => p.id == '5'), // Sunscreen SPF 50
        ],
        eveningRoutineProducts: [
          products.firstWhere((p) => p.id == '4'), // Retinol Night Cream
          products.firstWhere((p) => p.id == '3'), // Vitamin C Brightening Mask
          products.firstWhere((p) => p.id == '6'), // Hydrating Toner
        ],
        bio: 'Academy Award-winning actress known for her roles in La La Land and Easy A.',
        profession: 'Actress',
      ),

      Celebrity(
        id: '2',
        name: 'Rihanna',
        image: 'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=150&h=150&fit=crop&crop=face',
        testimonial: 'Perfect for my nighttime routine!',
        socialMediaLinks: {
          'instagram': 'https://instagram.com/badgalriri',
          'facebook': 'https://facebook.com/rihanna',
          'snapchat': 'https://snapchat.com/add/rihanna',
        },
        recommendedProducts: [
          products.firstWhere((p) => p.id == '4'), // Retinol Night Cream
          products.firstWhere((p) => p.id == '9'), // Luminous Foundation
        ],
        morningRoutineProducts: [
          products.firstWhere((p) => p.id == '7'), // Charcoal Face Wash
          products.firstWhere((p) => p.id == '6'), // Hydrating Toner
          products.firstWhere((p) => p.id == '5'), // Sunscreen SPF 50
        ],
        eveningRoutineProducts: [
          products.firstWhere((p) => p.id == '4'), // Retinol Night Cream
          products.firstWhere((p) => p.id == '1'), // Anti-aging Serum
        ],
        bio: 'Multi-Grammy Award-winning artist and founder of Fenty Beauty.',
        profession: 'Singer & Entrepreneur',
      ),

      Celebrity(
        id: '3',
        name: 'Zendaya',
        image: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150&h=150&fit=crop&crop=face',
        testimonial: 'Gives me that natural glow!',
        socialMediaLinks: {
          'instagram': 'https://instagram.com/zendaya',
          'snapchat': 'https://snapchat.com/add/zendayaa',
        },
        recommendedProducts: [
          products.firstWhere((p) => p.id == '8'), // Glow Serum
          products.firstWhere((p) => p.id == '10'), // Natural Glow Tinted Moisturizer
        ],
        morningRoutineProducts: [
          products.firstWhere((p) => p.id == '8'), // Glow Serum
          products.firstWhere((p) => p.id == '10'), // Natural Glow Tinted Moisturizer
          products.firstWhere((p) => p.id == '5'), // Sunscreen SPF 50
        ],
        eveningRoutineProducts: [
          products.firstWhere((p) => p.id == '7'), // Charcoal Face Wash
          products.firstWhere((p) => p.id == '3'), // Vitamin C Brightening Mask
        ],
        bio: 'Emmy Award-winning actress and fashion icon.',
        profession: 'Actress & Singer',
      ),

      Celebrity(
        id: '4',
        name: 'Selena Gomez',
        image: 'https://images.unsplash.com/photo-1567532939604-b6b5b0db2604?w=150&h=150&fit=crop&crop=face',
        testimonial: 'Perfect for my no-makeup makeup days!',
        socialMediaLinks: {
          'instagram': 'https://instagram.com/selenagomez',
          'facebook': 'https://facebook.com/Selena',
          'snapchat': 'https://snapchat.com/add/selenagomez',
        },
        recommendedProducts: [
          products.firstWhere((p) => p.id == '10'), // Natural Glow Tinted Moisturizer
          products.firstWhere((p) => p.id == '2'), // Aloe Vera Gel
        ],
        morningRoutineProducts: [
          products.firstWhere((p) => p.id == '10'), // Natural Glow Tinted Moisturizer
          products.firstWhere((p) => p.id == '2'), // Aloe Vera Gel
        ],
        eveningRoutineProducts: [
          products.firstWhere((p) => p.id == '6'), // Hydrating Toner
          products.firstWhere((p) => p.id == '1'), // Anti-aging Serum
        ],
        bio: 'Singer, actress, and founder of Rare Beauty.',
        profession: 'Singer & Actress',
      ),

      Celebrity(
        id: '5',
        name: 'Kim Kardashian',
        image: 'https://images.unsplash.com/photo-1615109398623-88346a601842?w=150&h=150&fit=crop&crop=face',
        testimonial: 'Essential for creating that perfect contour!',
        socialMediaLinks: {
          'instagram': 'https://instagram.com/kimkardashian',
          'facebook': 'https://facebook.com/KimKardashian',
          'snapchat': 'https://snapchat.com/add/kimkardashian',
        },
        recommendedProducts: [
          products.firstWhere((p) => p.id == '12'), // Contour & Highlight Kit
          products.firstWhere((p) => p.id == '9'), // Luminous Foundation
        ],
        morningRoutineProducts: [
          products.firstWhere((p) => p.id == '9'), // Luminous Foundation
          products.firstWhere((p) => p.id == '12'), // Contour & Highlight Kit
        ],
        eveningRoutineProducts: [
          products.firstWhere((p) => p.id == '7'), // Charcoal Face Wash
          products.firstWhere((p) => p.id == '4'), // Retinol Night Cream
        ],
        bio: 'Reality TV star, entrepreneur, and beauty mogul.',
        profession: 'Entrepreneur',
      ),

      Celebrity(
        id: '6',
        name: 'Taylor Swift',
        image: 'https://images.unsplash.com/photo-1494790108755-2616c04a5821?w=150&h=150&fit=crop&crop=face',
        testimonial: 'Perfect red for my signature look',
        socialMediaLinks: {
          'instagram': 'https://instagram.com/taylorswift',
          'facebook': 'https://facebook.com/TaylorSwift',
        },
        recommendedProducts: [
          products.firstWhere((p) => p.id == '13'), // Red Lip Classic
          products.firstWhere((p) => p.id == '11'), // Matte Lipstick Collection
        ],
        morningRoutineProducts: [
          products.firstWhere((p) => p.id == '6'), // Hydrating Toner
          products.firstWhere((p) => p.id == '5'), // Sunscreen SPF 50
        ],
        eveningRoutineProducts: [
          products.firstWhere((p) => p.id == '13'), // Red Lip Classic
          products.firstWhere((p) => p.id == '11'), // Matte Lipstick Collection
        ],
        bio: 'Grammy Award-winning singer-songwriter and global superstar.',
        profession: 'Singer & Songwriter',
      ),
    ];
  }
} 