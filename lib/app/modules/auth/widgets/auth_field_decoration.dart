import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';

/// Field chrome shared by every auth screen (sign in, forgot password, reset
/// password) so the three stay pixel-identical instead of drifting apart as
/// each one is edited.
///
/// A resting hairline that turns brand-coloured and thicker on focus, so the
/// active field is obvious without shouting.
InputDecoration authInputDecoration(
  BuildContext context, {
  required String hint,
  required IconData icon,
  Widget? suffix,
}) {
  OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(Constants.radiusDefault),
    borderSide: BorderSide(color: color, width: width),
  );

  return InputDecoration(
    hintText: hint,
    hintStyle: poppinsRegular.copyWith(
      fontSize: Constants.fontSizeDefault,
      color: context.textLight,
    ),
    prefixIcon: Icon(icon, color: context.textSecondary),
    suffixIcon: suffix,
    filled: true,
    fillColor: context.cardBackground,
    border: border(context.textLight.withValues(alpha: 0.4), 1),
    enabledBorder: border(context.textLight.withValues(alpha: 0.4), 1),
    focusedBorder: border(ColorResource.primaryDark, 1.5),
    errorBorder: border(ColorResource.error, 1),
    focusedErrorBorder: border(ColorResource.error, 1.5),
    errorStyle: poppinsRegular.copyWith(
      fontSize: Constants.fontSizeExtraSmall,
      color: ColorResource.error,
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: Constants.paddingSizeDefault,
      vertical: Constants.paddingSizeDefault,
    ),
  );
}

/// Label sitting above an auth field, matching [authInputDecoration].
Widget authFieldLabel(BuildContext context, String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: Constants.paddingSizeSmall),
    child: Text(
      text,
      style: poppinsMedium.copyWith(
        fontSize: Constants.fontSizeSmall,
        color: context.textSecondary,
      ),
    ),
  );
}
