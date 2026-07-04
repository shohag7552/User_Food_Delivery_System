import 'dart:async';

import 'package:appwrite_user_app/app/common/widgets/web_top_nav.dart';
import 'package:appwrite_user_app/app/controllers/banner_controller.dart';
import 'package:appwrite_user_app/app/controllers/category_controller.dart';
import 'package:appwrite_user_app/app/controllers/notification_controller.dart';
import 'package:appwrite_user_app/app/controllers/product_controller.dart';
import 'package:appwrite_user_app/app/controllers/profile_controller.dart';
import 'package:appwrite_user_app/app/modules/dashboard/section_widget/all_products_widget.dart';
import 'package:appwrite_user_app/app/modules/dashboard/section_widget/category_section_widget.dart';
import 'package:appwrite_user_app/app/modules/dashboard/section_widget/food_card_metrics.dart';
import 'package:appwrite_user_app/app/modules/dashboard/section_widget/new_items_widget.dart';
import 'package:appwrite_user_app/app/modules/dashboard/section_widget/offer_products_widget.dart';
import 'package:appwrite_user_app/app/modules/dashboard/section_widget/popular_dishes_widget.dart';
import 'package:appwrite_user_app/app/modules/dashboard/section_widget/todays_specials_widget.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/promotional_banner.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  static const Duration _reconnectReloadDelay = Duration(seconds: 1);
  static const int _maxReconnectReloadAttempts = 3;

  final ScrollController _scrollController = ScrollController();
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _reconnectReloadTimer;
  bool _hadConnection = true;
  bool _isReloadingAfterReconnect = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);
    _listenToConnectivity();
    _initApiDataCall();
  }

  Future<void> _listenToConnectivity() async {
    _hadConnection = await _checkConnection();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      results,
    ) async {
      final hasConnection = _hasUsableConnection(results);
      if (hasConnection && !_hadConnection) {
        _scheduleReconnectReload();
      }
      _hadConnection = hasConnection;
    });
  }

  void _scheduleReconnectReload() {
    _reconnectReloadTimer?.cancel();
    _reconnectReloadTimer = Timer(_reconnectReloadDelay, () {
      if (!mounted) return;
      _reloadHomeDataAfterReconnect();
    });
  }

  Future<bool> _checkConnection() async {
    final results = await _connectivity.checkConnectivity();
    return _hasUsableConnection(results);
  }

  bool _hasUsableConnection(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // Load more when near bottom
      Get.find<ProductController>().loadMoreProducts();
    }
  }

  Future<void> _initApiDataCall({bool canReload = false}) async {
    final categoryController = Get.find<CategoryController>();
    final bannerController = Get.find<BannerController>();
    final notificationController = Get.find<NotificationController>();
    final productController = Get.find<ProductController>();

    unawaited(notificationController.getNotifications());

    await Future.wait([
      categoryController.getCategories(reload: canReload),
      bannerController.getBanners(reload: canReload),
      productController.getSpecialProducts(reload: canReload),
      productController.getPopularProducts(reload: canReload),
      productController.getOfferProducts(reload: canReload),
      productController.getNewProducts(reload: canReload),
      productController.getProducts(reload: canReload),
    ]);
  }

  Future<void> _reloadHomeData() async {
    await _initApiDataCall(canReload: true);
  }

  Future<void> _reloadHomeDataAfterReconnect() async {
    if (_isReloadingAfterReconnect) return;

    _isReloadingAfterReconnect = true;
    try {
      for (var attempt = 0; attempt < _maxReconnectReloadAttempts; attempt++) {
        if (!mounted) return;

        await _reloadHomeData();

        if (!_hasHomeReloadErrors()) {
          return;
        }

        if (attempt < _maxReconnectReloadAttempts - 1) {
          await Future<void>.delayed(
            Duration(milliseconds: 800 * (attempt + 1)),
          );
        }
      }
    } finally {
      _isReloadingAfterReconnect = false;
    }
  }

  bool _hasHomeReloadErrors() {
    final categoryController = Get.find<CategoryController>();
    final bannerController = Get.find<BannerController>();
    final productController = Get.find<ProductController>();

    return categoryController.errorMessage != null ||
        bannerController.errorMessage != null ||
        productController.errorMessage != null ||
        productController.specialsErrorMessage != null ||
        productController.popularErrorMessage != null ||
        productController.offersErrorMessage != null ||
        productController.newErrorMessage != null;
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _reconnectReloadTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Desktop-web content never grows past this width; sections are centered
  /// with symmetric gutters beyond it (same treatment as the ecommerce home).
  static const double _maxContentWidth = 1200;

  /// Promo banner height on desktop web. With the content cap this yields a
  /// ~3.5:1 hero strip (like the ecommerce hero) instead of the thin 200px
  /// band the widget's mobile-oriented default produces at full cap width.
  static const double _webBannerHeight = 320;

  /// Centers [child] within [_maxContentWidth]. A no-op below that width, so
  /// mobile/tablet layouts are unaffected.
  Widget _capped(Widget child) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: child,
        ),
      );

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    // Desktop web gets a hero card + width-capped sections; the shared
    // WebTopNav above owns search, so no in-page search bar there.
    final isWebShell = WebTopNav.isEnabled(context);
    // Grid: 2 columns on phones, 3 on tablets; web derives its count from
    // FoodCardMetrics so the cards match the carousel sections.
    final int? gridColumns =
        isWebShell ? FoodCardMetrics.webColumns(size.width) : null;
    // Side gutters that center the all-products grid within the content cap.
    final double gridPadding = isWebShell && size.width > _maxContentWidth
        ? (size.width - _maxContentWidth) / 2 + 20
        : 20;

    return RefreshIndicator(
      onRefresh: () async => _initApiDataCall(canReload: true),
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Web: rounded greeting hero. Mobile: collapsing gradient app bar.
          if (isWebShell) _buildWebHero() else _buildSliverAppBar(context),

          // Main Content
          SliverToBoxAdapter(
            child: _capped(
              Column(
                children: [
                  const SizedBox(height: 20),

                  _buildPromotionalBanners(),

                  const SizedBox(height: Constants.spaceSection),

                  // Categories
                  CategorySectionWidget(),

                  const SizedBox(height: Constants.spaceSection),

                  // Today's Specials
                  const TodaysSpecialsWidget(),

                  const SizedBox(height: Constants.spaceSection),

                  // Popular Dishes
                  const PopularDishesWidget(),

                  // Offer Products — spaces itself and disappears entirely
                  // when there are no discounted items.
                  const OfferProductsWidget(),

                  const SizedBox(height: Constants.spaceSection),

                  // New Items
                  const NewItemsWidget(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // All-products header. The mobile variant relies on the status-bar
          // padding for its paint area (toolbarHeight 0), which is 0 on web —
          // so web gets its own pinned header with a real height and inline
          // filter chips instead of the hidden popup.
          if (isWebShell)
            _buildWebProductsHeader()
          else
            _buildMobileProductsHeader(),

          AllProductsWidget(
            isTablet: isTablet,
            scrollController: _scrollController,
            crossAxisCount: gridColumns,
            horizontalPadding: gridPadding,
          ),
        ],
      ),
    );
  }

  /// Mobile pinned products header — title + filter popup painted within the
  /// status-bar padding area (toolbarHeight 0), exactly as before.
  Widget _buildMobileProductsHeader() {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      pinned: true,
      backgroundColor: ColorResource.scaffoldBackground,
      elevation: 0,
      toolbarHeight: 0,
      flexibleSpace: GetBuilder<ProductController>(
        builder: (productController) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'all_products'.tr,
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeExtraLarge,
                    color: ColorResource.textPrimary,
                  ),
                ),
                PopupMenuButton<ProductListFilter>(
                  tooltip: 'Filter products',
                  onSelected: (filter) async {
                    await productController.setProductFilter(filter);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: ProductListFilter.all,
                      child: _buildFilterMenuItem(
                        label: 'all'.tr,
                        isSelected: productController.selectedProductFilter ==
                            ProductListFilter.all,
                      ),
                    ),
                    PopupMenuItem(
                      value: ProductListFilter.veg,
                      child: _buildFilterMenuItem(
                        label: 'veg'.tr,
                        isSelected: productController.selectedProductFilter ==
                            ProductListFilter.veg,
                      ),
                    ),
                    PopupMenuItem(
                      value: ProductListFilter.nonVeg,
                      child: _buildFilterMenuItem(
                        label: 'non_veg'.tr,
                        isSelected: productController.selectedProductFilter ==
                            ProductListFilter.nonVeg,
                      ),
                    ),
                  ],
                  icon: Icon(
                    Icons.filter_list,
                    color: productController.selectedProductFilter ==
                            ProductListFilter.all
                        ? ColorResource.textPrimary
                        : ColorResource.primaryDark,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Desktop-web pinned products header: an explicit 64px bar (web has no
  /// status-bar padding for the mobile variant to paint in) with the section
  /// title and always-visible filter chips.
  Widget _buildWebProductsHeader() {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      pinned: true,
      primary: false,
      toolbarHeight: 64,
      titleSpacing: 0,
      backgroundColor: ColorResource.scaffoldBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: GetBuilder<ProductController>(
        builder: (productController) {
          return _capped(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'all_products'.tr,
                      style: poppinsBold.copyWith(
                        fontSize: Constants.fontSizeExtraLarge,
                        color: ColorResource.textPrimary,
                      ),
                    ),
                  ),
                  _webFilterChip(
                    productController,
                    ProductListFilter.all,
                    'all'.tr,
                  ),
                  _webFilterChip(
                    productController,
                    ProductListFilter.veg,
                    'veg'.tr,
                  ),
                  _webFilterChip(
                    productController,
                    ProductListFilter.nonVeg,
                    'non_veg'.tr,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Pill-style veg/non-veg filter chip for the web products header.
  Widget _webFilterChip(
    ProductController controller,
    ProductListFilter filter,
    String label,
  ) {
    final bool selected = controller.selectedProductFilter == filter;

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: InkWell(
        onTap: () => controller.setProductFilter(filter),
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: selected ? ColorResource.primaryGradient : null,
            color: selected ? null : ColorResource.cardBackground,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : ColorResource.textLight.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            label,
            style: (selected ? poppinsBold : poppinsMedium).copyWith(
              fontSize: Constants.fontSizeSmall,
              color: selected
                  ? ColorResource.textWhite
                  : ColorResource.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
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
            // Only show title (search bar) when collapsed
            title: isCollapsed ? _buildSearchBar() : null,
            titlePadding: isCollapsed ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8) : null,
            background: Container(
              decoration: BoxDecoration(
                gradient: ColorResource.primaryGradient,
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Greeting
                          Expanded(
                            child: _buildGreetingTexts(
                              Constants.fontSizeExtraLarge,
                            ),
                          ),
                          _buildNotificationBell(),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Search Bar (only in expanded state)
                      _buildSearchBar(),
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

  /// Desktop-web hero: a rounded gradient card with the time-aware greeting
  /// and the notification bell. No in-page search bar — the shared WebTopNav
  /// above owns search on web.
  Widget _buildWebHero() {
    return SliverToBoxAdapter(
      child: _capped(
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
            decoration: BoxDecoration(
              gradient: ColorResource.primaryGradient,
              borderRadius: BorderRadius.circular(Constants.radiusLarge),
              boxShadow: ColorResource.customShadow,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildGreetingTexts(Constants.fontSizeOverLarge),
                ),
                _buildNotificationBell(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Time-aware greeting + tagline (shared by the mobile app bar and web hero;
  /// only the tagline size differs).
  Widget _buildGreetingTexts(double taglineFontSize) {
    return GetBuilder<ProfileController>(
      builder: (profileController) {
        final greeting = _greetingContent();
        final firstName = _resolveFirstName(
          profileController.userProfile?.name,
        );
        final greetingLine = firstName.isEmpty
            ? '${greeting.greetingKey.tr} 👋'
            : '${greeting.greetingKey.tr}, $firstName 👋';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greetingLine,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: ColorResource.textWhite.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              greeting.taglineKey.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: poppinsBold.copyWith(
                fontSize: taglineFontSize,
                color: ColorResource.textWhite,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Notification bell with the unread indicator (shared by both headers).
  Widget _buildNotificationBell() {
    return GetBuilder<NotificationController>(
      builder: (notificationController) {
        final hasUnreadNotifications = notificationController.unreadCount > 0;

        return InkWell(
          borderRadius: BorderRadius.circular(Constants.radiusDefault),
          onTap: () => context.pushNamed(RouteNames.notifications),
          child: Stack(
            children: [
              Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ColorResource.overlayMedium,
                    borderRadius: BorderRadius.circular(
                      Constants.radiusDefault,
                    ),
                  ),
                  child: Icon(
                    Icons.notifications_outlined,
                    color: ColorResource.textWhite,
                    size: 24,
                  ),
                ),
              ),
              if (hasUnreadNotifications)
                Positioned(
                  top: 6,
                  right: 6,
                  child: IgnorePointer(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: ColorResource.error,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ColorResource.primaryDark,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.pushNamed(RouteNames.search),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: ColorResource.cardBackground,
          borderRadius: BorderRadius.circular(Constants.radiusLarge),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.transparent,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.22)
                  : Colors.black.withValues(alpha: 0.1),
              blurRadius: isDark ? 18 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: ColorResource.textSecondary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'search_for_dishes'.tr,
                style: poppinsRegular.copyWith(
                  fontSize: Constants.fontSizeDefault,
                  color: ColorResource.textLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionalBanners() {
    // On desktop web: a fixed hero-scale height and 20px side gutters so the
    // banner aligns with the other capped sections. Mobile keeps the widget's
    // own carousel sizing (enlarged center page, peeking neighbours).
    final isWebShell = WebTopNav.isEnabled(context);

    return GetBuilder<BannerController>(
      builder: (bannerController) {
        final banner = PromotionalBanner(
          banners: bannerController.banners,
          isLoading: bannerController.isLoading,
          errorMessage: bannerController.errorMessage,
          onRetry: () => bannerController.getBanners(),
          height: isWebShell ? _webBannerHeight : null,
        );

        if (!isWebShell) return banner;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: banner,
        );
      },
    );
  }

  /// Returns the localization keys for the greeting and tagline based on the
  /// current time of day, so the header feels contextual rather than static.
  ({String greetingKey, String taglineKey}) _greetingContent() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return (greetingKey: 'good_morning', taglineKey: 'tagline_morning');
    }
    if (hour >= 12 && hour < 17) {
      return (greetingKey: 'good_afternoon', taglineKey: 'tagline_afternoon');
    }
    if (hour >= 17 && hour < 21) {
      return (greetingKey: 'good_evening', taglineKey: 'tagline_evening');
    }
    return (greetingKey: 'good_night', taglineKey: 'tagline_night');
  }

  /// Extracts the first name from a full name for a friendlier greeting.
  String _resolveFirstName(String? fullName) {
    final trimmed = fullName?.trim() ?? '';
    if (trimmed.isEmpty) return '';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  Widget _buildFilterMenuItem({
    required String label,
    required bool isSelected,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: poppinsMedium.copyWith(
              fontSize: Constants.fontSizeDefault,
              color: isSelected
                  ? ColorResource.primaryDark
                  : ColorResource.textPrimary,
            ),
          ),
        ),
        if (isSelected)
          Icon(
            Icons.check_rounded,
            size: 18,
            color: ColorResource.primaryDark,
          ),
      ],
    );
  }
}
