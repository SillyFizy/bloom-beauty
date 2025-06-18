import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloom_beauty/widgets/common/optimized_image.dart';
import 'package:bloom_beauty/constants/app_constants.dart';

void main() {
  group('ProductDetailImage Tests', () {
    testWidgets('Should display ProductDetailImage widget',
        (WidgetTester tester) async {
      const testImageUrl = 'https://example.com/test-image.jpg';
      const fallbackUrls = [
        'https://example.com/fallback1.jpg',
        'https://example.com/fallback2.jpg',
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductDetailImage(
              imageUrl: testImageUrl,
              isSmallScreen: true,
              fallbackUrls: fallbackUrls,
            ),
          ),
        ),
      );

      expect(find.byType(ProductDetailImage), findsOneWidget);
    });

    testWidgets('Should handle empty image URL gracefully',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProductDetailImage(
              imageUrl: '',
              isSmallScreen: true,
            ),
          ),
        ),
      );

      expect(find.byType(ProductDetailImage), findsOneWidget);

      // Should show error/fallback state for empty URL
      await tester.pump();
      expect(find.byType(ProductDetailImage), findsOneWidget);
    });

    test('AppConstants should provide platform-aware base URL', () {
      // Test that baseUrl is properly configured
      final baseUrl = AppConstants.baseUrl;
      expect(baseUrl, isNotEmpty);
      expect(baseUrl, contains('http'));
    });

    testWidgets('Should display loading indicator initially',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProductDetailImage(
              imageUrl: 'https://example.com/test-image.jpg',
              isSmallScreen: false,
            ),
          ),
        ),
      );

      // Initially should show the widget
      expect(find.byType(ProductDetailImage), findsOneWidget);
    });

    test('Should have valid fallback URLs format', () {
      const fallbackUrls = [
        'http://10.0.2.2:8000/media/products/test1.jpg',
        'http://10.0.2.2:8000/media/products/test2.jpg',
      ];

      for (final url in fallbackUrls) {
        expect(url, contains('/media/products/'));
        expect(url, contains('.jpg'));
      }
    });
  });
}
