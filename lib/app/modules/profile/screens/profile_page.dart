import 'package:appwrite_user_app/app/common/widgets/auth_dialog.dart';
import 'package:appwrite_user_app/app/common/widgets/directional_flip.dart';
import 'package:appwrite_user_app/app/controllers/auth_controller.dart';
import 'package:appwrite_user_app/app/controllers/localization_controller.dart';
import 'package:appwrite_user_app/app/controllers/policy_controller.dart';
import 'package:appwrite_user_app/app/controllers/profile_controller.dart';
import 'package:appwrite_user_app/app/helper/currency_helper.dart';
import 'package:appwrite_user_app/app/helper/nav_bar_visibility.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:appwrite_user_app/app/modules/language/widgets/language_selector.dart';
import 'package:appwrite_user_app/app/helper/localization_extension_helper.dart';
import 'package:appwrite_user_app/app/modules/profile/widgets/change_password_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  @override
  void initState() {
    super.initState();

    Get.find<PolicyController>().fetchPolicies();
  }

  /// Wraps an account-only action: runs it when signed in, otherwise opens the
  /// login flow so a guest can still tap the option and be guided to sign in.
  VoidCallback _authGuard(bool isLoggedIn, VoidCallback onAuthed) {
    return isLoggedIn ? onAuthed : () => AuthFlow.openLogin(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: GetBuilder<AuthController>(
        builder: (auth) {
          final bool isLoggedIn = auth.isLoggedIn;
          return GetBuilder<ProfileController>(
        builder: (controller) {
          return RefreshIndicator(
            onRefresh: controller.fetchUserProfile,
            color: ColorResource.primaryDark,
            child: CustomScrollView(
              slivers: [
                // App Bar with User Info
                _buildSliverAppBar(controller, isLoggedIn),

                // Profile Options
                SliverToBoxAdapter(
                  child: NavClearance(
                    builder: (context, bottom) => Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, bottom),
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isLoggedIn) ...[
                          _buildGuestSignInCard(),
                          const SizedBox(height: 20),
                        ],
                        _buildSection(
                          title: 'account'.tr,
                          items: [
                            _ProfileOption(
                              icon: Icons.person_outline,
                              title: 'my_profile'.tr,
                              subtitle: 'my_profile_subtitle'.tr,
                              onTap: _authGuard(isLoggedIn, () {
                                context.pushNamed(RouteNames.editProfile);
                              }),
                            ),
                            _ProfileOption(
                              icon: Icons.location_on_outlined,
                              title: 'saved_addresses'.tr,
                              subtitle: 'manage_delivery_addresses'.tr,
                              onTap: _authGuard(isLoggedIn, () {
                                context.pushNamed(RouteNames.addresses);
                              }),
                            ),
                            _ProfileOption(
                              icon: Icons.lock_outline_rounded,
                              title: 'change_password'.trClean,
                              subtitle: 'update_your_account_password'.trClean,
                              onTap: _authGuard(isLoggedIn, () {
                                ChangePasswordDialog.show(context);
                              }),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        _buildSection(
                          title: 'orders_and_activity'.tr,
                          items: [
                            _ProfileOption(
                              icon: Icons.history,
                              title: 'order_history'.tr,
                              subtitle: 'order_history_subtitle'.tr,
                              onTap: _authGuard(isLoggedIn, () {
                                context.pushNamed(RouteNames.orderHistory);
                              }),
                            ),
                            _ProfileOption(
                              icon: Icons.favorite_outline,
                              title: 'favorites'.tr,
                              subtitle: 'favorites_subtitle'.tr,
                              onTap: _authGuard(isLoggedIn, () {
                                context.pushNamed(
                                  RouteNames.favorites,
                                  queryParameters: {'fromMenu': 'true'},
                                );
                              }),
                            ),
                            // _ProfileOption(
                            //   icon: Icons.star_outline,
                            //   title: 'reviews_and_ratings'.tr,
                            //   subtitle: 'your_reviews_on_items'.tr,
                            //   onTap: () {
                            //     Get.snackbar('reviews_and_ratings'.tr, 'feature_coming_soon'.tr);
                            //   },
                            // ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        _buildSection(
                          title: 'offers_and_rewards'.tr,
                          items: [
                            _ProfileOption(
                              icon: Icons.local_offer_outlined,
                              title: 'coupons'.tr,
                              subtitle: 'view_and_apply_promo_codes'.tr,
                              trailing: _buildBadge('3'),
                              onTap: _authGuard(isLoggedIn, () {
                                context.pushNamed(RouteNames.coupons);
                              }),
                            ),
                            _ProfileOption(
                              icon: Icons.card_giftcard_outlined,
                              title: 'loyalty_points'.tr,
                              subtitle: 'earn_and_redeem_points'.tr,
                              onTap: _authGuard(isLoggedIn, () {
                                context.pushNamed(RouteNames.loyalty);
                              }),
                            ),
                            // _ProfileOption(
                            //   icon: Icons.share_outlined,
                            //   title: 'refer_and_earn'.tr,
                            //   subtitle: 'invite_friends_and_get_rewards'.tr,
                            //   onTap: () {
                            //     Get.snackbar('refer_and_earn'.tr, 'feature_coming_soon'.tr);
                            //   },
                            // ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        _buildSection(
                          title: 'app_settings'.tr,
                          items: [
                            _ProfileOption(
                              icon: Icons.notifications_outlined,
                              title: 'notifications_title'.tr,
                              subtitle: 'manage_notification_preferences'.tr,
                              onTap: _authGuard(isLoggedIn, () {
                                context.pushNamed(RouteNames.notifications);
                              }),
                            ),
                            GetBuilder<LocalizationController>(
                              builder: (localizationController) {
                                return _ThemeModeOption(
                                  isDarkMode: localizationController.darkTheme,
                                  onChanged: (value) {
                                    localizationController.setTheme(
                                      isDark: value,
                                    );
                                  },
                                );
                              },
                            ),
                            GetBuilder<LocalizationController>(
                              builder: (localeController) {
                                final selectedLang = localeController.languages.isNotEmpty
                                    ? localeController.languages[localeController.selectedLanguageIndex]
                                    : null;
                                return _ProfileOption(
                                  icon: Icons.language_outlined,
                                   title: 'language'.tr,
                                  subtitle: selectedLang?.languageName ?? 'English',
                                  onTap: () {
                                    LanguageSelector.show(context);
                                  },
                                );
                              },
                            ),
                            _ProfileOption(
                              icon: Icons.help_outline,
                              title: 'help_and_support'.tr,
                              subtitle: 'get_help_or_contact_us'.tr,
                              onTap: () {
                                context.pushNamed(RouteNames.helpSupport);
                              },
                            ),
                            _ProfileOption(
                              icon: Icons.info_outline,
                              title: 'about_us'.tr,
                              subtitle: 'learn_more_about_us'.tr,
                              onTap: () {
                                context.pushNamed(
                                  RouteNames.policy,
                                  pathParameters: {'type': PolicyType.aboutUs},
                                );
                              },
                            ),
                            _ProfileOption(
                              icon: Icons.description_outlined,
                              title: 'terms_and_conditions_title'.tr,
                              subtitle: 'read_our_terms'.tr,
                              onTap: () {
                                context.pushNamed(
                                  RouteNames.policy,
                                  pathParameters: {'type': PolicyType.terms},
                                );
                              },
                            ),
                            _ProfileOption(
                              icon: Icons.privacy_tip_outlined,
                              title: 'privacy_policy_title'.tr,
                              subtitle: 'read_our_privacy_policy'.tr,
                              onTap: () {
                                context.pushNamed(
                                  RouteNames.policy,
                                  pathParameters: {'type': PolicyType.privacy},
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        _buildSection(
                          title: 'account_actions'.tr,
                          items: isLoggedIn
                              ? [
                                  _ProfileOption(
                                    icon: Icons.logout,
                                    title: 'logout'.tr,
                                    subtitle: 'sign_out_of_your_account'.tr,
                                    iconColor: ColorResource.error,
                                    onTap: () {
                                      _showLogoutDialog(context);
                                    },
                                  ),
                                  _ProfileOption(
                                    icon: Icons.delete_outline,
                                    title: 'delete_account'.tr,
                                    subtitle:
                                        'permanently_delete_your_account'.tr,
                                    iconColor: ColorResource.error,
                                    onTap: () {
                                      _showDeleteAccountDialog(context);
                                    },
                                  ),
                                ]
                              : [
                                  _ProfileOption(
                                    icon: Icons.login_rounded,
                                    title: 'login'.tr,
                                    subtitle:
                                        'login_to_access_this_section'.tr,
                                    onTap: () => AuthFlow.openLogin(context),
                                  ),
                                ],
                        ),

                        const SizedBox(height: 20),

                        // App Version
                        Center(
                          child: Text(
                            '${'version'.tr}: ${Constants.appVersion}',
                            style: poppinsRegular.copyWith(
                              fontSize: Constants.fontSizeSmall,
                              color: isDark
                                  ? Colors.white54
                                  : context.textLight,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  ),
                ),
              ],
            ),
          );
        },
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(ProfileController controller, bool isLoggedIn) {
    final user = controller.userProfile;

    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: ColorResource.primaryDark,
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // Calculate collapse ratio (0.0 = fully expanded, 1.0 = fully collapsed)
          final double appBarHeight = constraints.maxHeight;
          final double statusBarHeight = MediaQuery.of(context).padding.top;
          final double minHeight = kToolbarHeight + statusBarHeight;
          final double collapseRatio = ((appBarHeight - minHeight) / (180 - minHeight)).clamp(0.0, 1.0);
          final bool isCollapsed = collapseRatio < 0.1; // Fully collapsed threshold

          return FlexibleSpaceBar(
            title: isCollapsed ? Padding(
              padding: const EdgeInsets.only(bottom: Constants.paddingSizeSmall),
              child: Text(
                'profile'.tr,
                style: poppinsBold.copyWith(color: Colors.white, fontSize: Constants.fontSizeExtraLarge),
              ),
            ) : null,
            titlePadding: isCollapsed ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8) : null,
            background: Container(
              decoration: BoxDecoration(
                gradient: ColorResource.primaryGradient,
              ),
              child: SafeArea(
                child: controller.isLoading
                    ? Center(
                  child: CircularProgressIndicator(
                    color: ColorResource.textWhite,
                  ),
                )
                    : Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Profile Picture
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ColorResource.textWhite,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: ColorResource.textWhite,
                          child: !isLoggedIn
                              ? _buildGuestAvatar()
                              : (user?.profileImageUrl != null
                                  ? ClipOval(
                                      child: Image.network(
                                        user!.profileImageUrl!,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return _buildAvatarPlaceholder(user);
                                        },
                                      ),
                                    )
                                  : _buildAvatarPlaceholder(user)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (isLoggedIn) ...[
                        Text(
                          user?.name ?? 'Loading...',
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
                            color:
                                ColorResource.textWhite.withValues(alpha: 0.9),
                          ),
                        ),
                      ] else ...[
                        // Guest: a compact identity line (same height as the
                        // signed-in name + balance, so the header never
                        // overflows). The prominent sign-in CTA is the card at
                        // the top of the list below.
                        Text(
                          'guest_user'.tr,
                          style: poppinsBold.copyWith(
                            fontSize: Constants.fontSizeLarge,
                            color: ColorResource.textWhite,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'browsing_as_guest'.tr,
                          style: poppinsRegular.copyWith(
                            fontSize: Constants.fontSizeDefault,
                            color:
                                ColorResource.textWhite.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Prominent, tappable "sign in / create account" card shown at the top of
  /// the list for guests — the primary call to action, kept out of the header
  /// so nothing overflows.
  Widget _buildGuestSignInCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => AuthFlow.openLogin(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(Constants.radiusLarge),
          border: Border.all(
            color: ColorResource.primaryDark.withValues(alpha: 0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.22)
                  : ColorResource.primaryDark.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorResource.primaryDark
                    .withValues(alpha: isDark ? 0.20 : 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_outline_rounded,
                color: ColorResource.primaryDark,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'guest_cta_title'.tr,
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeDefault,
                      color: isDark ? Colors.white : context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'guest_cta_subtitle'.tr,
                    style: poppinsRegular.copyWith(
                      fontSize: Constants.fontSizeSmall,
                      color: isDark ? Colors.white60 : context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                gradient: ColorResource.primaryGradient,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'login'.tr,
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeSmall,
                  color: ColorResource.textWhite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Avatar shown for signed-out guests — a person glyph on the brand gradient.
  Widget _buildGuestAvatar() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: ColorResource.primaryGradient,
      ),
      child: const Center(
        child: Icon(
          Icons.person_rounded,
          size: 42,
          color: ColorResource.textWhite,
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(dynamic user) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: ColorResource.primaryGradient,
      ),
      child: Center(
        child: Text(
          user?.initials ?? '?',
          style: poppinsBold.copyWith(
            fontSize: 32,
            color: ColorResource.textWhite,
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> items,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            title,
            style: poppinsBold.copyWith(
              fontSize: Constants.fontSizeDefault,
              color: isDark ? Colors.white70 : context.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
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
          child: Material(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(Constants.radiusLarge),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: List.generate(items.length, (index) {
                final isLast = index == items.length - 1;
                return Column(
                  children: [
                    items[index],
                    if (!isLast)
                      Divider(
                        height: 1,
                        indent: 60,
                        color: theme.dividerColor.withValues(
                          alpha: isDark ? 0.45 : 0.3,
                        ),
                      ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ColorResource.error,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        count,
        style: poppinsBold.copyWith(
          fontSize: 12,
          color: ColorResource.textWhite,
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'cancel'.tr,
              style: poppinsMedium.copyWith(color: context.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              // Get AuthController and call logout
              final authController = Get.find<AuthController>();
              await authController.logout();

              // Return to the dashboard as a guest (login is offered on demand).
              if (context.mounted) context.goNamed(RouteNames.dashboard);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorResource.error,
            ),
            child: Text(
              'logout'.tr,
              style: poppinsBold.copyWith(color: ColorResource.textWhite),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'delete_account'.tr,
          style: poppinsBold.copyWith(fontSize: Constants.fontSizeLarge),
        ),
        content: Text(
          'delete_account_warning'.tr,
          style: poppinsRegular.copyWith(fontSize: Constants.fontSizeDefault),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'cancel'.tr,
              style: poppinsMedium.copyWith(color: context.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await Get.find<AuthController>().deleteAccount();
              if (ok && context.mounted) {
                context.goNamed(RouteNames.dashboard);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorResource.error,
            ),
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

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Color? iconColor;
  final VoidCallback onTap;

  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final resolvedIconColor = iconColor ?? ColorResource.primaryDark;

    return ListTile(
      contentPadding: theme.listTileTheme.contentPadding,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: resolvedIconColor.withValues(alpha: isDark ? 0.18 : 0.1),
          borderRadius: BorderRadius.circular(Constants.radiusDefault),
        ),
        child: Icon(
          icon,
          color: resolvedIconColor,
          size: 24,
        ),
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
          fontSize: Constants.fontSizeSmall,
          color: isDark ? Colors.white60 : context.textSecondary,
        ),
      ),
      trailing: trailing ??
          DirectionalFlip(
            child: Icon(
              Icons.chevron_right,
              color: isDark ? Colors.white38 : context.textLight,
            ),
          ),
      onTap: onTap,
    );
  }
}

class _ThemeModeOption extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onChanged;

  const _ThemeModeOption({
    required this.isDarkMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListTile(
      contentPadding: theme.listTileTheme.contentPadding,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: ColorResource.primaryDark.withValues(alpha: isDark ? 0.18 : 0.1),
          borderRadius: BorderRadius.circular(Constants.radiusDefault),
        ),
        child: Icon(
          isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
          color: ColorResource.primaryDark,
          size: 24,
        ),
      ),
      title: Text(
        'Dark mode',
        style: poppinsMedium.copyWith(
          fontSize: Constants.fontSizeDefault,
          color: isDark ? Colors.white : context.textPrimary,
        ),
      ),
      subtitle: Text(
        isDarkMode
            ? 'Use a darker appearance across the app'
            : 'Switch to a brighter appearance across the app',
        style: poppinsRegular.copyWith(
          fontSize: Constants.fontSizeSmall,
          color: isDark ? Colors.white60 : context.textSecondary,
        ),
      ),
      trailing: Switch.adaptive(
        value: isDarkMode,
        onChanged: onChanged,
      ),
      onTap: () => onChanged(!isDarkMode),
    );
  }
}
