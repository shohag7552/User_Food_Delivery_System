import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';

/// Terminal state of an auth flow — "check your inbox", "this link doesn't
/// work", "password updated".
///
/// One widget for all three so a success and a failure are laid out the same
/// way and only the icon, colour and copy change; the flow never appears to
/// jump to a different kind of page depending on the outcome.
class AuthStatusPanel extends StatelessWidget {
  final IconData icon;

  /// Defaults to the brand colour; pass [ColorResource.error] for failures.
  final Color? iconColor;
  final String title;
  final String message;

  /// Optional supporting line under [message] — e.g. the link's expiry.
  final String? footnote;

  final String? primaryLabel;
  final VoidCallback? onPrimary;

  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// Disables [onSecondary] while a cooldown is running, without removing the
  /// button — the label carries the remaining time.
  final bool secondaryEnabled;

  const AuthStatusPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.iconColor,
    this.footnote,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.secondaryEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final accent = iconColor ?? ColorResource.primaryDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: Constants.iconCircleSize,
            height: Constants.iconCircleSize,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: Constants.iconSizeLarge, color: accent),
          ),
        ),
        const SizedBox(height: Constants.paddingSizeLarge),
        Text(
          title,
          textAlign: TextAlign.center,
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeExtraLarge,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: Constants.paddingSizeSmall),
        Text(
          message,
          textAlign: TextAlign.center,
          style: poppinsRegular.copyWith(
            fontSize: Constants.fontSizeDefault,
            color: context.textSecondary,
            height: 1.5,
          ),
        ),
        if (footnote != null) ...[
          const SizedBox(height: Constants.paddingSizeSmall),
          Text(
            footnote!,
            textAlign: TextAlign.center,
            style: poppinsRegular.copyWith(
              fontSize: Constants.fontSizeSmall,
              color: context.textLight,
            ),
          ),
        ],
        if (primaryLabel != null) ...[
          const SizedBox(height: Constants.paddingSizeExtraLarge),
          SizedBox(
            height: Constants.minTapTarget + Constants.paddingSizeDefault,
            child: ElevatedButton(
              onPressed: onPrimary,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorResource.primaryDark,
                foregroundColor: ColorResource.textWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Constants.radiusDefault),
                ),
              ),
              child: Text(
                primaryLabel!,
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeLarge,
                  color: ColorResource.textWhite,
                ),
              ),
            ),
          ),
        ],
        if (secondaryLabel != null) ...[
          const SizedBox(height: Constants.paddingSizeSmall),
          TextButton(
            onPressed: secondaryEnabled ? onSecondary : null,
            style: TextButton.styleFrom(
              foregroundColor: ColorResource.primaryDark,
              disabledForegroundColor: context.textLight,
            ),
            child: Text(
              secondaryLabel!,
              style: poppinsMedium.copyWith(
                fontSize: Constants.fontSizeDefault,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
