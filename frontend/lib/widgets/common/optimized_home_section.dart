import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../constants/app_constants.dart';

/// Optimized widget for home screen sections with built-in lazy loading
/// and performance optimizations
class OptimizedHomeSection extends StatefulWidget {
  final String sectionKey;
  final Widget Function() contentBuilder;
  final double placeholderHeight;
  final double visibilityThreshold;
  final VoidCallback? onVisible;
  final Duration transitionDuration;
  final bool useShimmer;
  final Widget? customPlaceholder;

  const OptimizedHomeSection({
    super.key,
    required this.sectionKey,
    required this.contentBuilder,
    this.placeholderHeight = 300,
    this.visibilityThreshold = 0.1,
    this.onVisible,
    this.transitionDuration = AppConstants.shortAnimation,
    this.useShimmer = false,
    this.customPlaceholder,
  });

  @override
  State<OptimizedHomeSection> createState() => _OptimizedHomeSectionState();
}

class _OptimizedHomeSectionState extends State<OptimizedHomeSection>
    with AutomaticKeepAliveClientMixin {
  bool _isVisible = false;
  bool _hasBeenVisible = false;
  bool _isContentBuilt = false;
  Widget? _builtContent;

  @override
  bool get wantKeepAlive => _hasBeenVisible;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return VisibilityDetector(
      key: Key('optimized_section_${widget.sectionKey}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > widget.visibilityThreshold && !_hasBeenVisible) {
          setState(() {
            _isVisible = true;
            _hasBeenVisible = true;
          });
          widget.onVisible?.call();
          
          // Build content in next frame to avoid blocking current frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_isContentBuilt) {
              setState(() {
                _builtContent = widget.contentBuilder();
                _isContentBuilt = true;
              });
            }
          });
        }
      },
      child: AnimatedSwitcher(
        duration: kReleaseMode ? Duration.zero : widget.transitionDuration,
        child: _isContentBuilt && _builtContent != null
            ? _builtContent!
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    if (widget.customPlaceholder != null) {
      return widget.customPlaceholder!;
    }

    if (widget.useShimmer && !kReleaseMode) {
      return _buildShimmerPlaceholder();
    }

    return SizedBox(
      height: widget.placeholderHeight,
      child: kDebugMode
          ? Container(
              color: AppConstants.borderColor.withOpacity(0.1),
              child: Center(
                child: Text(
                  'Loading ${widget.sectionKey}...',
                  style: TextStyle(
                    color: AppConstants.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildShimmerPlaceholder() {
    return Container(
      height: widget.placeholderHeight,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title shimmer
          Container(
            width: 200,
            height: 20,
            decoration: BoxDecoration(
              color: AppConstants.borderColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          // Content shimmer
          Expanded(
            child: Row(
              children: List.generate(3, (index) => 
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: AppConstants.borderColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Optimized horizontal list view for home screen sections
class OptimizedHorizontalList extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double height;
  final EdgeInsetsGeometry? padding;
  final double cacheExtent;
  final String? debugLabel;

  const OptimizedHorizontalList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.height,
    this.padding,
    this.cacheExtent = AppConstants.listCacheExtent,
    this.debugLabel,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: padding,
        itemCount: itemCount,
        cacheExtent: cacheExtent,
        addAutomaticKeepAlives: true,
        addRepaintBoundaries: true,
        itemBuilder: (context, index) {
          // Wrap each item in RepaintBoundary for performance isolation
          return RepaintBoundary(
            key: ValueKey('${debugLabel ?? 'item'}_$index'),
            child: itemBuilder(context, index),
          );
        },
      ),
    );
  }
}

/// Performance monitoring widget for debugging
class PerformanceMonitor extends StatelessWidget {
  final Widget child;
  final String label;

  const PerformanceMonitor({
    super.key,
    required this.child,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode) {
      return child;
    }

    return RepaintBoundary(
      child: child,
    );
  }
} 