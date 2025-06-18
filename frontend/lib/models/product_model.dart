import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

class ProductVariant {
  final String id;
  final String name;
  final String color;
  final List<String> images;
  final double? priceAdjustment; // Additional price for this variant

  ProductVariant({
    required this.id,
    required this.name,
    required this.color,
    required this.images,
    this.priceAdjustment,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'],
      name: json['name'],
      color: json['color'],
      images: List<String>.from(json['images']),
      priceAdjustment: json['price_adjustment']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'images': images,
      'price_adjustment': priceAdjustment,
    };
  }
}

class ProductReview {
  final String id;
  final String userId;
  final String userName;
  final String userImage;
  final double rating;
  final String comment;
  final DateTime date;
  final List<String> images;
  final bool isVerifiedPurchase;
  final int helpfulCount;
  final int reportCount;

  ProductReview({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.rating,
    required this.comment,
    required this.date,
    this.images = const [],
    this.isVerifiedPurchase = false,
    this.helpfulCount = 0,
    this.reportCount = 0,
  });

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    return ProductReview(
      id: json['id'],
      userId: json['user_id'],
      userName: json['user_name'],
      userImage: json['user_image'],
      rating: json['rating'].toDouble(),
      comment: json['comment'],
      date: DateTime.parse(json['date']),
      images: List<String>.from(json['images'] ?? []),
      isVerifiedPurchase: json['is_verified_purchase'] ?? false,
      helpfulCount: json['helpful_count'] ?? 0,
      reportCount: json['report_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_image': userImage,
      'rating': rating,
      'comment': comment,
      'date': date.toIso8601String(),
      'images': images,
      'is_verified_purchase': isVerifiedPurchase,
      'helpful_count': helpfulCount,
      'report_count': reportCount,
    };
  }
}

class CelebrityEndorsement {
  final String celebrityName;
  final String celebrityImage;
  final String? testimonial;

  CelebrityEndorsement({
    required this.celebrityName,
    required this.celebrityImage,
    this.testimonial,
  });

  factory CelebrityEndorsement.fromJson(Map<String, dynamic> json) {
    return CelebrityEndorsement(
      celebrityName: json['celebrity_name'],
      celebrityImage: json['celebrity_image'],
      testimonial: json['testimonial'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'celebrity_name': celebrityName,
      'celebrity_image': celebrityImage,
      'testimonial': testimonial,
    };
  }
}

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? discountPrice;
  final List<String> images;
  final String categoryId;
  final String brand;
  final double rating;
  final int reviewCount;
  final bool isInStock;
  final List<String> ingredients;
  final int beautyPoints;
  final List<ProductVariant> variants;
  final List<ProductReview> reviews;
  final CelebrityEndorsement? celebrityEndorsement;

