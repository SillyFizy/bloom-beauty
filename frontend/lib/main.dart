import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/products/product_list_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/search/search_screen.dart';
import 'constants/app_constants.dart';
import 'providers/app_providers.dart';
import 'providers/cart_provider.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize local storage
  await StorageService.init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppProviders.create(
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppConstants.accentColor,
            primary: AppConstants.accentColor,
            secondary: AppConstants.favoriteColor,
            surface: AppConstants.surfaceColor,
            onSurface: AppConstants.textPrimary,
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
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
          cardTheme: const CardTheme(
            color: AppConstants.surfaceColor,
            elevation: AppConstants.cardElevation,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(AppConstants.borderRadius)),
            ),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: AppConstants.backgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(AppConstants.borderRadius)),
              borderSide: BorderSide(color: AppConstants.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(AppConstants.borderRadius)),
              borderSide: BorderSide(color: AppConstants.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(AppConstants.borderRadius)),
              borderSide: BorderSide(color: AppConstants.accentColor, width: 2),
            ),
          ),
          textTheme: const TextTheme(
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
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: AppConstants.surfaceColor,
            selectedItemColor: AppConstants.accentColor,
            unselectedItemColor: AppConstants.textSecondary,
            type: BottomNavigationBarType.fixed,
            elevation: 8,
          ),
        ),
        routerConfig: _router,
      ),
    );
  }
}

// Navigation state holder for transition direction awareness
class NavigationState {
  static int previousTab = 0;
  static int currentTab = 0;
  
  static SlideDirection getDirectionForTransition(int from, int to) {
    // Horizontal navigation (left-right based on tab order)
    if (to > from) {
      return SlideDirection.fromRight; // Moving right in tab order
    } else {
      return SlideDirection.fromLeft;  // Moving left in tab order
    }
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
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        child: const SplashScreen(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    ),
    
    // Login Screen
    GoRoute(
      path: '/login',
      name: 'login',
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        child: const LoginScreen(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    ),
    
    // Main App Shell with Bottom Navigation and Smooth Transitions
    ShellRoute(
      builder: (context, state, child) {
        return MainNavigationWrapper(child: child);
      },
      routes: [
        // Home
        GoRoute(
          path: '/home',
          name: 'home',
          pageBuilder: (context, state) {
            NavigationState.previousTab = NavigationState.currentTab;
            NavigationState.currentTab = 0;
            return CustomTransitionPage<void>(
              key: state.pageKey,
              child: const HomeScreen(),
              transitionDuration: const Duration(milliseconds: 300),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                final direction = NavigationState.getDirectionForTransition(
                  NavigationState.previousTab, 
                  NavigationState.currentTab
                );
                return _buildSlideTransition(animation, secondaryAnimation, child, direction);
              },
            );
          },
        ),
        
        // Categories
        GoRoute(
          path: '/categories',
          name: 'categories',
          pageBuilder: (context, state) {
            NavigationState.previousTab = NavigationState.currentTab;
            NavigationState.currentTab = 1;
            return CustomTransitionPage<void>(
              key: state.pageKey,
              child: const ProductListScreen(),
              transitionDuration: const Duration(milliseconds: 300),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                final direction = NavigationState.getDirectionForTransition(
                  NavigationState.previousTab, 
                  NavigationState.currentTab
                );
                return _buildSlideTransition(animation, secondaryAnimation, child, direction);
              },
            );
          },
        ),
        
        // Search
        GoRoute(
          path: '/search',
          name: 'search',
          pageBuilder: (context, state) {
            NavigationState.previousTab = NavigationState.currentTab;
            NavigationState.currentTab = 2;
            return CustomTransitionPage<void>(
              key: state.pageKey,
              child: const SearchScreen(),
              transitionDuration: const Duration(milliseconds: 300),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                final direction = NavigationState.getDirectionForTransition(
                  NavigationState.previousTab, 
                  NavigationState.currentTab
                );
                return _buildSlideTransition(animation, secondaryAnimation, child, direction);
              },
            );
          },
        ),
        
        // Cart
        GoRoute(
          path: '/cart',
          name: 'cart',
          pageBuilder: (context, state) {
            NavigationState.previousTab = NavigationState.currentTab;
            NavigationState.currentTab = 3;
            return CustomTransitionPage<void>(
              key: state.pageKey,
              child: const CartScreen(),
              transitionDuration: const Duration(milliseconds: 300),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                // Cart slides up from bottom for a more natural feeling
                return _buildSlideTransition(animation, secondaryAnimation, child, SlideDirection.fromBottom);
              },
            );
          },
        ),
        
