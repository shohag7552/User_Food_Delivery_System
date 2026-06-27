import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:appwrite_user_app/app/helper/platform/app_exit.dart';

import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:appwrite_user_app/app/controllers/cart_animation_controller.dart';
import 'package:appwrite_user_app/app/controllers/cart_controller.dart';
import 'package:appwrite_user_app/app/controllers/favorites_controller.dart';
import 'package:appwrite_user_app/app/modules/dashboard/screens/home_module_view.dart';
import 'package:appwrite_user_app/app/modules/cart/screens/cart_page.dart';
import 'package:appwrite_user_app/app/modules/favorites/screens/favorites_screen.dart';
import 'package:appwrite_user_app/app/modules/orders/screens/orders_page.dart';
import 'package:appwrite_user_app/app/modules/profile/screens/profile_page.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final Connectivity _connectivity = Connectivity();
  late PageController _pageController;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  int _selectedIndex = 0;
  bool _canExit = false;
  bool _hadConnection = true;

  // Pages
  final List<Widget> _pages = [
    const HomeModuleView(),
    const FavoritesScreen(),
    const CartPage(),
    const OrdersPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();

    Get.lazyPut(() => CartAnimationController());
    _pageController = PageController(initialPage: 0);
    _listenToConnectivity();

    // Load favorites
    Get.find<FavoritesController>().fetchFavorites(canUpdate: false);

    // Load cart items (using hardcoded user_id for now)
    Get.find<CartController>().getCartItems();
  }

  Future<void> _reloadDashboardData() async {
    await Future.wait([
      Get.find<FavoritesController>().fetchFavorites(canUpdate: false),
      Get.find<CartController>().getCartItems(),
    ]);
  }

  Future<void> _listenToConnectivity() async {
    _hadConnection = await _checkConnection();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      results,
    ) async {
      final hasConnection = _hasUsableConnection(results);
      if (hasConnection && !_hadConnection) {
        await _reloadDashboardData();
      }
      _hadConnection = hasConnection;
    });
  }

  Future<bool> _checkConnection() async {
    final results = await _connectivity.checkConnectivity();
    return _hasUsableConnection(results);
  }

  bool _hasUsableConnection(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onNavItemTapped(int index) {
    // Subtle physical feedback for a more premium, tactile feel.
    HapticFeedback.selectionClick();
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
              exitApp();
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
        extendBody: true,
        // Web gets a top navigation header (like a website); mobile keeps the
        // floating bottom navigation bar.
        appBar: kIsWeb ? _buildWebTopNav() : null,
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          // Disable swipe paging on web — navigation happens via the top bar.
          physics: kIsWeb
              ? const NeverScrollableScrollPhysics()
              : const BouncingScrollPhysics(),
          children: _pages,
        ),
        bottomNavigationBar: kIsWeb ? null : _buildBottomNavBar(),
      ),
    );
  }

  /// Top navigation header used on web: a centered, max-width bar carrying the
  /// brand and the same destinations as the mobile bottom bar.
  PreferredSizeWidget _buildWebTopNav() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Material(
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
                  // Drop the text labels on tight widths so the items never
                  // overflow; keep them on roomy desktop layouts.
                  final bool showLabels = constraints.maxWidth >= 720;
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: showLabels ? 20 : 12,
                    ),
                    child: SizedBox(
                      height: 64,
                      child: Row(
                        children: [
                          // Brand / logo — shrinks with ellipsis before it can
                          // push the nav items off-screen.
                          Flexible(
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
                          const SizedBox(width: 12),
                          _webNavItem(
                            Icons.home_rounded,
                            'home'.tr,
                            0,
                            showLabels,
                          ),
                          _webNavItem(
                            Icons.favorite_rounded,
                            'favorites'.tr,
                            1,
                            showLabels,
                          ),
                          _webCartNavItem(showLabels),
                          _webNavItem(
                            Icons.receipt_long_rounded,
                            'orders'.tr,
                            3,
                            showLabels,
                          ),
                          _webNavItem(
                            Icons.person_rounded,
                            'profile'.tr,
                            4,
                            showLabels,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _webNavItem(IconData icon, String label, int index, bool showLabel) {
    final isSelected = _selectedIndex == index;
    final color = isSelected
        ? ColorResource.primaryDark
        : ColorResource.textSecondary;

    return Padding(
      padding: EdgeInsets.only(left: showLabel ? 8 : 2),
      child: Tooltip(
        message: showLabel ? '' : label,
        child: InkWell(
          onTap: () => _onNavItemTapped(index),
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

  Widget _webCartNavItem(bool showLabel) {
    return GetBuilder<CartController>(
      builder: (cartController) {
        final itemCount = cartController.itemCount;
        final isSelected = _selectedIndex == 2;
        final color = isSelected
            ? ColorResource.primaryDark
            : ColorResource.textSecondary;

        return Padding(
          padding: EdgeInsets.only(left: showLabel ? 8 : 2),
          child: Tooltip(
            message: showLabel ? '' : 'cart'.tr,
            child: InkWell(
              onTap: () => _onNavItemTapped(2),
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
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(Icons.shopping_cart_rounded,
                            color: color, size: 22),
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
                    if (showLabel) ...[
                      const SizedBox(width: 8),
                      Text(
                        'cart'.tr,
                        style:
                            (isSelected ? poppinsBold : poppinsMedium).copyWith(
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
      },
    );
  }

  Widget _buildBottomNavBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Padding(
        // Detaches the bar from the screen edges so it floats.
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            // Frosted-glass blur of the content scrolling beneath the bar.
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                // Translucent so the blur reads as real glass.
                color: ColorResource.cardBackground
                    .withValues(alpha: isDark ? 0.72 : 0.82),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.white.withValues(alpha: 0.55),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.40)
                        : ColorResource.shadowDark,
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(Icons.home_rounded, 'home'.tr, 0),
                    _buildNavItem(Icons.favorite_rounded, 'favorites'.tr, 1),
                    _buildCartNavItem(),
                    _buildNavItem(Icons.receipt_long_rounded, 'orders'.tr, 3),
                    _buildNavItem(Icons.person_rounded, 'profile'.tr, 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;

    final item = GestureDetector(
      onTap: () => _onNavItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: poppinsMedium.copyWith(
                    fontSize: Constants.fontSizeSmall,
                    color: ColorResource.textWhite,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    // Only the selected item flexes to absorb leftover width; unselected
    // items stay compact. This guarantees the row never overflows.
    return isSelected ? Flexible(child: item) : item;
  }

  Widget _buildCartNavItem() {
    final isSelected = _selectedIndex == 2;

    final cart = GetBuilder<CartController>(
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? ColorResource.primaryGradient
                  : null,
              borderRadius: BorderRadius.circular(Constants.radiusLarge),
              border: isSelected
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
                      Icons.shopping_cart_rounded,
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
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'cart'.tr,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: poppinsMedium.copyWith(
                        fontSize: Constants.fontSizeSmall,
                        color: ColorResource.textWhite,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );

    // Match the flex behaviour of the other items so the row can't overflow.
    return isSelected ? Flexible(child: cart) : cart;
  }
}
