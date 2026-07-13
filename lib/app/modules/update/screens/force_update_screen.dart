import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:appwrite_user_app/app/controllers/update_controller.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Blocking screen shown when the store requires a newer app version. There is
/// no way out but to update — [PopScope] with `canPop: false` swallows the back
/// button, and the app only reaches here from the splash bootstrap.
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: GetBuilder<UpdateController>(
                builder: (updateController) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.system_update,
                      size: 96,
                      color: ColorResource.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'update_required'.tr,
                      textAlign: TextAlign.center,
                      style: poppinsBold.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'update_required_message'.tr,
                      textAlign: TextAlign.center,
                      style: poppinsRegular.copyWith(
                        fontSize: 14,
                        color: context.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final opened = await updateController.openStore();
                          if (!opened) {
                            customToster(
                              'could_not_open_link'.tr,
                              isSuccess: false,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorResource.primary,
                          foregroundColor: ColorResource.textWhite,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              Constants.radiusDefault,
                            ),
                          ),
                        ),
                        child: Text(
                          'update_now'.tr,
                          style: poppinsMedium.copyWith(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
