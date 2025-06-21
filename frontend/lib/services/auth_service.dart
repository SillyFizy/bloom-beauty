import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class AuthService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  
  /// Login with phone number and password
  static Future<Map<String, dynamic>?> login(String phoneNumber, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/users/login/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'phone_number': phoneNumber,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Store tokens and user data
        await _storeAuthData(
          accessToken: data['access'],
          refreshToken: data['refresh'],
          userData: data,
        );
        
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Register new user with phone number
  static Future<Map<String, dynamic>?> register({
    required String phoneNumber,
    required String password,
    required String firstName,
    required String lastName,
    String? email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/users/register/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'phone_number': phoneNumber,
          'password': password,
          'password2': password,
          'first_name': firstName,
          'last_name': lastName,
          if (email != null && email.isNotEmpty) 'email': email,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(_formatErrorMessage(errorData));
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get current user profile
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final token = await getAccessToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/users/profile/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        await _storeUserData(userData);
        return userData;
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          return getCurrentUser(); // Retry with new token
        } else {
          await logout(); // Clear invalid tokens
          return null;
        }
      }
    } catch (e) {
      print('Error getting current user: $e');
    }
    return null;
  }

  /// Logout user
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userDataKey);
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    if (token == null) return false;
    
    // Verify token is still valid
    final user = await getCurrentUser();
    return user != null;
  }

  /// Get stored access token
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  /// Get stored refresh token
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  /// Get stored user data
  static Future<Map<String, dynamic>?> getStoredUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);
    if (userDataString != null) {
      return jsonDecode(userDataString);
    }
    return null;
  }

  /// Store authentication data
  static Future<void> _storeAuthData({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> userData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setString(_userDataKey, jsonEncode(userData));
  }

  /// Store user data
  static Future<void> _storeUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, jsonEncode(userData));
  }

  /// Refresh access token
  static Future<bool> _refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/users/token/refresh/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'refresh': refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_accessTokenKey, data['access']);
        return true;
      }
    } catch (e) {
      print('Error refreshing token: $e');
    }
    return false;
  }

  /// Format error message from API response
  static String _formatErrorMessage(Map<String, dynamic> errorData) {
    if (errorData.containsKey('detail')) {
      return errorData['detail'];
    }
    
    // Handle field-specific errors
    final List<String> errors = [];
    errorData.forEach((key, value) {
      if (value is List) {
        errors.addAll(value.map((e) => '$key: $e'));
      } else {
        errors.add('$key: $value');
      }
    });
    
    return errors.isNotEmpty ? errors.join('\n') : 'An error occurred';
  }

  /// Make authenticated HTTP request
  static Future<http.Response?> makeAuthenticatedRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final token = await getAccessToken();
    if (token == null) return null;

    final url = Uri.parse('${AppConstants.apiBaseUrl}$endpoint');
    final requestHeaders = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      ...?headers,
    };

    try {
      http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: requestHeaders);
          break;
        case 'POST':
          response = await http.post(url, headers: requestHeaders, body: body != null ? jsonEncode(body) : null);
          break;
        case 'PUT':
          response = await http.put(url, headers: requestHeaders, body: body != null ? jsonEncode(body) : null);
          break;
        case 'PATCH':
          response = await http.patch(url, headers: requestHeaders, body: body != null ? jsonEncode(body) : null);
          break;
        case 'DELETE':
          response = await http.delete(url, headers: requestHeaders);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      // Handle token refresh if needed
      if (response.statusCode == 401) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          // Retry request with new token
          final newToken = await getAccessToken();
          requestHeaders['Authorization'] = 'Bearer $newToken';
          
          switch (method.toUpperCase()) {
            case 'GET':
              response = await http.get(url, headers: requestHeaders);
              break;
            case 'POST':
              response = await http.post(url, headers: requestHeaders, body: body != null ? jsonEncode(body) : null);
              break;
            case 'PUT':
              response = await http.put(url, headers: requestHeaders, body: body != null ? jsonEncode(body) : null);
              break;
            case 'PATCH':
              response = await http.patch(url, headers: requestHeaders, body: body != null ? jsonEncode(body) : null);
              break;
            case 'DELETE':
              response = await http.delete(url, headers: requestHeaders);
              break;
          }
        }
      }

      return response;
    } catch (e) {
      print('Error making authenticated request: $e');
      return null;
    }
  }
}
