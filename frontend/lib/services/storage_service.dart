import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  static SharedPreferences? _prefs;
  
  // Initialize SharedPreferences
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }
  
  // Ensure preferences are initialized
  static Future<SharedPreferences> get _preferences async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!;
  }
  
  static Future<void> setString(String key, String value) async {
    final prefs = await _preferences;
    await prefs.setString(key, value);
  }
  
  static Future<String?> getString(String key) async {
    final prefs = await _preferences;
    return prefs.getString(key);
  }
  
  static Future<void> setInt(String key, int value) async {
    final prefs = await _preferences;
    await prefs.setInt(key, value);
  }
  
  static Future<int?> getInt(String key) async {
    final prefs = await _preferences;
    return prefs.getInt(key);
  }
  
  static Future<void> setBool(String key, bool value) async {
    final prefs = await _preferences;
    await prefs.setBool(key, value);
  }
  
  static Future<bool?> getBool(String key) async {
    final prefs = await _preferences;
    return prefs.getBool(key);
  }
  
  static Future<void> setObject(String key, Map<String, dynamic> value) async {
    final prefs = await _preferences;
    await prefs.setString(key, json.encode(value));
  }
  
  static Future<Map<String, dynamic>?> getObject(String key) async {
    final prefs = await _preferences;
    final jsonString = prefs.getString(key);
    if (jsonString != null) {
      return json.decode(jsonString);
    }
    return null;
  }
  
  static Future<void> setStringList(String key, List<String> value) async {
    final prefs = await _preferences;
    await prefs.setStringList(key, value);
  }
  
  static Future<List<String>?> getStringList(String key) async {
    try {
      final prefs = await _preferences;
      return prefs.getStringList(key);
    } catch (e) {
      // Handle cases where the stored data is not a valid string list
      debugPrint('Error loading string list for key $key: $e');
      // Try to clean up the corrupted data
      try {
        final prefs = await _preferences;
        await prefs.remove(key);
      } catch (cleanupError) {
        debugPrint('Error cleaning up corrupted data: $cleanupError');
      }
      return null;
    }
  }

  static Future<void> remove(String key) async {
    final prefs = await _preferences;
    await prefs.remove(key);
  }
  
  static Future<void> clear() async {
    final prefs = await _preferences;
    await prefs.clear();
  }
}
