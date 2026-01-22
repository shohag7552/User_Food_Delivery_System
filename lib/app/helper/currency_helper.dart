import 'package:appwrite_user_app/app/controllers/settings_controller.dart';
import 'package:appwrite_user_app/app/controllers/splash_controller.dart';
import 'package:get/get.dart';

/// Centralized currency formatting helper
/// Uses business setup data to format amounts consistently across the app
class CurrencyHelper {
  /// Get currency symbol from business setup
  /// Falls back to '$' if business setup is not available
  static String getCurrencySymbol() {
    // Try to get from business setup
    // Note: This assumes you have a BusinessSetupController
    // If you don't have one, we'll use a default symbol
    try {
      // Uncomment when BusinessSetupController is available:
      final businessSetup = Get.find<SettingsController>().businessSetup;
      return businessSetup?.currency ?? '\$';
      
      // For now, using default
      return '\$';
    } catch (e) {
      return '\$'; // Default fallback
    }
  }

  /// Format amount with currency symbol
  /// Example: formatAmount(10.50) => "$10.50"
  static String formatAmount(double amount, {int decimalPlaces = 2}) {
    final symbol = getCurrencySymbol();
    return '$symbol${amount.toStringAsFixed(decimalPlaces)}';
  }

  /// Format amount without decimal if it's a whole number
  /// Example: formatAmountSmart(10.00) => "$10", formatAmountSmart(10.50) => "$10.50"
  static String formatAmountSmart(double amount) {
    final symbol = getCurrencySymbol();
    if (amount == amount.roundToDouble()) {
      return '$symbol${amount.toInt()}';
    }
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  /// Get just the numeric part formatted
  /// Example: formatNumeric(10.50) => "10.50"
  static String formatNumeric(double amount, {int decimalPlaces = 2}) {
    return amount.toStringAsFixed(decimalPlaces);
  }

  /// Parse currency string to double
  /// Example: parseAmount("$10.50") => 10.50
  static double parseAmount(String amountString) {
    // Remove currency symbol and any spaces
    final symbol = getCurrencySymbol();
    String cleaned = amountString
        .replaceAll(symbol, '')
        .replaceAll(' ', '')
        .replaceAll(',', '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  /// Format with thousand separators
  /// Example: formatWithSeparators(1000.50) => "$1,000.50"
  static String formatWithSeparators(double amount) {
    final symbol = getCurrencySymbol();
    final parts = amount.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];
    
    // Add thousand separators
    String formatted = '';
    int count = 0;
    for (int i = integerPart.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        formatted = ',$formatted';
      }
      formatted = integerPart[i] + formatted;
      count++;
    }
    
    return '$symbol$formatted.$decimalPart';
  }
}