        // Profile
        GoRoute(
          path: '/profile',
          name: 'profile',
          pageBuilder: (context, state) {
            NavigationState.previousTab = NavigationState.currentTab;
            NavigationState.currentTab = 4;
            return CustomTransitionPage<void>(
              key: state.pageKey,
              child: const ProfileScreen(),
              transitionDuration: const Duration(milliseconds: 300),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                final direction = NavigationState.getDirectionForTransition(
                  NavigationState.previousTab, 
                  NavigationState.currentTab
                );
                return _buildSlideTransition(animation, secondaryAnimation, child, direction);
              },
            );
          },
        ),
      ],
    ),
  ],
);

// Enum for slide directions
enum SlideDirection { fromLeft, fromRight, fromTop, fromBottom }

// Custom transition builders
Widget _buildSlideTransition(
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
  SlideDirection direction,
) {
  late Offset begin;
  const end = Offset.zero;
  
  switch (direction) {
    case SlideDirection.fromLeft:
      begin = const Offset(-1.0, 0.0);
      break;
    case SlideDirection.fromRight:
      begin = const Offset(1.0, 0.0);
      break;
    case SlideDirection.fromTop:
      begin = const Offset(0.0, -1.0);
      break;
    case SlideDirection.fromBottom:
      begin = const Offset(0.0, 1.0);
      break;
  }
  
  // Use a more refined curve for better feel
  const curve = Curves.easeOutCubic;
  const reverseCurve = Curves.easeInCubic;
  
  final slideAnimation = Tween<Offset>(begin: begin, end: end).animate(
    CurvedAnimation(parent: animation, curve: curve),
  );
  
  // Scale animation for subtle depth effect
  final scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
    CurvedAnimation(parent: animation, curve: curve),
  );
  
  // Secondary animation for exiting screen
  final secondarySlideAnimation = Tween<Offset>(
    begin: Offset.zero,
    end: Offset(-begin.dx * 0.3, -begin.dy * 0.3), // Subtle parallax effect
  ).animate(
    CurvedAnimation(parent: secondaryAnimation, curve: reverseCurve),
  );
  
  final secondaryFadeAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
    CurvedAnimation(parent: secondaryAnimation, curve: reverseCurve),
  );
  
  return SlideTransition(
    position: secondarySlideAnimation,
    child: FadeTransition(
      opacity: secondaryFadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: child,
        ),
      ),
    ),
  );
}

// Main Navigation Wrapper with Bottom Navigation
class MainNavigationWrapper extends StatefulWidget {
  final Widget child;

  const MainNavigationWrapper({
    super.key,
    required this.child,
  });

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> 
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _tabAnimationController;

  @override
  void initState() {
    super.initState();
    _tabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabAnimationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return; // Don't navigate to same tab
    
    // Add haptic feedback
    HapticFeedback.selectionClick();
    
    setState(() {
      _selectedIndex = index;
    });

    // Animate tab indicator
    _tabAnimationController.forward(from: 0);

    // Navigate with direction-aware transitions
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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: widget.child,
      ),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive design breakpoints
          final screenWidth = MediaQuery.of(context).size.width;
          final isSmallScreen = screenWidth < 600;
          final isMediumScreen = screenWidth >= 600 && screenWidth < 900;
          final isLargeScreen = screenWidth >= 900;
          
          // Responsive sizing
          final navHeight = isSmallScreen ? 80.0 : (isMediumScreen ? 90.0 : 100.0);
          final maxNavWidth = isLargeScreen ? 800.0 : double.infinity;
          
