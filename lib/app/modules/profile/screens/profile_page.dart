import 'package:appwrite_user_app/app/common/widgets/auth_gate.dart';
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
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: AuthGate(
        child: GetBuilder<ProfileController>(
        builder: (controller) {
          return RefreshIndicator(
            onRefresh: controller.fetchUserProfile,
            color: ColorResource.primaryDark,
            child: CustomScrollView(
              slivers: [
                // App Bar with User Info
                _buildSliverAppBar(controller),

                // Profile Options
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      Constants.bottomNavSpace,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSection(
                          title: 'account'.tr,
                          items: [
                            _ProfileOption(
                              icon: Icons.person_outline,
                              title: 'my_profile'.tr,
                              subtitle: 'my_profile_subtitle'.tr,
                              onTap: () {
                                context.pushNamed(RouteNames.editProfile);
                              },
                            ),
                            _ProfileOption(
                              icon: Icons.location_on_outlined,
                              title: 'saved_addresses'.tr,
                              subtitle: 'manage_delivery_addresses'.tr,
                              onTap: () {
                                context.pushNamed(RouteNames.addresses);
                              },
                            ),
                            _ProfileOption(
                              icon: Icons.payment_outlined,
                              title: 'payment_methods'.tr,
                              subtitle: 'manage_payment_options'.tr,
                              onTap: () {
                                Get.snackbar('payment_methods'.tr, 'feature_coming_soon'.tr);
                              },
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
                              onTap: () {
                                context.pushNamed(RouteNames.orderHistory);
                              },
                            ),
                            _ProfileOption(
                              icon: Icons.favorite_outline,
                              title: 'favorites'.tr,
                              subtitle: 'favorites_subtitle'.tr,
                              onTap: () {
                                context.pushNamed(
                                  RouteNames.favorites,
                                  queryParameters: {'fromMenu': 'true'},
                                );
                              },
                            ),
                            _ProfileOption(
                              icon: Icons.star_outline,
                              title: 'reviews_and_ratings'.tr,
                              subtitle: 'your_reviews_on_items'.tr,
                              onTap: () {
                                Get.snackbar('reviews_and_ratings'.tr, 'feature_coming_soon'.tr);
                              },
                            ),
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
                              onTap: () {
                                context.pushNamed(RouteNames.coupons);
                              },
                            ),
                            _ProfileOption(
                              icon: Icons.card_giftcard_outlined,
                              title: 'loyalty_points'.tr,
                              subtitle: 'earn_and_redeem_points'.tr,
                              onTap: () {
                                context.pushNamed(RouteNames.loyalty);
                              },
                            ),
                            _ProfileOption(
                              icon: Icons.share_outlined,
                              title: 'refer_and_earn'.tr,
                              subtitle: 'invite_friends_and_get_rewards'.tr,
                              onTap: () {
                                Get.snackbar('refer_and_earn'.tr, 'feature_coming_soon'.tr);
                              },
                            ),
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
                              onTap: () {
                                context.pushNamed(RouteNames.notifications);
                              },
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
                                    context.pushNamed(RouteNames.language);
                                  },
                                );
                              },
                            ),
                            _ProfileOption(
                              icon: Icons.help_outline,
                              title: 'help_and_support'.tr,
                              subtitle: 'get_help_or_contact_us'.tr,
                              onTap: () {
                                Get.snackbar('help_and_support'.tr, 'feature_coming_soon'.tr);
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
                          items: [
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
                              subtitle: 'permanently_delete_your_account'.tr,
                              iconColor: ColorResource.error,
                              onTap: () {
                                _showDeleteAccountDialog(context);
                              },
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
                                  : ColorResource.textLight,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      ),
    );
  }

  Widget _buildSliverAppBar(ProfileController controller) {
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
                          child: user?.profileImageUrl != null
                              ? ClipOval(
                            child: Image.network(
                              user!.profileImageUrl!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildAvatarPlaceholder(user);
                              },
                            ),
                          )
                              : _buildAvatarPlaceholder(user),
                        ),
                      ),
                      const SizedBox(height: 12),
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
                          color: ColorResource.textWhite.withValues(alpha: 0.9),
                        ),
                      ),
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
              color: isDark ? Colors.white70 : ColorResource.textSecondary,
            ),
          ),
        ),
        Container(
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
              style: poppinsMedium.copyWith(color: ColorResource.textSecondary),
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
          'are_you_sure_want_to_delete_account'.tr,
          style: poppinsRegular.copyWith(fontSize: Constants.fontSizeDefault),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'cancel'.tr,
              style: poppinsMedium.copyWith(color: ColorResource.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement account deletion
              Get.snackbar(
                'account_deletion'.tr,
                'feature_coming_soon'.tr,
                backgroundColor: ColorResource.error,
                colorText: ColorResource.textWhite,
              );
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
          color: isDark ? Colors.white : ColorResource.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: poppinsRegular.copyWith(
          fontSize: Constants.fontSizeSmall,
          color: isDark ? Colors.white60 : ColorResource.textSecondary,
        ),
      ),
      trailing: trailing ??
          Icon(
            Icons.chevron_right,
            color: isDark ? Colors.white38 : ColorResource.textLight,
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
          color: isDark ? Colors.white : ColorResource.textPrimary,
        ),
      ),
      subtitle: Text(
        isDarkMode
            ? 'Use a darker appearance across the app'
            : 'Switch to a brighter appearance across the app',
        style: poppinsRegular.copyWith(
          fontSize: Constants.fontSizeSmall,
          color: isDark ? Colors.white60 : ColorResource.textSecondary,
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
