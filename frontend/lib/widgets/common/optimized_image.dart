import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import '../../constants/app_constants.dart';

/// Optimized image widget for better performance and error handling
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final Duration fadeInDuration;
  final Duration fadeOutDuration;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.memCacheWidth,
    this.memCacheHeight,
    this.fadeInDuration = const Duration(milliseconds: 50),
    this.fadeOutDuration = const Duration(milliseconds: 25),
  });

  @override
  Widget build(BuildContext context) {
    // Return simple placeholder in release mode if image URL is empty
    if (imageUrl.isEmpty || imageUrl == 'null') {
      return _buildPlaceholder();
    }

    // For better performance in release mode, use simpler caching strategy
    final effectiveMemCacheWidth =
        kReleaseMode ? (memCacheWidth ?? 150) : (memCacheWidth ?? 200);

    final effectiveMemCacheHeight =
        kReleaseMode ? (memCacheHeight ?? 150) : (memCacheHeight ?? 200);

    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: effectiveMemCacheWidth,
      memCacheHeight: effectiveMemCacheHeight,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeOutDuration,
      maxWidthDiskCache: kReleaseMode ? 300 : 500,
      maxHeightDiskCache: kReleaseMode ? 300 : 500,
      placeholder: (context, url) => placeholder ?? _buildPlaceholder(),
      errorWidget: (context, url, error) {
        // Reduce error logging in release mode for better performance
        if (kDebugMode) {
          debugPrint('Image loading error for $url: $error');
        }
        return errorWidget ?? _buildErrorWidget();
      },
    );

    // Apply border radius if provided
    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    // Wrap in RepaintBoundary for better performance
    return RepaintBoundary(child: imageWidget);
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppConstants.borderColor.withValues(alpha: 0.1),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: AppConstants.textSecondary,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: AppConstants.borderColor.withValues(alpha: 0.1),
      child: const Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: AppConstants.textSecondary,
          size: 24,
        ),
      ),
    );
  }
}

/// Specialized optimized image for product details with mobile-specific optimizations
class ProductDetailImage extends StatelessWidget {
  final String imageUrl;
  final bool isSmallScreen;
  final List<String>? fallbackUrls;
  final VoidCallback? onImageTap;

  const ProductDetailImage({
    super.key,
    required this.imageUrl,
    required this.isSmallScreen,
    this.fallbackUrls,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onImageTap,
      child: _buildImageWithFallback(imageUrl, 0),
    );
  }

  Widget _buildImageWithFallback(String url, int fallbackIndex) {
    // If URL is empty or null, start with fallback immediately
    if (url.isEmpty || url == 'null') {
      return _buildFallbackImage(fallbackIndex);
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      // Optimized cache settings for mobile
      memCacheWidth: isSmallScreen ? 300 : 400,
      memCacheHeight: isSmallScreen ? 300 : 400,
      maxWidthDiskCache: isSmallScreen ? 400 : 600,
      maxHeightDiskCache: isSmallScreen ? 400 : 600,
      // Faster fade animations for mobile
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 100),
      // Mobile-optimized placeholder
      placeholder: (context, url) => Container(
        color: AppConstants.surfaceColor,
        child: Center(
          child: SizedBox(
            width: isSmallScreen ? 30 : 40,
            height: isSmallScreen ? 30 : 40,
            child: CircularProgressIndicator(
              color: AppConstants.accentColor,
              strokeWidth: 2.0,
            ),
          ),
        ),
      ),
      // Enhanced error handling with fallback chain
      errorWidget: (context, url, error) {
        if (kDebugMode) {
          debugPrint('ProductDetailImage failed for $url: $error');
        }

        // Try next fallback if available
        if (fallbackUrls != null && fallbackIndex < fallbackUrls!.length) {
          return _buildImageWithFallback(
              fallbackUrls![fallbackIndex], fallbackIndex + 1);
        }

        // Use general fallback if no specific fallbacks available
        return _buildFallbackImage(fallbackIndex);
      },
      // Add timeout handling
      httpHeaders: const {
        'Cache-Control': 'max-age=86400', // Cache for 24 hours
      },
    );
  }

  Widget _buildFallbackImage(int fallbackIndex) {
    // Get verified fallback images for mobile devices
    final List<String> verifiedFallbacks = [
      'tiana-eyeshadow-palette_1_product_33_20250507_195811.jpg',
      'riding-solo-single-shadow_1_product_312_20250508_214207.jpg',
      'flawless-stay-liquid-foundation_6_product_167_20250508_161948.jpg',
      'lesdomakeup-mi-vida-lip-trio_1_product_239_20250508_204511.jpg',
      'yerimua-bad-lip-duo_1_product_350_20250508_220246.jpg',
      'volumizing-mascara_1_product_456_20250509_205844.jpg',
    ];

    if (fallbackIndex < verifiedFallbacks.length) {
      final fallbackImageUrl =
          '${AppConstants.baseUrl}/media/products/${verifiedFallbacks[fallbackIndex]}';

      return CachedNetworkImage(
        imageUrl: fallbackImageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        memCacheWidth: isSmallScreen ? 250 : 300,
        memCacheHeight: isSmallScreen ? 250 : 300,
        fadeInDuration: const Duration(milliseconds: 150),
        fadeOutDuration: const Duration(milliseconds: 100),
        placeholder: (context, url) => Container(
          color: AppConstants.surfaceColor,
          child: Center(
            child: SizedBox(
              width: isSmallScreen ? 25 : 35,
              height: isSmallScreen ? 25 : 35,
              child: CircularProgressIndicator(
                color: AppConstants.accentColor,
                strokeWidth: 1.5,
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) {
          if (kDebugMode) {
            debugPrint('Fallback image failed: $url - $error');
          }
          // Try next fallback
          return _buildFallbackImage(fallbackIndex + 1);
        },
      );
    }

    // Final fallback - static error state
    return Container(
      color: AppConstants.surfaceColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: isSmallScreen ? 40 : 50,
              color: AppConstants.textSecondary.withOpacity(0.5),
            ),
            SizedBox(height: isSmallScreen ? 8 : 10),
            Text(
              'Image unavailable',
              style: TextStyle(
                color: AppConstants.textSecondary.withOpacity(0.7),
                fontSize: isSmallScreen ? 11 : 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Specialized optimized image for product cards
class ProductImage extends OptimizedImage {
  const ProductImage({
    super.key,
    required super.imageUrl,
    super.width,
    super.height,
    super.fit = BoxFit.cover,
    super.borderRadius,
    bool isMobile = false,
  }) : super(
          memCacheWidth: isMobile ? 150 : 200,
          memCacheHeight: isMobile ? 150 : 200,
          fadeInDuration: const Duration(milliseconds: 50),
          fadeOutDuration: const Duration(milliseconds: 25),
        );
}

/// Specialized optimized image for celebrity avatars
class CelebrityAvatar extends OptimizedImage {
  const CelebrityAvatar({
    super.key,
    required super.imageUrl,
    super.width = 32,
    super.height = 32,
  }) : super(
          memCacheWidth: 64,
          memCacheHeight: 64,
          fit: BoxFit.cover,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          fadeInDuration: const Duration(milliseconds: 50),
          fadeOutDuration: const Duration(milliseconds: 25),
        );
}
