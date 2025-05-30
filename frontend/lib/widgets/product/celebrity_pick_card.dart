import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/product_model.dart';

class CelebrityPickCard extends StatefulWidget {
  final Product product;
  final String celebrityName;
  final String celebrityImage;
  final String? testimonial;
  final VoidCallback? onTap;
  final int index;

  const CelebrityPickCard({
    super.key,
    required this.product,
    required this.celebrityName,
    required this.celebrityImage,
    this.testimonial,
    this.onTap,
    required this.index,
  });

  @override
  State<CelebrityPickCard> createState() => _CelebrityPickCardState();
}

class _CelebrityPickCardState extends State<CelebrityPickCard>
    with TickerProviderStateMixin {
  late AnimationController _primaryController;
  late AnimationController _shimmerController;
  
  // Primary entrance animations
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotateAnimation;
  
  // Shimmer/highlight animation
  late Animation<double> _shimmerAnimation;
  late Animation<Offset> _shimmerPositionAnimation;
  
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startEntranceAnimation();
  }

  void _initializeAnimations() {
    // Primary controller for entrance animations
    _primaryController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    // Shimmer controller for premium feel
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Entrance animations with faster, snappier curves
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _primaryController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _primaryController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _primaryController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));

    _rotateAnimation = Tween<double>(
      begin: -0.05,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _primaryController,
      curve: const Interval(0.1, 0.8, curve: Curves.easeOutBack),
    ));

    // Shimmer animations for premium feel
    _shimmerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    _shimmerPositionAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: const Offset(1.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
  }

  void _startEntranceAnimation() {
    Future.delayed(Duration(milliseconds: widget.index * 30), () {
      if (mounted) {
        _primaryController.forward();
        
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            _shimmerController.repeat(reverse: true);
          }
        });
      }
    });
  }

  void _handleTapDown() {
    setState(() => _isPressed = true);
  }

  void _handleTapUp() {
    setState(() => _isPressed = false);
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _handleTapDown(),
      onTapUp: (_) => _handleTapUp(),
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _primaryController,
          _shimmerController,
        ]),
        builder: (context, child) {
          // Clamp animation values to prevent assertion failures
          final scaleValue = (_scaleAnimation.value * (_isPressed ? 0.98 : 1.0)).clamp(0.0, 2.0);
          final fadeValue = _fadeAnimation.value.clamp(0.0, 1.0);
          final rotateValue = _rotateAnimation.value.clamp(-1.0, 1.0);
          final shimmerValue = _shimmerAnimation.value.clamp(0.0, 1.0);
          
          return Transform.rotate(
            angle: rotateValue,
            child: Transform.scale(
              scale: scaleValue,
              child: SlideTransition(
                position: _slideAnimation,
                child: Opacity(
                  opacity: fadeValue,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: AppConstants.accentColor.withOpacity(0.1),
                          blurRadius: 40,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppConstants.surfaceColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Background gradient
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppConstants.accentColor.withOpacity(0.05),
                                    AppConstants.favoriteColor.withOpacity(0.05),
                                    Colors.transparent,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  stops: const [0.0, 0.3, 1.0],
                                ),
                              ),
                            ),
                            
                            // Product display area
                            Positioned.fill(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    // Product icon/image placeholder
                                    Expanded(
                                      flex: 3,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              AppConstants.accentColor.withOpacity(0.15),
                                              AppConstants.favoriteColor.withOpacity(0.15),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.spa_rounded,
                                            size: 42,
                                            color: AppConstants.accentColor.withOpacity(0.8),
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 12),
                                    
                                    // Product name
                                    Flexible(
                                      child: Text(
                                        widget.product.name,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppConstants.textPrimary,
                                          height: 1.2,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Celebrity pick badge - top right
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppConstants.accentColor,
                                      AppConstants.accentColor.withOpacity(0.8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppConstants.accentColor.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      size: 10,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 3),
                                    Flexible(
                                      child: Text(
                                        widget.celebrityName.split(' ')[0],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.3,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Celebrity info bottom section
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.black.withOpacity(0.8),
                                      Colors.black.withOpacity(0.4),
                                      Colors.transparent,
                                    ],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Celebrity avatar
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            AppConstants.accentColor,
                                            AppConstants.favoriteColor,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          widget.celebrityName[0],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                    const SizedBox(width: 10),
                                    
                                    // Celebrity name
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            widget.celebrityName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.2,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            'Celebrity Pick',
                                            style: TextStyle(
                                              color: AppConstants.accentColor.withOpacity(0.9),
                                              fontSize: 9,
                                              fontWeight: FontWeight.w500,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Shimmer overlay for premium feel
                            if (shimmerValue > 0)
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Transform.translate(
                                    offset: Offset(
                                      _shimmerPositionAnimation.value.dx * 200,
                                      0,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            Colors.white.withOpacity(0.1 * shimmerValue),
                                            Colors.white.withOpacity(0.2 * shimmerValue),
                                            Colors.white.withOpacity(0.1 * shimmerValue),
                                            Colors.transparent,
                                          ],
                                          stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
                                          begin: const Alignment(-1.0, -0.3),
                                          end: const Alignment(1.0, 0.3),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            
                            // Touch feedback overlay
                            if (_isPressed)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
} 