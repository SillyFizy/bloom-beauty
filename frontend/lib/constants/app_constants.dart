import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// App Constants
class AppConstants {
  // App Info
  static const String appName = 'Bloom Beauty';
  static const String version = '1.0.0';

  // Platform-aware API URLs - fixes mobile image loading issues
  static String get baseUrl {
    // For web, always use localhost
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }

    // For mobile platforms, use conditional logic
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000'; // Android emulator special IP
    } else {
      return 'http://127.0.0.1:8000'; // iOS simulator and other platforms
    }
  }

  static const String apiVersion = '/v1';

  // Colors - New Elegant Palette
  static const Color primaryColor = Color(0xFFFFFFFF); // White
  static const Color accentColor = Color(0xFFC7A052); // Golden
  static const Color favoriteColor = Color(0xFFE49EB1); // Pink for favorites

  // Supporting colors
  static const Color backgroundColor = Color(0xFFFAFAFA); // Very light gray
  static const Color surfaceColor = Color(0xFFFFFFFF); // White
  static const Color textPrimary = Color(0xFF2D2D2D); // Dark gray for text
  static const Color textSecondary =
      Color(0xFF7A7A7A); // Medium gray for secondary text
  static const Color borderColor = Color(0xFFE8E8E8); // Light gray for borders

  // Status colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFF44336);
  static const Color warningColor = Color(0xFFFF9800);

  // Gradients
  static const List<Color> accentGradient = [
    Color(0xFFC7A052), // Golden
    Color(0xFFD4B366), // Lighter golden
  ];

  // Dimensions
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double cardElevation = 4.0;
  static const double listCacheExtent = 500.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);

  // Image loading timeouts and cache settings for mobile optimization
  static const Duration imageLoadTimeout = Duration(seconds: 10);
  static const Duration imageCacheTimeout = Duration(hours: 24);
  static const int imageMemoryCacheSize = 200;
  static const int imageMaxCacheObjects = 200;
}

class ImageConstants {
  static const String logoPath = 'assets/images/logo.png';
  static const String placeholderPath = 'assets/images/placeholder.png';
}
