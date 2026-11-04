import 'package:kikomart_user_app/app/helper/routes/app_router.dart';
import 'package:kikomart_user_app/app/resources/colors.dart';
import 'package:kikomart_user_app/app/resources/constants.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Round back button for wide (web/tablet) auth pages, which have no app
/// bar. Same look as the sign-in page's.
///
/// When there is nothing to pop (the page was opened from a link or a
/// reloaded browser tab) it goes to sign-in instead, so the user is never
/// stuck on the page.
class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        padding: const EdgeInsets.only(bottom: Constants.paddingSizeDefault),
        child: InkWell(
          onTap: () => goBackToSignIn(context),
          borderRadius: BorderRadius.circular(Constants.radiusExtraLarge),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.cardBackground,
              shape: BoxShape.circle,
              border: Border.all(
                color: context.textLight.withValues(alpha: isDark ? 0.35 : 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              // Mirrors itself in right-to-left languages (Arabic).
              Icons.arrow_back_rounded,
              color: context.textPrimary,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

/// Back to the sign-in page, whether the current page was pushed on top of it
/// or opened directly.
void goBackToSignIn(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AppRouter.login);
  }
}
