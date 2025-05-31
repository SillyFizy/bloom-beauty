import 'dart:convert';

class StorageService {
  // In-memory storage as fallback
  static Map<String, dynamic> _memoryStorage = {};
  
  static Future<void> setString(String key, String value) async {
    _memoryStorage[key] = value;
  }
  
  static Future<String?> getString(String key) async {
    return _memoryStorage[key] as String?;
  }
  
  static Future<void> setInt(String key, int value) async {
    _memoryStorage[key] = value;
  }
  
  static Future<int?> getInt(String key) async {
    return _memoryStorage[key] as int?;
  }
  
  static Future<void> setBool(String key, bool value) async {
    _memoryStorage[key] = value;
  }
  
  static Future<bool?> getBool(String key) async {
    return _memoryStorage[key] as bool?;
  }
  
  static Future<void> setObject(String key, Map<String, dynamic> value) async {
    _memoryStorage[key] = json.encode(value);
  }
  
  static Future<Map<String, dynamic>?> getObject(String key) async {
    final jsonString = _memoryStorage[key] as String?;
    if (jsonString != null) {
      return json.decode(jsonString);
    }
    return null;
  }
  
  static Future<void> remove(String key) async {
    _memoryStorage.remove(key);
  }
  
  static Future<void> clear() async {
    _memoryStorage.clear();
  }
}
