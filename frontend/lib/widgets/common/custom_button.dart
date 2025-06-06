import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

enum ButtonType {
  primary,
  secondary,
  outline,
  text,
}

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final ButtonType type;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.type = ButtonType.primary,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    if (widget.isEnabled && !widget.isLoading) {
      setState(() {
        _isPressed = true;
      });
    }
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
  }

  void _onTapCancel() {
    setState(() {
      _isPressed = false;
    });
  }

  Color get _primaryColor => widget.backgroundColor ?? AppConstants.accentColor;

  @override
  Widget build(BuildContext context) {
    Widget button = _buildButton();

    if (widget.width != null || widget.height != null) {
      button = SizedBox(
        width: widget.width,
        height: widget.height,
        child: button,
      );
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.isEnabled && !widget.isLoading ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: button,
      ),
    );
  }

  Widget _buildButton() {
    switch (widget.type) {
      case ButtonType.primary:
        return _buildPrimaryButton();
      case ButtonType.secondary:
        return _buildSecondaryButton();
      case ButtonType.outline:
        return _buildOutlineButton();
      case ButtonType.text:
        return _buildTextButton();
    }
  }

  Widget _buildPrimaryButton() {
    final backgroundColor = widget.isEnabled
        ? _primaryColor
        : AppConstants.textSecondary.withValues(alpha: 0.3);
    final textColor = widget.textColor ?? Colors.white;

    return Container(
      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(widget.borderRadius ?? 8),
        boxShadow: widget.isEnabled
            ? [
                BoxShadow(
                  color: _primaryColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: _buildButtonContent(textColor),
    );
  }

  Widget _buildSecondaryButton() {
    final backgroundColor = widget.isEnabled
        ? AppConstants.surfaceColor
        : AppConstants.textSecondary.withValues(alpha: 0.1);
    final textColor = widget.textColor ?? AppConstants.textPrimary;

    return Container(
      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(widget.borderRadius ?? 8),
        border: Border.all(
          color: AppConstants.borderColor,
          width: 1,
        ),
      ),
      child: _buildButtonContent(textColor),
    );
  }

  Widget _buildOutlineButton() {
    final borderColor = widget.isEnabled ? _primaryColor : AppConstants.textSecondary;
    final textColor = widget.textColor ?? (widget.isEnabled ? _primaryColor : AppConstants.textSecondary);

    return Container(
      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(widget.borderRadius ?? 8),
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
      ),
      child: _buildButtonContent(textColor),
    );
  }

  Widget _buildTextButton() {
    final textColor = widget.textColor ?? (widget.isEnabled ? _primaryColor : AppConstants.textSecondary);

    return Container(
      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: _buildButtonContent(textColor),
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
          const SizedBox(width: 8),
          Text(
            widget.text,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.7),
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
