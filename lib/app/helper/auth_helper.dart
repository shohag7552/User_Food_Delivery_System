import 'package:appwrite/models.dart';
import 'package:appwrite_user_app/app/controllers/auth_controller.dart';
import 'package:get/get.dart';

class AuthHelper {
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(email);
  }

  static bool isStrongPassword(String password) {
    // At least 8 characters, one uppercase, one lowercase, one number, one special character
    final passwordRegex = RegExp(
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
    return passwordRegex.hasMatch(password);
  }

  static Future<String?> getUserId() async {
    // Placeholder for actual user ID retrieval logic
    return Get.find<AuthController>().getUserId();
  }
}