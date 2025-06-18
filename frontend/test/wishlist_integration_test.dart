import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bloom_beauty/providers/wishlist_provider.dart';
import 'package:bloom_beauty/models/product_model.dart';
import 'package:bloom_beauty/utils/wishlist_utils.dart';

void main() {
  group('Wishlist Integration Tests', () {
    late WishlistProvider wishlistProvider;
    late Product testProduct;

    setUp(() {
      wishlistProvider = WishlistProvider();
      testProduct = Product(
        id: 'test_product_1',
        name: 'Test Beauty Product',
        description: 'A test product for wishlist functionality',
        price: 25.99,
        images: ['https://example.com/test-image.jpg'],
        brand: 'Test Brand',
        categoryId: 'skincare',
        isInStock: true,
        rating: 4.5,
        reviewCount: 150,
        beautyPoints: 25,
        ingredients: ['Water', 'Glycerin', 'Hyaluronic Acid'],
      );
    });

    testWidgets('WishlistUtils.safeToggleWishlist works correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: wishlistProvider,
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        await WishlistUtils.safeToggleWishlist(
                            context, testProduct);
                      },
                      child: const Text('Toggle Wishlist'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Initial state - product should not be in wishlist
      expect(wishlistProvider.isInWishlist(testProduct.id), false);
      expect(wishlistProvider.itemCount, 0);

      // Tap the toggle button
      await tester.tap(find.text('Toggle Wishlist'));
      await tester.pumpAndSettle();

      // Product should now be in wishlist
      expect(wishlistProvider.isInWishlist(testProduct.id), true);
      expect(wishlistProvider.itemCount, 1);

      // Tap again to remove
      await tester.tap(find.text('Toggle Wishlist'));
      await tester.pumpAndSettle();

      // Product should be removed from wishlist
      expect(wishlistProvider.isInWishlist(testProduct.id), false);
      expect(wishlistProvider.itemCount, 0);
    });

    testWidgets('WishlistUtils.isProductInWishlist works correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: wishlistProvider,
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: Center(
                    child: Text(
                      WishlistUtils.isProductInWishlist(context, testProduct.id)
                          ? 'In Wishlist'
                          : 'Not In Wishlist',
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Initially should show "Not In Wishlist"
      expect(find.text('Not In Wishlist'), findsOneWidget);

      // Add product to wishlist manually
      await wishlistProvider.addToWishlist(testProduct);
      await tester.pumpAndSettle();

      // Should now show "In Wishlist"
      expect(find.text('In Wishlist'), findsOneWidget);
    });

    testWidgets('WishlistUtils.getWishlistCount works correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: wishlistProvider,
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: Center(
                    child: Text(
                      'Count: ${WishlistUtils.getWishlistCount(context)}',
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Initially should show count 0
      expect(find.text('Count: 0'), findsOneWidget);

      // Add products to wishlist
      await wishlistProvider.addToWishlist(testProduct);
      await tester.pumpAndSettle();

      // Should now show count 1
      expect(find.text('Count: 1'), findsOneWidget);

      // Add another product
      final testProduct2 = Product(
        id: 'test_product_2',
        name: 'Test Beauty Product 2',
        description: 'Another test product',
        price: 35.99,
        images: ['https://example.com/test-image-2.jpg'],
        brand: 'Test Brand 2',
        categoryId: 'makeup',
        isInStock: true,
        rating: 4.0,
        reviewCount: 75,
        beautyPoints: 35,
        ingredients: ['Mica', 'Talc', 'Iron Oxides'],
      );

      await wishlistProvider.addToWishlist(testProduct2);
      await tester.pumpAndSettle();

      // Should now show count 2
      expect(find.text('Count: 2'), findsOneWidget);
    });

    test('WishlistProvider force refresh button states', () async {
      // Add a product to wishlist
      await wishlistProvider.addToWishlist(testProduct);
      expect(wishlistProvider.isInWishlist(testProduct.id), true);
      expect(wishlistProvider.itemCount, 1);

      // Force refresh should maintain state
      wishlistProvider.forceRefreshButtonStates();
      expect(wishlistProvider.isInWishlist(testProduct.id), true);
      expect(wishlistProvider.itemCount, 1);

      // Remove product and force refresh
      await wishlistProvider.removeFromWishlist(testProduct.id);
      wishlistProvider.forceRefreshButtonStates();
      expect(wishlistProvider.isInWishlist(testProduct.id), false);
      expect(wishlistProvider.itemCount, 0);
    });

    test('WishlistProvider initialization state', () {
      // New provider should not be initialized
      final newProvider = WishlistProvider();
      expect(newProvider.isInitialized, false);
      expect(newProvider.itemCount, 0);

      // After loading from storage, should be initialized
      newProvider.loadWishlistFromStorage();
      expect(newProvider.isInitialized, true);
    });

    test('WishlistProvider toggle functionality', () async {
      expect(wishlistProvider.isInWishlist(testProduct.id), false);

      // First toggle should add product
      final success1 = await wishlistProvider.toggleWishlist(testProduct);
      expect(success1, true);
      expect(wishlistProvider.isInWishlist(testProduct.id), true);
      expect(wishlistProvider.itemCount, 1);

      // Second toggle should remove product
      final success2 = await wishlistProvider.toggleWishlist(testProduct);
      expect(success2, true);
      expect(wishlistProvider.isInWishlist(testProduct.id), false);
      expect(wishlistProvider.itemCount, 0);
    });
  });
}
