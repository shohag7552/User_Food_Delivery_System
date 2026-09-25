import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Address-form input: the label sits above the field (so it never collapses
/// into the border while typing), with a required marker or an "optional" tag,
/// a filled theme-aware surface and a primary focus ring.
class AddressFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final bool isRequired;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final Iterable<String>? autofillHints;

  const AddressFormField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.isRequired = true,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.textCapitalization = TextCapitalization.words,
    this.inputFormatters,
    this.validator,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final borderColor = context.textLight.withValues(alpha: 0.3);

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(Constants.radiusDefault),
          borderSide: BorderSide(color: color, width: width),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: ColorResource.error),
                )
              else
                TextSpan(
                  text: '  (${'optional'.tr})',
                  style: poppinsRegular.copyWith(
                    fontSize: Constants.fontSizeSmall,
                    color: context.textLight,
                  ),
                ),
            ],
          ),
          style: poppinsMedium.copyWith(
            fontSize: Constants.fontSizeSmall + 1,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: Constants.paddingSizeExtraSmall + 2),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          autofillHints: autofillHints,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: poppinsRegular.copyWith(
            fontSize: Constants.fontSizeDefault,
            color: context.textPrimary,
          ),
          cursorColor: primary,
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: poppinsRegular.copyWith(
              fontSize: Constants.fontSizeDefault,
              color: context.textLight,
            ),
            prefixIcon: Icon(icon, size: 20, color: context.textSecondary),
            prefixIconConstraints: const BoxConstraints(
              minWidth: Constants.minTapTarget + Constants.paddingSizeExtraSmall,
              minHeight: Constants.minTapTarget,
            ),
            filled: true,
            fillColor: context.scaffoldBackground,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Constants.paddingSizeDefault,
              vertical: Constants.paddingSizeDefault,
            ),
            errorStyle: poppinsRegular.copyWith(
              fontSize: Constants.fontSizeSmall,
              color: ColorResource.error,
            ),
            border: border(borderColor),
            enabledBorder: border(borderColor),
            focusedBorder: border(primary, 1.5),
            errorBorder: border(ColorResource.error),
            focusedErrorBorder: border(ColorResource.error, 1.5),
          ),
        ),
      ],
    );
  }
}
