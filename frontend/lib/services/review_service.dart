import 'dart:async';
import '../models/product_model.dart';
import 'product_service.dart';
import 'package:flutter/foundation.dart';

/// Service responsible for all review-related data operations
/// Provides abstraction between UI components and review data sources
class ReviewService {
  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;
  ReviewService._internal();

  final ProductService _productService = ProductService();
  
  // Cache for review data
  Map<String, List<ProductReview>>? _cachedProductReviews;
  DateTime? _lastCacheUpdate;
  static const Duration _cacheExpiry = Duration(minutes: 15);

  /// Get reviews for a specific product
  Future<List<ProductReview>> getProductReviews(String productId) async {
    if (_shouldRefreshCache()) {
      await _refreshReviewCache();
    }
    
    return _cachedProductReviews?[productId] ?? [];
  }

  /// Get all reviews across all products
  Future<List<ProductReview>> getAllReviews() async {
    final products = await _productService.getAllProducts();
    final allReviews = <ProductReview>[];
    
    for (final product in products) {
      allReviews.addAll(product.reviews);
    }
    
    return allReviews;
  }

  /// Add a new review for a product
  Future<bool> addReview({
    required String productId,
    required String userId,
    required String userName,
    required double rating,
    required String comment,
    String? userImage,
    List<String>? images,
  }) async {
    try {
      final product = await _productService.getProductById(productId);
      if (product == null) return false;

      final newReview = ProductReview(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        userName: userName,
        userImage: userImage ?? '',
        rating: rating,
        comment: comment,
        date: DateTime.now(),
        images: images ?? [],
        isVerifiedPurchase: true, // Would check against orders in production
        helpfulCount: 0,
        reportCount: 0,
      );

      // In production, this would save to backend
      // For now, add to local cache
      _cachedProductReviews ??= {};
      _cachedProductReviews![productId] ??= [];
      _cachedProductReviews![productId]!.add(newReview);

      return true;
    } catch (e) {
      debugPrint('Error adding review: $e');
      return false;
    }
  }

  /// Update an existing review
  Future<bool> updateReview({
    required String reviewId,
    required String productId,
    double? rating,
    String? comment,
  }) async {
    try {
      final reviews = await getProductReviews(productId);
      final reviewIndex = reviews.indexWhere((review) => review.id == reviewId);
      
      if (reviewIndex == -1) return false;

      final existingReview = reviews[reviewIndex];
      final updatedReview = ProductReview(
        id: existingReview.id,
        userId: existingReview.userId,
        userName: existingReview.userName,
        userImage: existingReview.userImage,
        rating: rating ?? existingReview.rating,
        comment: comment ?? existingReview.comment,
        date: existingReview.date,
        images: existingReview.images,
        isVerifiedPurchase: existingReview.isVerifiedPurchase,
        helpfulCount: existingReview.helpfulCount,
        reportCount: existingReview.reportCount,
      );

      _cachedProductReviews![productId]![reviewIndex] = updatedReview;
      return true;
    } catch (e) {
      debugPrint('Error updating review: $e');
      return false;
    }
  }

  /// Delete a review
  Future<bool> deleteReview(String reviewId, String productId) async {
    try {
      final reviews = await getProductReviews(productId);
      reviews.removeWhere((review) => review.id == reviewId);
      return true;
    } catch (e) {
      debugPrint('Error deleting review: $e');
      return false;
    }
  }

  /// Mark review as helpful
  Future<bool> markReviewHelpful(String reviewId, String productId) async {
    try {
      final reviews = await getProductReviews(productId);
      final reviewIndex = reviews.indexWhere((review) => review.id == reviewId);
      
      if (reviewIndex == -1) return false;

      final review = reviews[reviewIndex];
      final updatedReview = ProductReview(
        id: review.id,
        userId: review.userId,
        userName: review.userName,
        userImage: review.userImage,
        rating: review.rating,
        comment: review.comment,
        date: review.date,
        images: review.images,
        isVerifiedPurchase: review.isVerifiedPurchase,
        helpfulCount: review.helpfulCount + 1,
        reportCount: review.reportCount,
      );

      _cachedProductReviews![productId]![reviewIndex] = updatedReview;
      return true;
    } catch (e) {
      debugPrint('Error marking review helpful: $e');
      return false;
    }
  }

