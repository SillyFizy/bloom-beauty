import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

/// Global app state provider for managing app-wide state
/// This includes loading states, connectivity, and other global state
class AppStateProvider with ChangeNotifier {
  // Private state variables
  bool _isGlobalLoading = false;
  bool _isOnline = true;
  bool _isInitialized = false;
  String? _globalError;

  // Connectivity monitoring
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Theme and UI state
  bool _isDarkMode = false;
  double _textScaleFactor = 1.0;

  // Navigation state
  String _currentRoute = '/home';
  String _previousRoute = '/';
  bool _isReturningFromProductDetail = false;

  // App initialization state
  bool _isAppInitialized = false;
  bool _isFirstLaunch = true;

  // Getters
  bool get isGlobalLoading => _isGlobalLoading;
  bool get isOnline => _isOnline;
  bool get isInitialized => _isInitialized;
  String? get globalError => _globalError;
  bool get hasGlobalError => _globalError != null;
  bool get isDarkMode => _isDarkMode;
  double get textScaleFactor => _textScaleFactor;
  String get currentRoute => _currentRoute;
  String get previousRoute => _previousRoute;
  bool get isReturningFromProductDetail => _isReturningFromProductDetail;
  bool get isAppInitialized => _isAppInitialized;
  bool get isFirstLaunch => _isFirstLaunch;
  bool get isLoading => _isGlobalLoading;

  /// Initialize the app state provider
  Future<void> initialize() async {
    try {
      _setGlobalLoading(true);
      _clearGlobalError();

      // Check initial connectivity status
      final connectivityResults = await Connectivity().checkConnectivity();
      _isOnline = !connectivityResults.contains(ConnectivityResult.none);

      // Listen to connectivity changes
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
        (List<ConnectivityResult> results) {
          final wasOnline = _isOnline;
          _isOnline = !results.contains(ConnectivityResult.none);

          // Notify listeners if connectivity status changed
          if (wasOnline != _isOnline) {
            notifyListeners();
          }
        },
      );

      _isInitialized = true;
      _setGlobalLoading(false);
    } catch (e) {
      _setGlobalError('Failed to initialize app: $e');
      _setGlobalLoading(false);
    }
  }

  /// Set global loading state
  void setGlobalLoading(bool loading) {
    _setGlobalLoading(loading);
  }

  /// Set global error
  void setGlobalError(String error) {
    _setGlobalError(error);
  }

  /// Clear global error
  void clearGlobalError() {
    _clearGlobalError();
  }

  /// Force refresh connectivity status
  Future<void> refreshConnectivity() async {
    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      final wasOnline = _isOnline;
      _isOnline = !connectivityResults.contains(ConnectivityResult.none);

      if (wasOnline != _isOnline) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
    }
  }

  /// Simulate network request with global loading
  Future<T> performGlobalOperation<T>(Future<T> Function() operation) async {
    try {
      _setGlobalLoading(true);
      _clearGlobalError();
      final result = await operation();
      _setGlobalLoading(false);
      return result;
    } catch (e) {
      _setGlobalError('Operation failed: $e');
      _setGlobalLoading(false);
      rethrow;
    }
  }

  /// Update current route and track navigation
  void updateRoute(String newRoute) {
    _previousRoute = _currentRoute;
    _currentRoute = newRoute;

    // Check if we're returning from product detail to home
    _isReturningFromProductDetail =
        _previousRoute.contains('/product') && newRoute == '/home';

    debugPrint(
        'AppStateProvider: Navigation - Previous: $_previousRoute, Current: $_currentRoute');
    debugPrint(
        'AppStateProvider: Returning from product detail: $_isReturningFromProductDetail');

    notifyListeners();
  }

  /// Reset navigation flags
  void resetNavigationFlags() {
    _isReturningFromProductDetail = false;
    notifyListeners();
  }

  /// Toggle dark mode
  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  /// Set text scale factor
  void setTextScaleFactor(double scale) {
    _textScaleFactor = scale.clamp(0.8, 1.5);
    notifyListeners();
  }

  /// Mark app as initialized
  void setAppInitialized(bool initialized) {
    _isAppInitialized = initialized;
    if (initialized) {
      _isFirstLaunch = false;
    }
    notifyListeners();
  }

  /// Set online status
  void setOnlineStatus(bool online) {
    _isOnline = online;
    notifyListeners();
  }

  // Private helper methods
  void _setGlobalLoading(bool loading) {
    if (_isGlobalLoading != loading) {
      _isGlobalLoading = loading;
      if (loading) _clearGlobalError();
      notifyListeners();
    }
  }

  void _setGlobalError(String error) {
    _globalError = error;
    _isGlobalLoading = false;
    notifyListeners();
  }

  void _clearGlobalError() {
    if (_globalError != null) {
      _globalError = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
