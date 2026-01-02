import 'package:appwrite_user_app/app/appwrite/appwrite_service.dart';
import 'package:appwrite_user_app/app/modules/login/domain/repository/auth_repo_interface.dart';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository implements AuthRepoInterface {
  final SharedPreferences sharedPreferences;
  final AppwriteService appwriteService;
  
  AuthRepository({required this.sharedPreferences, required this.appwriteService});

  // @override
  // Future<bool> login(String email, String password) async {
  //   // TODO: Implement actual login logic with Appwrite
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
    return await appwriteService.loginAdmin(email, password);
  }

  @override
  Future<bool> isLoggedIn() async {
    // TODO: Check if user is logged in
    return await appwriteService.isLoggedIn();
  }
}
