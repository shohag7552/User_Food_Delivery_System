import 'package:appwrite_user_app/app/controllers/cart_controller.dart';
import 'package:appwrite_user_app/app/modules/search/screens/search_page.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Shared web/desktop top navigation bar.
///
/// Layout: [Brand] [Home] [Favorites] ──search── [Cart] [Orders] [Profile] [Menu]
///
/// [selectedIndex] highlights the active destination (pass null on sub-pages so
/// nothing is highlighted). Destinations map to the dashboard tab indices:
/// 0 Home · 1 Favorites · 2 Cart · 3 Orders · 4 Profile.
class WebTopNav extends StatelessWidget implements PreferredSizeWidget {
  final int? selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onMenuTap;

  const WebTopNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onMenuTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: ColorResource.cardBackground,
      elevation: 0.5,
      shadowColor: isDark
          ? Colors.black.withValues(alpha: 0.4)
          : Colors.black.withValues(alpha: 0.08),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bool showLabels = constraints.maxWidth >= 720;
                return Padding(
                  padding: EdgeInsets.only(left: showLabels ? 20 : 12),
                  child: SizedBox(
                    height: 64,
                    child: Row(
                      children: [
                        // Brand — capped so it never crowds the nav items.
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 160),
                          child: ShaderMask(
                            shaderCallback: (bounds) => ColorResource
                                .primaryGradient
                                .createShader(bounds),
                            child: Text(
                              Constants.appName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: poppinsBold.copyWith(
                                fontSize: Constants.fontSizeOverLarge,
                                color: ColorResource.textWhite,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _navItem(Icons.home_rounded, 'home'.tr, 0, showLabels),
                        _navItem(
                          Icons.favorite_rounded,
                          'favorites'.tr,
                          1,
                          showLabels,
                        ),
                        // Centered search pill.
                        Expanded(
                          child: Center(
                            child: ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxWidth: 400),
                              child: GestureDetector(
                                onTap: () => Get.to(() => const SearchPage()),
                                child: Container(
                                  height: 38,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: ColorResource.scaffoldBackground,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: ColorResource.textLight
                                          .withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.search_rounded,
                                        size: 18,
                                        color: ColorResource.textSecondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'search_products'.tr,
                                          style: poppinsRegular.copyWith(
                                            fontSize: Constants.fontSizeDefault,
                                            color: ColorResource.textLight,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _cartItem(),
                        _navItem(
                          Icons.receipt_long_rounded,
                          'orders'.tr,
                          3,
                          false,
                        ),
                        _navItem(
                          Icons.person_rounded,
                          'profile'.tr,
                          4,
                          false,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 16,
                          ),
                          child: VerticalDivider(
                            width: 1,
                            color: ColorResource.textLight
                                .withValues(alpha: 0.25),
                          ),
                        ),
                        _menuButton(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuButton() {
    return Tooltip(
      message: 'menu'.tr,
      child: InkWell(
        onTap: onMenuTap,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        hoverColor: ColorResource.primaryDark.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            Icons.menu_rounded,
            size: 22,
            color: ColorResource.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index, bool showLabel) {
    final isSelected = selectedIndex == index;
    final color = isSelected
        ? ColorResource.primaryDark
        : ColorResource.textSecondary;

    return Padding(
      padding: EdgeInsets.only(left: showLabel ? 8 : 2),
      child: Tooltip(
        message: showLabel ? '' : label,
        child: InkWell(
          onTap: () => onDestinationSelected(index),
          borderRadius: BorderRadius.circular(Constants.radiusLarge),
          hoverColor: ColorResource.primaryDark.withValues(alpha: 0.06),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: showLabel ? 14 : 10,
              vertical: 10,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 22),
                if (showLabel) ...[
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: (isSelected ? poppinsBold : poppinsMedium).copyWith(
                      fontSize: Constants.fontSizeDefault,
                      color: color,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cartItem() {
    return GetBuilder<CartController>(
      builder: (cartController) {
        final itemCount = cartController.itemCount;
        final isSelected = selectedIndex == 2;
        final color = isSelected
            ? ColorResource.primaryDark
            : ColorResource.textSecondary;

        return Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Tooltip(
            message: 'cart'.tr,
            child: InkWell(
              onTap: () => onDestinationSelected(2),
              borderRadius: BorderRadius.circular(Constants.radiusLarge),
              hoverColor: ColorResource.primaryDark.withValues(alpha: 0.06),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(Icons.shopping_cart_rounded, color: color, size: 22),
                    if (itemCount > 0)
                      Positioned(
                        right: -8,
                        top: -8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: ColorResource.error,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Center(
                            child: Text(
                              itemCount > 99 ? '99+' : '$itemCount',
                              style: poppinsBold.copyWith(
                                fontSize: 9,
                                color: ColorResource.textWhite,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
