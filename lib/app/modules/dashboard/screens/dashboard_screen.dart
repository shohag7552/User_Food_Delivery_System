import 'dart:async';
import 'dart:io';

import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:appwrite_user_app/app/modules/dashboard/screens/home_page.dart';
import 'package:appwrite_user_app/app/modules/dashboard/screens/profile_page.dart';
import 'package:appwrite_user_app/app/modules/cart/screens/cart_page.dart';
import 'package:appwrite_user_app/app/modules/favorites/screens/favorites_screen.dart';
import 'package:appwrite_user_app/app/modules/orders/screens/orders_page.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:flutter/material.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/controllers/cart_controller.dart';
import 'package:appwrite_user_app/app/controllers/favorites_controller.dart';
import 'package:appwrite_user_app/app/controllers/cart_animation_controller.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late PageController _pageController;
  int _selectedIndex = 0;
  bool _canExit = false;

  // Pages
  final List<Widget> _pages = [
    const HomePage(),
    const FavoritesScreen(),
    const CartPage(),
    const OrdersPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    
    // Load favorites
    Get.find<FavoritesController>().fetchFavorites(canUpdate: false);
    
    // Load cart items (using hardcoded user_id for now)
    Get.find<CartController>().getCartItems();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onNavItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (_selectedIndex != 0) {
          _onNavItemTapped(0);
        } else {
          if(_canExit) {
            if (GetPlatform.isAndroid) {
              SystemNavigator.pop();
            } else if (GetPlatform.isIOS) {
              exit(0);
            }
          }else {
            customToster('back_press_again_to_exit'.tr, isSuccess: true);
            _canExit = true;
            Timer(const Duration(seconds: 2), () {
              _canExit = false;
            });
          }
        }
      },
      child: Scaffold(
        backgroundColor: ColorResource.scaffoldBackground,
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          physics: const BouncingScrollPhysics(),
          children: _pages,
        ),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: ColorResource.cardBackground,
        boxShadow: [
          BoxShadow(
            color: ColorResource.shadowMedium,
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', 0),
              _buildNavItem(Icons.favorite, 'Favorites', 1),
              _buildCartNavItem(),
              _buildNavItem(Icons.receipt_long, 'Orders', 3),
              _buildNavItem(Icons.person, 'Profile', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onNavItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? ColorResource.primaryGradient : null,
          borderRadius: BorderRadius.circular(Constants.radiusLarge),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? ColorResource.textWhite
                  : ColorResource.textSecondary,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeSmall,
                  color: ColorResource.textWhite,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCartNavItem() {
    final isSelected = _selectedIndex == 2;

    return GetBuilder<CartController>(
      builder: (cartController) {
        final itemCount = cartController.itemCount;
        final hasItems = itemCount > 0;

        return GestureDetector(
          onTap: () {
            // Get.to(() => const CartPage());
            _onNavItemTapped(2);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? ColorResource.primaryGradient
                  : (hasItems
                      ? LinearGradient(
                          colors: [
                            ColorResource.primaryDark.withValues(alpha: 0.15),
                            ColorResource.primaryDark.withValues(alpha: 0.08),
                          ],
                        )
                      : null),
              borderRadius: BorderRadius.circular(Constants.radiusLarge),
              border: hasItems && !isSelected
                  ? Border.all(
                      color: ColorResource.primaryDark.withValues(alpha: 0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  key: Get.find<CartAnimationController>().cartIconKey,
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.shopping_cart,
                      color: isSelected
                          ? ColorResource.textWhite
                          : (hasItems
                              ? ColorResource.primaryDark
                              : ColorResource.textSecondary),
                      size: 24,
                    ),
                    if (hasItems)
                      Positioned(
                        right: -8,
                        top: -8,
                        child: TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 500),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: 0.8 + (0.2 * value),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      ColorResource.error,
                                      ColorResource.error.withValues(alpha: 0.8),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: ColorResource.error
                                          .withValues(alpha: 0.5),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Center(
                                  child: Text(
                                    itemCount > 99 ? '99+' : '$itemCount',
                                    style: poppinsBold.copyWith(
                                      fontSize: 10,
                                      color: ColorResource.textWhite,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Cart',
                    style: poppinsMedium.copyWith(
                      fontSize: Constants.fontSizeSmall,
                      color: ColorResource.textWhite,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
