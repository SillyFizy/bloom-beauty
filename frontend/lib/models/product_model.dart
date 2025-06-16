import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

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

    // Generate realistic beauty points based on price range
    int beautyPoints;
    if (price >= 50) {
      beautyPoints =
          45 + (json['id'].hashCode % 20); // 45-64 points for expensive items
    } else if (price >= 25) {
      beautyPoints =
          25 + (json['id'].hashCode % 15); // 25-39 points for mid-range items
    } else {
      beautyPoints =
          10 + (json['id'].hashCode % 10); // 10-19 points for budget items
    }

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
        debugPrint('  Beauty Points: $beautyPoints');
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

    // Generate higher beauty points for bestselling products (these are popular!)
    int beautyPoints;
    if (price >= 50) {
      beautyPoints = 55 +
          (json['id'].hashCode % 25); // 55-79 points for expensive bestsellers
    } else if (price >= 25) {
      beautyPoints = 35 +
          (json['id'].hashCode % 20); // 35-54 points for mid-range bestsellers
    } else {
      beautyPoints = 20 +
          (json['id'].hashCode % 15); // 20-34 points for budget bestsellers
    }

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
        debugPrint('  Beauty Points: $beautyPoints');
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

    // Generate trending-specific beauty points (these are HOT products!)
    int beautyPoints;
    if (price >= 50) {
      beautyPoints = 65 +
          (json['id'].hashCode %
              30); // 65-94 points for expensive trending items
    } else if (price >= 25) {
      beautyPoints = 45 +
          (json['id'].hashCode %
              25); // 45-69 points for mid-range trending items
    } else {
      beautyPoints = 30 +
          (json['id'].hashCode % 20); // 30-49 points for budget trending items
    }

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
        debugPrint('Trending Debug:');
        debugPrint('  Product ID: ${json['id']}');
        debugPrint('  Product Slug: ${json['slug']}');
        debugPrint('  Product Name: ${json['name']}');
        debugPrint('  All JSON keys: ${json.keys.toList()}');
        debugPrint('  Beauty Points: $beautyPoints');
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

  /// Get platform-aware base URL for images
  static String _getImageBaseUrl() {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000'; // Android emulator special IP
    } else {
      return 'http://127.0.0.1:8000'; // iOS simulator and other platforms
    }
  }
}
