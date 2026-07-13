import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NoInternetScreen extends StatelessWidget {
  final VoidCallback onRetry;
  final bool isReloading;

  const NoInternetScreen({
    super.key,
    required this.onRetry,
    this.isReloading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.scaffoldBackground,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.cardBackground,
                  borderRadius: BorderRadius.circular(
                    Constants.radiusExtraLarge,
                  ),
                  boxShadow: ColorResource.customShadow,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              ColorResource.error.withValues(alpha: 0.12),
                              ColorResource.primaryMedium.withValues(
                                alpha: 0.12,
                              ),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.wifi_off_rounded,
                          size: 40,
                          color: ColorResource.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'no_internet_title'.tr,
                        textAlign: TextAlign.center,
                        style: poppinsBold.copyWith(
                          fontSize: Constants.fontSizeOverLarge,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isReloading
                            ? 'reconnecting_data'.tr
                            : 'no_internet_message'.tr,
                        textAlign: TextAlign.center,
                        style: poppinsRegular.copyWith(
                          height: 1.6,
                          color: context.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isReloading ? null : onRetry,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorResource.primaryDark,
                            foregroundColor: ColorResource.textWhite,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                Constants.radiusLarge,
                              ),
                            ),
                            elevation: 0,
                          ),
                          child: isReloading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: ColorResource.textWhite,
                                  ),
                                )
                              : Text(
                                  'check_connection'.tr,
                                  style: poppinsMedium.copyWith(
                                    color: ColorResource.textWhite,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'we_will_refresh_when_back_online'.tr,
                        textAlign: TextAlign.center,
                        style: poppinsRegular.copyWith(
                          color: context.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
