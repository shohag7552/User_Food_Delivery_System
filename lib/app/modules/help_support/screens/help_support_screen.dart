import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:appwrite_user_app/app/common/widgets/directional_flip.dart';
import 'package:appwrite_user_app/app/common/widgets/web_top_nav.dart';
import 'package:appwrite_user_app/app/controllers/settings_controller.dart';
import 'package:appwrite_user_app/app/helper/dashboard_tab_bus.dart';
import 'package:appwrite_user_app/app/models/store_setup_model.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/web_profile_drawer.dart';
import 'package:appwrite_user_app/app/modules/help_support/widgets/help_faq_section.dart';
import 'package:appwrite_user_app/app/modules/help_support/widgets/help_quick_action.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// Help & Support — a premium contact hub driven by the store's own setup data
/// (phone, email, address, website, social links from [SettingsController]),
/// plus a static FAQ. Fully responsive: a gradient hero + slivers on
/// mobile/tablet, and the shared web top-nav with a centred, width-constrained
/// column on desktop web.
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Width the content column is capped at on desktop web so lines stay
  /// readable instead of stretching edge to edge.
  static const double _maxContentWidth = 820;

  @override
  void initState() {
    super.initState();
    // Ensure the store contact details are loaded (splash only guarantees
    // business setup); fetch on demand if they aren't in memory yet.
    if (Get.isRegistered<SettingsController>()) {
      final settings = Get.find<SettingsController>();
      if (settings.storeSetup == null) {
        settings.fetchStoreSetup();
      }
    }
  }

  // ── URL / intent launchers ────────────────────────────────────────────────

  Future<void> _openUri(Uri uri) async {
    try {
      final opened =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) customToster('could_not_open_link'.tr, isSuccess: false);
    } catch (_) {
      customToster('could_not_open_link'.tr, isSuccess: false);
    }
  }

  void _call(String phone) => _openUri(Uri(scheme: 'tel', path: phone.trim()));

  void _sendEmail(String email) =>
      _openUri(Uri(scheme: 'mailto', path: email.trim()));

  void _openWeb(String url) {
    var value = url.trim();
    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      value = 'https://$value';
    }
    _openUri(Uri.parse(value));
  }

  void _openDirections(StoreSetupModel store) {
    final query = Uri.encodeComponent(
      [store.address, store.city, store.state, store.zipCode]
          .where((e) => e.trim().isNotEmpty)
          .join(', '),
    );
    _openUri(Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$query'));
  }

  @override
  Widget build(BuildContext context) {
    final showWebNav = WebTopNav.isEnabled(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: context.scaffoldBackground,
      endDrawer: showWebNav ? const WebProfileDrawer() : null,
      appBar: showWebNav
          ? WebTopNav(
              selectedIndex: null,
              onDestinationSelected: (index) =>
                  DashboardTabs.open(context, index),
              onMenuTap: () => _scaffoldKey.currentState?.openEndDrawer(),
            )
          : null,
      body: GetBuilder<SettingsController>(
        builder: (settings) {
          final store = settings.storeSetup;

          if (settings.isLoading && store == null) {
            return const Center(
              child: CircularProgressIndicator(
                color: ColorResource.primaryDark,
              ),
            );
          }

          if (showWebNav) {
            return SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: _maxContentWidth),
                  child: Padding(
                    padding: const EdgeInsets.all(Constants.paddingSizeLarge),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _WebHeader(store: store),
                        const SizedBox(height: Constants.paddingSizeLarge),
                        ..._sections(store),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              _buildSliverHero(context, store),
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.all(Constants.paddingSizeDefault),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _sections(store),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// The ordered list of content sections, shared by the mobile and web layouts.
  List<Widget> _sections(StoreSetupModel? store) {
    return [
      if (store != null) ...[
        // _buildSectionTitle('how_can_we_help'.tr),
        // const SizedBox(height: Constants.paddingSizeSmall),
        // _buildQuickActions(store),
        // const SizedBox(height: Constants.spaceSection),
        _buildSectionTitle('contact_information'.tr),
        const SizedBox(height: Constants.paddingSizeSmall),
        _ContactCard(
          store: store,
          onCall: _call,
          onEmail: _sendEmail,
          onWeb: _openWeb,
          onDirections: () => _openDirections(store),
        ),
        if (_hasSocials(store)) ...[
          const SizedBox(height: Constants.spaceSection),
          _buildSectionTitle('follow_us'.tr),
          const SizedBox(height: Constants.paddingSizeSmall),
          _SocialRow(store: store, onTap: _openWeb),
        ],
      ] else ...[
        _buildUnavailableNote(),
      ],
      const SizedBox(height: Constants.spaceSection),
      _buildSectionTitle('faq_title'.tr),
      const SizedBox(height: Constants.paddingSizeSmall),
      const HelpFaqSection(),
      const SizedBox(height: Constants.spaceSection),
      _StillNeedHelpCard(
        store: store,
        onContact: () {
          if (store == null) return;
          if (store.phone.trim().isNotEmpty) {
            _call(store.phone);
          } else if (store.email.trim().isNotEmpty) {
            _sendEmail(store.email);
          }
        },
      ),
      const SizedBox(height: Constants.paddingSizeLarge),
    ];
  }

  Widget _buildQuickActions(StoreSetupModel store) {
    final actions = <Widget>[
      if (store.phone.trim().isNotEmpty)
        HelpQuickAction(
          icon: Icons.call_rounded,
          label: 'call_us'.tr,
          onTap: () => _call(store.phone),
        ),
      if (store.email.trim().isNotEmpty)
        HelpQuickAction(
          icon: Icons.mail_outline_rounded,
          label: 'email_us'.tr,
          onTap: () => _sendEmail(store.email),
        ),
      if (store.address.trim().isNotEmpty)
        HelpQuickAction(
          icon: Icons.directions_outlined,
          label: 'visit_us'.tr,
          onTap: () => _openDirections(store),
        ),
      if ((store.website ?? '').trim().isNotEmpty)
        HelpQuickAction(
          icon: Icons.language_rounded,
          label: 'website'.tr,
          onTap: () => _openWeb(store.website!),
        ),
    ];

    return Row(
      children: [
        for (int i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: Constants.paddingSizeSmall),
          Expanded(child: actions[i]),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Text(
      title,
      style: poppinsBold.copyWith(
        fontSize: Constants.fontSizeDefault,
        color: isDark ? Colors.white70 : context.textSecondary,
      ),
    );
  }

  Widget _buildUnavailableNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Constants.paddingSizeLarge),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              color: ColorResource.primaryDark, size: 22),
          const SizedBox(width: Constants.paddingSizeSmall),
          Expanded(
            child: Text(
              'support_unavailable'.tr,
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: context.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasSocials(StoreSetupModel store) =>
      (store.facebook ?? '').trim().isNotEmpty ||
      (store.instagram ?? '').trim().isNotEmpty ||
      (store.twitter ?? '').trim().isNotEmpty ||
      (store.website ?? '').trim().isNotEmpty;

  /// Gradient hero used on mobile / tablet. The rich expanded content (glyph +
  /// title + subtitle) fades out as the bar collapses, while a compact pinned
  /// title fades in — so the two never overlap.
  Widget _buildSliverHero(BuildContext context, StoreSetupModel? store) {
    const double expandedHeight = 200;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: ColorResource.primaryDark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final double statusBarHeight = MediaQuery.of(context).padding.top;
          final double minHeight = kToolbarHeight + statusBarHeight;
          final double collapseRatio =
              ((constraints.maxHeight - minHeight) / (expandedHeight - minHeight))
                  .clamp(0.0, 1.0);
          final bool isCollapsed = collapseRatio < 0.3;

          return FlexibleSpaceBar(
            centerTitle: true,
            titlePadding: const EdgeInsets.symmetric(
              horizontal: Constants.paddingSizeExtraLarge,
              vertical: Constants.paddingSizeDefault,
            ),
            // Only the collapsed state shows the app-bar title; expanded state
            // renders its own heading inside the background.
            title: isCollapsed
                ? Text(
                    'help_and_support'.tr,
                    textAlign: TextAlign.center,
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeExtraLarge,
                      color: ColorResource.textWhite,
                    ),
                  )
                : null,
            background: _HeroBackground(contentOpacity: collapseRatio),
          );
        },
      ),
    );
  }
}

/// Decorative gradient background for the hero (mobile) — brand circles plus a
/// support glyph, heading and subtitle. [contentOpacity] fades the heading out
/// as the bar collapses so it never clashes with the pinned title.
class _HeroBackground extends StatelessWidget {
  final double contentOpacity;
  const _HeroBackground({required this.contentOpacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: ColorResource.primaryGradient),
      child: Stack(
        children: [
          Positioned(top: -30, right: -30, child: _circle(140, 0.06)),
          Positioned(bottom: -20, left: -20, child: _circle(110, 0.06)),
          SafeArea(
            child: Opacity(
              opacity: contentOpacity,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Constants.paddingSizeLarge,
                  Constants.paddingSizeSmall,
                  Constants.paddingSizeLarge,
                  Constants.paddingSizeLarge,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(Constants.paddingSizeSmall),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.support_agent_rounded,
                          color: Colors.white, size: 26),
                    ),
                    const SizedBox(height: Constants.paddingSizeSmall),
                    Text(
                      'help_and_support'.tr,
                      style: poppinsBold.copyWith(
                        fontSize: Constants.fontSizeOverLarge,
                        color: ColorResource.textWhite,
                      ),
                    ),
                    const SizedBox(height: Constants.paddingSizeExtraSmall),
                    Text(
                      'help_support_subtitle'.tr,
                      style: poppinsMedium.copyWith(
                        fontSize: Constants.fontSizeSmall,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, double alpha) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: alpha),
        ),
      );
}

/// Rounded gradient banner used at the top of the desktop-web layout (where the
/// page keeps the shared web top-nav instead of a sliver app bar).
class _WebHeader extends StatelessWidget {
  final StoreSetupModel? store;
  const _WebHeader({this.store});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Constants.paddingSizeExtraLarge),
      decoration: BoxDecoration(
        gradient: ColorResource.primaryGradient,
        borderRadius: BorderRadius.circular(Constants.radiusExtraLarge),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(Constants.paddingSizeDefault),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.support_agent_rounded,
                color: Colors.white, size: 30),
          ),
          const SizedBox(width: Constants.paddingSizeDefault),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'help_and_support'.tr,
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeOverLarge,
                    color: ColorResource.textWhite,
                  ),
                ),
                const SizedBox(height: Constants.paddingSizeExtraSmall),
                Text(
                  'help_support_subtitle'.tr,
                  style: poppinsRegular.copyWith(
                    fontSize: Constants.fontSizeDefault,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A grouped card listing every reachable contact channel, each row tappable.
class _ContactCard extends StatelessWidget {
  final StoreSetupModel store;
  final void Function(String phone) onCall;
  final void Function(String email) onEmail;
  final void Function(String url) onWeb;
  final VoidCallback onDirections;

  const _ContactCard({
    required this.store,
    required this.onCall,
    required this.onEmail,
    required this.onWeb,
    required this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final rows = <Widget>[
      if (store.phone.trim().isNotEmpty)
        _ContactRow(
          icon: Icons.call_rounded,
          label: 'phone_number'.tr,
          value: store.phone,
          actionIcon: Icons.call_outlined,
          onTap: () => onCall(store.phone),
        ),
      if (store.email.trim().isNotEmpty)
        _ContactRow(
          icon: Icons.mail_outline_rounded,
          label: 'email_address'.tr,
          value: store.email,
          actionIcon: Icons.north_east_rounded,
          onTap: () => onEmail(store.email),
        ),
      if (store.address.trim().isNotEmpty)
        _ContactRow(
          icon: Icons.location_on_outlined,
          label: 'store_address'.tr,
          value: [store.address, store.city, store.state, store.zipCode]
              .where((e) => e.trim().isNotEmpty)
              .join(', '),
          actionIcon: Icons.directions_outlined,
          onTap: onDirections,
        ),
      if ((store.website ?? '').trim().isNotEmpty)
        _ContactRow(
          icon: Icons.language_rounded,
          label: 'website'.tr,
          value: store.website!,
          actionIcon: Icons.north_east_rounded,
          onTap: () => onWeb(store.website!),
        ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.22)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1)
              Divider(
                height: 1,
                indent: 60,
                color: theme.dividerColor
                    .withValues(alpha: isDark ? 0.45 : 0.3),
              ),
          ],
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final IconData actionIcon;
  final VoidCallback onTap;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.actionIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Constants.paddingSizeDefault,
        vertical: Constants.paddingSizeExtraSmall,
      ),
      leading: Container(
        padding: const EdgeInsets.all(Constants.paddingSizeSmall),
        decoration: BoxDecoration(
          color:
              ColorResource.primaryDark.withValues(alpha: isDark ? 0.18 : 0.1),
          borderRadius: BorderRadius.circular(Constants.radiusDefault),
        ),
        child: Icon(icon, color: ColorResource.primaryDark, size: 22),
      ),
      title: Text(
        label,
        style: poppinsRegular.copyWith(
          fontSize: Constants.fontSizeSmall,
          color: isDark ? Colors.white60 : context.textSecondary,
        ),
      ),
      subtitle: Text(
        value,
        style: poppinsMedium.copyWith(
          fontSize: Constants.fontSizeDefault,
          color: isDark ? Colors.white : context.textPrimary,
        ),
      ),
      trailing: DirectionalFlip(
        child: Icon(actionIcon,
            size: 18,
            color: isDark ? Colors.white54 : ColorResource.primaryMedium),
      ),
    );
  }
}

/// Row of circular social buttons — only the platforms the store filled in.
class _SocialRow extends StatelessWidget {
  final StoreSetupModel store;
  final void Function(String url) onTap;

  const _SocialRow({required this.store, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[
      if ((store.facebook ?? '').trim().isNotEmpty)
        _SocialButton(
          icon: Icons.facebook_rounded,
          color: const Color(0xFF1877F2),
          onTap: () => onTap(store.facebook!),
        ),
      if ((store.instagram ?? '').trim().isNotEmpty)
        _SocialButton(
          icon: Icons.camera_alt_rounded,
          color: const Color(0xFFE1306C),
          onTap: () => onTap(store.instagram!),
        ),
      if ((store.twitter ?? '').trim().isNotEmpty)
        _SocialButton(
          icon: Icons.alternate_email_rounded,
          color: const Color(0xFF1DA1F2),
          onTap: () => onTap(store.twitter!),
        ),
      if ((store.website ?? '').trim().isNotEmpty)
        _SocialButton(
          icon: Icons.public_rounded,
          color: ColorResource.primaryDark,
          onTap: () => onTap(store.website!),
        ),
    ];

    return Row(
      children: [
        for (final button in buttons) ...[
          button,
          const SizedBox(width: Constants.paddingSizeDefault),
        ],
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Constants.radiusExtraLarge),
      child: Container(
        padding: const EdgeInsets.all(Constants.paddingSizeDefault),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}

/// Closing call-to-action encouraging the user to reach out directly.
class _StillNeedHelpCard extends StatelessWidget {
  final StoreSetupModel? store;
  final VoidCallback onContact;

  const _StillNeedHelpCard({required this.store, required this.onContact});

  @override
  Widget build(BuildContext context) {
    final canContact = store != null &&
        (store!.phone.trim().isNotEmpty || store!.email.trim().isNotEmpty);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Constants.paddingSizeLarge),
      decoration: BoxDecoration(
        gradient: ColorResource.primaryGradient,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'still_need_help'.tr,
            style: poppinsBold.copyWith(
              fontSize: Constants.fontSizeLarge,
              color: ColorResource.textWhite,
            ),
          ),
          const SizedBox(height: Constants.paddingSizeExtraSmall),
          Text(
            'still_need_help_desc'.tr,
            style: poppinsRegular.copyWith(
              fontSize: Constants.fontSizeSmall,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          if (canContact) ...[
            const SizedBox(height: Constants.paddingSizeDefault),
            GestureDetector(
              onTap: onContact,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Constants.paddingSizeLarge,
                  vertical: Constants.paddingSizeSmall,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(Constants.radiusExtraLarge),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.support_agent_rounded,
                        size: 18, color: ColorResource.primaryDark),
                    const SizedBox(width: Constants.paddingSizeExtraSmall),
                    Text(
                      'contact_support'.tr,
                      style: poppinsBold.copyWith(
                        fontSize: Constants.fontSizeSmall,
                        color: ColorResource.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
