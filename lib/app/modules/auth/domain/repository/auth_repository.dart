import 'package:appwrite_user_app/app/appwrite/appwrite_service.dart';
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

  // @override
  // Future<bool> logout() async {
  //   // TODO: Implement actual logout logic
  //   return true;
  // }

  @override
  Future<bool> loginAdmin(String email, String password) async {
    return false;
  }

  @override
  Future<bool> isLoggedIn() async {
    // TODO: Check if user is logged in
    return await appwriteService.isLoggedIn();
  }

  @override
  Future<bool> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      // 1. Create Appwrite account
      final user = await appwriteService.signUp(
        email: email,
        password: password,
        name: name,
      );

      // 2. Create user document in users collection
      await appwriteService.createUserDocument(
        userId: user.$id,
        name: name,
        email: email,
        phone: phone,
        role: 'customer',
      );

      return true;
    } catch (e) {
      print('Signup error in repository: $e');
      return false;
    }
  }
}
