import 'package:kikomart_user_app/app/resources/colors.dart';
import 'package:kikomart_user_app/app/resources/constants.dart';
import 'package:kikomart_user_app/app/resources/images.dart';
import 'package:kikomart_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';

/// Logo, title and subtitle at the top of the password-recovery screens.
/// Laid out exactly like the sign-in page's header, so the flow looks like
/// one set of pages.
class AuthHeader extends StatelessWidget {
  final String? title;
  final String? subtitle;

  const AuthHeader({super.key, this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: Constants.paddingSizeSmall),
        ClipRRect(
          borderRadius: BorderRadius.circular(Constants.radiusExtraLarge),
          child: Image.asset(Images.logo, width: 76, fit: BoxFit.cover),
        ),
        if (title != null) ...[
          const SizedBox(height: Constants.paddingSizeLarge),
          Text(
            title!,
            textAlign: TextAlign.center,
            style: poppinsBold.copyWith(
              fontSize: Constants.fontSizeOverLarge,
              color: context.textPrimary,
            ),
          ),
        ],
        if (subtitle != null) ...[
          const SizedBox(height: Constants.paddingSizeExtraSmall),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: poppinsRegular.copyWith(
              fontSize: Constants.fontSizeDefault,
              color: context.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
