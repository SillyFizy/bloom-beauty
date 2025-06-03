import 'package:intl/intl.dart';

class Formatters {
  static String formatPrice(double price) {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(price)} IQD';
  }
  
  static String formatPriceCompact(double price) {
    final formatter = NumberFormat('#,###');
    
    // For very large numbers, use abbreviated format in tight spaces
    if (price >= 1000000000) {
      final billions = price / 1000000000;
      return '${billions.toStringAsFixed(1)}B IQD';
    } else if (price >= 1000000) {
      final millions = price / 1000000;
      return '${millions.toStringAsFixed(1)}M IQD';
    } else if (price >= 100000) {
      final thousands = price / 1000;
      return '${thousands.toStringAsFixed(0)}K IQD';
    } else {
      return '${formatter.format(price)} IQD';
    }
  }
  
  static String formatDate(DateTime date) {
    final formatter = DateFormat('MMM dd, yyyy');
    return formatter.format(date);
  }
  
  static String formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('MMM dd, yyyy hh:mm a');
    return formatter.format(dateTime);
  }
  
  static String formatPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    final digits = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digits.length == 10) {
      return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
    }
    
    return phoneNumber;
  }
  
  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
  
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
