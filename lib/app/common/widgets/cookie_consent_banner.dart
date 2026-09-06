import 'package:appwrite_user_app/app/controllers/settings_controller.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A professional, floating downside-corner banner for displaying the store's
/// [cookies_text] configured in business setup.
///
/// Follows modern UI/UX design standards:
/// - Floating in the bottom trailing corner on a wide browser window, or a
///   full-width bar across the bottom in a narrow one.
/// - Theme-aware card with subtle shadow and glassmorphic finish.
/// - Persists the customer's answer, so it is asked once and not on every
///   reload.
///
/// **Web only.** The notice is about what a *browser* stores, and the consent
/// rules it exists to satisfy apply to a site, not to an installed app. On
/// Android and iOS it renders nothing and does not even read preferences —
/// showing it there would be asking permission for something that is not
/// happening.
class CookieConsentBanner extends StatefulWidget {
  const CookieConsentBanner({super.key});

  @override
  State<CookieConsentBanner> createState() => _CookieConsentBannerState();
}

class _CookieConsentBannerState extends State<CookieConsentBanner> {
  static const String _acceptedKey = 'cookie_consent_accepted';

  /// Declining (or closing) is an answer too, and it is stored separately from
  /// [_acceptedKey] so consent itself is never recorded by a dismissal.
  ///
  /// Without this the banner came back on every page load: a web app reloads
  /// constantly, and only "Accept" was remembered — so the one customer who
  /// does not want to accept is the one asked again every single time.
  static const String _dismissedKey = 'cookie_consent_dismissed';

  bool _isDismissed = true;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // No storage read on mobile: there is nothing to ask about there.
    if (kIsWeb) _checkConsentStatus();
  }

  Future<void> _checkConsentStatus() async {
    try {
      final prefs = Get.isRegistered<SharedPreferences>()
          ? Get.find<SharedPreferences>()
          : await SharedPreferences.getInstance();

      final answered = (prefs.getBool(_acceptedKey) ?? false) ||
          (prefs.getBool(_dismissedKey) ?? false);
      if (mounted) {
        setState(() {
          _isDismissed = answered;
          _isInitialized = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isDismissed = false;
          _isInitialized = true;
        });
      }
    }
  }

  Future<void> _acceptConsent() => _answer(_acceptedKey);

  Future<void> _dismissNotice() => _answer(_dismissedKey);

  /// Hides the banner and remembers that it was answered.
  ///
  /// The write is best-effort: a browser with site data blocked throws here,
  /// and the notice still closes for this visit rather than refusing to go
  /// away.
  Future<void> _answer(String key) async {
    setState(() {
      _isDismissed = true;
    });
    try {
      final prefs = Get.isRegistered<SharedPreferences>()
          ? Get.find<SharedPreferences>()
          : await SharedPreferences.getInstance();
      await prefs.setBool(key, true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || !_isInitialized || _isDismissed) {
      return const SizedBox.shrink();
    }

    return GetBuilder<SettingsController>(
      builder: (settingsController) {
        final cookiesText =
            settingsController.businessSetup?.cookiesText?.trim() ?? '';

        if (cookiesText.isEmpty || _isDismissed) {
          return const SizedBox.shrink();
        }

        final double screenWidth = MediaQuery.of(context).size.width;
        final bool isDesktop = screenWidth >= 768;

        return Positioned(
          bottom: isDesktop ? 24 : 16,
          right: isDesktop ? 24 : 16,
          left: isDesktop ? null : 16,
          child: Material(
            type: MaterialType.transparency,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 400 : screenWidth - 32,
              ),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _isDismissed ? 0.0 : 1.0,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: context.textLight.withValues(alpha: 0.18),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: ColorResource.primaryDark
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.cookie_rounded,
                              color: ColorResource.primaryDark,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'cookies_privacy_title'.tr,
                              style: poppinsBold.copyWith(
                                fontSize: Constants.fontSizeLarge,
                                color: context.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _dismissNotice,
                            icon: const Icon(Icons.close_rounded),
                            iconSize: 20,
                            color: context.textSecondary,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        cookiesText,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: poppinsRegular.copyWith(
                          fontSize: Constants.fontSizeSmall,
                          color: context.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: _dismissNotice,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: context.textSecondary,
                              side: BorderSide(
                                color: context.textLight.withValues(alpha: 0.25),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'decline'.tr,
                              style: poppinsMedium.copyWith(
                                fontSize: Constants.fontSizeSmall,
                                color: context.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _acceptConsent,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorResource.primaryDark,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'accept_cookies'.tr,
                              style: poppinsBold.copyWith(
                                fontSize: Constants.fontSizeSmall,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
