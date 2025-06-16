import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/wishlist_provider.dart';
import '../../constants/app_constants.dart';

class WishlistButton extends StatefulWidget {
  final Product product;
  final double? size;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? backgroundColor;
  final bool showBackground;
  final bool showShadow;
  final String? heroTag;
  final VoidCallback? onPressed;
  final bool isCompact;

  const WishlistButton({
    super.key,
    required this.product,
    this.size,
    this.activeColor,
    this.inactiveColor,
    this.backgroundColor,
    this.showBackground = true,
    this.showShadow = true,
    this.heroTag,
    this.onPressed,
    this.isCompact = false,
  });

  @override
  State<WishlistButton> createState() => _WishlistButtonState();
}

class _WishlistButtonState extends State<WishlistButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleWishlistToggle() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    // Call custom onPressed if provided
    widget.onPressed?.call();

    // Haptic feedback
    await HapticFeedback.lightImpact();

    // Animate button
    await _animationController.forward();
    await _animationController.reverse();

    try {
      final wishlistProvider = context.read<WishlistProvider>();

      final success = await wishlistProvider.toggleWishlist(widget.product);

      if (success && mounted && context.mounted) {
        final isNowInWishlist =
            wishlistProvider.isInWishlist(widget.product.id);

        // Show feedback message
        final message =
            isNowInWishlist ? 'Added to wishlist' : 'Removed from wishlist';

        final snackBarColor = isNowInWishlist
            ? AppConstants.favoriteColor
            : AppConstants.textSecondary;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isNowInWishlist ? Icons.favorite : Icons.favorite_border,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: snackBarColor,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        );
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating wishlist: $e'),
            backgroundColor: AppConstants.errorColor,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WishlistProvider>(
      builder: (context, wishlistProvider, child) {
        final isInWishlist = wishlistProvider.isInWishlist(widget.product.id);
        final buttonSize = widget.size ?? (widget.isCompact ? 20.0 : 24.0);
        final containerSize = widget.isCompact ? 28.0 : 32.0;

        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: GestureDetector(
                  onTap: _isProcessing ? null : _handleWishlistToggle,
                  child: Hero(
                    tag: widget.heroTag ?? 'wishlist_${widget.product.id}',
                    child: Container(
                      width: widget.showBackground ? containerSize : null,
                      height: widget.showBackground ? containerSize : null,
                      decoration: widget.showBackground
                          ? BoxDecoration(
                              color: widget.backgroundColor ??
                                  (isInWishlist
                                      ? AppConstants.favoriteColor
                                          .withValues(alpha: 0.1)
                                      : Colors.white.withValues(alpha: 0.9)),
                              shape: BoxShape.circle,
                              boxShadow: widget.showShadow
                                  ? [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            )
                          : null,
                      child: _isProcessing
                          ? Center(
                              child: SizedBox(
                                width: buttonSize * 0.7,
                                height: buttonSize * 0.7,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    widget.activeColor ??
                                        AppConstants.favoriteColor,
                                  ),
                                ),
                              ),
                            )
                          : Icon(
                              isInWishlist
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: buttonSize,
                              color: isInWishlist
                                  ? (widget.activeColor ??
                                      AppConstants.favoriteColor)
                                  : (widget.inactiveColor ??
                                      AppConstants.textSecondary),
                            ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Compact version of wishlist button for use in tight spaces
class CompactWishlistButton extends StatelessWidget {
  final Product product;
  final double? size;
  final Color? activeColor;
  final Color? inactiveColor;

  const CompactWishlistButton({
    super.key,
    required this.product,
    this.size,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return WishlistButton(
      product: product,
      size: size ?? 18,
      activeColor: activeColor,
      inactiveColor: inactiveColor,
      showBackground: false,
      showShadow: false,
      isCompact: true,
    );
  }
}

/// Floating wishlist button for product detail screens
class FloatingWishlistButton extends StatelessWidget {
  final Product product;
  final VoidCallback? onPressed;

  const FloatingWishlistButton({
    super.key,
    required this.product,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<WishlistProvider>(
      builder: (context, wishlistProvider, child) {
        final isSmallScreen = MediaQuery.of(context).size.width < 600;

        return Container(
          width: isSmallScreen ? 44 : 52,
          height: isSmallScreen ? 44 : 52,
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
            border: Border.all(
              color: AppConstants.borderColor.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppConstants.textSecondary.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.05),
                blurRadius: 1,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
            child: Material(
              color: Colors.transparent,
              child: Center(
                child: WishlistButton(
                  product: product,
                  size: isSmallScreen ? 20 : 24,
                  onPressed: onPressed,
                  showBackground: false,
                  showShadow: false,
                  heroTag: 'floating_wishlist_${product.id}',
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
