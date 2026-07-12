import 'dart:io' show Platform;

import 'package:appwrite_user_app/app/models/business_setup_model.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

/// Owns the force-update decision and the "open the store" action.
///
/// The running build version comes from [Constants.appVersion] (kept in sync
/// with pubspec at release time) — this app deliberately avoids a
/// `package_info_plus` dependency. Business rules live in [BusinessSetupModel];
/// this controller only orchestrates state + navigation intent.
class UpdateController extends GetxController implements GetxService {
  bool _forceUpdateRequired = false;
  bool get forceUpdateRequired => _forceUpdateRequired;

  String? _storeUrl;
  String? get storeUrl => _storeUrl;

  /// Recomputes the force-update state from the freshly loaded [setup].
  /// Safe to call with a null setup (e.g. settings failed to load) — it simply
  /// clears the flag so the app is never blocked on missing config.
  void checkForForceUpdate(BusinessSetupModel? setup) {
    if (setup == null) {
      _forceUpdateRequired = false;
      _storeUrl = null;
    } else {
      _forceUpdateRequired = setup.requiresForceUpdate(Constants.appVersion);
      _storeUrl = _resolveStoreUrl(setup);
    }
    update();
  }

  /// Picks the store URL for the current platform, falling back to the other
  /// platform's URL so the update button is never dead when only one is set.
  /// Web (where [Platform] is unavailable) prefers the Android/Play link.
  String? _resolveStoreUrl(BusinessSetupModel setup) {
    final android = _nullIfBlank(setup.androidStoreUrl);
    final ios = _nullIfBlank(setup.iosStoreUrl);
    if (kIsWeb) return android ?? ios;
    if (Platform.isIOS) return ios ?? android;
    return android ?? ios;
  }

  String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  /// Opens the resolved store URL externally. Returns false when there is no
  /// URL to open or the launch fails, so the view can show a toast.
  Future<bool> openStore() async {
    final url = _storeUrl;
    if (url == null) return false;

    final normalized = url.contains('://') ? url : 'https://$url';
    final uri = Uri.tryParse(normalized);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      return false;
    }
    try {
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
    } catch (e) {
      debugPrint('Failed to open store url: $e');
      return false;
    }
  }
}
