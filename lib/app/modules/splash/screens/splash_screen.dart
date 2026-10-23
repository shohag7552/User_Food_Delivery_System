import 'dart:async';

import 'package:kikomart_user_app/app/controllers/auth_controller.dart';
import 'package:kikomart_user_app/app/controllers/settings_controller.dart';
import 'package:kikomart_user_app/app/controllers/splash_controller.dart';
import 'package:kikomart_user_app/app/controllers/update_controller.dart';
import 'package:kikomart_user_app/app/helper/routes/app_router.dart';
import 'package:kikomart_user_app/app/resources/colors.dart';
import 'package:kikomart_user_app/app/resources/constants.dart';
import 'package:kikomart_user_app/app/resources/images.dart';
import 'package:kikomart_user_app/app/resources/text_style.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashScreen extends StatefulWidget {
  /// Where to go once the bootstrap finishes, instead of the dashboard.
  ///
  /// Set by screens that were reached outside the normal boot path — a cold
  /// deep link into `/reset-password` skips the splash entirely, so it sends
  /// the user back through here afterwards to get settings and module state
  /// loaded before they land anywhere else.
  final String? nextLocation;

  const SplashScreen({super.key, this.nextLocation});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _hasConnection = true;
  bool _isBootstrapping = false;
  bool _hasNavigated = false;

  /// Settings could not be loaded (backend unreachable or misconfigured).
  /// Shows a retry instead of leaving the logo up forever.
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _listenToConnectivity();

    Future.delayed(const Duration(milliseconds: 500), () async {
      if (!mounted) return;

      final hasConnection = await _checkConnection();

      if (hasConnection) {
        await _bootstrapApp();
      }
    });
  }

  Future<void> _listenToConnectivity() async {
    _hasConnection = await _checkConnection();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      results,
    ) async {
      final hasConnection = _hasUsableConnection(results);
      final wasOffline = !_hasConnection;
      _hasConnection = hasConnection;

      if (hasConnection && wasOffline) {
        await _bootstrapApp();
      }
    });
  }

  Future<bool> _checkConnection() async {
    final results = await _connectivity.checkConnectivity();
    final hasConnection = _hasUsableConnection(results);
    _hasConnection = hasConnection;
    return hasConnection;
  }

  bool _hasUsableConnection(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }

  Future<void> _bootstrapApp() async {
    if (!mounted || !_hasConnection || _isBootstrapping || _hasNavigated) {
      return;
    }

    _isBootstrapping = true;
    if (_loadFailed) setState(() => _loadFailed = false);

    bool settingsFetched = false;
    try {
      // Prime the cached auth state so login-gated pages render correctly.
      await Get.find<AuthController>().isAlreadyLoggedIn();
      settingsFetched = await Get.find<SplashController>().fetchSettings();
    } catch (e) {
      debugPrint('Splash bootstrap failed: $e');
    }

    if (!mounted) return;

    _isBootstrapping = false;

    if (_hasNavigated) return;
    if (!settingsFetched) {
      setState(() => _loadFailed = true);
      return;
    }

    _hasNavigated = true;

    // Block behind the startup gate when the store is down for maintenance or
    // requires a newer version. Maintenance takes precedence — the store being
    // offline outright wins over "please upgrade".
    final updateController = Get.find<UpdateController>();
    updateController.checkForForceUpdate(
      Get.find<SettingsController>().businessSetup,
    );
    if (updateController.maintenanceModeOn) {
      AppRouter.router.goNamed(RouteNames.maintenance);
      return;
    }
    if (updateController.forceUpdateRequired) {
      AppRouter.router.goNamed(RouteNames.forceUpdate);
      return;
    }

    // A caller that handed off to the splash purely for the bootstrap gets its
    // destination back — the maintenance / force-update gates above still take
    // precedence, which is correct.
    final next = widget.nextLocation;
    if (next != null && next.isNotEmpty) {
      AppRouter.router.go(next);
      return;
    }

    // Always open on the dashboard so guests can browse products. Signing in is
    // requested only when an action requires it (checkout, favorites, profile…).
    AppRouter.router.goNamed(RouteNames.dashboard);
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(Constants.radiusExtraLarge),
              child: Image.asset(
                Images.logo,
                width: Constants.splashLogoSize,
                height: Constants.splashLogoSize,
              ),
            ),
            const SizedBox(height: Constants.paddingSizeLarge),

            Text(
              Constants.appName,
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeOverLarge,
                color: context.textPrimary,
              ),
            ),

            if (_loadFailed) ...[
              const SizedBox(height: Constants.paddingSizeExtraLarge),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Constants.paddingSizeExtraLarge,
                ),
                child: Text(
                  'could_not_load_store_settings'.tr,
                  textAlign: TextAlign.center,
                  style: poppinsRegular.copyWith(
                    fontSize: Constants.fontSizeDefault,
                    color: context.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: Constants.paddingSizeDefault),
              ElevatedButton.icon(
                onPressed: _bootstrapApp,
                icon: const Icon(Icons.refresh_rounded),
                label: Text('retry'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorResource.primaryDark,
                  foregroundColor: ColorResource.textWhite,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
