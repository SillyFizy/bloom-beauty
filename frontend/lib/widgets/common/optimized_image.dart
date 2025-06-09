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
    final effectiveMemCacheWidth = kReleaseMode 
        ? (memCacheWidth ?? 150) 
        : (memCacheWidth ?? 200);
    
    final effectiveMemCacheHeight = kReleaseMode 
        ? (memCacheHeight ?? 150) 
        : (memCacheHeight ?? 200);

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