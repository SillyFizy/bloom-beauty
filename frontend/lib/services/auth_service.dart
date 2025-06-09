class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  
  // In-memory storage as fallback
  static final Map<String, String> _memoryStorage = {};
  
  static Future<bool> login(String email, String password) async {
    try {
      // Implement actual login logic
      // For now, return true for demo
      _memoryStorage[_tokenKey] = 'dummy_token';
      _memoryStorage[_userIdKey] = 'dummy_user_id';
      return true;
    } catch (e) {
      return false;
    }
  }
  
  static Future<void> logout() async {
    _memoryStorage.remove(_tokenKey);
    _memoryStorage.remove(_userIdKey);
  }
  
  static Future<bool> isLoggedIn() async {
    return _memoryStorage.containsKey(_tokenKey);
  }
  
  static Future<String?> getToken() async {
    return _memoryStorage[_tokenKey];
  }
}
