import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../providers/wishlist_provider.dart';
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
    // Load wishlist data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WishlistProvider>().loadWishlistFromStorage();
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        
    return Scaffold(
          backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
            backgroundColor: AppConstants.surfaceColor,
            elevation: 0,
            title: Text(
              'Profile',
              style: TextStyle(
                fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),
            centerTitle: false,
      ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Profile Section
                _buildUserProfileSection(isSmallScreen),
                
                SizedBox(height: isSmallScreen ? 24 : 32),
                
                // Menu Options
                _buildMenuSection(isSmallScreen),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserProfileSection(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppConstants.textSecondary.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Avatar
          Container(
            width: isSmallScreen ? 60 : 80,
            height: isSmallScreen ? 60 : 80,
            decoration: BoxDecoration(
              color: AppConstants.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(isSmallScreen ? 30 : 40),
            ),
            child: Icon(
              Icons.person,
              size: isSmallScreen ? 32 : 40,
              color: AppConstants.accentColor,
            ),
            ),
          
          SizedBox(width: isSmallScreen ? 16 : 20),
          
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User Name',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 22,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textPrimary,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 4 : 6),
                Text(
                  'user@email.com',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: AppConstants.textSecondary,
                  ),
          ),
              ],
            ),
          ),
          
          // Edit Profile Button
          IconButton(
            onPressed: () {
              // TODO: Navigate to edit profile
            },
            icon: Icon(
              Icons.edit,
              color: AppConstants.accentColor,
              size: isSmallScreen ? 20 : 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppConstants.textSecondary.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // My Orders
          _buildMenuItem(
            icon: Icons.shopping_bag_outlined,
            title: 'My Orders',
            subtitle: 'View your order history',
            onTap: () {
              // TODO: Navigate to orders
              ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
                  content: Text('Orders feature coming soon!'),
                  backgroundColor: AppConstants.accentColor,
                  duration: Duration(seconds: 2),

                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            isSmallScreen: isSmallScreen,
          ),
          
          const Divider(height: 1),
          
          // Wishlist with counter
          Consumer<WishlistProvider>(
            builder: (context, wishlistProvider, child) {
              return _buildMenuItem(
                icon: Icons.favorite_outline,
                title: 'My Wishlist',
                subtitle: '${wishlistProvider.itemCount} item${wishlistProvider.itemCount == 1 ? '' : 's'} saved',
                onTap: _navigateToWishlist,
                isSmallScreen: isSmallScreen,
                trailing: wishlistProvider.itemCount > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppConstants.favoriteColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${wishlistProvider.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : null,
              );
            },
          ),
          
          const Divider(height: 1),
          
          // Beauty Points
          _buildMenuItem(
            icon: Icons.stars_outlined,
            title: 'Beauty Points',
            subtitle: 'Earn points with every purchase',
            onTap: () {
              // TODO: Navigate to beauty points
              ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
                  content: Text('Beauty Points feature coming soon!'),
                  backgroundColor: AppConstants.favoriteColor,
                  duration: Duration(seconds: 2),

                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            isSmallScreen: isSmallScreen,
          ),
          
          const Divider(height: 1),
          
          // Settings
          _buildMenuItem(
            icon: Icons.settings_outlined,
            title: 'Settings',
            subtitle: 'Preferences and account settings',
            onTap: () {
              // TODO: Navigate to settings
              ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
                  content: Text('Settings feature coming soon!'),
                  backgroundColor: AppConstants.accentColor,
                  duration: Duration(seconds: 2),

                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            isSmallScreen: isSmallScreen,
          ),
          
          const Divider(height: 1),
          
          // Help & Support
          _buildMenuItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help with your orders',
            onTap: () {
              // TODO: Navigate to help
              ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
                  content: Text('Help & Support feature coming soon!'),
                  backgroundColor: AppConstants.accentColor,
                  duration: Duration(seconds: 2),

                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            isSmallScreen: isSmallScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isSmallScreen,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
        child: Row(
          children: [
            // Icon
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
              decoration: BoxDecoration(
                color: AppConstants.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppConstants.accentColor,
                size: isSmallScreen ? 20 : 24,
              ),
            ),
            
            SizedBox(width: isSmallScreen ? 12 : 16),
            
            // Title and Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 15 : 16,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 2 : 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 13,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Trailing widget or arrow
            trailing ?? Icon(
              Icons.arrow_forward_ios,
              size: isSmallScreen ? 16 : 18,
              color: AppConstants.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
