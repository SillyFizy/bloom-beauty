import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_constants.dart';

class CelebrityScreen extends StatelessWidget {
  final String celebrityName;
  final String celebrityImage;
  final String? testimonial;
  final List<String> routineProducts;
  final List<String> recommendedProducts;

  const CelebrityScreen({
    super.key,
    required this.celebrityName,
    required this.celebrityImage,
    this.testimonial,
    this.routineProducts = const [],
    this.recommendedProducts = const [],
  });

  Future<void> _launchSocialMedia(String platform) async {
    String url = '';
    
    // Format celebrity name for URLs (replace spaces with underscores/dots)
    final formattedName = celebrityName.toLowerCase().replaceAll(' ', '');
    
    switch (platform) {
      case 'facebook':
        url = 'https://facebook.com/$formattedName';
        break;
      case 'instagram':
        url = 'https://instagram.com/$formattedName';
        break;
      case 'snapchat':
        url = 'https://snapchat.com/add/$formattedName';
        break;
    }
    
    if (url.isNotEmpty) {
      try {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        // Handle error silently or show a snackbar
        debugPrint('Could not launch $url: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar with celebrity image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppConstants.surfaceColor,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppConstants.surfaceColor.withOpacity(0.9),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppConstants.borderColor,
                  width: 1,
                ),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: AppConstants.textPrimary,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppConstants.favoriteColor.withOpacity(0.1),
                      AppConstants.backgroundColor,
                    ],
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppConstants.favoriteColor,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppConstants.favoriteColor.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 96,
                      backgroundColor: AppConstants.surfaceColor,
                      backgroundImage: NetworkImage(celebrityImage),
                      onBackgroundImageError: (exception, stackTrace) {
                        // Fallback to icon if image fails to load
                      },
                      child: celebrityImage.isEmpty ? 
                        Icon(
                          Icons.star_rounded,
                          color: AppConstants.favoriteColor,
                          size: 80,
                        ) : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Celebrity content
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppConstants.surfaceColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  
                  // Celebrity name and title
                  _buildCelebrityHeader(),
                  
                  // Testimonial section
                  if (testimonial != null && testimonial!.isNotEmpty)
                    _buildTestimonial(),
                  
                  // Complete routine section
                  _buildCompleteRoutine(),
                  
                  // Recommended products section  
                  _buildRecommendedProducts(),
                  
                  // Beauty secrets section
                  _buildBeautySecrets(),
                  
                  // Social media links
                  _buildSocialMediaLinks(),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCelebrityHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Column(
        children: [
          Text(
            celebrityName,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Discover the secrets behind $celebrityName\'s radiant glow with their exclusive beauty philosophy and skincare routine.',
            style: TextStyle(
              fontSize: 16,
              color: AppConstants.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonial() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppConstants.favoriteColor.withOpacity(0.08),
            AppConstants.accentColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppConstants.favoriteColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.format_quote,
            color: AppConstants.favoriteColor,
            size: 40,
          ),
          const SizedBox(height: 16),
          Text(
            testimonial!,
            style: TextStyle(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: AppConstants.textPrimary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            '— $celebrityName',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.favoriteColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteRoutine() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Complete Routine',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          
          // Morning and Evening sections
          Row(
            children: [
              Expanded(child: _buildRoutineSection('Morning', _getMorningProducts())),
              const SizedBox(width: 20),
              Expanded(child: _buildRoutineSection('Evening', _getEveningProducts())),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineSection(String title, List<String> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppConstants.accentColor,
          ),
        ),
        const SizedBox(height: 12),
        ...products.map((product) => Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppConstants.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppConstants.borderColor,
              width: 1,
            ),
          ),
          child: Text(
            product,
            style: TextStyle(
              fontSize: 14,
              color: AppConstants.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildRecommendedProducts() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommended Products',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          
          // Product grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.8,
            children: _getRecommendedProductsList().map((product) => _buildProductCard(product)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, String> product) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppConstants.textSecondary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image placeholder
          Container(
            height: 120,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppConstants.backgroundColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Center(
              child: Icon(
                Icons.image_outlined,
                size: 40,
                color: AppConstants.accentColor,
              ),
            ),
          ),
          
          // Product details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product['price'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppConstants.accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppConstants.favoriteColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Celebrity Essential',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppConstants.favoriteColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeautySecrets() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppConstants.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Beauty Secrets',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppConstants.borderColor,
                width: 1,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.play_circle_outline,
                    size: 60,
                    color: AppConstants.favoriteColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Watch $celebrityName share their skin care tips and secrets.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppConstants.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaLinks() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialButton(
                'facebook',
                Icons.facebook,
                AppConstants.favoriteColor,
              ),
              const SizedBox(width: 20),
              _buildSocialButton(
                'instagram',
                Icons.camera_alt,
                AppConstants.accentColor,
              ),
              const SizedBox(width: 20),
              _buildSocialButton(
                'snapchat',
                Icons.camera,
                AppConstants.textPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(String platform, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => _launchSocialMedia(platform),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: color,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: color,
          size: 28,
        ),
      ),
    );
  }

  // Helper methods to get sample data
  List<String> _getMorningProducts() {
    return [
      'Gentle Cleanser',
      'Vitamin C Serum',
      'Moisturizer',
      'SPF 50 Sunscreen',
    ];
  }

  List<String> _getEveningProducts() {
    return [
      'Makeup Remover',
      'Deep Cleanser',
      'Night Serum',
      'Rich Night Cream',
    ];
  }

  List<Map<String, String>> _getRecommendedProductsList() {
    return [
      {
        'name': '$celebrityName Glow Serum',
        'price': '35,000 IQD',
      },
      {
        'name': '$celebrityName Radiant Cream',
        'price': '45,000 IQD',
      },
      {
        'name': '$celebrityName Perfecting Mist',
        'price': '30,000 IQD',
      },
      {
        'name': '$celebrityName Hydrating Essence',
        'price': '40,000 IQD',
      },
    ];
  }
} 