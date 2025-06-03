import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/product_model.dart';
import '../../constants/app_constants.dart';
import '../../providers/product_provider.dart';
import '../products/product_detail_screen.dart';

class CelebrityScreen extends StatelessWidget {
  final String celebrityName;
  final String celebrityImage;
  final String? testimonial;
  final List<String> routineProducts;
  final List<Product> recommendedProducts;
  final Map<String, String> socialMediaLinks; // New field for social media links
  final List<Product> morningRoutineProducts; // New field for morning routine
  final List<Product> eveningRoutineProducts; // New field for evening routine

  const CelebrityScreen({
    super.key,
    required this.celebrityName,
    required this.celebrityImage,
    this.testimonial,
    this.routineProducts = const [],
    this.recommendedProducts = const [],
    this.socialMediaLinks = const {},
    this.morningRoutineProducts = const [], // New parameter
    this.eveningRoutineProducts = const [], // New parameter
  });

  Future<void> _launchSocialMedia(String url) async {
    if (url.isNotEmpty) {
      try {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          debugPrint('Could not launch $url');
        }
      } catch (e) {
        debugPrint('Error launching $url: $e');
      }
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isSmallScreen,
  }) {
    return Container(
      width: isSmallScreen ? 44 : 52,
      height: isSmallScreen ? 44 : 52,
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
        border: Border.all(
          color: AppConstants.borderColor.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppConstants.textSecondary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppConstants.surfaceColor,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
            ),
            child: Center(
              child: Icon(
                icon,
                color: AppConstants.textPrimary,
                size: isSmallScreen ? 20 : 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToProduct(BuildContext context, Product product) async {
    try {
      // Get the latest product data from the service to ensure accuracy
      final productProvider = context.read<ProductProvider>();
      final freshProduct = await productProvider.getProductById(product.id);
      
      if (freshProduct != null) {
        // Create an updated product with correct celebrity endorsement if needed
        Product productToNavigate = freshProduct;
        
        // If the product doesn't have celebrity endorsement but should have it,
        // create a copy with the correct endorsement
        if (freshProduct.celebrityEndorsement == null || 
            freshProduct.celebrityEndorsement!.celebrityName != celebrityName) {
          productToNavigate = Product(
            id: freshProduct.id,
            name: freshProduct.name,
            description: freshProduct.description,
            price: freshProduct.price,
            discountPrice: freshProduct.discountPrice,
            images: freshProduct.images,
            categoryId: freshProduct.categoryId,
            brand: freshProduct.brand,
            rating: freshProduct.rating,
            reviewCount: freshProduct.reviewCount,
            isInStock: freshProduct.isInStock,
            ingredients: freshProduct.ingredients,
            beautyPoints: freshProduct.beautyPoints,
            variants: freshProduct.variants,
            reviews: freshProduct.reviews,
            celebrityEndorsement: CelebrityEndorsement(
              celebrityName: celebrityName,
              celebrityImage: celebrityImage,
              testimonial: testimonial,
            ),
          );
        }
        
        // Add to recently viewed
        await productProvider.addToRecentlyViewed(productToNavigate);
        
        // Navigate to product detail
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: productToNavigate),
            ),
          );
        }
      } else {
        // Fallback to original product if service fails
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          );
        }
      }
    } catch (e) {
      // Error handling - fallback to original product
      debugPrint('Error fetching fresh product data: $e');
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine if we're on a small, medium, or large screen
        final isSmallScreen = constraints.maxWidth < 600;
        final isMediumScreen = constraints.maxWidth >= 600 && constraints.maxWidth < 900;

        return Scaffold(
          backgroundColor: AppConstants.backgroundColor,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppConstants.backgroundColor,
                  AppConstants.surfaceColor,
                ],
                stops: const [0.0, 0.3],
              ),
            ),
            child: CustomScrollView(
              slivers: [
                // Responsive App Bar
                _buildResponsiveSliverAppBar(isSmallScreen),
                
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
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : (isMediumScreen ? 20 : 32),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 30),
                          
                          // Celebrity header
                          _buildCelebrityHeader(isSmallScreen),
                          
                          // Testimonial section
                          if (testimonial != null && testimonial!.isNotEmpty)
                            _buildTestimonial(isSmallScreen),
                          
                          // Morning and Evening routine - FIRST
                          if (morningRoutineProducts.isNotEmpty || eveningRoutineProducts.isNotEmpty)
                            _buildResponsiveRoutineSection(context, isSmallScreen, isMediumScreen),
                          
                          // Recommended products - SECOND  
                          if (recommendedProducts.isNotEmpty)
                            _buildResponsiveRecommendedProducts(context, isSmallScreen, isMediumScreen),
                          
                          // Beauty secrets video - THIRD
                          _buildBeautySecrets(isSmallScreen),
                          
                          // Social media - LAST
                          if (socialMediaLinks.isNotEmpty)
                            _buildResponsiveSocialMedia(isSmallScreen),
                          
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResponsiveSliverAppBar(bool isSmallScreen) {
    return SliverAppBar(
      expandedHeight: isSmallScreen ? 280 : 320,
      pinned: true,
      backgroundColor: AppConstants.surfaceColor,
      elevation: 0,
      leading: Builder(
        builder: (context) => _buildActionButton(
          icon: Icons.arrow_back_ios,
          onPressed: () => Navigator.pop(context),
          isSmallScreen: isSmallScreen,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppConstants.favoriteColor.withOpacity(0.15),
                    AppConstants.favoriteColor.withOpacity(0.08),
                    AppConstants.accentColor.withOpacity(0.05),
                    AppConstants.surfaceColor,
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
            
            // Decorative background elements
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppConstants.favoriteColor.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              top: 20,
              left: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppConstants.accentColor.withOpacity(0.08),
                ),
              ),
            ),
            
            // Celebrity image container
            SafeArea(
              child: Center(
                child: Container(
                  width: isSmallScreen ? 180 : 220,
                  height: isSmallScreen ? 180 : 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppConstants.favoriteColor.withOpacity(0.3),
                        AppConstants.favoriteColor.withOpacity(0.1),
                        Colors.transparent,
                      ],
                      stops: const [0.7, 0.9, 1.0],
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppConstants.favoriteColor,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppConstants.favoriteColor.withOpacity(0.4),
                          blurRadius: 25,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: AppConstants.favoriteColor.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: celebrityImage.isNotEmpty
                          ? Image.network(
                              celebrityImage,
                              fit: BoxFit.cover,
                              width: isSmallScreen ? 164 : 204,
                              height: isSmallScreen ? 164 : 204,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildFallbackImage(isSmallScreen);
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return _buildLoadingImage(isSmallScreen, loadingProgress);
                              },
                            )
                          : _buildFallbackImage(isSmallScreen),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackImage(bool isSmallScreen) {
    return Container(
      width: isSmallScreen ? 164 : 204,
      height: isSmallScreen ? 164 : 204,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            AppConstants.favoriteColor.withOpacity(0.2),
            AppConstants.favoriteColor.withOpacity(0.1),
            AppConstants.surfaceColor,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_rounded,
              color: AppConstants.favoriteColor,
              size: isSmallScreen ? 50 : 70,
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            Text(
              'Celebrity',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                fontWeight: FontWeight.w600,
                color: AppConstants.favoriteColor,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingImage(bool isSmallScreen, ImageChunkEvent loadingProgress) {
    return Container(
      width: isSmallScreen ? 164 : 204,
      height: isSmallScreen ? 164 : 204,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            AppConstants.favoriteColor.withOpacity(0.1),
            AppConstants.surfaceColor,
          ],
          stops: const [0.0, 1.0],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      (loadingProgress.expectedTotalBytes ?? 1)
                  : null,
              color: AppConstants.favoriteColor,
              strokeWidth: 3,
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                color: AppConstants.favoriteColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCelebrityHeader(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 20 : 30, 
        vertical: 20
      ),
      child: Column(
        children: [
          Text(
            celebrityName,
            style: TextStyle(
              fontSize: isSmallScreen ? 28 : 32,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppConstants.favoriteColor.withOpacity(0.1),
                  AppConstants.accentColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppConstants.favoriteColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              'Beauty Influencer',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppConstants.favoriteColor,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Discover the secrets behind $celebrityName\'s radiant glow with their exclusive beauty philosophy and skincare routine.',
            style: TextStyle(
              fontSize: isSmallScreen ? 15 : 16,
              color: AppConstants.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonial(bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 20, 
        vertical: 20
      ),
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
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
            size: isSmallScreen ? 30 : 40,
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Text(
            testimonial!,
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 18,
              fontStyle: FontStyle.italic,
              color: AppConstants.textPrimary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Text(
            '— $celebrityName',
            style: TextStyle(
              fontSize: isSmallScreen ? 13 : 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.favoriteColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveRoutineSection(BuildContext context, bool isSmallScreen, bool isMediumScreen) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 0 : 0, 
        vertical: 20
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Complete Beauty Routine',
            style: TextStyle(
              fontSize: isSmallScreen ? 22 : 24,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          
          // Responsive layout: Stack vertically on small screens, side by side on larger screens
          if (isSmallScreen)
            Column(
              children: [
                _buildRoutineSection(context, 'Morning', morningRoutineProducts, isSmallScreen),
                const SizedBox(height: 20),
                _buildRoutineSection(context, 'Evening', eveningRoutineProducts, isSmallScreen),
              ],
            )
          else
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildRoutineSection(context, 'Morning', morningRoutineProducts, isSmallScreen),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildRoutineSection(context, 'Evening', eveningRoutineProducts, isSmallScreen),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRoutineSection(BuildContext context, String title, List<Product> products, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              title == 'Morning' ? Icons.wb_sunny : Icons.nights_stay,
              color: AppConstants.accentColor,
              size: isSmallScreen ? 18 : 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: AppConstants.accentColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (products.isNotEmpty)
          ...products.asMap().entries.map((entry) {
            final index = entry.key;
            final product = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: _buildRoutineProductCard(context, product, index + 1, isSmallScreen),
            );
          }).toList()
        else
          _buildEmptyRoutineCard(isSmallScreen),
      ],
    );
  }

  Widget _buildRoutineProductCard(BuildContext context, Product product, int step, bool isSmallScreen) {
    return GestureDetector(
      onTap: () => _navigateToProduct(context, product),
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 10 : 16),
        decoration: BoxDecoration(
          color: AppConstants.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppConstants.borderColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppConstants.textSecondary.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Step number
              Container(
                width: isSmallScreen ? 22 : 28,
                height: isSmallScreen ? 22 : 28,
                decoration: BoxDecoration(
                  color: AppConstants.accentColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    step.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 11 : 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              SizedBox(width: isSmallScreen ? 10 : 12),
              
              // Product image
              Container(
                width: isSmallScreen ? 35 : 50,
                height: isSmallScreen ? 35 : 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppConstants.borderColor.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: product.images.isNotEmpty
                      ? Image.network(
                          product.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppConstants.surfaceColor,
                              child: Icon(
                                Icons.image_outlined,
                                color: AppConstants.accentColor,
                                size: isSmallScreen ? 14 : 20,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: AppConstants.surfaceColor,
                          child: Icon(
                            Icons.image_outlined,
                            color: AppConstants.accentColor,
                            size: isSmallScreen ? 14 : 20,
                          ),
                        ),
                ),
              ),
              
              SizedBox(width: isSmallScreen ? 8 : 12),
              
              // Product details - Flexible to prevent overflow
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimary,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isSmallScreen ? 2 : 4),
                    Text(
                      '${product.getCurrentPrice().toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} IQD',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10 : 12,
                        color: AppConstants.accentColor,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Tap indicator
              Padding(
                padding: EdgeInsets.only(left: isSmallScreen ? 4 : 8),
                child: Icon(
                  Icons.chevron_right,
                  color: AppConstants.accentColor,
                  size: isSmallScreen ? 14 : 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyRoutineCard(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 16, 
        vertical: isSmallScreen ? 16 : 20
      ),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.borderColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.schedule,
            color: AppConstants.textSecondary,
            size: isSmallScreen ? 20 : 24,
          ),
          const SizedBox(height: 8),
          Text(
            'Routine coming soon',
            style: TextStyle(
              fontSize: isSmallScreen ? 11 : 12,
              color: AppConstants.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveRecommendedProducts(BuildContext context, bool isSmallScreen, bool isMediumScreen) {
    // Calculate grid columns based on screen size
    int crossAxisCount;
    double childAspectRatio;
    double spacing;
    
    if (isSmallScreen) {
      crossAxisCount = 2;
      childAspectRatio = 0.75;
      spacing = 8;
    } else if (isMediumScreen) {
      crossAxisCount = 3;
      childAspectRatio = 0.8;
      spacing = 12;
    } else {
      crossAxisCount = 4;
      childAspectRatio = 0.85;
      spacing = 16;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommended Products',
            style: TextStyle(
              fontSize: isSmallScreen ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          
          // Responsive grid with proper overflow handling
          LayoutBuilder(
            builder: (context, constraints) {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: recommendedProducts.length,
                itemBuilder: (context, index) {
                  final product = recommendedProducts[index];
                  return _buildResponsiveProductCard(context, product, isSmallScreen);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveProductCard(BuildContext context, Product product, bool isSmallScreen) {
    return GestureDetector(
      onTap: () => _navigateToProduct(context, product),
      child: Container(
        decoration: BoxDecoration(
          color: AppConstants.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppConstants.borderColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppConstants.textSecondary.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: product.images.isNotEmpty
                      ? Image.network(
                          product.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppConstants.backgroundColor,
                              child: Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  size: isSmallScreen ? 24 : 32,
                                  color: AppConstants.accentColor,
                                ),
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: AppConstants.backgroundColor,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          (loadingProgress.expectedTotalBytes ?? 1)
                                      : null,
                                  color: AppConstants.accentColor,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: AppConstants.backgroundColor,
                          child: Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: isSmallScreen ? 24 : 32,
                              color: AppConstants.accentColor,
                            ),
                          ),
                        ),
                ),
              ),
            ),
            
            // Product details with proper overflow handling
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.textPrimary,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: isSmallScreen ? 2 : 4),
                          Text(
                            '${product.getCurrentPrice().toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} IQD',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 10 : 11,
                              color: AppConstants.accentColor,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Celebrity Pick badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 4 : 6, 
                        vertical: isSmallScreen ? 2 : 3
                      ),
                      decoration: BoxDecoration(
                        color: AppConstants.favoriteColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppConstants.favoriteColor.withOpacity(0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        'Celebrity Pick',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 8 : 9,
                          color: AppConstants.favoriteColor,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBeautySecrets(bool isSmallScreen) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
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
              fontSize: isSmallScreen ? 22 : 24,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: isSmallScreen ? 160 : 200,
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
                    size: isSmallScreen ? 50 : 60,
                    color: AppConstants.favoriteColor,
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Watch $celebrityName share their beauty tips and secrets.',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        color: AppConstants.textSecondary,
                      ),
                      textAlign: TextAlign.center,
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

  Widget _buildResponsiveSocialMedia(bool isSmallScreen) {
    final availableLinks = <String, Map<String, dynamic>>{};
    
    // Check which social media platforms are available
    if (socialMediaLinks.containsKey('facebook')) {
      availableLinks['facebook'] = {
        'icon': FontAwesomeIcons.facebookF,
        'color': const Color(0xFF1877F2),
        'bgColor': const Color(0xFF1877F2),
        'label': 'Facebook',
        'url': socialMediaLinks['facebook']!,
      };
    }
    
    if (socialMediaLinks.containsKey('instagram')) {
      availableLinks['instagram'] = {
        'icon': FontAwesomeIcons.instagram,
        'color': const Color(0xFFE4405F),
        'bgColor': const Color(0xFFE4405F),
        'label': 'Instagram',
        'url': socialMediaLinks['instagram']!,
      };
    }
    
    if (socialMediaLinks.containsKey('snapchat')) {
      availableLinks['snapchat'] = {
        'icon': FontAwesomeIcons.snapchat,
        'color': const Color(0xFF000000),
        'bgColor': const Color(0xFFFFFC00),
        'label': 'Snapchat',
        'url': socialMediaLinks['snapchat']!,
      };
    }

    if (availableLinks.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 30, 0, 20),
      child: Column(
        children: [
          // Header section
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppConstants.accentColor.withOpacity(0.1),
                  AppConstants.favoriteColor.withOpacity(0.08),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              border: Border.all(
                color: AppConstants.accentColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.share_rounded,
                  color: AppConstants.accentColor,
                  size: isSmallScreen ? 24 : 28,
                ),
                const SizedBox(height: 12),
                Text(
                  'Connect with $celebrityName',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Follow for the latest beauty tips and updates',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 14,
                    color: AppConstants.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // Social media buttons section
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
            decoration: BoxDecoration(
              color: AppConstants.backgroundColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              border: Border(
                left: BorderSide(
                  color: AppConstants.accentColor.withOpacity(0.2),
                  width: 1,
                ),
                right: BorderSide(
                  color: AppConstants.accentColor.withOpacity(0.2),
                  width: 1,
                ),
                bottom: BorderSide(
                  color: AppConstants.accentColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppConstants.textSecondary.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: isSmallScreen ? 12 : 16,
              runSpacing: isSmallScreen ? 12 : 16,
              children: availableLinks.entries.map((entry) {
                return _buildResponsiveSocialButton(
                  entry.key,
                  entry.value['icon'],
                  entry.value['color'],
                  entry.value['bgColor'],
                  entry.value['label'],
                  entry.value['url'],
                  isSmallScreen,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveSocialButton(
    String platform, 
    IconData icon, 
    Color iconColor, 
    Color bgColor, 
    String label, 
    String url,
    bool isSmallScreen,
  ) {
    return GestureDetector(
      onTap: () => _launchSocialMedia(url),
      child: Container(
        width: isSmallScreen ? 100 : 120,
        padding: EdgeInsets.symmetric(
          vertical: isSmallScreen ? 12 : 16, 
          horizontal: isSmallScreen ? 8 : 12
        ),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: platform == 'snapchat' 
                ? Colors.black.withOpacity(0.3)
                : bgColor.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: platform == 'snapchat'
                  ? Colors.black.withOpacity(0.15)
                  : bgColor.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: AppConstants.textSecondary.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon container
            Container(
              width: isSmallScreen ? 40 : 52,
              height: isSmallScreen ? 40 : 52,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: platform == 'snapchat'
                        ? Colors.black.withOpacity(0.4)
                        : bgColor.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: platform == 'snapchat' ? Colors.black : Colors.white,
                size: isSmallScreen ? 18 : 24,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Platform label
            Text(
              label,
              style: TextStyle(
                fontSize: isSmallScreen ? 11 : 13,
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 4),
            
            // Follow indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: platform == 'snapchat' 
                    ? Colors.black.withOpacity(0.1)
                    : bgColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Follow',
                style: TextStyle(
                  fontSize: isSmallScreen ? 9 : 10,
                  color: platform == 'snapchat' 
                      ? Colors.black87
                      : bgColor.withOpacity(0.8),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 