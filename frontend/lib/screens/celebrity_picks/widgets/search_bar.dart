import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';

class CelebrityPicksSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final VoidCallback onClear;

  const CelebrityPicksSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return Container(
      margin: EdgeInsets.all(isSmallScreen ? 12 : 16),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search celebrity picks...',
          hintStyle: TextStyle(
            color: AppConstants.textSecondary.withOpacity(0.6),
            fontSize: isSmallScreen ? 14 : 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppConstants.textSecondary.withOpacity(0.6),
            size: isSmallScreen ? 20 : 24,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: AppConstants.textSecondary,
                    size: isSmallScreen ? 20 : 24,
                  ),
                  onPressed: onClear,
                )
              : null,
          filled: true,
          fillColor: AppConstants.surfaceColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 25),
            borderSide: BorderSide(
              color: AppConstants.borderColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 25),
            borderSide: BorderSide(
              color: AppConstants.borderColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 25),
borderSide: const BorderSide(

              color: AppConstants.accentColor,
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16 : 20,
            vertical: isSmallScreen ? 12 : 16,
          ),
        ),
        style: TextStyle(
          color: AppConstants.textPrimary,
          fontSize: isSmallScreen ? 14 : 16,
        ),
      ),
    );
  }
} 
