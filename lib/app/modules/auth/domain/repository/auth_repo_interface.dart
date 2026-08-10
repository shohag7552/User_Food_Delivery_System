import 'package:appwrite/models.dart';
import 'package:appwrite_user_app/app/modules/auth/domain/services/password_reset_failure.dart';

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

  /// Asks Appwrite to email a password-reset link.
  ///
  /// Returns normally both when the mail was accepted **and** when no account
  /// matches the address — callers must show the same neutral message either
  /// way, or the form becomes a way to discover who has an account.
  ///
  /// Throws [PasswordResetFailure] for anything the user can act on.
  Future<void> sendPasswordResetLink(String email);

  /// Sets a new password from the `userId`/`secret` carried by the emailed
  /// link. Needs no session — this runs for a signed-out user.
  ///
  /// Throws [PasswordResetFailure] when the link is invalid or expired, or the
  /// password is rejected by the project's password policy.
  Future<void> resetPasswordWithLink({
    required String userId,
    required String secret,
    required String password,
  });

  /// Stores the sign-in credentials on the device so the login form can
  /// prefill them next time. Survives logout by design.
  Future<void> saveRememberedCredentials({
    required String email,
    required String password,
  });

  /// Forgets any device-stored credentials (the user unticked "remember me").
  Future<void> clearRememberedCredentials();

  /// The remembered credentials, or null when "remember me" is off. Reads from
  /// already-loaded local storage, so it is synchronous.
  ({String email, String password})? getRememberedCredentials();

  Future<bool> updatePassword({
    required String password,
    required String oldPassword,
  });
}
