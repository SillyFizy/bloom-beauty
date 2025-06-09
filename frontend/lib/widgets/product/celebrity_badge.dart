import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../constants/app_constants.dart';
import '../../models/product_model.dart';

class CelebrityBadge extends StatelessWidget {
  final CelebrityEndorsement endorsement;
  final bool isSmallScreen;
  final VoidCallback? onTap;

  const CelebrityBadge({
    super.key,
    required this.endorsement,
    this.isSmallScreen = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final badgeSize = isSmallScreen ? 32.0 : 36.0;
    final fontSize = isSmallScreen ? 10.0 : 11.0;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 6 : 8,
          vertical: isSmallScreen ? 4 : 5,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppConstants.accentColor,
              AppConstants.accentColor.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 18),
          boxShadow: [
            BoxShadow(
              color: AppConstants.accentColor.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Celebrity avatar
            Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 1.5,
                ),
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: endorsement.celebrityImage,
                  fit: BoxFit.cover,
                  memCacheWidth: (badgeSize * 2).round(),
                  memCacheHeight: (badgeSize * 2).round(),
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      color: Colors.white,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppConstants.backgroundColor,
                    child: Icon(
                      Icons.person,
                      size: badgeSize * 0.6,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            
            SizedBox(width: isSmallScreen ? 5 : 6),
            
            // "Pick" text
            Text(
              'PICK',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CelebrityBadgeSimple extends StatelessWidget {
  final String celebrityName;
  final bool isSmallScreen;
  final VoidCallback? onTap;

  const CelebrityBadgeSimple({
    super.key,
    required this.celebrityName,
    this.isSmallScreen = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = isSmallScreen ? 8.0 : 9.0;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 4 : 6,
          vertical: isSmallScreen ? 2 : 3,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppConstants.accentColor,
              AppConstants.accentColor.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
          boxShadow: [
            BoxShadow(
              color: AppConstants.accentColor.withValues(alpha: 0.3),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_rounded,
              size: isSmallScreen ? 10 : 12,
              color: Colors.white,
            ),
            SizedBox(width: isSmallScreen ? 2 : 3),
            Text(
              'PICK',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
