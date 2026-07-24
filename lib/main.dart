import 'dart:async';

import 'package:appwrite_user_app/app/common/widgets/no_internet_screen.dart';
import 'package:appwrite_user_app/app/controllers/localization_controller.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/messages.dart';
import 'package:appwrite_user_app/global.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import 'app/resources/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Clean web URLs (/category/... instead of /#/category/...); no-op off web.
  usePathUrlStrategy();

  // Web: make pushNamed()-opened pages (product/order/category details, …)
  // update the browser URL. go_router stopped reflecting imperative pushes in
  // the URL by default (v8+); it warns the top route may not be deep-linkable,
  // but every pushed route here hydrates itself from its URL, so it is safe.
  GoRouter.optionURLReflectsImperativeAPIs = true;

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
        Global.setSystemUi(isDarkMode: localizeController.darkTheme);

        final baseTheme = localizeController.darkTheme ? darkTheme : lightTheme;

        return GetMaterialApp.router(
          title: Constants.appName,
          debugShowCheckedModeBanner: false,
          // On web, swap the heavy default page push for a subtle fade+slide.
          theme: kIsWeb
              ? baseTheme.copyWith(
                  pageTransitionsTheme: webPageTransitionsTheme,
                )
              : baseTheme,
          // theme: darkTheme,
          locale: localizeController.locale,
          translations: Messages(languages: widget.languages),
          fallbackLocale: Locale(
            Constants.languages[0].languageCode,
            Constants.languages[0].countryCode,
          ),
          // Localized Material/Cupertino widgets and, crucially, RTL text
          // direction for Arabic (resolved from the active locale).
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: Constants.languages
              .map((l) => Locale(l.languageCode, l.countryCode))
              .toList(),
          routeInformationParser: AppRouter.router.routeInformationParser,
          routerDelegate: AppRouter.router.routerDelegate,
          routeInformationProvider: AppRouter.router.routeInformationProvider,
          backButtonDispatcher: AppRouter.router.backButtonDispatcher,
          builder: (context, child) {
            final appChild = child  ?? const SizedBox.shrink();

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
        );
      },
    );
  }
}
