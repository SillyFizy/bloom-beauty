class Validators {
  /// Format and validate Iraqi phone numbers
  static String formatIraqiPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters except +
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // If it already starts with +964, return as is
    if (cleaned.startsWith('+964')) {
      return cleaned;
    }
    
    // If it starts with 964, add + prefix
    if (cleaned.startsWith('964')) {
      return '+$cleaned';
    }
    
    // If it starts with 0, remove the 0 and add +964
    if (cleaned.startsWith('0')) {
      return '+964${cleaned.substring(1)}';
    }
    
    // If it's just the local number (without 0), add +964
    if (cleaned.length >= 9 && cleaned.length <= 10) {
      return '+964$cleaned';
    }
    
    // Return original if can't format
    return phoneNumber;
  }

  /// Validate Iraqi phone number
  static String? validateIraqiPhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Try to format the number
    String formatted = formatIraqiPhoneNumber(value);
    
    // Check if it matches the expected Iraqi format
    final iraqiPhoneRegex = RegExp(r'^\+964[0-9]{9,10}$');
    if (!iraqiPhoneRegex.hasMatch(formatted)) {
      return 'Please enter a valid Iraqi phone number\n(e.g., 0770000000 or 770000000)';
    }
    
    return null;
  }

  /// Validate phone number
  static String? validatePhoneNumber(String? value) {
    // Use Iraqi phone validation for this app
    return validateIraqiPhoneNumber(value);
  }

  /// Validate name (first name, last name)
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters long';
    }
    
    // Check for valid name characters (letters, spaces, hyphens, apostrophes)
    final nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");
    if (!nameRegex.hasMatch(value.trim())) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }
    
    return null;
  }

  /// Validate email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  /// Validate password (for login)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    return null;
  }

  /// Validate new password (for registration)
  static String? validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    
    // Check for at least one uppercase letter
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    
    // Check for at least one lowercase letter
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    
    // Check for at least one digit
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    
    return null;
  }

  /// Validate confirm password
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  /// Validate address
  static String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Address is required';
    }
    
    if (value.trim().length < 5) {
      return 'Please enter a valid address';
    }
    
    return null;
  }

  /// Validate city
  static String? validateCity(String? value) {
    if (value == null || value.isEmpty) {
      return 'City is required';
    }
    
    if (value.trim().length < 2) {
      return 'Please enter a valid city name';
    }
    
    return null;
  }

  /// Validate postal code
  static String? validatePostalCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Postal code is required';
    }
    
    // Basic postal code validation (can be customized for different countries)
    final postalRegex = RegExp(r'^[a-zA-Z0-9\s\-]{3,10}$');
    if (!postalRegex.hasMatch(value.trim())) {
      return 'Please enter a valid postal code';
    }
    
    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    return null;
  }

  /// Validate minimum length
  static String? validateMinLength(String? value, int minLength, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters long';
    }
    
    return null;
  }

  /// Validate maximum length
  static String? validateMaxLength(String? value, int maxLength, String fieldName) {
    if (value != null && value.length > maxLength) {
      return '$fieldName must be no more than $maxLength characters long';
    }
    
    return null;
  }

  /// Validate numeric value
  static String? validateNumeric(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    if (double.tryParse(value) == null) {
      return '$fieldName must be a valid number';
    }
    
    return null;
  }
}
