import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../services/review_service.dart';

/// Provider for managing review state throughout the application
/// Uses the service layer for data operations and notifies listeners of state changes
class ReviewProvider with ChangeNotifier {
  final ReviewService _reviewService = ReviewService();

  // State variables
  Map<String, List<ProductReview>> _productReviews = {};
  List<ProductReview> _allReviews = [];
  List<ProductReview> _recentReviews = [];
  List<ProductReview> _userReviews = [];
  List<Map<String, dynamic>> _topReviewers = [];
  
  Map<String, ReviewStatistics> _reviewStatistics = {};
  
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  
  String _selectedProductId = '';
  ReviewSortOption _currentSortOption = ReviewSortOption.newest;
  Map<String, dynamic> _currentFilters = {};

  // Getters
  Map<String, List<ProductReview>> get productReviews => Map.unmodifiable(_productReviews);
  List<ProductReview> get allReviews => List.unmodifiable(_allReviews);
  List<ProductReview> get recentReviews => List.unmodifiable(_recentReviews);
  List<ProductReview> get userReviews => List.unmodifiable(_userReviews);
  List<Map<String, dynamic>> get topReviewers => List.unmodifiable(_topReviewers);
  
  Map<String, ReviewStatistics> get reviewStatistics => Map.unmodifiable(_reviewStatistics);
  
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  bool get hasError => _error != null;
  
  String get selectedProductId => _selectedProductId;
  ReviewSortOption get currentSortOption => _currentSortOption;
  Map<String, dynamic> get currentFilters => Map.unmodifiable(_currentFilters);

  /// Initialize and load review data
  Future<void> initialize() async {
    await loadAllReviews();
    await loadRecentReviews();
    await loadTopReviewers();
  }

  /// Load all reviews across all products
  Future<void> loadAllReviews() async {
    try {
      _setLoading(true);
      _clearError();
      
      _allReviews = await _reviewService.getAllReviews();
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load reviews: $e');
      _setLoading(false);
    }
  }

  /// Load reviews for a specific product
  Future<void> loadProductReviews(String productId, {bool forceRefresh = false}) async {
    try {
      _setLoading(true);
      _clearError();
      _selectedProductId = productId;
      
      final reviews = await _reviewService.getProductReviews(productId);
      _productReviews[productId] = reviews;
      
      // Load statistics for this product
      await _loadProductReviewStatistics(productId);
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load product reviews: $e');
      _setLoading(false);
    }
  }

  /// Load review statistics for a product
  Future<void> _loadProductReviewStatistics(String productId) async {
    try {
      final statistics = await _reviewService.getReviewStatistics(productId);
      _reviewStatistics[productId] = statistics;
    } catch (e) {
      debugPrint('Failed to load review statistics: $e');
    }
  }

  /// Load recent reviews
  Future<void> loadRecentReviews() async {
    try {
      _recentReviews = await _reviewService.getRecentReviews();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load recent reviews: $e');
    }
  }

  /// Load top reviewers
  Future<void> loadTopReviewers() async {
    try {
      _topReviewers = await _reviewService.getTopReviewers();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load top reviewers: $e');
    }
  }

  /// Load reviews for a specific user
  Future<void> loadUserReviews(String userId) async {
    try {
      _setLoading(true);
      _clearError();
      
      _userReviews = await _reviewService.getUserReviews(userId);
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load user reviews: $e');
      _setLoading(false);
    }
  }

  /// Add a new review
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
      _setSubmitting(true);
      _clearError();
      
      // Validate review content first
      final validation = await _reviewService.validateReview(
        comment: comment,
        rating: rating,
      );
      
      if (!validation.isValid) {
        _setError('Review validation failed: ${validation.issues.join(', ')}');
        _setSubmitting(false);
        return false;
      }
      
      final success = await _reviewService.addReview(
        productId: productId,
        userId: userId,
        userName: userName,
        rating: rating,
        comment: comment,
        userImage: userImage,
        images: images,
      );
      
