import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_constants.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/recently_viewed_provider.dart';
import '../wishlist/wishlist_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Load providers data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WishlistProvider>().loadWishlistFromStorage();
      context.read<RecentlyViewedProvider>().loadFromStorage();
      // Initialize auth provider to check current authentication state
      context.read<AuthProvider>().initialize();
    });
  }

  Future<void> _navigateToWishlist() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WishlistScreen(),
      ),
    );
  }

  Future<void> _handleSignOut() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logout();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Signed out successfully'),
          backgroundColor: AppConstants.accentColor,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Profile Header
              _buildProfileHeader(),
              
              const SizedBox(height: 32),
              
              // Menu Grid
              _buildMenuGrid(),
              
              const SizedBox(height: 32),
              
              // Beauty Points Section
              _buildBeautyPointsSection(),
              
              const SizedBox(height: 24),
              
              // Recently Viewed Section (conditional)
              Consumer<RecentlyViewedProvider>(
                builder: (context, recentlyViewedProvider, child) {
                  if (recentlyViewedProvider.hasItems) {
                    return Column(
                      children: [
                        _buildRecentlyViewedSection(recentlyViewedProvider),
                        const SizedBox(height: 24),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              
              // Sign Out Button (conditional - only show if authenticated)
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  if (authProvider.isAuthenticated) {
                    return Column(
                      children: [
                        const SizedBox(height: 8),
                        _buildSignOutButton(),
                        const SizedBox(height: 20),
                      ],
                    );
                  }
                  return const SizedBox(height: 20);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Column(
          children: [
            // Profile Icon (static, no picture functionality)
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppConstants.accentColor.withOpacity(0.2),
                    AppConstants.favoriteColor.withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.accentColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppConstants.surfaceColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppConstants.accentColor.withOpacity(0.1),
                        AppConstants.favoriteColor.withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: Icon(
                    authProvider.isAuthenticated ? Icons.person : Icons.person_outline,
                    size: 50,
                    color: AppConstants.accentColor,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // User Name/App Name - conditional based on auth state
            Text(
              authProvider.isAuthenticated 
                ? 'Welcome, ${authProvider.firstName ?? 'Beauty Lover'}!'
                : 'Your Beauty Profile',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            // User info or signup prompt - conditional based on auth state
            Text(
              authProvider.isAuthenticated
                ? 'Phone: ${authProvider.phoneNumber ?? 'Not provided'}\n${authProvider.points != null ? '${authProvider.points} Beauty Points' : ''}'
                : 'Sign up to unlock exclusive features and\ntrack your beauty journey',
              style: const TextStyle(
                fontSize: 16,
                color: AppConstants.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 20),
            
            // Login/Signup Button - only show if not authenticated
            if (!authProvider.isAuthenticated)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.push('/login');
                  },
                  icon: const Icon(Icons.person_add, size: 20),
                  label: const Text(
                    'Sign Up / Sign In',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMenuGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildMenuCard(
          icon: Icons.shopping_bag_outlined,
          title: 'Orders History',
          color: AppConstants.accentColor,
          onTap: () => _showComingSoon('Orders History'),
        ),
        Consumer<WishlistProvider>(
          builder: (context, wishlistProvider, child) {
            return _buildMenuCard(
              icon: Icons.favorite_outline,
              title: 'Skincare\nFavorites',
              color: AppConstants.favoriteColor,
              onTap: _navigateToWishlist,
              badge: wishlistProvider.itemCount > 0 ? '${wishlistProvider.itemCount}' : null,
            );
          },
        ),
        _buildMenuCard(
          icon: Icons.person_outline,
          title: 'Beauty Profile',
          color: AppConstants.accentColor,
          onTap: () => _showComingSoon('Beauty Profile'),
        ),
        _buildMenuCard(
          icon: Icons.notifications_outlined,
          title: 'Notification\nPreferences',
          color: AppConstants.favoriteColor,
          onTap: () => _showComingSoon('Notification Preferences'),
        ),
      ],
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textPrimary,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            if (badge != null)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBeautyPointsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppConstants.accentColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Beauty Points',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
                ),
              ),
              Text(
                '1500 Points',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: 0.75,
              backgroundColor: AppConstants.borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(AppConstants.accentColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentlyViewedSection(RecentlyViewedProvider recentlyViewedProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recently Viewed',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120, // Increased height to accommodate product name
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: recentlyViewedProvider.getRecentlyViewed(limit: 5).length,
              itemBuilder: (context, index) {
                final product = recentlyViewedProvider.getRecentlyViewed(limit: 5)[index];
                return GestureDetector(
                  onTap: () {
                    context.push('/product/${product.id}');
                  },
                  child: Container(
                    width: 100,
                    margin: EdgeInsets.only(right: index < 4 ? 12 : 0),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppConstants.backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppConstants.borderColor,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: product.images.isNotEmpty
                                ? Image.network(
                                    product.images.first,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.image_outlined,
                                        color: AppConstants.textSecondary,
                                        size: 24,
                                      );
                                    },
                                  )
                                : Icon(
                                    Icons.image_outlined,
                                    color: AppConstants.textSecondary,
                                    size: 24,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppConstants.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: authProvider.isLoading ? null : _handleSignOut,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: authProvider.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppConstants.textSecondary),
                    ),
                  )
                : Text(
                    'Sign Out',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppConstants.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        );
      },
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon!'),
        backgroundColor: AppConstants.accentColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
