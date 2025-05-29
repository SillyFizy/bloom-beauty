import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

enum ButtonVariant { primary, secondary, outline, text }

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final bool isExpanded;
  final IconData? icon;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.isExpanded = true,
    this.icon,
    this.color,
    this.padding,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
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

  Color get _primaryColor => widget.color ?? AppConstants.accentColor;

  @override
  Widget build(BuildContext context) {
    Widget button = _buildButton();

    if (widget.isExpanded) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: button,
        );
      },
    );
  }

  Widget _buildButton() {
    switch (widget.variant) {
      case ButtonVariant.primary:
        return _buildPrimaryButton();
      case ButtonVariant.secondary:
        return _buildSecondaryButton();
      case ButtonVariant.outline:
        return _buildOutlineButton();
      case ButtonVariant.text:
        return _buildTextButton();
    }
  }

  Widget _buildPrimaryButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
        gradient: LinearGradient(
          colors: [
            _primaryColor,
            _primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isLoading ? null : widget.onPressed,
          onTapDown: widget.isLoading ? null : (_) => _animationController.forward(),
          onTapUp: widget.isLoading ? null : (_) => _animationController.reverse(),
          onTapCancel: widget.isLoading ? null : () => _animationController.reverse(),
          borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
          child: Container(
            padding: widget.padding ??
                const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: _buildButtonContent(Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
        color: _primaryColor.withOpacity(0.1),
        border: Border.all(
          color: _primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isLoading ? null : widget.onPressed,
          onTapDown: widget.isLoading ? null : (_) => _animationController.forward(),
          onTapUp: widget.isLoading ? null : (_) => _animationController.reverse(),
          onTapCancel: widget.isLoading ? null : () => _animationController.reverse(),
          borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
          child: Container(
            padding: widget.padding ??
                const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: _buildButtonContent(_primaryColor),
          ),
        ),
      ),
    );
  }

  Widget _buildOutlineButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
        border: Border.all(
          color: _primaryColor,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isLoading ? null : widget.onPressed,
          onTapDown: widget.isLoading ? null : (_) => _animationController.forward(),
          onTapUp: widget.isLoading ? null : (_) => _animationController.reverse(),
          onTapCancel: widget.isLoading ? null : () => _animationController.reverse(),
          borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
          child: Container(
            padding: widget.padding ??
                const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: _buildButtonContent(_primaryColor),
          ),
        ),
      ),
    );
  }

  Widget _buildTextButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.isLoading ? null : widget.onPressed,
        onTapDown: widget.isLoading ? null : (_) => _animationController.forward(),
        onTapUp: widget.isLoading ? null : (_) => _animationController.reverse(),
        onTapCancel: widget.isLoading ? null : () => _animationController.reverse(),
        borderRadius: BorderRadius.circular(widget.borderRadius ?? 8),
        child: Container(
          padding: widget.padding ??
              const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: _buildButtonContent(_primaryColor),
        ),
      ),
    );
  }

  Widget _buildButtonContent(Color textColor) {
    if (widget.isLoading) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Loading...',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    if (widget.icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.icon,
            color: textColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            widget.text,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Text(
      widget.text,
      style: TextStyle(
        color: textColor,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.center,
    );
  }
}
