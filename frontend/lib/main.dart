import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/products/product_list_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'constants/app_constants.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.accentColor,
          primary: AppConstants.accentColor,
          secondary: AppConstants.favoriteColor,
          surface: AppConstants.surfaceColor,
          background: AppConstants.backgroundColor,
          brightness: Brightness.light,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: AppConstants.textPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: AppConstants.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.accentColor,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        cardTheme: CardTheme(
          color: AppConstants.surfaceColor,
          elevation: AppConstants.cardElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppConstants.backgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            borderSide: BorderSide(color: AppConstants.borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            borderSide: BorderSide(color: AppConstants.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            borderSide: BorderSide(color: AppConstants.accentColor, width: 2),
          ),
        ),
        textTheme: TextTheme(
          headlineLarge: TextStyle(
            color: AppConstants.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            color: AppConstants.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            color: AppConstants.textPrimary,
          ),
          bodyMedium: TextStyle(
            color: AppConstants.textSecondary,
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppConstants.surfaceColor,
          selectedItemColor: AppConstants.accentColor,
          unselectedItemColor: AppConstants.textSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
      ),
      routerConfig: _router,
    );
  }
}

// Router Configuration
final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    // Splash Screen
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    
    // Login Screen
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    
    // Main App Shell with Bottom Navigation
    ShellRoute(
      builder: (context, state, child) {
        return MainNavigationWrapper(child: child);
      },
      routes: [
        // Home
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        
        // Categories
        GoRoute(
          path: '/categories',
          name: 'categories',
          builder: (context, state) => const ProductListScreen(),
        ),
        
        // Search
        GoRoute(
          path: '/search',
          name: 'search',
          builder: (context, state) => const ProductListScreen(),
        ),
        
        // Cart
        GoRoute(
          path: '/cart',
          name: 'cart',
          builder: (context, state) => const CartScreen(),
        ),
        
        // Profile
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);

// Main Navigation Wrapper with Bottom Navigation
class MainNavigationWrapper extends StatefulWidget {
  final Widget child;

  const MainNavigationWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        context.goNamed('home');
        break;
      case 1:
        context.goNamed('categories');
        break;
      case 2:
        context.goNamed('search');
        break;
      case 3:
        context.goNamed('cart');
        break;
      case 4:
        context.goNamed('profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Update selected index based on current route
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home')) {
      _selectedIndex = 0;
    } else if (location.startsWith('/categories')) {
      _selectedIndex = 1;
    } else if (location.startsWith('/search')) {
      _selectedIndex = 2;
    } else if (location.startsWith('/cart')) {
      _selectedIndex = 3;
    } else if (location.startsWith('/profile')) {
      _selectedIndex = 4;
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                index: 0,
              ),
                _buildNavItem(
                icon: Icons.grid_view_outlined,
                activeIcon: Icons.grid_view,
                label: 'Categories',
                index: 1,
              ),
              _buildNavItem(
                icon: Icons.search_outlined,
                activeIcon: Icons.search,
                label: 'Search',
                index: 2,
              ),
              _buildNavItem(
                icon: Icons.shopping_cart_outlined,
                activeIcon: Icons.shopping_cart,
                label: 'Cart',
                index: 3,
              ),
              _buildNavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profile',
                index: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final bool isSelected = _selectedIndex == index;
    
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected 
                  ? AppConstants.accentColor
                  : AppConstants.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected 
                    ? AppConstants.accentColor
                    : AppConstants.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