  // Verified large images (100KB+ range) that work on both web and mobile
  static const List<String> _availableImages = [
    'tiana-eyeshadow-palette_1_product_33_20250507_195811.jpg', // 100KB
    'flawless-stay-powder-foundation_6_product_225_20250508_203603.jpg', // 100KB
    'riding-solo-single-shadow_1_product_312_20250508_214207.jpg', // 103KB
    'lesdomakeup-mi-vida-lip-trio_1_product_239_20250508_204511.jpg', // 104KB
    'flawless-stay-liquid-foundation_6_product_167_20250508_161948.jpg', // 104KB
    'eyebrow-911-essentials-various-shades_1_product_441_20250509_204423.jpg', // 105KB
    'volumizing-mascara_2_product_459_20250509_205845.jpg', // 106KB
    'tease-me-shadow-palette_1_product_460_20250509_210720.jpg', // 108KB - VERIFIED EXISTS
    'tease-me-shadow-palette_3_product_462_20250509_210720.jpg', // 205KB - VERIFIED EXISTS
    'nude-x-12-piece-brush-set_1_product_125_20250508_153613.jpg', // 90KB
    'eyebrow-definer-pencil_1_product_434_20250509_200954.jpg', // 134KB
    'glittery-perfect_1_product_50_20250507_203020.jpg', // 145KB
    'yerimua-bad-lip-duo_1_product_350_20250508_220246.jpg', // 167KB
    'volumizing-mascara_4_product_457_20250509_205844.jpg', // 201KB
    'nude-x-shadow-palette_2_product_288_20250508_212708.jpg', // 245KB
    'sand-snatchural-palette_2_product_450_20250509_205245.jpg', // 267KB
    'volumizing-mascara_1_product_456_20250509_205844.jpg', // 289KB
    'tease-me-shadow-palette_2_product_463_20250509_210720.jpg', // 127KB - VERIFIED EXISTS
    'volumizing-mascara_3_product_458_20250509_205845.jpg', // 334KB
    'sand-snatchural-palette_4_product_448_20250509_205245.jpg', // 378KB
    'sand-snatchural-palette_1_product_445_20250509_204951.jpg', // 389KB
    'tease-me-shadow-palette_4_product_461_20250509_210720.jpg', // 178KB - VERIFIED EXISTS
    'eyebrow-definer-pencil_5_product_436_20250509_200954.jpg', // 120KB - CORRECTED TIMESTAMP
    'camo-snatchural-palette_4_product_451_20250509_205245.jpg', // 152KB - VERIFIED LARGE FILE
  ];

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.discountPrice,
    required this.images,
    required this.categoryId,
    required this.brand,
    required this.rating,
    required this.reviewCount,
    required this.isInStock,
    required this.ingredients,
    required this.beautyPoints,
    this.variants = const [],
    this.reviews = const [],
    this.celebrityEndorsement,
  });

  // Get current price based on selected variant
  double getCurrentPrice([ProductVariant? selectedVariant]) {
    double basePrice = discountPrice ?? price;
    if (selectedVariant?.priceAdjustment != null) {
      basePrice += selectedVariant!.priceAdjustment!;
    }
    return basePrice;
  }

  // Get current images based on selected variant
  List<String> getCurrentImages([ProductVariant? selectedVariant]) {
    if (selectedVariant != null && selectedVariant.images.isNotEmpty) {
      return selectedVariant.images;
    }
    return images;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      discountPrice: json['discount_price']?.toDouble(),
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      categoryId: json['category_id']?.toString() ?? '',
      brand: json['brand'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: (json['review_count'] ?? 0).toInt(), // Fix type conversion
      isInStock: json['is_in_stock'] ?? true,
      ingredients: json['ingredients'] != null
          ? List<String>.from(json['ingredients'])
          : [],
      beautyPoints: (json['beauty_points'] ?? 0).toInt(), // Fix type conversion
      variants: json['variants'] != null
          ? (json['variants'] as List)
              .map((v) => ProductVariant.fromJson(v))
              .toList()
          : [],
      reviews: json['reviews'] != null
          ? (json['reviews'] as List)
              .map((r) => ProductReview.fromJson(r))
              .toList()
          : [],
      celebrityEndorsement: json['celebrity_endorsement'] != null
          ? CelebrityEndorsement.fromJson(json['celebrity_endorsement'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'discount_price': discountPrice,
      'images': images,
      'category_id': categoryId,
      'brand': brand,
      'rating': rating,
      'review_count': reviewCount,
      'is_in_stock': isInStock,
      'ingredients': ingredients,
      'beauty_points': beautyPoints,
      'variants': variants.map((v) => v.toJson()).toList(),
      'reviews': reviews.map((r) => r.toJson()).toList(),
      'celebrity_endorsement': celebrityEndorsement?.toJson(),
    };
  }

  /// Factory method to create Product from New Arrivals API response
  factory Product.fromNewArrivalsApi(Map<String, dynamic> json) {
    // Parse the price correctly (it comes as string from API)
    final priceStr = json['price']?.toString() ?? '0';
    final price = double.tryParse(priceStr) ?? 0.0;

    // Parse sale_price if available
    double? salePrice;
    if (json['sale_price'] != null) {
      final salePriceStr = json['sale_price'].toString();
      salePrice = double.tryParse(salePriceStr);
    }

    // Use beauty points from backend (no more mock data)
    final beautyPoints = (json['beauty_points'] ?? 0).toInt();

    // Generate consistent realistic rating (4.0-4.9 range)
    final ratingBase = 4.0 + ((json['id'].hashCode % 10) / 10.0); // 4.0-4.9
    final rating = double.parse(ratingBase.toStringAsFixed(1));

    // Generate review count based on rating (higher rating = more reviews)
    final reviewCount =
        ((rating - 4.0) * 100 + 50 + (json['id'].hashCode % 30)).toInt();

    // Handle featured_image with platform-aware URL
    List<String> images = [];
    if (json['featured_image'] != null) {
      // Use platform-aware URL for images
      final baseImageUrl = _getImageBaseUrl();
      final imageUrl = '$baseImageUrl/media/products/${json['featured_image']}';
      images.add(imageUrl);
    } else {
      // Temporary fallback: Use sample images from backend media until proper image assignment
      final baseImageUrl = _getImageBaseUrl();
      final fallbackImages = [
        'tiana-eyeshadow-palette_1_product_33_20250507_195811.jpg',
        'volumizing-mascara_1_product_456_20250509_205844.jpg',
        'yerimua-bad-lip-duo_1_product_350_20250508_220246.jpg',
        'rosy-mcmichael-vol-2-pink-dream-blushes_5_product_292_20250508_212928.jpg',
        'sand-snatchural-palette_1_product_445_20250509_204951.jpg',
        'stay-blushing-cute-lip-and-cheek-balm_1_product_299_20250508_213502.jpg',
      ];

      // Use product ID to select a consistent fallback image
      final productId = int.tryParse(json['id'].toString()) ?? 0;
      final imageIndex = productId % fallbackImages.length;
      final fallbackImage = fallbackImages[imageIndex];

      final imageUrl = '$baseImageUrl/media/products/$fallbackImage';
      images.add(imageUrl);

      // Debug logging
      if (kDebugMode) {
        debugPrint('New Arrivals Debug:');
        debugPrint('  Product ID: ${json['id']}');
        debugPrint('  Product Name: ${json['name']}');
        debugPrint('  Beauty Points (from backend): $beautyPoints');
        debugPrint('  Rating: $rating');
        debugPrint('  Review Count: $reviewCount');
        debugPrint('  Image Index: $imageIndex');
        debugPrint('  Fallback Image: $fallbackImage');
        debugPrint('  Full URL: $imageUrl');
        debugPrint('  Base URL: $baseImageUrl');
      }
    }

    return Product(
      id: json['slug'] ??
          json['id'].toString(), // Use slug as ID for proper navigation
      name: json['name'] ?? '',
      description: json['name'] ??
          '', // Using name as description since API doesn't provide description
      price: price,
      discountPrice: salePrice,
      images: images,
      categoryId: json['category_name'] ??
          'Unknown', // Using category_name as categoryId
      brand: json['brand_name'] ?? '',
      rating: rating,
      reviewCount: reviewCount,
      isInStock: json['stock'] != null ? (json['stock'] as int) > 0 : true,
      ingredients: [], // API doesn't provide ingredients
      beautyPoints: beautyPoints,
      variants: [],
      reviews: [],
      celebrityEndorsement: null,
    );
  }

  /// Factory method to create Product from Bestselling API response
  factory Product.fromBestsellingApi(Map<String, dynamic> json) {
    // Parse the price correctly (it comes as string from API)
    final priceStr = json['price']?.toString() ?? '0';
    final price = double.tryParse(priceStr) ?? 0.0;

    // Parse sale_price if available
    double? salePrice;
    if (json['sale_price'] != null) {
      final salePriceStr = json['sale_price'].toString();
      salePrice = double.tryParse(salePriceStr);
    }

    // Use beauty points from backend (no more mock data)
    final beautyPoints = (json['beauty_points'] ?? 0).toInt();

    // Generate higher ratings for bestselling products (4.2-4.9 range)
    final ratingBase = 4.2 + ((json['id'].hashCode % 8) / 10.0); // 4.2-4.9
    final rating = double.parse(ratingBase.toStringAsFixed(1));

    // Generate higher review count for bestselling products (they're popular!)
    final reviewCount =
        ((rating - 4.0) * 150 + 100 + (json['id'].hashCode % 50)).toInt();

    // Handle featured_image with platform-aware URL
    List<String> images = [];
    if (json['featured_image'] != null) {
      // Use platform-aware URL for images
      final baseImageUrl = _getImageBaseUrl();
      final imageUrl = '$baseImageUrl/media/products/${json['featured_image']}';
      images.add(imageUrl);
    } else {
      // Temporary fallback: Use sample images from backend media until proper image assignment
      final baseImageUrl = _getImageBaseUrl();
      final fallbackImages = [
        'tiana-eyeshadow-palette_1_product_33_20250507_195811.jpg',
        'volumizing-mascara_1_product_456_20250509_205844.jpg',
        'yerimua-bad-lip-duo_1_product_350_20250508_220246.jpg',
        'rosy-mcmichael-vol-2-pink-dream-blushes_5_product_292_20250508_212928.jpg',
        'sand-snatchural-palette_1_product_445_20250509_204951.jpg',
        'stay-blushing-cute-lip-and-cheek-balm_1_product_299_20250508_213502.jpg',
      ];

      // Use product ID to select a consistent fallback image
      final productId = int.tryParse(json['id'].toString()) ?? 0;
      final imageIndex = productId % fallbackImages.length;
      final fallbackImage = fallbackImages[imageIndex];

      final imageUrl = '$baseImageUrl/media/products/$fallbackImage';
      images.add(imageUrl);

      // Debug logging
      if (kDebugMode) {
        debugPrint('Bestselling Debug:');
        debugPrint('  Product ID: ${json['id']}');
        debugPrint('  Product Name: ${json['name']}');
        debugPrint('  Beauty Points (from backend): $beautyPoints');
        debugPrint('  Rating: $rating');
        debugPrint('  Review Count: $reviewCount');
        debugPrint('  Image Index: $imageIndex');
        debugPrint('  Fallback Image: $fallbackImage');
        debugPrint('  Full URL: $imageUrl');
        debugPrint('  Base URL: $baseImageUrl');
      }
    }

    return Product(
      id: json['slug'] ??
          json['id'].toString(), // Use slug as ID for proper navigation
      name: json['name'] ?? '',
      description: json['name'] ??
          '', // Using name as description since API doesn't provide description
      price: price,
      discountPrice: salePrice,
      images: images,
      categoryId: json['category_name'] ??
          'Unknown', // Using category_name as categoryId
      brand: json['brand_name'] ?? '',
      rating: rating,
      reviewCount: reviewCount,
      isInStock: json['stock'] != null ? (json['stock'] as int) > 0 : true,
      ingredients: [], // API doesn't provide ingredients
      beautyPoints: beautyPoints,
      variants: [],
      reviews: [],
      celebrityEndorsement: null,
    );
  }

  /// Factory method to create Product from Trending API response
  factory Product.fromTrendingApi(Map<String, dynamic> json) {
    // Parse the price correctly (it comes as string from API)
    final priceStr = json['price']?.toString() ?? '0';
    final price = double.tryParse(priceStr) ?? 0.0;

    // Parse sale_price if available
    double? salePrice;
    if (json['sale_price'] != null) {
      final salePriceStr = json['sale_price'].toString();
      salePrice = double.tryParse(salePriceStr);
    }

    // Use beauty points from backend (no more mock data)
    final beautyPoints = (json['beauty_points'] ?? 0).toInt();

    // Generate higher ratings for trending products (4.3-4.9 range - they're trending for a reason!)
    final ratingBase = 4.3 + ((json['id'].hashCode % 7) / 10.0); // 4.3-4.9
    final rating = double.parse(ratingBase.toStringAsFixed(1));

    // Generate high review count for trending products (they're getting attention!)
    final reviewCount =
        ((rating - 4.0) * 200 + 150 + (json['id'].hashCode % 75)).toInt();

    // Handle featured_image with platform-aware URL
    List<String> images = [];
    if (json['featured_image'] != null) {
      // Use platform-aware URL for images
      final baseImageUrl = _getImageBaseUrl();
      final imageUrl = '$baseImageUrl/media/products/${json['featured_image']}';
      images.add(imageUrl);
    } else {
      // RANDOM IMAGE FROM BACKEND/MEDIA when DB response is null
      final baseImageUrl = _getImageBaseUrl();
      final productId = int.tryParse(json['id'].toString()) ?? 0;
      final randomImage = _getRandomBackendImage(productId);
      final imageUrl = '$baseImageUrl/media/products/$randomImage';
      images.add(imageUrl);

      // Debug logging
      if (kDebugMode) {
        debugPrint('Trending Debug - RANDOM IMAGE:');
        debugPrint('  Product ID: ${json['id']}');
        debugPrint('  Product Slug: ${json['slug']}');
        debugPrint('  Product Name: ${json['name']}');
        debugPrint('  Featured Image: NULL -> Using Random');
        debugPrint('  Beauty Points (from backend): $beautyPoints');
        debugPrint('  Rating: $rating');
        debugPrint('  Review Count: $reviewCount');
        debugPrint('  Random Image: $randomImage');
        debugPrint('  Full URL: $imageUrl');
      }
    }

    return Product(
      id: json['slug'] ??
          json['id'].toString(), // Use slug as ID for proper navigation
      name: json['name'] ?? '',
      description: json['name'] ??
          '', // Using name as description since API doesn't provide description
      price: price,
      discountPrice: salePrice,
      images: images,
      categoryId: json['category_name'] ??
          'Unknown', // Using category_name as categoryId
      brand: json['brand_name'] ?? '',
      rating: rating,
      reviewCount: reviewCount,
      isInStock: json['stock'] != null ? (json['stock'] as int) > 0 : true,
      ingredients: [], // API doesn't provide ingredients
      beautyPoints: beautyPoints,
      variants: [],
      reviews: [],
      celebrityEndorsement: null,
    );
  }

  /// Factory method to create Product from Backend API response
  factory Product.fromBackendApi(Map<String, dynamic> json) {
    // Parse the price correctly (it comes as string from API)
    final priceStr = json['price']?.toString() ?? '0';
    final price = double.tryParse(priceStr) ?? 0.0;

    // Parse sale_price if available
    double? salePrice;
    if (json['sale_price'] != null) {
      final salePriceStr = json['sale_price'].toString();
      salePrice = double.tryParse(salePriceStr);
    }

    // Use beauty points from backend (no more mock data)
    final productId = json['id'] ?? 0;
    final beautyPoints = (json['beauty_points'] ?? 0).toInt();

    // Generate consistent realistic rating (4.0-4.9 range) (MOCKUP)
    final ratingBase = 4.0 + ((productId.hashCode % 10) / 10.0); // 4.0-4.9
    final rating = double.parse(ratingBase.toStringAsFixed(1));

    // Generate review count based on rating (higher rating = more reviews) (MOCKUP)
    final reviewCount =
        ((rating - 4.0) * 100 + 50 + (productId.hashCode % 30)).toInt();

    // Handle featured_image with platform-aware URL and random fallback
    List<String> images = [];
    if (json['featured_image'] != null &&
        json['featured_image'].toString().isNotEmpty) {
      // Use platform-aware URL for images
      final baseImageUrl = _getImageBaseUrl();
      final imageUrl =
          '${baseImageUrl}/media/products/${json['featured_image']}';
      images.add(imageUrl);
    } else {
      // RANDOM IMAGE FROM BACKEND/MEDIA when DB response is null
      final baseImageUrl = _getImageBaseUrl();
      final randomImage = _getRandomBackendImage(productId);
      final imageUrl = '${baseImageUrl}/media/products/$randomImage';
      images.add(imageUrl);

      // Debug logging
      if (kDebugMode) {
        debugPrint('Backend Products Debug - RANDOM IMAGE:');
        debugPrint('  Product ID: ${json['id']}');
        debugPrint('  Product Name: ${json['name']}');
        debugPrint('  Featured Image: NULL -> Using Random');
        debugPrint('  Beauty Points (from backend): $beautyPoints');
        debugPrint('  Rating: $rating');
        debugPrint('  Review Count: $reviewCount');
        debugPrint('  Random Image: $randomImage');
        debugPrint('  Full URL: $imageUrl');
      }
    }

    // Create Product with backend data + mockup rating/beauty points
    return Product(
      id: json['slug'] ??
          json['id'].toString(), // Use slug as ID for proper navigation
      name: json['name'] ?? '',
      description: json['name'] ??
          '', // Using name as description since backend doesn't provide detailed description
      price: price,
      discountPrice: salePrice,
      images: images,
      categoryId: json['category_name'] ??
          'Unknown', // Using category_name as categoryId for filtering
      brand: json['brand_name'] ?? '',
      rating: rating, // MOCKUP
      reviewCount: reviewCount, // MOCKUP
      isInStock: json['stock'] != null ? (json['stock'] as int) > 0 : true,
      ingredients: [], // Backend doesn't provide ingredients yet
      beautyPoints: beautyPoints, // FROM BACKEND
      variants: [],
      reviews: [],
      celebrityEndorsement: null, // No celebrity picks for now as requested
    );
  }

  /// Get random image from backend media folder (consistent per product ID)
  static String _getRandomBackendImage(int productId) {
    // Use product ID to generate consistent but varied random selection
    final int randomSeed = (productId * 37 + 13) % _availableImages.length;
    return _availableImages[randomSeed];
  }

  /// Get platform-aware base URL for images - now uses centralized AppConstants
  static String _getImageBaseUrl() {
    return AppConstants.baseUrl;
  }
}
