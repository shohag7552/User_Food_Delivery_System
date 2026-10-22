import 'package:kikomart_user_app/app/resources/colors.dart';
import 'package:kikomart_user_app/app/resources/constants.dart';
import 'package:kikomart_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Shown whenever the app has no usable connection.
///
/// One centred, width-capped column serves phone, tablet and web alike: what
/// is wrong, that the app will reconnect on its own, and a retry button.
class NoInternetScreen extends StatelessWidget {
  final VoidCallback onRetry;
  final bool isReloading;

  const NoInternetScreen({
    super.key,
    required this.onRetry,
    this.isReloading = false,
  });

  /// Keeps the copy and the button at a readable width on wide screens.
  static const double _maxContentWidth = 460;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.scaffoldBackground,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Constants.paddingSizeLarge),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxContentWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: Constants.iconCircleSize,
                    height: Constants.iconCircleSize,
                    decoration: BoxDecoration(
                      color: ColorResource.primaryDark.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.wifi_off_rounded,
                      size: Constants.iconSizeLarge,
                      color: ColorResource.primaryDark,
                    ),
                  ),
                  const SizedBox(height: Constants.paddingSizeExtraLarge),
                  Text(
                    'no_internet_title'.tr,
                    textAlign: TextAlign.center,
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeExtraLarge,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: Constants.paddingSizeSmall),
                  Text(
                    isReloading
                        ? 'reconnecting_data'.tr
                        : 'we_will_reconnect_automatically'.tr,
                    textAlign: TextAlign.center,
                    style: poppinsRegular.copyWith(
                      fontSize: Constants.fontSizeDefault,
                      color: context.textSecondary,
                    ),
                  ),
                  const SizedBox(height: Constants.paddingSizeExtraLarge),
                  _buildRetryButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRetryButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: isReloading ? null : onRetry,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorResource.primaryDark,
          foregroundColor: ColorResource.textWhite,
          // Dimmed rather than greyed, so it reads as busy, not broken.
          disabledBackgroundColor:
              ColorResource.primaryDark.withValues(alpha: 0.6),
          disabledForegroundColor: ColorResource.textWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Constants.radiusDefault),
          ),
          elevation: 0,
        ),
        icon: isReloading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: ColorResource.textWhite,
                ),
              )
            : const Icon(Icons.refresh_rounded, size: 20),
        label: Text(
          isReloading ? 'reconnecting'.tr : 'check_connection'.tr,
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeDefault,
            color: ColorResource.textWhite,
          ),
        ),
      ),
    );
  }
}
