import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Sticky footer holding the save action, pinned to the bottom of the page so
/// it stays reachable however far the form is scrolled.
///
/// Mobile: a single full-width button. Web: the bar spans the viewport but its
/// content is capped to [maxContentWidth], with Cancel + Save aligned to the
/// end — the standard web form-footer layout.
class AddressSaveBar extends StatelessWidget {
  final String label;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback? onCancel;
  final bool isWeb;
  final double maxContentWidth;

  /// Width of the web Save button, so it reads as a button, not a banner.
  static const double _webButtonWidth = 220;

  const AddressSaveBar({
    super.key,
    required this.label,
    required this.isSaving,
    required this.onSave,
    this.onCancel,
    this.isWeb = false,
    this.maxContentWidth = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(color: context.textLight.withValues(alpha: 0.15)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        // Scaffold hands a bottomNavigationBar the full screen height as its
        // max; a plain Center would expand to fill it and cover the page.
        // heightFactor: 1 centres horizontally but shrink-wraps vertically.
        child: Align(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWeb
                    ? Constants.paddingSizeLarge
                    : Constants.paddingSizeDefault,
                vertical: Constants.paddingSizeSmall + 2,
              ),
              child: isWeb ? _webActions(context) : _saveButton(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _webActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (onCancel != null) ...[
          SizedBox(
            height: Constants.minTapTarget + Constants.paddingSizeSmall,
            child: OutlinedButton(
              onPressed: isSaving ? null : onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: context.textPrimary,
                side: BorderSide(
                  color: context.textLight.withValues(alpha: 0.4),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: Constants.paddingSizeExtraLarge,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Constants.radiusDefault),
                ),
              ),
              child: Text(
                'cancel'.tr,
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeDefault,
                ),
              ),
            ),
          ),
          const SizedBox(width: Constants.paddingSizeSmall),
        ],
        SizedBox(width: _webButtonWidth, child: _saveButton()),
      ],
    );
  }

  Widget _saveButton() {
    return SizedBox(
      width: double.infinity,
      height: Constants.minTapTarget + Constants.paddingSizeSmall,
      child: ElevatedButton(
        onPressed: isSaving ? null : onSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorResource.primaryDark,
          disabledBackgroundColor:
              ColorResource.primaryDark.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Constants.radiusDefault),
          ),
        ),
        child: isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: ColorResource.textWhite,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_rounded,
                    size: 20,
                    color: ColorResource.textWhite,
                  ),
                  const SizedBox(width: Constants.paddingSizeExtraSmall + 2),
                  Text(
                    label,
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeDefault + 1,
                      color: ColorResource.textWhite,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
