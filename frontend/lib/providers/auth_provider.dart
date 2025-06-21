import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  Map<String, dynamic>? _userData;
  String? _error;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get userData => _userData;
  String? get error => _error;
  bool get hasError => _error != null;

  // User data getters
  String? get phoneNumber => _userData?['phone_number'];
  String? get firstName => _userData?['first_name'];
  String? get lastName => _userData?['last_name'];
  String? get fullName => _userData?['full_name'];
  String? get email => _userData?['email'];
  String? get tier => _userData?['tier'];
  int? get points => _userData?['points'];
  bool? get isVerified => _userData?['is_verified'];

  /// Initialize the provider by checking stored authentication state
  Future<void> initialize() async {
    await _loadAuthState();
  }

  /// Load authentication state from local storage
  Future<void> _loadAuthState() async {
    try {
      _setLoading(true);
      
      // Check if user is logged in and get user data
      final isLoggedIn = await AuthService.isLoggedIn();
      
      if (isLoggedIn) {
        final userData = await AuthService.getStoredUserData();
        if (userData != null) {
          _isAuthenticated = true;
          _userData = userData;
        } else {
          // Try to fetch fresh user data
          final freshUserData = await AuthService.getCurrentUser();
          if (freshUserData != null) {
            _isAuthenticated = true;
            _userData = freshUserData;
          } else {
            await AuthService.logout();
            _isAuthenticated = false;
            _userData = null;
          }
        }
      } else {
        _isAuthenticated = false;
        _userData = null;
      }
      
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load authentication state: $e');
      _setLoading(false);
    }
  }

  /// Login user with phone number and password
  Future<bool> login(String phoneNumber, String password) async {
    try {
      _setLoading(true);
      _clearError();

      final userData = await AuthService.login(phoneNumber, password);
      
      if (userData != null) {
        _isAuthenticated = true;
        _userData = userData;
        _setLoading(false);
        return true;
      }
      
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Login failed: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Register new user
  Future<bool> register({
    required String phoneNumber,
    required String password,
    required String firstName,
    required String lastName,
    String? email,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final result = await AuthService.register(
        phoneNumber: phoneNumber,
        password: password,
        firstName: firstName,
        lastName: lastName,
        email: email,
      );
      
      if (result != null) {
        // After successful registration, automatically log in
        final loginSuccess = await login(phoneNumber, password);
        _setLoading(false);
        return loginSuccess;
      }
      
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Registration failed: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      _setLoading(true);
      _clearError();

      await AuthService.logout();
      
      _isAuthenticated = false;
      _userData = null;
      
      _setLoading(false);
    } catch (e) {
      _setError('Logout failed: $e');
      _setLoading(false);
    }
  }

  /// Refresh user data
  Future<void> refreshUserData() async {
    try {
      if (!_isAuthenticated) return;
      
      final userData = await AuthService.getCurrentUser();
      if (userData != null) {
        _userData = userData;
        notifyListeners();
      } else {
        // Token might be expired, force logout
        await logout();
      }
    } catch (e) {
      _setError('Failed to refresh user data: $e');
    }
  }

  /// Check if user is authenticated (refresh from server)
  Future<bool> checkAuthStatus() async {
    try {
      final isLoggedIn = await AuthService.isLoggedIn();
      
      if (isLoggedIn != _isAuthenticated) {
        if (isLoggedIn) {
          await _loadAuthState();
        } else {
          _isAuthenticated = false;
          _userData = null;
          notifyListeners();
        }
      }
      
      return isLoggedIn;
    } catch (e) {
      _setError('Failed to check auth status: $e');
      return false;
    }
  }

  /// Clear authentication state
  Future<void> clearAuth() async {
    await AuthService.logout();
    _isAuthenticated = false;
    _userData = null;
    notifyListeners();
  }

  /// Update user data locally (after profile updates)
  void updateUserData(Map<String, dynamic> newUserData) {
    _userData = {...?_userData, ...newUserData};
    notifyListeners();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
} 