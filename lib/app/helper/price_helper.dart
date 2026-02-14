import 'package:appwrite_user_app/app/controllers/settings_controller.dart';
import 'package:get/get.dart';

class PriceHelper {
  /// Format price with dynamic currency symbol from business setup
  static String formatPrice(double price, {int decimalPlaces = 2}) {
    try {
      final settingsController = Get.find<SettingsController>();
      final String currency = settingsController.businessSetup?.currency ?? '\$';
      
      return '$currency${price.toStringAsFixed(decimalPlaces)}';
    } catch (e) {
      // Fallback to default currency if settings controller not found
      return '\$${price.toStringAsFixed(decimalPlaces)}';
    }
  }

  /// Get just the currency symbol
  static String getCurrencySymbol() {
    try {
      final settingsController = Get.find<SettingsController>();
      return settingsController.businessSetup?.currency ?? '\$';
    } catch (e) {
      return '\$';
    }
  }
}
