import 'package:appwrite_user_app/app/modules/address/screens/addresses_page.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorResource.scaffoldBackground,
      body: CustomScrollView(
        slivers: [
          // App Bar with User Info
          _buildSliverAppBar(),
          
          // Profile Options
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    title: 'Account',
                    items: [
                      _ProfileOption(
                        icon: Icons.person_outline,
                        title: 'My Profile',
                        subtitle: 'Edit your personal information',
                        onTap: () {
                          // TODO: Navigate to edit profile
                          Get.snackbar('My Profile', 'Feature coming soon');
                        },
                      ),
                      _ProfileOption(
                        icon: Icons.location_on_outlined,
                        title: 'Saved Addresses',
                        subtitle: 'Manage your delivery addresses',
                        onTap: () {
                          Get.to(AddressesPage());
                          // Get.snackbar('Addresses', 'Feature coming soon');
                        },
                      ),
                      _ProfileOption(
                        icon: Icons.payment_outlined,
                        title: 'Payment Methods',
                        subtitle: 'Manage your payment options',
                        onTap: () {
                          Get.snackbar('Payment Methods', 'Feature coming soon');
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildSection(
                    title: 'Orders & Activity',
                    items: [
                      _ProfileOption(
                        icon: Icons.history,
                        title: 'Order History',
                        subtitle: 'View your past orders',
                        onTap: () {
                          Get.snackbar('Order History', 'Feature coming soon');
                        },
                      ),
                      _ProfileOption(
                        icon: Icons.favorite_outline,
                        title: 'Favorites',
                        subtitle: 'Your favorite items',
                        onTap: () {
                          Get.snackbar('Favorites', 'Feature coming soon');
                        },
                      ),
                      _ProfileOption(
                        icon: Icons.star_outline,
                        title: 'Reviews & Ratings',
                        subtitle: 'Your reviews on items',
                        onTap: () {
                          Get.snackbar('Reviews', 'Feature coming soon');
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildSection(
                    title: 'Offers & Rewards',
                    items: [
                      _ProfileOption(
                        icon: Icons.local_offer_outlined,
                        title: 'Coupons',
                        subtitle: 'View and apply promo codes',
                        trailing: _buildBadge('3'),
                        onTap: () {
                          Get.snackbar('Coupons', 'Feature coming soon');
                        },
                      ),
                      _ProfileOption(
                        icon: Icons.card_giftcard_outlined,
                        title: 'Loyalty Points',
                        subtitle: 'Earn and redeem points',
                        onTap: () {
                          Get.snackbar('Loyalty Points', 'Feature coming soon');
                        },
                      ),
                      _ProfileOption(
                        icon: Icons.share_outlined,
                        title: 'Refer & Earn',
                        subtitle: 'Invite friends and get rewards',
                        onTap: () {
                          Get.snackbar('Refer & Earn', 'Feature coming soon');
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildSection(
                    title: 'App Settings',
                    items: [
                      _ProfileOption(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        subtitle: 'Manage notification preferences',
                        onTap: () {
                          Get.snackbar('Notifications', 'Feature coming soon');
                        },
                      ),
                      _ProfileOption(
                        icon: Icons.language_outlined,
                        title: 'Language',
                        subtitle: 'English',
                        onTap: () {
                          Get.snackbar('Language', 'Feature coming soon');
                        },
                      ),
                      _ProfileOption(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        subtitle: 'Get help or contact us',
                        onTap: () {
                          Get.snackbar('Help & Support', 'Feature coming soon');
                        },
                      ),
                      _ProfileOption(
                        icon: Icons.info_outline,
                        title: 'About Us',
                        subtitle: 'Learn more about us',
                        onTap: () {
                          Get.snackbar('About Us', 'Feature coming soon');
                        },
                      ),
                      _ProfileOption(
                        icon: Icons.description_outlined,
                        title: 'Terms & Conditions',
                        subtitle: 'Read our terms',
                        onTap: () {
                          Get.snackbar('Terms & Conditions', 'Feature coming soon');
                        },
                      ),
                      _ProfileOption(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        subtitle: 'Read our privacy policy',
                        onTap: () {
                          Get.snackbar('Privacy Policy', 'Feature coming soon');
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildSection(
                    title: 'Account Actions',
                    items: [
                      _ProfileOption(
                        icon: Icons.logout,
                        title: 'Logout',
                        subtitle: 'Sign out of your account',
                        iconColor: ColorResource.error,
                        onTap: () {
                          _showLogoutDialog(context);
                        },
                      ),
                      _ProfileOption(
                        icon: Icons.delete_outline,
                        title: 'Delete Account',
                        subtitle: 'Permanently delete your account',
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
                      'Version 1.0.0',
                      style: poppinsRegular.copyWith(
                        fontSize: Constants.fontSizeSmall,
                        color: ColorResource.textLight,
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
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: ColorResource.primaryDark,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: ColorResource.primaryGradient,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: ColorResource.textWhite,
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: ColorResource.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'John Doe', // TODO: Get from auth
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeLarge,
                      color: ColorResource.textWhite,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'john.doe@example.com', // TODO: Get from auth
                    style: poppinsRegular.copyWith(
                      fontSize: Constants.fontSizeDefault,
                      color: ColorResource.textWhite.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<_ProfileOption> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            title,
            style: poppinsBold.copyWith(
              fontSize: Constants.fontSizeDefault,
              color: ColorResource.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: ColorResource.cardBackground,
            borderRadius: BorderRadius.circular(Constants.radiusLarge),
            boxShadow: ColorResource.customShadow,
          ),
          child: Column(
            children: items.map((item) {
              final isLast = items.indexOf(item) == items.length - 1;
              return Column(
                children: [
                  item,
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 60,
                      color: ColorResource.textLight.withValues(alpha: 0.2),
                    ),
                ],
              );
            }).toList(),
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
      builder: (context) => AlertDialog(
        title: Text(
          'Logout',
          style: poppinsBold.copyWith(fontSize: Constants.fontSizeLarge),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: poppinsRegular.copyWith(fontSize: Constants.fontSizeDefault),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: poppinsMedium.copyWith(color: ColorResource.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement logout
              Get.snackbar(
                'Logged Out',
                'You have been logged out successfully',
                backgroundColor: Colors.green,
                colorText: ColorResource.textWhite,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorResource.error,
            ),
            child: Text(
              'Logout',
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
          'Delete Account',
          style: poppinsBold.copyWith(fontSize: Constants.fontSizeLarge),
        ),
        content: Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone.',
          style: poppinsRegular.copyWith(fontSize: Constants.fontSizeDefault),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: poppinsMedium.copyWith(color: ColorResource.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement account deletion
              Get.snackbar(
                'Account Deletion',
                'Feature coming soon',
                backgroundColor: ColorResource.error,
                colorText: ColorResource.textWhite,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorResource.error,
            ),
            child: Text(
              'Delete',
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (iconColor ?? ColorResource.primaryDark).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(Constants.radiusDefault),
        ),
        child: Icon(
          icon,
          color: iconColor ?? ColorResource.primaryDark,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: poppinsMedium.copyWith(
          fontSize: Constants.fontSizeDefault,
          color: ColorResource.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: poppinsRegular.copyWith(
          fontSize: Constants.fontSizeSmall,
          color: ColorResource.textSecondary,
        ),
      ),
      trailing: trailing ??
          Icon(
            Icons.chevron_right,
            color: ColorResource.textLight,
          ),
      onTap: onTap,
    );
  }
}
