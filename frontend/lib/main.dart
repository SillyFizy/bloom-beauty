import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/products/product_list_screen.dart';
import 'screens/products/product_detail_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/celebrity/celebrity_screen.dart';
import 'screens/checkout/checkout_screen.dart';
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
          cardTheme: const CardThemeData(
            color: AppConstants.surfaceColor,
            elevation: AppConstants.cardElevation,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.all(Radius.circular(AppConstants.borderRadius)),
            ),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: AppConstants.backgroundColor,
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.all(Radius.circular(AppConstants.borderRadius)),
              borderSide: BorderSide(color: AppConstants.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.all(Radius.circular(AppConstants.borderRadius)),
              borderSide: BorderSide(color: AppConstants.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.all(Radius.circular(AppConstants.borderRadius)),
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

// Navigation state holder for smooth transitions
class NavigationState extends ChangeNotifier {
  static final NavigationState _instance = NavigationState._internal();
  factory NavigationState() => _instance;
  NavigationState._internal();

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }
}

// Router Configuration without authentication guards for now
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

    // Main App Shell with Smooth Navigation
    GoRoute(
      path: '/home',
      name: 'home',
      pageBuilder: (context, state) => NoTransitionPage<void>(
        key: state.pageKey,
        child: const MainNavigationWrapper(),
      ),
    ),

    // Product Detail Screen (modal-style overlay)
    GoRoute(
      path: '/product/:productId',
      name: 'product-detail',
      pageBuilder: (context, state) {
        final productId = state.pathParameters['productId']!;
        return CustomTransitionPage<void>(
          key: state.pageKey,
          child: ProductDetailScreen(productId: productId),
          transitionDuration: const Duration(milliseconds: 350),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 1.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
                child: child,
              ),
            );
          },
        );
      },
    ),

    // Celebrity Screen (modal-style overlay)
    GoRoute(
      path: '/celebrity',
      name: 'celebrity',
      pageBuilder: (context, state) {
        return CustomTransitionPage<void>(
          key: state.pageKey,
          child: const CelebrityScreen(),
          transitionDuration: const Duration(milliseconds: 350),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
                child: child,
              ),
            );
          },
        );
      },
    ),

    // Checkout Screen (modal-style overlay)
    GoRoute(
      path: '/checkout',
      name: 'checkout',
      pageBuilder: (context, state) {
        return CustomTransitionPage<void>(
          key: state.pageKey,
          child: const CheckoutScreen(),
          transitionDuration: const Duration(milliseconds: 350),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 1.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        );
      },
    ),
  ],
);

// Main Navigation Wrapper with PageView for smooth transitions
class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _tabAnimationController;
  int _currentIndex = 0;
  static bool _hasInitializedEssentials = false;

  // Define all main screens
  final List<Widget> _screens = const [
    HomeScreen(),
    ProductListScreen(),
    SearchScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  final List<String> _screenNames = [
    'Home',
    'Categories', 
    'Search',
    'Cart',
    'Profile',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _tabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    // Initialize essential providers immediately when main navigation loads
    if (!_hasInitializedEssentials) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeEssentialProviders();
      });
    }
  }

  Future<void> _initializeEssentialProviders() async {
    if (_hasInitializedEssentials) return;
    
    try {
      debugPrint('MainNavigationWrapper: Initializing essential providers');
      await AppProviders.initializeEssentialProviders(context);
      _hasInitializedEssentials = true;
      debugPrint('MainNavigationWrapper: Essential providers initialized');
    } catch (e) {
      debugPrint('MainNavigationWrapper: Error initializing essential providers: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabAnimationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_currentIndex == index) return; // Don't navigate to same tab

    // Add haptic feedback for better user experience
    HapticFeedback.selectionClick();

    // Calculate distance between current and target tabs
    final distance = (index - _currentIndex).abs();
    
    // Update state immediately for instant UI feedback
    setState(() {
      _currentIndex = index;
    });

    // Update navigation state
    NavigationState().setIndex(index);

    // Smart navigation: instant for distant tabs, smooth for close ones
    if (distance > 2) {
      // For distant tabs (e.g., Home to Profile), jump instantly to prevent ghosting
      _pageController.jumpToPage(index);
    } else {
      // For close tabs (e.g., Home to Categories), use smooth animation
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }

    // Animate tab indicator
    _tabAnimationController.forward(from: 0);
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    NavigationState().setIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe to prevent accidental navigation
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return LayoutBuilder(
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
                color: Colors.grey.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, -4),
                spreadRadius: 0,
              ),
            ],
            border: Border(
              top: BorderSide(
                color: AppConstants.borderColor.withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
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
    final bool isSelected = _currentIndex == index;

    // Responsive sizing
    final iconSize = isSelected
        ? (isSmallScreen ? 26.0 : (isMediumScreen ? 28.0 : 30.0))
        : (isSmallScreen ? 24.0 : (isMediumScreen ? 26.0 : 28.0));
    
    final fontSize = isSmallScreen ? 11.0 : (isMediumScreen ? 12.0 : 13.0);
    final verticalPadding = isSmallScreen ? 8.0 : (isMediumScreen ? 10.0 : 12.0);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onItemTapped(index),
          borderRadius: BorderRadius.circular(12),
          splashColor: AppConstants.accentColor.withValues(alpha: 0.1),
          highlightColor: AppConstants.accentColor.withValues(alpha: 0.05),
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: verticalPadding,
              horizontal: 4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon with smooth transition
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.all(isSelected ? 2 : 0),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppConstants.accentColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    size: iconSize,
                    color: isSelected 
                        ? AppConstants.accentColor 
                        : AppConstants.textSecondary,
                  ),
                ),
                
                // Spacing
                SizedBox(height: isSmallScreen ? 4 : 6),
                
                // Label with smooth transition
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected 
                        ? AppConstants.accentColor 
                        : AppConstants.textSecondary,
                    letterSpacing: 0.5,
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
