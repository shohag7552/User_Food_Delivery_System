import 'package:appwrite/models.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_service.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:appwrite_user_app/app/modules/auth/domain/repository/auth_repo_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository implements AuthRepoInterface {
  final SharedPreferences sharedPreferences;
  final AppwriteService appwriteService;
  
  AuthRepository({required this.sharedPreferences, required this.appwriteService});

  // @override
  // Future<bool> auth(String email, String password) async {
  //   // TODO: Implement actual auth logic with Appwrite
  //   // For now, return a placeholder
  //   return true;
  // }

  @override
  Future<void> logout() async {
    // TODO: Implement actual logout logic
    return await appwriteService.signOut();
  }

  @override
  Future<bool> loginAdmin(String email, String password) async {
    try {
      // Attempt to sign in with Appwrite
      bool isSuccess = await appwriteService.signIn(email: email, password: password);
      
      // If successful, show success message
      print('Login successful for: $email');
      return isSuccess;
    } catch (e) {
      // Handle login errors
      String errorMessage = 'Login failed. Please try again.';
      
      if (e.toString().contains('Invalid credentials') || 
          e.toString().contains('401') ||
          e.toString().contains('Invalid email or password')) {
        errorMessage = 'Invalid email or password.';
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        errorMessage = 'Network error. Please check your connection.';
      } else if (e.toString().contains('User not found')) {
        errorMessage = 'No account found with this email.';
      }
      
      print('Login error: $e');
      // Show error toast to user
      // Note: The toast will be shown by the controller/UI layer
      customToster(errorMessage);
      return false;
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    return await appwriteService.isLoggedIn();
  }

  @override
  Future<bool> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
      // 1. Create Appwrite account
      AppWriteResponse data = await appwriteService.signUp(
        email: email,
        password: password,
        name: name,
      );

      print('Signup Response: ${data.response}');
      // 2. Create user document in users collection
      if(data.response.$id.isEmpty) {
        return false;
      }
      await appwriteService.createUserDocument(
        userId: data.response.$id,
        name: name,
        email: email,
        phone: phone,
        role: 'customer',
      );

      return true;
  }

  @override
  Future<User?> getCurrentUser() async {
    return await appwriteService.getCurrentUser();
  }
}
