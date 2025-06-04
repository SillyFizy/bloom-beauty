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
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  
  // Getters
  bool get isGlobalLoading => _isGlobalLoading;
  bool get isOnline => _isOnline;
  bool get isInitialized => _isInitialized;
  String? get globalError => _globalError;
  bool get hasGlobalError => _globalError != null;

  /// Initialize the app state provider
  Future<void> initialize() async {
    try {
      _setGlobalLoading(true);
      _clearGlobalError();
      
      // Check initial connectivity status
      final connectivityResult = await Connectivity().checkConnectivity();
      _isOnline = connectivityResult != ConnectivityResult.none;
      
      // Listen to connectivity changes
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
        (ConnectivityResult result) {
          final wasOnline = _isOnline;
          _isOnline = result != ConnectivityResult.none;
          
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
      final connectivityResult = await Connectivity().checkConnectivity();
      final wasOnline = _isOnline;
      _isOnline = connectivityResult != ConnectivityResult.none;
      
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