import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

class SkeletonLoader extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    super.key,
    required this.child,
    this.isLoading = true,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.isLoading) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(SkeletonLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _animationController.repeat();
      } else {
        _animationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + _animation.value * 2, 0.0),
              end: Alignment(1.0 + _animation.value * 2, 0.0),
              colors: [
                AppConstants.borderColor.withValues(alpha: 0.1),
                AppConstants.borderColor.withValues(alpha: 0.3),
                AppConstants.borderColor.withValues(alpha: 0.1),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

class SkeletonCard extends StatelessWidget {
  final bool isSmallScreen;
  final bool isHorizontal;

  const SkeletonCard({
    super.key,
    required this.isSmallScreen,
    this.isHorizontal = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isHorizontal) {
      return Container(
        width: isSmallScreen ? 160 : 180,
        margin: EdgeInsets.only(right: isSmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image skeleton
            Expanded(
              flex: 3,
              child: SkeletonLoader(
                width: double.infinity,
                height: double.infinity,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Container(),
              ),
            ),
            // Content skeleton
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(
                      width: double.infinity,
                      height: isSmallScreen ? 16 : 18,
                      child: Container(),
                    ),
                    const SizedBox(height: 8),
                    SkeletonLoader(
                      width: isSmallScreen ? 80 : 100,
                      height: isSmallScreen ? 14 : 16,
                      child: Container(),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SkeletonLoader(
                          width: isSmallScreen ? 60 : 80,
                          height: isSmallScreen ? 16 : 18,
                          child: Container(),
                        ),
                        SkeletonLoader(
                          width: isSmallScreen ? 40 : 50,
                          height: isSmallScreen ? 16 : 18,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        height: isSmallScreen ? 100 : 120,
        margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image skeleton
            SkeletonLoader(
              width: isSmallScreen ? 100 : 120,
              height: double.infinity,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: Container(),
            ),
            // Content skeleton
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(
                      width: double.infinity,
                      height: isSmallScreen ? 16 : 18,
                      child: Container(),
                    ),
                    const SizedBox(height: 8),
                    SkeletonLoader(
                      width: isSmallScreen ? 120 : 150,
                      height: isSmallScreen ? 14 : 16,
                      child: Container(),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SkeletonLoader(
                          width: isSmallScreen ? 80 : 100,
                          height: isSmallScreen ? 16 : 18,
                          child: Container(),
                        ),
                        SkeletonLoader(
                          width: isSmallScreen ? 50 : 60,
                          height: isSmallScreen ? 16 : 18,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}

class SkeletonSection extends StatelessWidget {
  final String title;
  final bool isSmallScreen;
  final bool isHorizontal;
  final int itemCount;

  const SkeletonSection({
    super.key,
    required this.title,
    required this.isSmallScreen,
    this.isHorizontal = true,
    this.itemCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header skeleton
        Padding(
          padding: EdgeInsets.fromLTRB(
            isSmallScreen ? 16 : 20,
            isSmallScreen ? 24 : 32,
            isSmallScreen ? 16 : 20,
            isSmallScreen ? 16 : 20,
          ),
          child: Row(
            children: [
              SkeletonLoader(
                width: isSmallScreen ? 28 : 32,
                height: isSmallScreen ? 28 : 32,
                borderRadius: BorderRadius.circular(16),
                child: Container(),
              ),
              SizedBox(width: isSmallScreen ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(
                      width: isSmallScreen ? 140 : 170,
                      height: isSmallScreen ? 18 : 20,
                      child: Container(),
                    ),
                    const SizedBox(height: 6),
                    SkeletonLoader(
                      width: isSmallScreen ? 100 : 120,
                      height: isSmallScreen ? 14 : 16,
                      child: Container(),
                    ),
                  ],
                ),
              ),
              SkeletonLoader(
                width: isSmallScreen ? 70 : 90,
                height: isSmallScreen ? 28 : 32,
                borderRadius: BorderRadius.circular(20),
                child: Container(),
              ),
            ],
          ),
        ),

        // Content skeleton
        if (isHorizontal)
          SizedBox(
            height: isSmallScreen ? 280 : 320,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                return SkeletonCard(
                  isSmallScreen: isSmallScreen,
                  isHorizontal: true,
                );
              },
            ),
          )
        else
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20),
            child: Column(
              children: List.generate(itemCount, (index) {
                return SkeletonCard(
                  isSmallScreen: isSmallScreen,
                  isHorizontal: false,
                );
              }),
            ),
          ),
      ],
    );
  }
}

class SkeletonGrid extends StatelessWidget {
  final bool isSmallScreen;
  final int crossAxisCount;
  final int itemCount;

  const SkeletonGrid({
    super.key,
    required this.isSmallScreen,
    this.crossAxisCount = 2,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: isSmallScreen ? 12 : 16,
        mainAxisSpacing: isSmallScreen ? 16 : 20,
        childAspectRatio: isSmallScreen ? 0.7 : 0.75,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return SkeletonCard(
          isSmallScreen: isSmallScreen,
          isHorizontal: true,
        );
      },
    );
  }
} 