      if (success) {
        // Refresh the product reviews
        await loadProductReviews(productId);
        await loadAllReviews();
        await loadRecentReviews();
      }
      
      _setSubmitting(false);
      return success;
    } catch (e) {
      _setError('Failed to add review: $e');
      _setSubmitting(false);
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
      _setSubmitting(true);
      _clearError();
      
      if (comment != null && rating != null) {
        final validation = await _reviewService.validateReview(
          comment: comment,
          rating: rating,
        );
        
        if (!validation.isValid) {
          _setError('Review validation failed: ${validation.issues.join(', ')}');
          _setSubmitting(false);
          return false;
        }
      }
      
      final success = await _reviewService.updateReview(
        reviewId: reviewId,
        productId: productId,
        rating: rating,
        comment: comment,
      );
      
      if (success) {
        await loadProductReviews(productId);
        await loadAllReviews();
      }
      
      _setSubmitting(false);
      return success;
    } catch (e) {
      _setError('Failed to update review: $e');
      _setSubmitting(false);
      return false;
    }
  }

  /// Delete a review
  Future<bool> deleteReview(String reviewId, String productId) async {
    try {
      _setSubmitting(true);
      _clearError();
      
      final success = await _reviewService.deleteReview(reviewId, productId);
      
      if (success) {
        await loadProductReviews(productId);
        await loadAllReviews();
      }
      
      _setSubmitting(false);
      return success;
    } catch (e) {
      _setError('Failed to delete review: $e');
      _setSubmitting(false);
      return false;
    }
  }

  /// Mark review as helpful
  Future<bool> markReviewHelpful(String reviewId, String productId) async {
    try {
      final success = await _reviewService.markReviewHelpful(reviewId, productId);
      
      if (success) {
        // Update local cache immediately for better UX
        _updateReviewInCache(productId, reviewId, (review) {
          return ProductReview(
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
        });
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      debugPrint('Failed to mark review helpful: $e');
      return false;
    }
  }

  /// Report a review
  Future<bool> reportReview(String reviewId, String productId, String reason) async {
    try {
      final success = await _reviewService.reportReview(reviewId, productId, reason);
      
      if (success) {
        // Update local cache
        _updateReviewInCache(productId, reviewId, (review) {
          return ProductReview(
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
        });
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      debugPrint('Failed to report review: $e');
      return false;
    }
  }

  /// Get reviews by rating
  Future<List<ProductReview>> getReviewsByRating(String productId, double rating) async {
    try {
      return await _reviewService.getReviewsByRating(productId, rating);
    } catch (e) {
      debugPrint('Failed to get reviews by rating: $e');
      return [];
    }
  }

  /// Get reviews by rating range
  Future<List<ProductReview>> getReviewsByRatingRange(
    String productId, 
    double minRating, 
    double maxRating
  ) async {
    try {
      return await _reviewService.getReviewsByRatingRange(productId, minRating, maxRating);
    } catch (e) {
      debugPrint('Failed to get reviews by rating range: $e');
      return [];
    }
  }

  /// Get verified purchase reviews only
  Future<List<ProductReview>> getVerifiedReviews(String productId) async {
    try {
      return await _reviewService.getVerifiedReviews(productId);
    } catch (e) {
      debugPrint('Failed to get verified reviews: $e');
      return [];
    }
  }

  /// Get reviews with images
  Future<List<ProductReview>> getReviewsWithImages(String productId) async {
    try {
      return await _reviewService.getReviewsWithImages(productId);
    } catch (e) {
      debugPrint('Failed to get reviews with images: $e');
      return [];
    }
  }

  /// Sort reviews
  Future<void> sortReviews(String productId, ReviewSortOption sortOption) async {
    try {
      _currentSortOption = sortOption;
      
      if (_productReviews.containsKey(productId)) {
        final sortedReviews = await _reviewService.sortReviews(
          _productReviews[productId]!, 
          sortOption
        );
        _productReviews[productId] = sortedReviews;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to sort reviews: $e');
    }
  }

  /// Search reviews by content
  Future<void> searchReviews(String productId, String query) async {
    try {
      _setLoading(true);
      _clearError();
      
      final searchResults = await _reviewService.searchReviews(productId, query);
      _productReviews[productId] = searchResults;
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to search reviews: $e');
      _setLoading(false);
    }
  }

  /// Clear search and reload original reviews
  Future<void> clearSearchAndReload(String productId) async {
    await loadProductReviews(productId);
  }

  /// Validate review before submission
  Future<ReviewValidationResult> validateReview({
    required String comment,
    required double rating,
  }) async {
    try {
      return await _reviewService.validateReview(comment: comment, rating: rating);
    } catch (e) {
      return ReviewValidationResult(
        isValid: false, 
        issues: ['Validation failed: $e']
      );
    }
  }

  /// Get review statistics for a product
  ReviewStatistics? getProductReviewStatistics(String productId) {
    return _reviewStatistics[productId];
  }

  /// Get average rating for a product
  double getProductAverageRating(String productId) {
    final statistics = _reviewStatistics[productId];
    return statistics?.averageRating ?? 0.0;
  }

  /// Get total review count for a product
  int getProductReviewCount(String productId) {
    final statistics = _reviewStatistics[productId];
    return statistics?.totalReviews ?? 0;
  }

  /// Get rating distribution for a product
  Map<int, int> getProductRatingDistribution(String productId) {
    final statistics = _reviewStatistics[productId];
    return statistics?.ratingDistribution ?? {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
  }

  /// Check if user has reviewed a product
  bool hasUserReviewedProduct(String productId, String userId) {
    final reviews = _productReviews[productId] ?? [];
    return reviews.any((review) => review.userId == userId);
  }

  /// Get user's review for a product
  ProductReview? getUserProductReview(String productId, String userId) {
    final reviews = _productReviews[productId] ?? [];
    try {
      return reviews.firstWhere((review) => review.userId == userId);
    } catch (e) {
      return null;
    }
  }

  /// Get reviews by filter criteria
  List<ProductReview> getFilteredReviews(String productId, {
    double? minRating,
    double? maxRating,
    bool? verifiedOnly,
    bool? withImagesOnly,
  }) {
    final reviews = _productReviews[productId] ?? [];
    
    return reviews.where((review) {
      if (minRating != null && review.rating < minRating) return false;
      if (maxRating != null && review.rating > maxRating) return false;
      if (verifiedOnly == true && !review.isVerifiedPurchase) return false;
      if (withImagesOnly == true && review.images.isEmpty) return false;
      return true;
    }).toList();
  }

  /// Update review in local cache
  void _updateReviewInCache(String productId, String reviewId, ProductReview Function(ProductReview) updater) {
    if (_productReviews.containsKey(productId)) {
      final reviews = _productReviews[productId]!;
      final reviewIndex = reviews.indexWhere((review) => review.id == reviewId);
      
      if (reviewIndex != -1) {
        _productReviews[productId]![reviewIndex] = updater(reviews[reviewIndex]);
      }
    }
  }

  /// Refresh all review data
  Future<void> refresh() async {
    await loadAllReviews();
    await loadRecentReviews();
    await loadTopReviewers();
    
    // Refresh currently selected product reviews
    if (_selectedProductId.isNotEmpty) {
      await loadProductReviews(_selectedProductId);
    }
  }

  /// Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) _clearError();
  }

  void _setSubmitting(bool submitting) {
    _isSubmitting = submitting;
    if (submitting) _clearError();
  }

  void _setError(String error) {
    _error = error;
    _isLoading = false;
    _isSubmitting = false;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  /// Clear all cached data
  void clearCache() {
    _reviewService.clearCache();
    _productReviews = {};
    _allReviews = [];
    _recentReviews = [];
    _userReviews = [];
    _topReviewers = [];
    _reviewStatistics = {};
    _selectedProductId = '';
    _currentFilters = {};
    _clearError();
    notifyListeners();
  }

  @override
  void dispose() {
    _reviewService.dispose();
    super.dispose();
  }
} 
