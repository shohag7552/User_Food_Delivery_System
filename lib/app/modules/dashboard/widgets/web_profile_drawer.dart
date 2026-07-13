import 'package:appwrite_user_app/app/controllers/auth_controller.dart';
import 'package:appwrite_user_app/app/controllers/localization_controller.dart';
import 'package:appwrite_user_app/app/controllers/policy_controller.dart';
import 'package:appwrite_user_app/app/controllers/profile_controller.dart';
import 'package:appwrite_user_app/app/helper/currency_helper.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

/// Right-side drawer shown on web. Mirrors the profile page menu sections so
/// users can reach every account/settings destination without leaving the
/// current page.
class WebProfileDrawer extends StatefulWidget {
  const WebProfileDrawer({super.key});

  @override
  State<WebProfileDrawer> createState() => _WebProfileDrawerState();
}

class _WebProfileDrawerState extends State<WebProfileDrawer> {
  @override
  void initState() {
    super.initState();
    // Ensure profile and policy data are fresh when the drawer opens.
    Get.find<ProfileController>().fetchUserProfile();
    Get.find<PolicyController>().fetchPolicies();
  }

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Drawer(
      width: 300,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          _buildHeader(isDark),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // ── Account ──────────────────────────────────────────────
                _sectionLabel('account'.tr, isDark),
                _item(
                  icon: Icons.person_outline,
                  title: 'my_profile'.tr,
                  subtitle: 'my_profile_subtitle'.tr,
                  onTap: () {
                    _close();
                    context.pushNamed(RouteNames.editProfile);
                  },
                ),
                _item(
                  icon: Icons.location_on_outlined,
                  title: 'saved_addresses'.tr,
                  subtitle: 'manage_delivery_addresses'.tr,
                  onTap: () {
                    _close();
                    context.pushNamed(RouteNames.addresses);
                  },
                ),
                _item(
                  icon: Icons.payment_outlined,
                  title: 'payment_methods'.tr,
                  subtitle: 'manage_payment_options'.tr,
                  onTap: () {
                    _close();
                    Get.snackbar('payment_methods'.tr, 'feature_coming_soon'.tr);
                  },
                ),

                // ── Orders & Activity ─────────────────────────────────────
                _sectionLabel('orders_and_activity'.tr, isDark),
                _item(
                  icon: Icons.history,
                  title: 'order_history'.tr,
                  subtitle: 'order_history_subtitle'.tr,
                  onTap: () {
                    _close();
                    context.pushNamed(RouteNames.orderHistory);
                  },
                ),
                _item(
                  icon: Icons.favorite_outline,
                  title: 'favorites'.tr,
                  subtitle: 'favorites_subtitle'.tr,
                  onTap: () {
                    _close();
                    context.pushNamed(
                      RouteNames.favorites,
                      queryParameters: {'fromMenu': 'true'},
                    );
                  },
                ),
                _item(
                  icon: Icons.star_outline,
                  title: 'reviews_and_ratings'.tr,
                  subtitle: 'your_reviews_on_items'.tr,
                  onTap: () {
                    _close();
                    Get.snackbar('reviews_and_ratings'.tr, 'feature_coming_soon'.tr);
                  },
                ),

                // ── Offers & Rewards ──────────────────────────────────────
                _sectionLabel('offers_and_rewards'.tr, isDark),
                _item(
                  icon: Icons.local_offer_outlined,
                  title: 'coupons'.tr,
                  subtitle: 'view_and_apply_promo_codes'.tr,
                  onTap: () {
                    _close();
                    context.pushNamed(RouteNames.coupons);
                  },
                ),
                _item(
                  icon: Icons.card_giftcard_outlined,
                  title: 'loyalty_points'.tr,
                  subtitle: 'earn_and_redeem_points'.tr,
                  onTap: () {
                    _close();
                    context.pushNamed(RouteNames.loyalty);
                  },
                ),
                _item(
                  icon: Icons.share_outlined,
                  title: 'refer_and_earn'.tr,
                  subtitle: 'invite_friends_and_get_rewards'.tr,
                  onTap: () {
                    _close();
                    Get.snackbar('refer_and_earn'.tr, 'feature_coming_soon'.tr);
                  },
                ),

                // ── App Settings ──────────────────────────────────────────
                _sectionLabel('app_settings'.tr, isDark),
                _item(
                  icon: Icons.notifications_outlined,
                  title: 'notifications_title'.tr,
                  subtitle: 'manage_notification_preferences'.tr,
                  onTap: () {
                    _close();
                    context.pushNamed(RouteNames.notifications);
                  },
                ),
                // Dark mode toggle mirrors the profile page control exactly.
                GetBuilder<LocalizationController>(
                  builder: (lc) => _toggle(
                    icon: lc.darkTheme
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    title: 'dark_mode'.tr,
                    subtitle: lc.darkTheme
                        ? 'Use a lighter appearance'
                        : 'Use a darker appearance',
                    value: lc.darkTheme,
                    onChanged: (v) => lc.setTheme(isDark: v),
                  ),
                ),
                GetBuilder<LocalizationController>(
                  builder: (lc) {
                    final lang = lc.languages.isNotEmpty
                        ? lc.languages[lc.selectedLanguageIndex].languageName
                        : 'English';
                    return _item(
                      icon: Icons.language_outlined,
                      title: 'language'.tr,
                      subtitle: lang,
                      onTap: () {
                        _close();
                        context.pushNamed(RouteNames.language);
                      },
                    );
                  },
                ),
                _item(
                  icon: Icons.help_outline,
                  title: 'help_and_support'.tr,
                  subtitle: 'get_help_or_contact_us'.tr,
                  onTap: () {
                    _close();
                    Get.snackbar('help_and_support'.tr, 'feature_coming_soon'.tr);
                  },
                ),
                _item(
                  icon: Icons.info_outline,
                  title: 'about_us'.tr,
                  subtitle: 'learn_more_about_us'.tr,
                  onTap: () {
                    _close();
                    context.pushNamed(
                      RouteNames.policy,
                      pathParameters: {'type': PolicyType.aboutUs},
                    );
                  },
                ),
                _item(
                  icon: Icons.description_outlined,
                  title: 'terms_and_conditions_title'.tr,
                  subtitle: 'read_our_terms'.tr,
                  onTap: () {
                    _close();
                    context.pushNamed(
                      RouteNames.policy,
                      pathParameters: {'type': PolicyType.terms},
                    );
                  },
                ),
                _item(
                  icon: Icons.privacy_tip_outlined,
                  title: 'privacy_policy_title'.tr,
                  subtitle: 'read_our_privacy_policy'.tr,
                  onTap: () {
                    _close();
                    context.pushNamed(
                      RouteNames.policy,
                      pathParameters: {'type': PolicyType.privacy},
                    );
                  },
                ),

                // ── Account Actions ───────────────────────────────────────
                _sectionLabel('account_actions'.tr, isDark),
                _item(
                  icon: Icons.logout,
                  title: 'logout'.tr,
                  subtitle: 'sign_out_of_your_account'.tr,
                  iconColor: ColorResource.error,
                  onTap: () => _showLogoutDialog(),
                ),
                _item(
                  icon: Icons.delete_outline,
                  title: 'delete_account'.tr,
                  subtitle: 'permanently_delete_your_account'.tr,
                  iconColor: ColorResource.error,
                  onTap: () => _showDeleteAccountDialog(),
                ),

                // App version — same footer as the profile page.
                const SizedBox(height: 16),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      '${'version'.tr}: ${Constants.appVersion}',
                      style: poppinsRegular.copyWith(
                        fontSize: Constants.fontSizeSmall,
                        color: isDark ? Colors.white54 : context.textLight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isDark) {
    return GetBuilder<ProfileController>(
      builder: (controller) {
        final user = controller.userProfile;
        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(gradient: ColorResource.primaryGradient),
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
          child: Column(
            children: [
              // Avatar with border ring.
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 38,
                  backgroundColor: ColorResource.textWhite,
                  child: user?.profileImageUrl != null
                      ? ClipOval(
                          child: Image.network(
                            user!.profileImageUrl!,
                            width: 76,
                            height: 76,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, st) =>
                                _avatarPlaceholder(user.initials),
                          ),
                        )
                      : _avatarPlaceholder(user?.initials ?? '?'),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                user?.name ?? '...',
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeLarge,
                  color: ColorResource.textWhite,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${'balance'.tr}: ${CurrencyHelper.formatWithSeparators(user?.walletBalance ?? 0)}',
                style: poppinsRegular.copyWith(
                  fontSize: Constants.fontSizeDefault,
                  color: ColorResource.textWhite.withValues(alpha: 0.88),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _avatarPlaceholder(String initials) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: ColorResource.primaryGradient,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: poppinsBold.copyWith(
          fontSize: 28,
          color: ColorResource.textWhite,
        ),
      ),
    );
  }

  // ── List building helpers ────────────────────────────────────────────────────

  Widget _sectionLabel(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: poppinsBold.copyWith(
          fontSize: Constants.fontSizeExtraSmall,
          letterSpacing: 0.8,
          color: isDark ? Colors.white54 : context.textSecondary,
        ),
      ),
    );
  }

  Widget _item({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedColor = iconColor ?? ColorResource.primaryDark;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: resolvedColor.withValues(alpha: isDark ? 0.18 : 0.10),
          borderRadius: BorderRadius.circular(Constants.radiusDefault),
        ),
        child: Icon(icon, color: resolvedColor, size: 20),
      ),
      title: Text(
        title,
        style: poppinsMedium.copyWith(
          fontSize: Constants.fontSizeDefault,
          color: isDark ? Colors.white : context.textPrimary,
        ),
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeExtraSmall,
                color: isDark ? Colors.white60 : context.textSecondary,
              ),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right,
        size: 18,
        color: isDark ? Colors.white30 : context.textLight,
      ),
      dense: true,
      onTap: onTap,
    );
  }

  Widget _toggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ColorResource.primaryDark.withValues(alpha: isDark ? 0.18 : 0.10),
          borderRadius: BorderRadius.circular(Constants.radiusDefault),
        ),
        child: Icon(icon, color: ColorResource.primaryDark, size: 20),
      ),
      title: Text(
        title,
        style: poppinsMedium.copyWith(
          fontSize: Constants.fontSizeDefault,
          color: isDark ? Colors.white : context.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: poppinsRegular.copyWith(
          fontSize: Constants.fontSizeExtraSmall,
          color: isDark ? Colors.white60 : context.textSecondary,
        ),
      ),
      trailing: Switch.adaptive(value: value, onChanged: onChanged),
      dense: true,
      onTap: () => onChanged(!value),
    );
  }

  // ── Dialogs ──────────────────────────────────────────────────────────────────

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'logout'.tr,
          style: poppinsBold.copyWith(fontSize: Constants.fontSizeLarge),
        ),
        content: Text(
          'are_you_sure_want_to_logout_msg'.tr,
          style: poppinsRegular.copyWith(fontSize: Constants.fontSizeDefault),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'cancel'.tr,
              style: poppinsMedium.copyWith(color: context.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ColorResource.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await Get.find<AuthController>().logout();
              // Return to the dashboard as a guest (login is offered on demand).
              if (mounted) context.goNamed(RouteNames.dashboard);
            },
            child: Text(
              'logout'.tr,
              style: poppinsBold.copyWith(color: ColorResource.textWhite),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'delete_account'.tr,
          style: poppinsBold.copyWith(fontSize: Constants.fontSizeLarge),
        ),
        content: Text(
          'are_you_sure_want_to_delete_account'.tr,
          style: poppinsRegular.copyWith(fontSize: Constants.fontSizeDefault),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'cancel'.tr,
              style: poppinsMedium.copyWith(color: context.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ColorResource.error),
            onPressed: () {
              Navigator.pop(ctx);
              Get.snackbar(
                'account_deletion'.tr,
                'feature_coming_soon'.tr,
                backgroundColor: ColorResource.error,
                colorText: ColorResource.textWhite,
              );
            },
            child: Text(
              'delete'.tr,
              style: poppinsBold.copyWith(color: ColorResource.textWhite),
            ),
          ),
        ],
      ),
    );
  }
}
