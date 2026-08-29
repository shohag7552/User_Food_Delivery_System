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
/// - Floating position in the bottom-right downside corner (desktop web) or
///   bottom floating banner (mobile).
/// - Theme-aware card with subtle shadow and glassmorphic finish.
/// - Persists user consent in [SharedPreferences] (`cookie_consent_accepted`).
class CookieConsentBanner extends StatefulWidget {
  const CookieConsentBanner({super.key});

  @override
  State<CookieConsentBanner> createState() => _CookieConsentBannerState();
}

class _CookieConsentBannerState extends State<CookieConsentBanner> {
  static const String _consentKey = 'cookie_consent_accepted';

  bool _isDismissed = true;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _checkConsentStatus();
  }

  Future<void> _checkConsentStatus() async {
    try {
      final prefs = Get.isRegistered<SharedPreferences>()
          ? Get.find<SharedPreferences>()
          : await SharedPreferences.getInstance();

      final accepted = prefs.getBool(_consentKey) ?? false;
      if (mounted) {
        setState(() {
          _isDismissed = accepted;
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

  Future<void> _acceptConsent() async {
    setState(() {
      _isDismissed = true;
    });
    try {
      final prefs = Get.isRegistered<SharedPreferences>()
          ? Get.find<SharedPreferences>()
          : await SharedPreferences.getInstance();
      await prefs.setBool(_consentKey, true);
    } catch (_) {}
  }

  Future<void> _dismissNotice() async {
    setState(() {
      _isDismissed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _isDismissed) {
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
        final bool isDesktop = kIsWeb && screenWidth >= 768;

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
                              'cookies_privacy_title'.tr.isNotEmpty &&
                                      'cookies_privacy_title'.tr !=
                                          'cookies_privacy_title'
                                  ? 'cookies_privacy_title'.tr
                                  : 'Cookie Policy',
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
                              'decline'.tr.isNotEmpty &&
                                      'decline'.tr != 'decline'
                                  ? 'decline'.tr
                                  : 'Decline',
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
                              'accept_cookies'.tr.isNotEmpty &&
                                      'accept_cookies'.tr != 'accept_cookies'
                                  ? 'accept_cookies'.tr
                                  : 'Accept Cookies',
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
