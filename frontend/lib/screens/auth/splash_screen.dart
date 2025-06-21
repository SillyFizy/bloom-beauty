import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_constants.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particleController;
  late AnimationController _shimmerController;
  late AnimationController _logoController;

  late Animation<double> _backgroundAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _titleSlideAnimation;
  late Animation<double> _titleOpacityAnimation;
  late Animation<double> _taglineAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _particleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startLuxurySplashSequence();
  }

  void _initializeAnimations() {
    // Main animation controller for the entire sequence
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1800), // Faster and more responsive
      vsync: this,
    );

    // Particle animation controller
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Shimmer effect controller
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Logo specific controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Background gradient animation
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    ));

    // Logo animations with luxury feel
    _logoScaleAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    // Title slide animation with elegance
    _titleSlideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
    ));

    _titleOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
    ));

    // Tagline animation
    _taglineAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
    ));

    // Shimmer effect animation
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    // Particle animation
    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeOut,
    ));
  }

  void _startLuxurySplashSequence() async {
    try {
      // Start all animations in a coordinated sequence
      _particleController.repeat();
      _shimmerController.repeat();
      
      // Start main animation
      _mainController.forward();
      
      // Delay logo animation slightly for dramatic effect
      await Future.delayed(const Duration(milliseconds: 200));
      _logoController.forward();

      // Wait for the luxury experience to complete (optimized for better UX)
      await Future.delayed(const Duration(milliseconds: 2200)); // Slightly longer for better experience
      
      if (mounted) {
        // Smooth transition with fade out
        await _performSmoothTransition();
      }
    } catch (e) {
      debugPrint('SplashScreen: Error during luxury splash sequence: $e');
      if (mounted) {
        context.go('/home');
      }
    }
  }

  Future<void> _performSmoothTransition() async {
    try {
      // Create a smooth fade transition
      final fadeController = AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      );
      
      final fadeAnimation = Tween<double>(
        begin: 1.0,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: fadeController,
        curve: Curves.easeInOut,
      ));

      // Start fade out
      fadeController.forward();
      
      // Wait for fade to complete halfway, then navigate
      await Future.delayed(const Duration(milliseconds: 250));
      
      if (mounted) {
        context.go('/home');
      }
      
      // Clean up
      fadeController.dispose();
    } catch (e) {
      debugPrint('SplashScreen: Error during transition: $e');
      if (mounted) {
        context.go('/home');
      }
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    _shimmerController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final logoSize = screenSize.width * 0.35;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _mainController,
          _particleController,
          _shimmerController,
          _logoController,
        ]),
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  // Elegant light gradient using app colors
                  Color.lerp(
                    AppConstants.backgroundColor,
                    AppConstants.surfaceColor,
                    _backgroundAnimation.value,
                  )!,
                  Color.lerp(
                    AppConstants.surfaceColor,
                    AppConstants.accentColor.withValues(alpha: 0.05),
                    _backgroundAnimation.value,
                  )!,
                  Color.lerp(
                    AppConstants.backgroundColor,
                    AppConstants.favoriteColor.withValues(alpha: 0.03),
                    _backgroundAnimation.value,
                  )!,
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Luxury particle background
                _buildLuxuryParticles(screenSize),
                
                // Main content
                SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Spacer to push content up slightly
                        const Spacer(flex: 2),
                        
                        // Premium logo with luxury effects
                        _buildLuxuryLogo(logoSize),

                        SizedBox(height: screenSize.height * 0.06),

                        // Elegant app name with shimmer
                        _buildLuxuryTitle(),

                        SizedBox(height: screenSize.height * 0.02),

                        // Sophisticated tagline
                        _buildLuxuryTagline(),

                        const Spacer(flex: 3),

                        // Elegant loading indicator
                        _buildLuxuryLoadingIndicator(),
                        
                        SizedBox(height: screenSize.height * 0.08),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLuxuryParticles(Size screenSize) {
    return Positioned.fill(
      child: CustomPaint(
        painter: LuxuryParticlesPainter(_particleAnimation.value),
      ),
    );
  }

  Widget _buildLuxuryLogo(double logoSize) {
    return Transform.scale(
      scale: _logoScaleAnimation.value,
      child: Opacity(
        opacity: _logoOpacityAnimation.value,
        child: Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              // Multiple shadow layers for depth
              BoxShadow(
                color: AppConstants.accentColor.withValues(alpha: 0.3 * _logoOpacityAnimation.value),
                blurRadius: 30,
                offset: const Offset(0, 15),
                spreadRadius: 5,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2 * _logoOpacityAnimation.value),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: AppConstants.accentColor.withValues(alpha: 0.1 * _logoOpacityAnimation.value),
                blurRadius: 50,
                offset: const Offset(0, 25),
                spreadRadius: 10,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Logo image
              ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.asset(
                  'assets/images/splashScreenicon.png',
                  width: logoSize,
                  height: logoSize,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppConstants.accentColor,
                            AppConstants.accentColor.withValues(alpha: 0.8),
                            AppConstants.favoriteColor.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.spa_outlined,
                        size: logoSize * 0.5,
                        color: AppConstants.surfaceColor,
                      ),
                    );
                  },
                ),
              ),
              
              // Luxury overlay with shimmer effect
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppConstants.surfaceColor.withValues(alpha: 0.3 * _shimmerAnimation.value.abs()),
                        Colors.transparent,
                        AppConstants.accentColor.withValues(alpha: 0.2 * _shimmerAnimation.value.abs()),
                        AppConstants.favoriteColor.withValues(alpha: 0.1 * _shimmerAnimation.value.abs()),
                      ],
                      stops: const [0.0, 0.4, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLuxuryTitle() {
    return Transform.translate(
      offset: Offset(0, _titleSlideAnimation.value),
      child: Opacity(
        opacity: _titleOpacityAnimation.value,
        child: ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                AppConstants.accentColor,
                AppConstants.accentColor.withValues(alpha: 0.9),
                AppConstants.textPrimary,
              ],
              stops: const [0.0, 0.7, 1.0],
            ).createShader(bounds);
          },
          child: Text(
            AppConstants.appName,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w300,
              letterSpacing: 3.0,
              color: AppConstants.textPrimary,
              shadows: [
                Shadow(
                  color: AppConstants.accentColor.withValues(alpha: 0.3),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
                Shadow(
                  color: AppConstants.favoriteColor.withValues(alpha: 0.2),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLuxuryTagline() {
    return Opacity(
      opacity: _taglineAnimation.value,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          'Where Luxury Meets Beauty',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            letterSpacing: 1.5,
            color: AppConstants.textSecondary,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildLuxuryLoadingIndicator() {
    return Opacity(
      opacity: _taglineAnimation.value,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              AppConstants.accentColor.withValues(alpha: 0.15),
              AppConstants.favoriteColor.withValues(alpha: 0.1),
            ],
          ),
          border: Border.all(
            color: AppConstants.borderColor,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppConstants.accentColor,
            ),
          ),
        ),
      ),
    );
  }
}

class LuxuryParticlesPainter extends CustomPainter {
  final double animationValue;
  
  LuxuryParticlesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Create floating elegant particles using app colors
    for (int i = 0; i < 15; i++) {
      final double x = (size.width * (i * 0.1 + 0.1)) + 
                      (math.sin(animationValue * 2 * math.pi + i) * 25);
      final double y = (size.height * (i * 0.07 + 0.1)) + 
                      (math.cos(animationValue * 2 * math.pi + i) * 35);
      
      final double radius = 1.5 + math.sin(animationValue * math.pi + i) * 0.8;
      
      // Alternate between golden and pink particles
      final Color particleColor = i % 3 == 0 
        ? AppConstants.favoriteColor.withValues(
            alpha: 0.03 + (math.sin(animationValue * math.pi + i) * 0.04).abs()
          )
        : AppConstants.accentColor.withValues(
            alpha: 0.04 + (math.sin(animationValue * math.pi + i) * 0.06).abs()
          );
      
      canvas.drawCircle(
        Offset(x % size.width, y % size.height),
        radius,
        paint..color = particleColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
