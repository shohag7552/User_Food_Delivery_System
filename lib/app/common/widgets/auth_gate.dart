import 'package:appwrite_user_app/app/common/widgets/auth_dialog.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_button.dart';
import 'package:appwrite_user_app/app/controllers/auth_controller.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Global login gate for screens/sections that require an account.
///
/// Wrap a page's *body* (not the whole Scaffold — we keep the app bar / nav so
/// the user can move around and sign in): shows [child] when the user is signed
/// in, otherwise a friendly [LoginRequiredView]. Reacts to auth changes via the
/// cached `AuthController.isLoggedIn` flag, so it flips automatically on
/// login / logout.
///
/// ```dart
/// body: AuthGate(child: _buildRealBody()),
/// ```
class AuthGate extends StatelessWidget {
  final Widget child;

  /// Optional custom prompt (defaults to a generic "sign in" message).
  final String? message;

  const AuthGate({super.key, required this.child, this.message});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      builder: (auth) =>
          auth.isLoggedIn ? child : LoginRequiredView(message: message),
    );
  }
}

/// The "please log in" content: an icon, a short message and a Login button.
/// Usable on its own where a full [AuthGate] isn't needed.
class LoginRequiredView extends StatelessWidget {
  final String? message;

  const LoginRequiredView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: ColorResource.primaryDark.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                size: 46,
                color: ColorResource.primaryDark,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'login_required'.tr,
              textAlign: TextAlign.center,
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeExtraLarge,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message ?? 'login_to_access_this_section'.tr,
              textAlign: TextAlign.center,
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 220,
              child: CustomButton(
                buttonText: 'login'.tr,
                onPressed: () => AuthFlow.openLogin(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
