import 'package:appwrite/models.dart';

abstract class AuthRepoInterface {
  // Future<bool> auth(String email, String password);
  Future<void> logout();

  /// Permanently closes the current user's account: flags the user row inactive
  /// and blocks the Appwrite auth account (login rejected afterwards).
  Future<void> closeAccount();
  Future<bool> isLoggedIn();
  Future<bool> loginUser(String email, String password);
  Future<bool> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
  });
  Future<User?> getCurrentUser();
  Future<bool> requestPasswordResetOtp(String email);
  Future<bool> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String password,
  });
}
