import 'dart:async';

import 'package:appwrite_user_app/app/controllers/auth_controller.dart';
import 'package:appwrite_user_app/app/controllers/settings_controller.dart';
import 'package:appwrite_user_app/app/controllers/splash_controller.dart';
import 'package:appwrite_user_app/app/controllers/update_controller.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/images.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _hasConnection = true;
  bool _isBootstrapping = false;
  bool _hasNavigated = false;

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

    // Prime the cached auth state so login-gated pages render correctly.
    await Get.find<AuthController>().isAlreadyLoggedIn();
    final settingsFetched = await Get.find<SplashController>().fetchSettings();

    if (!mounted) return;

    _isBootstrapping = false;

    if (!settingsFetched || _hasNavigated) return;

    _hasNavigated = true;

    // Block behind the update screen when the store requires a newer version.
    final updateController = Get.find<UpdateController>();
    updateController.checkForForceUpdate(
      Get.find<SettingsController>().businessSetup,
    );
    if (updateController.forceUpdateRequired) {
      AppRouter.router.goNamed(RouteNames.forceUpdate);
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            ClipRRect(borderRadius: BorderRadius.circular(Constants.radiusExtraLarge), child: Image.asset(Images.logo, width: 150, height: 150)),
            SizedBox(height: 20),

            Text(
              Constants.appName,
              style: TextStyle(fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }
}
