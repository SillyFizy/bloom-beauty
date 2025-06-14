import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bloom_beauty/services/storage_service.dart';

void main() {
  group('Search History Persistence Tests', () {
    late Map<String, Object> initialValues;

    setUp(() async {
      // Create a fresh set of initial values for each test
      initialValues = <String, Object>{};
      SharedPreferences.setMockInitialValues(initialValues);
    });

    test('should save and load search history', () async {
      // Initialize with fresh storage
      SharedPreferences.setMockInitialValues({});
      await StorageService.init();
      
      // Test data
      final testHistory = ['makeup', 'skincare', 'lipstick', 'foundation'];
      
      // Save search history
      await StorageService.setStringList('test_search_history', testHistory);
      
      // Load search history
      final loadedHistory = await StorageService.getStringList('test_search_history');
      
      // Verify the data was saved and loaded correctly
      expect(loadedHistory, equals(testHistory));
    });

    test('should handle empty search history', () async {
      // Initialize with fresh storage
      SharedPreferences.setMockInitialValues({});
      await StorageService.init();
      
      // Try to load search history when none exists
      final loadedHistory = await StorageService.getStringList('non_existent_key');
      
      // Should return null for non-existent key
      expect(loadedHistory, isNull);
    });

    test('should persist data across multiple operations', () async {
      // Initialize with fresh storage
      SharedPreferences.setMockInitialValues({});
      await StorageService.init();
      
      // Save initial history
      await StorageService.setStringList('multi_test_history', ['first_search']);
      
      // Load and verify
      final firstLoad = await StorageService.getStringList('multi_test_history');
      expect(firstLoad, equals(['first_search']));
      
      // Add more items
      final updatedHistory = ['second_search', 'first_search'];
      await StorageService.setStringList('multi_test_history', updatedHistory);
      
      // Load and verify again
      final secondLoad = await StorageService.getStringList('multi_test_history');
      expect(secondLoad, equals(updatedHistory));
    });

    test('should clear search history', () async {
      // Initialize with fresh storage
      SharedPreferences.setMockInitialValues({});
      await StorageService.init();
      
      // Save some history first
      await StorageService.setStringList('clear_test_history', ['test1', 'test2']);
      
      // Verify it exists
      final beforeClear = await StorageService.getStringList('clear_test_history');
      expect(beforeClear, isNotNull);
      expect(beforeClear!.length, equals(2));
      
      // Clear the history
      await StorageService.remove('clear_test_history');
      
      // Verify it's gone
      final afterClear = await StorageService.getStringList('clear_test_history');
      expect(afterClear, isNull);
    });

    test('should handle malformed data gracefully', () async {
      // Initialize with fresh storage including malformed data
      SharedPreferences.setMockInitialValues({
        'malformed_key': 'this_is_a_string_not_a_list'
      });
      await StorageService.init();
      
      // Try to load as string list - should handle gracefully
      final result = await StorageService.getStringList('malformed_key');
      
      // Should return null and clean up the corrupted data
      expect(result, isNull);
    });

    test('demonstrates search functionality flow', () async {
      // Initialize with fresh storage
      SharedPreferences.setMockInitialValues({});
      await StorageService.init();
      
      // Simulate user search flow
      final searches = ['lipstick', 'foundation', 'mascara', 'lipstick']; // Note: lipstick appears twice
      final expectedHistory = <String>[];
      
      for (final search in searches) {
        // Remove duplicates (like the actual implementation does)
        expectedHistory.removeWhere((item) => item.toLowerCase() == search.toLowerCase());
        expectedHistory.insert(0, search);
      }
      
      // Save the final history
      await StorageService.setStringList('user_search_history', expectedHistory);
      
      // Load and verify
      final loadedHistory = await StorageService.getStringList('user_search_history');
      expect(loadedHistory, equals(['lipstick', 'mascara', 'foundation'])); // lipstick should only appear once at the beginning
    });
  });
} 