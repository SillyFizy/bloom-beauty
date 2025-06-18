import 'dart:ui';

/// Utility class for handling animation values safely to prevent
/// semantics assertion errors from infinite or NaN values
class AnimationUtils {
  /// Validates and clamps a double animation value to prevent infinite/NaN values
  static double safeAnimationValue(double value,
      {double min = 0.0, double max = 1.0, double fallback = 1.0}) {
    if (!value.isFinite) {
      return fallback;
    }
    return value.clamp(min, max);
  }

  /// Validates and clamps a scale animation value
  static double safeScaleValue(double value, {double fallback = 1.0}) {
    return safeAnimationValue(value, min: 0.1, max: 2.0, fallback: fallback);
  }

  /// Validates and clamps an opacity animation value
  static double safeOpacityValue(double value, {double fallback = 1.0}) {
    return safeAnimationValue(value, min: 0.0, max: 1.0, fallback: fallback);
  }

  /// Validates and clamps a rotation animation value (in radians)
  static double safeRotationValue(double value, {double fallback = 0.0}) {
    return safeAnimationValue(value, min: -6.28, max: 6.28, fallback: fallback);
  }

  /// Validates an Offset to ensure both dx and dy are finite
  static Offset safeOffset(Offset offset, {Offset fallback = Offset.zero}) {
    if (!offset.dx.isFinite || !offset.dy.isFinite) {
      return fallback;
    }
    return offset;
  }

  /// Creates a safe transform offset by validating the multiplier
  static Offset safeTransformOffset(
      double animationValue, double multiplierX, double multiplierY) {
    final safeValue = safeAnimationValue(animationValue);
    return Offset(multiplierX * safeValue, multiplierY * safeValue);
  }
}
