import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:appwrite_user_app/app/common/widgets/web_top_nav.dart';
import 'package:appwrite_user_app/app/controllers/settings_controller.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/models/store_setup_model.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// A simple, professional site footer shown ONLY on desktop web.
///
/// It self-gates on [WebTopNav.isEnabled] (`kIsWeb && width >= 900`), so on
/// Android/iOS and native tablets it collapses to nothing — pages can drop it
/// at the bottom of their scroll unconditionally without any mobile impact.
class WebFooter extends StatelessWidget {
  const WebFooter({super.key});

  /// Wraps the footer in a sliver for `CustomScrollView`-based pages.
  static Widget sliver() => const SliverToBoxAdapter(child: WebFooter());

  static const double _maxContentWidth = 1200;

  /// Below this inner width the three blocks stack vertically.
  static const double _stackWidth = 720;

  @override
  Widget build(BuildContext context) {
    // Web only — never renders on mobile / native tablet.
    if (!WebTopNav.isEnabled(context)) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final divider = context.textLight.withValues(alpha: 0.15);

    StoreSetupModel? store;
    String brandName = Constants.appName;
    if (Get.isRegistered<SettingsController>()) {
      final settings = Get.find<SettingsController>();
      store = settings.storeSetup;
      final businessName = settings.businessSetup?.businessName.trim() ?? '';
      final storeName = store?.storeName.trim() ?? '';
      brandName = businessName.isNotEmpty
          ? businessName
          : (storeName.isNotEmpty ? storeName : Constants.appName);
    }

    // Decide the row-vs-stack layout from MediaQuery — NOT a LayoutBuilder.
    // The footer is placed inside a SliverFillRemaining that measures its
    // intrinsic height, and LayoutBuilder throws when asked for intrinsics
    // (which was blanking the whole page on web).
    final double screenWidth = MediaQuery.of(context).size.width;
    final double contentWidth =
        (screenWidth < _maxContentWidth ? screenWidth : _maxContentWidth) -
            Constants.paddingSizeLarge * 2;
    final bool stacked = contentWidth < _stackWidth;
    final Widget brand = _brandBlock(context, brandName, store);
    final Widget links = _linksBlock(context);
    final Widget contact = _contactBlock(context, store);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: divider)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Constants.paddingSizeLarge,
              vertical: Constants.spaceSection,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (stacked)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      brand,
                      const SizedBox(height: Constants.paddingSizeLarge),
                      links,
                      const SizedBox(height: Constants.paddingSizeLarge),
                      contact,
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: brand),
                      const SizedBox(width: Constants.spaceSection),
                      Expanded(flex: 3, child: links),
                      const SizedBox(width: Constants.spaceSection),
                      Expanded(flex: 4, child: contact),
                    ],
                  ),
                const SizedBox(height: Constants.paddingSizeLarge),
                Divider(color: divider, height: 1),
                const SizedBox(height: Constants.paddingSizeDefault),
                Text(
                  '© ${DateTime.now().year} $brandName. ${'all_rights_reserved'.tr}',
                  style: poppinsRegular.copyWith(
                    fontSize: Constants.fontSizeSmall,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Blocks ────────────────────────────────────────────────────────────────

  Widget _brandBlock(
    BuildContext context,
    String brandName,
    StoreSetupModel? store,
  ) {
    final description = store?.description.trim() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          brandName,
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeExtraLarge,
            color: ColorResource.primaryDark,
          ),
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: Constants.paddingSizeSmall),
          Text(
            description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: poppinsRegular.copyWith(
              fontSize: Constants.fontSizeSmall,
              height: 1.5,
              color: context.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _linksBlock(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(context, 'quick_links'.tr),
        _footerLink(
          context,
          'about_us'.tr,
          () => context.pushNamed(
            RouteNames.policy,
            pathParameters: {'type': PolicyType.aboutUs},
          ),
        ),
        _footerLink(
          context,
          'terms_and_conditions_title'.tr,
          () => context.pushNamed(
            RouteNames.policy,
            pathParameters: {'type': PolicyType.terms},
          ),
        ),
        _footerLink(
          context,
          'privacy_policy_title'.tr,
          () => context.pushNamed(
            RouteNames.policy,
            pathParameters: {'type': PolicyType.privacy},
          ),
        ),
        _footerLink(
          context,
          'help_and_support'.tr,
          () => context.pushNamed(RouteNames.helpSupport),
        ),
      ],
    );
  }

  Widget _contactBlock(BuildContext context, StoreSetupModel? store) {
    final email = store?.email.trim() ?? '';
    final phone = store?.phone.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(context, 'contact_information'.tr),
        if (email.isNotEmpty)
          _contactRow(
            context,
            Icons.mail_outline_rounded,
            email,
            () => _launch(Uri(scheme: 'mailto', path: email)),
          ),
        if (phone.isNotEmpty)
          _contactRow(
            context,
            Icons.call_outlined,
            phone,
            () => _launch(Uri(scheme: 'tel', path: phone)),
          ),
        if (_hasSocials(store)) ...[
          const SizedBox(height: Constants.paddingSizeSmall),
          _socialRow(store!),
        ],
      ],
    );
  }

  // ── Pieces ──────────────────────────────────────────────────────────────

  Widget _heading(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Constants.paddingSizeSmall),
      child: Text(
        text,
        style: poppinsBold.copyWith(
          fontSize: Constants.fontSizeDefault,
          color: context.textPrimary,
        ),
      ),
    );
  }

  Widget _footerLink(BuildContext context, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Constants.radiusSmall),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Text(
          label,
          style: poppinsRegular.copyWith(
            fontSize: Constants.fontSizeSmall,
            color: context.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _contactRow(
    BuildContext context,
    IconData icon,
    String value,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Constants.radiusSmall),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Icon(icon, size: 16, color: ColorResource.primaryDark),
            const SizedBox(width: Constants.paddingSizeSmall),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: poppinsRegular.copyWith(
                  fontSize: Constants.fontSizeSmall,
                  color: context.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _socialRow(StoreSetupModel store) {
    final items = <(IconData, Color, String)>[
      if ((store.facebook ?? '').trim().isNotEmpty)
        (Icons.facebook_rounded, const Color(0xFF1877F2), store.facebook!),
      if ((store.instagram ?? '').trim().isNotEmpty)
        (Icons.camera_alt_rounded, const Color(0xFFE1306C), store.instagram!),
      if ((store.twitter ?? '').trim().isNotEmpty)
        (Icons.alternate_email_rounded, const Color(0xFF1DA1F2), store.twitter!),
      if ((store.website ?? '').trim().isNotEmpty)
        (Icons.public_rounded, ColorResource.primaryDark, store.website!),
    ];

    return Row(
      children: [
        for (final item in items) ...[
          InkWell(
            onTap: () => _launch(_normalizeWeb(item.$3)),
            borderRadius: BorderRadius.circular(Constants.radiusExtraLarge),
            child: Container(
              padding: const EdgeInsets.all(Constants.paddingSizeSmall),
              decoration: BoxDecoration(
                color: item.$2.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(item.$1, size: 18, color: item.$2),
            ),
          ),
          const SizedBox(width: Constants.paddingSizeSmall),
        ],
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  bool _hasSocials(StoreSetupModel? store) =>
      store != null &&
      ((store.facebook ?? '').trim().isNotEmpty ||
          (store.instagram ?? '').trim().isNotEmpty ||
          (store.twitter ?? '').trim().isNotEmpty ||
          (store.website ?? '').trim().isNotEmpty);

  Uri _normalizeWeb(String url) {
    var value = url.trim();
    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      value = 'https://$value';
    }
    return Uri.parse(value);
  }

  Future<void> _launch(Uri uri) async {
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) customToster('could_not_open_link'.tr, isSuccess: false);
    } catch (_) {
      customToster('could_not_open_link'.tr, isSuccess: false);
    }
  }
}