  /// Report a review
  Future<bool> reportReview(String reviewId, String productId, String reason) async {
    try {
      final reviews = await getProductReviews(productId);
      final reviewIndex = reviews.indexWhere((review) => review.id == reviewId);
      
      if (reviewIndex == -1) return false;

      final review = reviews[reviewIndex];
      final updatedReview = ProductReview(
        id: review.id,
        userId: review.userId,
        userName: review.userName,
        userImage: review.userImage,
        rating: review.rating,
        comment: review.comment,
        date: review.date,
        images: review.images,
        isVerifiedPurchase: review.isVerifiedPurchase,
        helpfulCount: review.helpfulCount,
        reportCount: review.reportCount + 1,
      );

      _cachedProductReviews![productId]![reviewIndex] = updatedReview;
      
      // In production, would send report to moderation system
      debugPrint('Review reported: $reviewId, Reason: $reason');
      
      return true;
    } catch (e) {
      debugPrint('Error reporting review: $e');
      return false;
    }
  }

  /// Get reviews by rating
  Future<List<ProductReview>> getReviewsByRating(String productId, double rating) async {
    final reviews = await getProductReviews(productId);
    return reviews.where((review) => review.rating == rating).toList();
  }

  /// Get reviews by rating range
  Future<List<ProductReview>> getReviewsByRatingRange(
    String productId, 
    double minRating, 
    double maxRating
  ) async {
    final reviews = await getProductReviews(productId);
    return reviews.where((review) => 
      review.rating >= minRating && review.rating <= maxRating
    ).toList();
  }

  /// Get verified purchase reviews only
  Future<List<ProductReview>> getVerifiedReviews(String productId) async {
    final reviews = await getProductReviews(productId);
    return reviews.where((review) => review.isVerifiedPurchase).toList();
  }

  /// Get reviews with images
  Future<List<ProductReview>> getReviewsWithImages(String productId) async {
    final reviews = await getProductReviews(productId);
    return reviews.where((review) => review.images.isNotEmpty).toList();
  }

  /// Sort reviews by various criteria
  Future<List<ProductReview>> sortReviews(
    List<ProductReview> reviews, 
    ReviewSortOption sortOption
  ) async {
    final sortedReviews = List<ProductReview>.from(reviews);
    
    switch (sortOption) {
      case ReviewSortOption.newest:
        sortedReviews.sort((a, b) => b.date.compareTo(a.date));
        break;
      case ReviewSortOption.oldest:
        sortedReviews.sort((a, b) => a.date.compareTo(b.date));
        break;
      case ReviewSortOption.highestRating:
        sortedReviews.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case ReviewSortOption.lowestRating:
        sortedReviews.sort((a, b) => a.rating.compareTo(b.rating));
        break;
      case ReviewSortOption.mostHelpful:
        sortedReviews.sort((a, b) => b.helpfulCount.compareTo(a.helpfulCount));
        break;
    }
    
    return sortedReviews;
  }

  /// Filter reviews by text content
  Future<List<ProductReview>> searchReviews(String productId, String query) async {
    if (query.isEmpty) return await getProductReviews(productId);
    
    final reviews = await getProductReviews(productId);
    final lowercaseQuery = query.toLowerCase();
    
    return reviews.where((review) =>
      review.comment.toLowerCase().contains(lowercaseQuery) ||
      review.userName.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }

  /// Get review statistics for a product
  Future<ReviewStatistics> getReviewStatistics(String productId) async {
    final reviews = await getProductReviews(productId);
    
    if (reviews.isEmpty) {
      return ReviewStatistics(
        totalReviews: 0,
        averageRating: 0.0,
        ratingDistribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        verifiedPurchaseCount: 0,
        reviewsWithImagesCount: 0,
      );
    }

    final totalReviews = reviews.length;
    final averageRating = reviews.fold(0.0, (sum, review) => sum + review.rating) / totalReviews;
    final verifiedPurchaseCount = reviews.where((review) => review.isVerifiedPurchase).length;
    final reviewsWithImagesCount = reviews.where((review) => review.images.isNotEmpty).length;
    
    final ratingDistribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final review in reviews) {
      final ratingKey = review.rating.round();
      ratingDistribution[ratingKey] = (ratingDistribution[ratingKey] ?? 0) + 1;
    }

    return ReviewStatistics(
      totalReviews: totalReviews,
      averageRating: averageRating,
      ratingDistribution: ratingDistribution,
      verifiedPurchaseCount: verifiedPurchaseCount,
      reviewsWithImagesCount: reviewsWithImagesCount,
    );
  }

