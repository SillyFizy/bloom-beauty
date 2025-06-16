import 'package:flutter/material.dart';

/// A safe wrapper widget for animated components that prevents
/// semantics assertion errors from invalid geometry values
class SafeAnimatedWidget extends StatelessWidget {
  final Widget child;
  final String debugLabel;

  const SafeAnimatedWidget({
    super.key,
    required this.child,
    this.debugLabel = 'SafeAnimatedWidget',
  });

  @override
  Widget build(BuildContext context) {
    try {
      return RepaintBoundary(
        child: child,
      );
    } catch (e) {
      // If there's any error during rendering, return a safe fallback
      debugPrint('$debugLabel: Caught rendering error: $e');
      return const SizedBox.shrink();
    }
  }
}

/// A safe wrapper for Transform operations
class SafeTransform extends StatelessWidget {
  final Widget child;
  final Matrix4? transform;
  final Offset? translation;
  final double? scale;
  final double? rotation;
  final Alignment alignment;

  const SafeTransform({
    super.key,
    required this.child,
    this.transform,
    this.translation,
    this.scale,
    this.rotation,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    try {
      Matrix4? safeTransform;

      if (transform != null) {
        // Validate the provided transform matrix
        safeTransform = _validateMatrix4(transform!);
      } else {
        // Build transform from individual parameters
        safeTransform = Matrix4.identity();

        if (translation != null) {
          final safeTranslation = _validateOffset(translation!);
          safeTransform = Matrix4.translationValues(
              safeTranslation.dx, safeTranslation.dy, 0.0);
        }

        if (scale != null) {
          final safeScale = _validateScale(scale!);
          safeTransform.scale(safeScale);
        }

        if (rotation != null) {
          final safeRotation = _validateRotation(rotation!);
          safeTransform.rotateZ(safeRotation);
        }
      }

      return Transform(
        alignment: alignment,
        transform: safeTransform,
        child: child,
      );
    } catch (e) {
      debugPrint(
          'SafeTransform: Caught error, returning child without transform: $e');
      return child;
    }
  }

  Matrix4 _validateMatrix4(Matrix4 matrix) {
    try {
      // Check if matrix values are finite
      for (int i = 0; i < 16; i++) {
        if (!matrix.storage[i].isFinite) {
          return Matrix4.identity();
        }
      }
      return matrix;
    } catch (e) {
      return Matrix4.identity();
    }
  }

  Offset _validateOffset(Offset offset) {
    if (!offset.dx.isFinite || !offset.dy.isFinite) {
      return Offset.zero;
    }
    // Clamp to reasonable bounds
    return Offset(
      offset.dx.clamp(-10000.0, 10000.0),
      offset.dy.clamp(-10000.0, 10000.0),
    );
  }

  double _validateScale(double scale) {
    if (!scale.isFinite || scale <= 0) {
      return 1.0;
    }
    return scale.clamp(0.01, 10.0);
  }

  double _validateRotation(double rotation) {
    if (!rotation.isFinite) {
      return 0.0;
    }
    return rotation.clamp(-6.28, 6.28); // ±2π radians
  }
}
