import 'package:appwrite/models.dart';

abstract class AuthRepoInterface {
  // Future<bool> auth(String email, String password);
  Future<void> logout();
  Future<bool> isLoggedIn();
  Future<bool> loginAdmin(String email, String password);
  Future<bool> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
  });
  Future<User?> getCurrentUser();
}
