import 'package:appwrite_user_app/app/controllers/settings_controller.dart';
import 'package:appwrite_user_app/app/controllers/splash_controller.dart';
import 'package:appwrite_user_app/app/controllers/update_controller.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Blocking screen shown while the store is in maintenance mode. There is
/// nothing the user can do but wait, so the only action is a retry that
/// re-fetches settings and lets them through once maintenance is turned off.
class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  bool _isRetrying = false;

  Future<void> _retry() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);

    // Re-pull settings, then re-evaluate the startup gate with the fresh data.
    await Get.find<SplashController>().fetchSettings();
    final updateController = Get.find<UpdateController>();
    updateController.checkForForceUpdate(
      Get.find<SettingsController>().businessSetup,
    );

    if (!mounted) return;
    setState(() => _isRetrying = false);

    // Still down — stay put. Otherwise route on (force update takes over if
    // that gate is now active, else the dashboard).
    if (updateController.maintenanceModeOn) return;
    if (updateController.forceUpdateRequired) {
      AppRouter.router.goNamed(RouteNames.forceUpdate);
    } else {
      AppRouter.router.goNamed(RouteNames.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.build_circle_outlined,
                    size: 96,
                    color: ColorResource.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'maintenance_mode_title'.tr,
                    textAlign: TextAlign.center,
                    style: poppinsBold.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'maintenance_mode_message'.tr,
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
                      onPressed: _isRetrying ? null : _retry,
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
                      child: _isRetrying
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              'retry'.tr,
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
    );
  }
}
