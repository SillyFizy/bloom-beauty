import 'package:flutter_test/flutter_test.dart';
import '../lib/utils/validators.dart';

void main() {
  group('Iraqi Phone Number Formatting Tests', () {
    test('should format phone number starting with 0', () {
      expect(
        Validators.formatIraqiPhoneNumber('0770123456'),
        equals('+964770123456'),
      );
    });

    test('should format phone number without leading 0', () {
      expect(
        Validators.formatIraqiPhoneNumber('770123456'),
        equals('+964770123456'),
      );
    });

    test('should keep already formatted +964 numbers', () {
      expect(
        Validators.formatIraqiPhoneNumber('+964770123456'),
        equals('+964770123456'),
      );
    });

    test('should add + to 964 numbers', () {
      expect(
        Validators.formatIraqiPhoneNumber('964770123456'),
        equals('+964770123456'),
      );
    });

    test('should handle phone numbers with spaces and formatting', () {
      expect(
        Validators.formatIraqiPhoneNumber('0770 123 456'),
        equals('+964770123456'),
      );
    });

    test('should handle 10-digit numbers starting with 0', () {
      expect(
        Validators.formatIraqiPhoneNumber('0770123456'),
        equals('+964770123456'),
      );
    });

    test('should handle 9-digit numbers without 0', () {
      expect(
        Validators.formatIraqiPhoneNumber('770123456'),
        equals('+964770123456'),
      );
    });
  });

  group('Iraqi Phone Number Validation Tests', () {
    test('should validate correct Iraqi phone number formats', () {
      expect(Validators.validateIraqiPhoneNumber('0770123456'), isNull);
      expect(Validators.validateIraqiPhoneNumber('770123456'), isNull);
      expect(Validators.validateIraqiPhoneNumber('+964770123456'), isNull);
      expect(Validators.validateIraqiPhoneNumber('964770123456'), isNull);
    });

    test('should reject invalid phone number formats', () {
      expect(
        Validators.validateIraqiPhoneNumber('123456'),
        contains('Please enter a valid Iraqi phone number'),
      );
      expect(
        Validators.validateIraqiPhoneNumber(''),
        equals('Phone number is required'),
      );
      expect(
        Validators.validateIraqiPhoneNumber('abc123'),
        contains('Please enter a valid Iraqi phone number'),
      );
    });

    test('should reject phone numbers that are too short', () {
      expect(
        Validators.validateIraqiPhoneNumber('077'),
        contains('Please enter a valid Iraqi phone number'),
      );
    });

    test('should reject phone numbers that are too long', () {
      expect(
        Validators.validateIraqiPhoneNumber('077012345678901'),
        contains('Please enter a valid Iraqi phone number'),
      );
    });
  });
} 