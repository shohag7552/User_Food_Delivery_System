/// A password-recovery step failed for a reason the user can act on.
///
/// [messageKey] is a **translation key**, not a message. Appwrite's error
/// vocabulary (`user_invalid_token`, `general_rate_limit_exceeded`, …) is
/// mapped to one of these inside `AuthRepository` and nowhere else, so the
/// controller and the views never have to know it exists — and the text the
/// user reads follows the app's language like every other string.
class PasswordResetFailure implements Exception {
  final String messageKey;

  const PasswordResetFailure(this.messageKey);

  @override
  String toString() => 'PasswordResetFailure($messageKey)';
}
