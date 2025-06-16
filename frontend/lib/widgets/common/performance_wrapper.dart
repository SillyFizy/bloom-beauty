import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'dart:async';

/// Performance wrapper that applies various optimizations to child widgets
class PerformanceWrapper extends StatefulWidget {
  final Widget child;
  final bool useRepaintBoundary;
  final bool useKeepAlive;
  final bool useLazyLoading;
  final VoidCallback? onVisible;
  final double visibilityThreshold;
  final String? debugLabel;

  const PerformanceWrapper({
    super.key,
    required this.child,
    this.useRepaintBoundary = true,
    this.useKeepAlive = false,
    this.useLazyLoading = false,
    this.onVisible,
    this.visibilityThreshold = 0.1,
    this.debugLabel,
  });

  @override
  State<PerformanceWrapper> createState() => _PerformanceWrapperState();
}

class _PerformanceWrapperState extends State<PerformanceWrapper>
    with AutomaticKeepAliveClientMixin {
  bool _isVisible = false;
  bool _hasBeenVisible = false;

  @override
  bool get wantKeepAlive => widget.useKeepAlive;

  @override
  Widget build(BuildContext context) {
    if (widget.useKeepAlive) {
      super.build(context);
    }

    Widget child = widget.child;

    // Apply lazy loading if enabled
    if (widget.useLazyLoading) {
      child = VisibilityDetector(
        key: Key(widget.debugLabel ?? 'performance_wrapper_${widget.hashCode}'),
        onVisibilityChanged: (info) {
          final isVisible = info.visibleFraction > widget.visibilityThreshold;
          if (isVisible && !_hasBeenVisible) {
            setState(() {
              _isVisible = true;
              _hasBeenVisible = true;
            });
            widget.onVisible?.call();
          }
        },
        child: _isVisible || !widget.useLazyLoading
            ? child
            : _buildPlaceholder(),
      );
    }

    // Apply RepaintBoundary if enabled and not in debug mode (to reduce overhead)
    if (widget.useRepaintBoundary && kReleaseMode) {
      child = RepaintBoundary(child: child);
    }

    return child;
  }

  Widget _buildPlaceholder() {
    return const SizedBox.shrink();
  }
}

/// Optimized ListView with performance wrappers for each item
class OptimizedListView extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final bool useRepaintBoundaries;

  const OptimizedListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
    this.useRepaintBoundaries = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        Widget item = itemBuilder(context, index);
        
        if (useRepaintBoundaries && kReleaseMode) {
          item = RepaintBoundary(child: item);
        }
        
        return item;
      },
    );
  }
}

/// Optimized GridView with performance wrappers for each item
class OptimizedGridView extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final SliverGridDelegate gridDelegate;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final bool useRepaintBoundaries;

  const OptimizedGridView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.gridDelegate,
    this.controller,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
    this.useRepaintBoundaries = true,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: controller,
      padding: padding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      gridDelegate: gridDelegate,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        Widget item = itemBuilder(context, index);
        
        if (useRepaintBoundaries && kReleaseMode) {
          item = RepaintBoundary(child: item);
        }
        
        return item;
      },
    );
  }
}

/// Debounced text field for search inputs
class DebouncedTextField extends StatefulWidget {
  final ValueChanged<String>? onChanged;
  final Duration debounceDelay;
  final TextEditingController? controller;
  final String? hintText;
  final InputDecoration? decoration;
  final TextStyle? style;

  const DebouncedTextField({
    super.key,
    this.onChanged,
    this.debounceDelay = const Duration(milliseconds: 300),
    this.controller,
    this.hintText,
    this.decoration,
    this.style,
  });

  @override
  State<DebouncedTextField> createState() => _DebouncedTextFieldState();
}

class _DebouncedTextFieldState extends State<DebouncedTextField> {
  Timer? _debounceTimer;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDelay, () {
      widget.onChanged?.call(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      style: widget.style,
      decoration: widget.decoration ?? InputDecoration(
        hintText: widget.hintText,
      ),
    );
  }
}

/// Lazy loading container that only builds content when visible
class LazyLoadContainer extends StatefulWidget {
  final Widget child;
  final Widget? placeholder;
  final double visibilityThreshold;
  final VoidCallback? onLoad;

  const LazyLoadContainer({
    super.key,
    required this.child,
    this.placeholder,
    this.visibilityThreshold = 0.1,
    this.onLoad,
  });

  @override
  State<LazyLoadContainer> createState() => _LazyLoadContainerState();
}

class _LazyLoadContainerState extends State<LazyLoadContainer> {
  bool _hasLoaded = false;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('lazy_load_${widget.hashCode}'),
      onVisibilityChanged: (info) {
        if (!_hasLoaded && info.visibleFraction > widget.visibilityThreshold) {
          setState(() {
            _hasLoaded = true;
          });
          widget.onLoad?.call();
        }
      },
      child: _hasLoaded 
          ? widget.child 
          : (widget.placeholder ?? const SizedBox.shrink()),
    );
  }
} 
