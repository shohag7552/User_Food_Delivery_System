import 'dart:async';

import 'package:appwrite_user_app/app/common/widgets/no_internet_screen.dart';
import 'package:appwrite_user_app/app/controllers/localization_controller.dart';
import 'package:appwrite_user_app/app/helper/routes/app_pages.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/messages.dart';
import 'package:appwrite_user_app/global.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';

import 'app/resources/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Stripe
  Stripe.publishableKey = Constants.stripePublishableKey;

  await Global.init().then((languages) => runApp(MyApp(languages: languages)));
}

class MyApp extends StatefulWidget {
  final Map<String, Map<String, String>> languages;
  const MyApp({super.key, required this.languages});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isCheckingConnection = true;
  bool _hasConnection = true;
  bool _isReloading = false;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    await _checkConnection();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      results,
    ) {
      unawaited(_handleConnectivityResults(results));
    });
  }

  Future<void> _checkConnection() async {
    final results = await _connectivity.checkConnectivity();
    await _handleConnectivityResults(results, showReloading: false);
  }

  Future<void> _handleConnectivityResults(
    List<ConnectivityResult> results, {
    bool showReloading = true,
  }) async {
    final hasConnection = results.any(
      (result) => result != ConnectivityResult.none,
    );
    final wasOffline = !_hasConnection;

    if (!mounted) return;

    setState(() {
      _hasConnection = hasConnection;
      _isCheckingConnection = false;
      _isReloading = showReloading && hasConnection && wasOffline;
    });

    if (_isReloading) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() {
        _isReloading = false;
      });
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LocalizationController>(
      builder: (localizeController) {
        return GetMaterialApp(
          title: Constants.appName,
          debugShowCheckedModeBanner: false,
          theme: localizeController.darkTheme ? darkTheme : lightTheme,
          // theme: darkTheme,
          locale: localizeController.locale,
          translations: Messages(languages: widget.languages),
          fallbackLocale: Locale(
            Constants.languages[0].languageCode,
            Constants.languages[0].countryCode,
          ),
          getPages: AppPages.routes,
          builder: (context, child) {
            final appChild = child ?? const SizedBox.shrink();

            if (_isCheckingConnection) {
              return appChild;
            }

            return Stack(
              children: [
                appChild,
                if (!_hasConnection)
                  Positioned.fill(
                    child: NoInternetScreen(
                      onRetry: _checkConnection,
                      isReloading: _isReloading,
                    ),
                  ),
              ],
            );
          },
          // home: VerificationScreen(tempToken: '', registrationModel: null),
          initialRoute: AppPages.goToSplashPage(),
        );
      },
    );
  }
}