  /// Get recent reviews across all products
  Future<List<ProductReview>> getRecentReviews({int limit = 10}) async {
    final allReviews = await getAllReviews();
    allReviews.sort((a, b) => b.date.compareTo(a.date));
    return allReviews.take(limit).toList();
  }

  /// Get reviews by user
  Future<List<ProductReview>> getUserReviews(String userId) async {
    final allReviews = await getAllReviews();
    return allReviews.where((review) => review.userId == userId).toList();
  }

  /// Get top reviewers (users with most reviews)
  Future<List<Map<String, dynamic>>> getTopReviewers({int limit = 10}) async {
    final allReviews = await getAllReviews();
    final userReviewCounts = <String, Map<String, dynamic>>{};
    
    for (final review in allReviews) {
      if (userReviewCounts.containsKey(review.userId)) {
        userReviewCounts[review.userId]!['count'] += 1;
        userReviewCounts[review.userId]!['totalRating'] += review.rating;
      } else {
        userReviewCounts[review.userId] = {
          'userId': review.userId,
          'userName': review.userName,
          'userImage': review.userImage,
          'count': 1,
          'totalRating': review.rating,
        };
      }
    }
    
    final topReviewers = userReviewCounts.values.toList();
    topReviewers.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    
    // Calculate average rating for each reviewer
    for (final reviewer in topReviewers) {
      reviewer['averageRating'] = reviewer['totalRating'] / reviewer['count'];
    }
    
    return topReviewers.take(limit).toList();
  }

  /// Validate review content
  Future<ReviewValidationResult> validateReview({
    required String comment,
    required double rating,
  }) async {
    final issues = <String>[];
    
    if (comment.trim().length < 10) {
      issues.add('Review comment must be at least 10 characters long');
    }
    
    if (comment.trim().length > 1000) {
      issues.add('Review comment cannot exceed 1000 characters');
    }
    
    if (rating < 1.0 || rating > 5.0) {
      issues.add('Rating must be between 1 and 5 stars');
    }
    
    // Check for inappropriate content (basic implementation)
    final inappropriateWords = ['spam', 'fake', 'terrible service'];
    final lowercaseComment = comment.toLowerCase();
    for (final word in inappropriateWords) {
      if (lowercaseComment.contains(word)) {
        issues.add('Review contains inappropriate content');
        break;
      }
    }
    
    return ReviewValidationResult(
      isValid: issues.isEmpty,
      issues: issues,
    );
  }

  /// Private methods

  bool _shouldRefreshCache() {
    if (_cachedProductReviews == null || _lastCacheUpdate == null) return true;
    return DateTime.now().difference(_lastCacheUpdate!) > _cacheExpiry;
  }

  Future<void> _refreshReviewCache() async {
    try {
      final products = await _productService.getAllProducts();
      _cachedProductReviews = {};
      
      for (final product in products) {
        _cachedProductReviews![product.id] = product.reviews;
      }
      
      _lastCacheUpdate = DateTime.now();
    } catch (e) {
      debugPrint('Error refreshing review cache: $e');
      _cachedProductReviews ??= {};
    }
  }

  /// Clear cache
  void clearCache() {
    _cachedProductReviews = null;
    _lastCacheUpdate = null;
  }

  /// Dispose resources
  void dispose() {
    clearCache();
  }
}

/// Enum for review sorting options
enum ReviewSortOption {
  newest,
  oldest,
  highestRating,
  lowestRating,
  mostHelpful,
}

/// Review statistics model
class ReviewStatistics {
  final int totalReviews;
  final double averageRating;
  final Map<int, int> ratingDistribution;
  final int verifiedPurchaseCount;
  final int reviewsWithImagesCount;

  ReviewStatistics({
    required this.totalReviews,
    required this.averageRating,
    required this.ratingDistribution,
    required this.verifiedPurchaseCount,
    required this.reviewsWithImagesCount,
  });
}

/// Review validation result
class ReviewValidationResult {
  final bool isValid;
  final List<String> issues;

  ReviewValidationResult({
    required this.isValid,
    required this.issues,
  });
} 
