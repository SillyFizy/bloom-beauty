import 'package:flutter/foundation.dart';

/// Performance monitoring utility for tracking app performance
/// Helps identify optimization opportunities and performance bottlenecks
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, DateTime> _startTimes = {};
  final Map<String, List<Duration>> _durations = {};
  final Map<String, int> _counters = {};

  /// Start tracking a performance metric
  void startTracking(String key) {
    _startTimes[key] = DateTime.now();
  }

  /// End tracking and record the duration
  void endTracking(String key) {
    final startTime = _startTimes.remove(key);
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _durations.putIfAbsent(key, () => []).add(duration);
      
      if (kDebugMode) {
        debugPrint('Performance: $key took ${duration.inMilliseconds}ms');
      }
    }
  }

  /// Increment a counter metric
  void incrementCounter(String key) {
    _counters[key] = (_counters[key] ?? 0) + 1;
  }

  /// Get average duration for a metric
  Duration? getAverageDuration(String key) {
    final durations = _durations[key];
    if (durations == null || durations.isEmpty) return null;
    
    final totalMs = durations.map((d) => d.inMilliseconds).reduce((a, b) => a + b);
    return Duration(milliseconds: (totalMs / durations.length).round());
  }

  /// Get counter value
  int getCounter(String key) => _counters[key] ?? 0;

  /// Get performance report
  Map<String, dynamic> getPerformanceReport() {
    final report = <String, dynamic>{};
    
    // Add duration metrics
    for (final key in _durations.keys) {
      final avg = getAverageDuration(key);
      if (avg != null) {
        report['avg_${key}_ms'] = avg.inMilliseconds;
        report['count_$key'] = _durations[key]!.length;
      }
    }
    
    // Add counter metrics
    for (final entry in _counters.entries) {
      report['counter_${entry.key}'] = entry.value;
    }
    
    return report;
  }

  /// Clear all metrics
  void clear() {
    _startTimes.clear();
    _durations.clear();
    _counters.clear();
  }

  /// Track widget build performance
  void trackWidgetBuild(String widgetName) {
    incrementCounter('widget_build_$widgetName');
  }

  /// Track provider rebuild performance
  void trackProviderRebuild(String providerName) {
    incrementCounter('provider_rebuild_$providerName');
  }

  /// Track navigation performance
  void trackNavigation(String routeName) {
    incrementCounter('navigation_$routeName');
  }

  /// Track API call performance
  void trackApiCall(String endpoint, Duration duration) {
    _durations.putIfAbsent('api_$endpoint', () => []).add(duration);
  }

  /// Memory usage monitoring
  Future<void> logMemoryUsage(String context) async {
    try {
      // This would require platform channels in a real implementation
      if (kDebugMode) {
        debugPrint('Memory usage at $context');
      }
    } catch (e) {
      debugPrint('Error logging memory usage: $e');
    }
  }

  /// Performance timing wrapper
  Future<T> time<T>(String key, Future<T> Function() operation) async {
    startTracking(key);
    try {
      final result = await operation();
      endTracking(key);
      return result;
    } catch (e) {
      endTracking(key);
      rethrow;
    }
  }

  /// Widget rebuild tracking mixin
  static void trackRebuild(String widgetName) {
    PerformanceMonitor().trackWidgetBuild(widgetName);
  }
}

/// Mixin for tracking widget rebuilds
mixin PerformanceTrackingMixin {
  void trackRebuild(String widgetName) {
    PerformanceMonitor().trackWidgetBuild(widgetName);
  }
}

/// Performance metrics for specific operations
class PerformanceMetrics {
  static const String productListLoad = 'product_list_load';
  static const String categoryLoad = 'category_load';
  static const String celebrityLoad = 'celebrity_load';
  static const String searchOperation = 'search_operation';
  static const String cartOperation = 'cart_operation';
  static const String wishlistOperation = 'wishlist_operation';
  static const String imageLoad = 'image_load';
  static const String navigationTransition = 'navigation_transition';
  static const String providerInitialization = 'provider_initialization';
  static const String cacheOperation = 'cache_operation';
} 