          return Container(
            height: navHeight,
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
            child: Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: maxNavWidth),
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home,
                        label: 'Home',
                        index: 0,
                        isSmallScreen: isSmallScreen,
                        isMediumScreen: isMediumScreen,
                      ),
                      _buildNavItem(
                        icon: Icons.grid_view_outlined,
                        activeIcon: Icons.grid_view,
                        label: 'Categories',
                        index: 1,
                        isSmallScreen: isSmallScreen,
                        isMediumScreen: isMediumScreen,
                      ),
                      _buildNavItem(
                        icon: Icons.search_outlined,
                        activeIcon: Icons.search,
                        label: 'Search',
                        index: 2,
                        isSmallScreen: isSmallScreen,
                        isMediumScreen: isMediumScreen,
                      ),
                      _buildNavItem(
                        icon: Icons.shopping_cart_outlined,
                        activeIcon: Icons.shopping_cart,
                        label: 'Cart',
                        index: 3,
                        isSmallScreen: isSmallScreen,
                        isMediumScreen: isMediumScreen,
                      ),
                      _buildNavItem(
                        icon: Icons.person_outline,
                        activeIcon: Icons.person,
                        label: 'Profile',
                        index: 4,
                        isSmallScreen: isSmallScreen,
                        isMediumScreen: isMediumScreen,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required bool isSmallScreen,
    required bool isMediumScreen,
  }) {
    final bool isSelected = _selectedIndex == index;
    
    // Responsive sizing with proper height management
    final iconSize = isSelected 
        ? (isSmallScreen ? 24.0 : (isMediumScreen ? 26.0 : 28.0))
        : (isSmallScreen ? 22.0 : (isMediumScreen ? 24.0 : 26.0));
    
    final fontSize = isSelected 
        ? (isSmallScreen ? 12.0 : (isMediumScreen ? 13.0 : 14.0))
        : (isSmallScreen ? 11.0 : (isMediumScreen ? 12.0 : 13.0));
    
    // Reduced padding to prevent overflow
    final verticalPadding = isSmallScreen ? 2.0 : (isMediumScreen ? 3.0 : 4.0);
    final borderRadius = isSmallScreen ? 12.0 : (isMediumScreen ? 14.0 : 16.0);
    
    // Optimized spacing to fit within navigation height
    final spacingHeight = isSmallScreen ? 1.0 : (isMediumScreen ? 1.5 : 2.0);
    final indicatorWidth = isSelected ? (isSmallScreen ? 20.0 : (isMediumScreen ? 24.0 : 28.0)) : 0.0;
    final indicatorHeight = 2.0; // Fixed height for consistency
    final indicatorTopMargin = isSmallScreen ? 1.0 : (isMediumScreen ? 1.5 : 2.0);
    
    // Badge sizing for cart
    final badgeMinSize = isSmallScreen ? 16.0 : (isMediumScreen ? 18.0 : 20.0);
    final badgeFontSize = isSmallScreen ? 10.0 : (isMediumScreen ? 11.0 : 12.0);
    
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(vertical: verticalPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            color: isSelected 
                ? AppConstants.accentColor.withOpacity(0.1)
                : Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon section with flexible sizing
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Special handling for cart icon to show badge
                    if (index == 3) 
                      Selector<CartProvider, int>(
                        selector: (context, cart) => cart.itemCount,
                        builder: (context, itemCount, child) {
                          return Hero(
                            tag: 'cart_icon',
                            child: Stack(
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    isSelected ? activeIcon : icon,
                                    key: ValueKey('cart_icon_$isSelected'),
                                    color: isSelected 
                                        ? AppConstants.accentColor
                                        : AppConstants.textSecondary,
                                    size: iconSize,
                                  ),
                                ),
                                if (itemCount > 0)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: AnimatedScale(
                                      scale: isSelected ? 1.1 : 1.0,
                                      duration: const Duration(milliseconds: 200),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: AppConstants.favoriteColor,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: BoxConstraints(
                                          minWidth: badgeMinSize,
                                          minHeight: badgeMinSize,
                                        ),
                                        child: Text(
                                          itemCount > 99 ? '99+' : itemCount.toString(),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: badgeFontSize,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      )
                    else
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isSelected ? activeIcon : icon,
                          key: ValueKey('${label}_icon_$isSelected'),
                          color: isSelected 
                              ? AppConstants.accentColor
                              : AppConstants.textSecondary,
                          size: iconSize,
                        ),
                      ),
                    SizedBox(height: spacingHeight),
                    // Text with constrained height
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        color: isSelected 
                            ? AppConstants.accentColor
                            : AppConstants.textSecondary,
                        fontSize: fontSize,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        height: 1.0, // Constrain line height
                      ),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              // Active indicator with controlled spacing
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                height: indicatorHeight,
                width: indicatorWidth,
                margin: EdgeInsets.only(top: indicatorTopMargin),
                decoration: BoxDecoration(
                  color: AppConstants.accentColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

