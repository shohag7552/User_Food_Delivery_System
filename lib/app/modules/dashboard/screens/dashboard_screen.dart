import 'dart:async';
import 'dart:ui' show ImageFilter, MaskFilter, BlurStyle;

import 'package:appwrite_user_app/app/helper/platform/app_exit.dart';

import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:appwrite_user_app/app/common/widgets/web_top_nav.dart';
import 'package:appwrite_user_app/app/controllers/cart_animation_controller.dart';
import 'package:appwrite_user_app/app/controllers/cart_controller.dart';
import 'package:appwrite_user_app/app/controllers/favorites_controller.dart';
import 'package:appwrite_user_app/app/helper/dashboard_tab_bus.dart';
import 'package:appwrite_user_app/app/helper/nav_bar_visibility.dart';
import 'package:appwrite_user_app/app/modules/dashboard/screens/home_module_view.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/web_profile_drawer.dart';
import 'package:appwrite_user_app/app/modules/cart/screens/cart_page.dart';
import 'package:appwrite_user_app/app/modules/favorites/screens/favorites_screen.dart';
import 'package:appwrite_user_app/app/modules/orders/screens/orders_page.dart';
import 'package:appwrite_user_app/app/modules/profile/screens/profile_page.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class DashboardScreen extends StatefulWidget {
  /// Tab requested by the URL's `?tab=` parameter; null when absent. Applied
  /// on first build and whenever the route delivers a new value (deep links,
  /// browser back/forward, in-app tab navigation from pushed pages).
  final int? initialTab;

  const DashboardScreen({super.key, this.initialTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Connectivity _connectivity = Connectivity();
  late PageController _pageController;

  /// One-shot bloom for the tapped tab's glow: it flares in then fades out.
  late final AnimationController _glowController;

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

    _selectedIndex = widget.initialTab ?? 0;
    _pageController = PageController(initialPage: _selectedIndex);
    // Start with the bar shown (a prior session may have left it hidden).
    NavBarVisibility.visible.value = true;
    // Starts settled (value 1 → pulse == 0) so no glow shows at launch.
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
      value: 1.0,
    );
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
  void didUpdateWidget(DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The route re-delivers the widget when the `?tab=` URL parameter changes
    // (browser back/forward, or tab navigation from a pushed page).
    final tab = widget.initialTab;
    if (tab != null && tab != _selectedIndex) {
      _animateTo(tab);
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _pageController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Hides the bottom bar while the user scrolls a vertical list down, and
  /// reveals it again on scroll up. Horizontal (page) scrolls are ignored.
  bool _handleScrollNotification(UserScrollNotification notification) {
    // Web uses the top nav (no floating bottom bar), so never auto-hide there.
    if (WebTopNav.isEnabled(context)) return false;
    if (notification.metrics.axis != Axis.vertical) return false;
    final ScrollDirection direction = notification.direction;
    if (direction == ScrollDirection.reverse) {
      NavBarVisibility.visible.value = false;
    } else if (direction == ScrollDirection.forward) {
      NavBarVisibility.visible.value = true;
    }
    return false;
  }

  void _animateTo(int index) {
    if (index == _selectedIndex) return;
    // Subtle physical feedback for a more premium, tactile feel.
    HapticFeedback.selectionClick();
    // Update the highlight immediately so the glow blooms on the right tab, and
    // always reveal the bar when switching tabs.
    setState(() => _selectedIndex = index);
    NavBarVisibility.visible.value = true;
    _glowController.forward(from: 0.0);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onNavItemTapped(int index) {
    _animateTo(index);
    _syncTabToUrl(index);
  }

  /// Web only: reflect the active tab in the browser URL (`/?tab=cart`) so
  /// the address bar names the visible screen and the link is shareable.
  /// No-op on mobile — tab switching stays purely local there.
  void _syncTabToUrl(int index) {
    if (!WebTopNav.isEnabled(context)) return;
    DashboardTabs.open(context, index);
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
      child: Builder(builder: (context) {
        // Desktop-web only — mobile/tablet (and narrow browser windows) keep
        // the regular mobile chrome (bottom nav, no top bar).
        final showWebNav = WebTopNav.isEnabled(context);

        return Scaffold(
          key: _scaffoldKey,
          // Inherit the theme's scaffoldBackgroundColor (same value) instead of
          // a static ColorResource read captured in build(). The ScaffoldState
          // is a Theme dependent, so the background repaints on a theme toggle
          // even though this screen's build() doesn't re-run.
          extendBody: true,
          appBar: showWebNav
              ? WebTopNav(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onNavItemTapped,
                  onMenuTap: () => _scaffoldKey.currentState?.openEndDrawer(),
                )
              : null,
          endDrawer: showWebNav ? const WebProfileDrawer() : null,
          body: NotificationListener<UserScrollNotification>(
            onNotification: _handleScrollNotification,
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              // Disable swipe paging under the top bar — navigation happens there.
              physics: const NeverScrollableScrollPhysics(),
              children: _pages,
            ),
          ),
          bottomNavigationBar: showWebNav ? null : _buildBottomNavBar(),
        );
      }),
    );
  }

  Widget _buildBottomNavBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Near-opaque so the bar is a clearly-defined surface even on the light
    // near-white scaffold (where a translucent white bar previously vanished).
    final Color navFill =
        context.cardBackground.withValues(alpha: isDark ? 0.82 : 0.96);
    // Neutral hairline edge — a white border is invisible on a light bg.
    final Color navBorder = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.06);
    // Layered contact + ambient shadow so the pill visibly floats.
    final List<BoxShadow> navShadows = isDark
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ];

    return ValueListenableBuilder<bool>(
      valueListenable: NavBarVisibility.visible,
      builder: (context, visible, child) => AnimatedSlide(
        // Slides fully below the screen when hidden; springs back up on reveal.
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
        offset: visible ? Offset.zero : const Offset(0, 1.4),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          opacity: visible ? 1.0 : 0.0,
          child: child,
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          // Detaches the bar from the screen edges so it floats.
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              // Subtle glass blur of the content scrolling beneath the bar; the
              // near-opaque fill above keeps it defined in light mode.
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: navFill,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: navBorder, width: 1),
                  boxShadow: navShadows,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      _buildNavItem(
                        CupertinoIcons.house,
                        CupertinoIcons.house_fill,
                        'home'.tr,
                        0,
                      ),
                      _buildNavItem(
                        CupertinoIcons.heart,
                        CupertinoIcons.heart_fill,
                        'favorites'.tr,
                        1,
                      ),
                      _buildCartNavItem(),
                      _buildNavItem(
                        CupertinoIcons.doc_text,
                        CupertinoIcons.doc_text_fill,
                        'orders'.tr,
                        3,
                      ),
                      _buildNavItem(
                        CupertinoIcons.person,
                        CupertinoIcons.person_fill,
                        'profile'.tr,
                        4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// A nav-bar icon that cross-fades between its outlined (inactive) and filled
  /// (active) form, and — when it becomes the selected tab — gives a springy
  /// bounce (driven by the one-shot [_glowController]). Only the selected icon
  /// bounces; the others stay put.
  Widget _navIcon(
    IconData outlined,
    IconData filled,
    bool isSelected,
    Color color,
  ) {
    final Widget icon = AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: Icon(
        isSelected ? filled : outlined,
        key: ValueKey<bool>(isSelected),
        color: color,
        size: 25,
      ),
    );

    if (!isSelected) return icon;

    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        // 0.7 → 1.0 with an easeOutBack overshoot = a single satisfying bounce;
        // settles back to exactly 1.0 when the controller finishes.
        final double t = _glowController.value.clamp(0.0, 1.0);
        final double scale = 0.7 + 0.3 * Curves.easeOutBack.transform(t);
        return Transform.scale(scale: scale, child: child);
      },
      child: icon,
    );
  }

  /// Transient soft glow behind the tapped tab's icon: a single blurred brand
  /// halo that swells outward and fades, like a drop's ripple on water — but
  /// smooth, not ringed. Zero-size ([Size.zero]) so it's purely painted and
  /// never adds to the icon's footprint / the nav-bar height.
  Widget _navGlow(bool isSelected) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, _) {
        final double t = isSelected ? _glowController.value : 1.0;
        // Settled (t == 1) → no glow, so nothing lingers on the active tab.
        if (t >= 1.0) return const SizedBox.shrink();
        return CustomPaint(
          size: Size.zero,
          painter: _GlowWavePainter(
            progress: t,
            color: ColorResource.primaryDark,
          ),
        );
      },
    );
  }

  /// The always-visible tab label; the selected one is bold and brand-coloured,
  /// the others regular and muted, easing between the two states.
  Widget _navLabel(String label, bool isSelected) {
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      style: (isSelected ? poppinsBold : poppinsRegular).copyWith(
        fontSize: Constants.fontSizeExtraSmall,
        color: isSelected ? ColorResource.primaryDark : context.textSecondary,
      ),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }

  Widget _buildNavItem(
    IconData outlined,
    IconData filled,
    String label,
    int index,
  ) {
    final isSelected = _selectedIndex == index;
    final Color color =
        isSelected ? ColorResource.primaryDark : context.textSecondary;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onNavItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  _navGlow(isSelected),
                  _navIcon(outlined, filled, isSelected, color),
                ],
              ),
              const SizedBox(height: 4),
              _navLabel(label, isSelected),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartNavItem() {
    final isSelected = _selectedIndex == 2;

    return Expanded(
      child: GetBuilder<CartController>(
        builder: (cartController) {
          final itemCount = cartController.itemCount;
          final hasItems = itemCount > 0;
          // Match the other tabs: brand red only when selected, muted otherwise
          // (the item-count badge still signals a non-empty cart).
          final Color color =
              isSelected ? ColorResource.primaryDark : context.textSecondary;

          return GestureDetector(
            onTap: () => _onNavItemTapped(2),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    // Animation target — only exists on Android/iOS; on web the
                    // controller isn't registered, so no key is attached.
                    key: CartAnimationController.isSupported
                        ? Get.find<CartAnimationController>().cartIconKey
                        : null,
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      _navGlow(isSelected),
                      _navIcon(
                        CupertinoIcons.cart,
                        CupertinoIcons.cart_fill,
                        isSelected,
                        color,
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
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        ColorResource.error,
                                        ColorResource.error
                                            .withValues(alpha: 0.8),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    // boxShadow: [
                                    //   BoxShadow(
                                    //     color: ColorResource.error
                                    //         .withValues(alpha: 0.5),
                                    //     blurRadius: 6,
                                    //     spreadRadius: 1,
                                    //   ),
                                    // ],
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
                  const SizedBox(height: 4),
                  _navLabel('cart'.tr, isSelected),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Paints one smooth, blurred glow that swells outward from the centre and
/// fades — a soft "drop on water" halo rather than hard rings. Drawn around the
/// canvas origin (the zero-size widget's centre), so it never affects layout.
class _GlowWavePainter extends CustomPainter {
  final double progress; // 0 → 1 over one tap
  final Color color;

  const _GlowWavePainter({required this.progress, required this.color});

  static const double _minRadius = 10;
  static const double _maxRadius = 40;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || progress >= 1.0) return;

    final double eased = Curves.easeOutSine.transform(progress);
    final double radius = _minRadius + (_maxRadius - _minRadius) * eased;
    // Fade smoothly to nothing as it swells out into the surroundings.
    final double opacity = (1.0 - eased) * 0.5;
    // Large, growing blur so the edge feathers away — a glow that dissolves,
    // not a disc.
    final double sigma = 12.0 + 18.0 * eased;

    final Paint paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma);

    canvas.drawCircle(Offset.zero, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _GlowWavePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
