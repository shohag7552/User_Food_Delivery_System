import 'dart:async';

import 'package:appwrite_user_app/app/controllers/banner_controller.dart';
import 'package:appwrite_user_app/app/controllers/category_controller.dart';
import 'package:appwrite_user_app/app/controllers/notification_controller.dart';
import 'package:appwrite_user_app/app/common/widgets/module_toggle.dart';
import 'package:appwrite_user_app/app/controllers/product_controller.dart';
import 'package:appwrite_user_app/app/controllers/profile_controller.dart';
import 'package:appwrite_user_app/app/modules/dashboard/section_widget/all_products_widget.dart';
import 'package:appwrite_user_app/app/modules/dashboard/section_widget/category_section_widget.dart';
import 'package:appwrite_user_app/app/modules/dashboard/section_widget/new_items_widget.dart';
import 'package:appwrite_user_app/app/modules/dashboard/section_widget/popular_dishes_widget.dart';
import 'package:appwrite_user_app/app/modules/dashboard/section_widget/todays_specials_widget.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/promotional_banner.dart';
import 'package:appwrite_user_app/app/modules/notification/screens/notification_screen.dart';
import 'package:appwrite_user_app/app/modules/search/screens/search_page.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return RefreshIndicator(
      onRefresh: () async => _initApiDataCall(canReload: true),
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Custom Sliver App Bar with gradient
          _buildSliverAppBar(context),

          // Main Content
          SliverToBoxAdapter(
            child: Column(
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

                const SizedBox(height: Constants.spaceSection),

                // New Items
                const NewItemsWidget(),

                const SizedBox(height: 20),
              ],
            ),
          ),

          SliverAppBar(
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
                              isSelected:
                                  productController.selectedProductFilter ==
                                  ProductListFilter.all,
                            ),
                          ),
                          PopupMenuItem(
                            value: ProductListFilter.veg,
                            child: _buildFilterMenuItem(
                              label: 'veg'.tr,
                              isSelected: productController.selectedProductFilter == ProductListFilter.veg,
                            ),
                          ),
                          PopupMenuItem(
                            value: ProductListFilter.nonVeg,
                            child: _buildFilterMenuItem(
                              label: 'non_veg'.tr,
                              isSelected: productController.selectedProductFilter == ProductListFilter.nonVeg,
                            ),
                          ),
                        ],
                        icon: Icon(
                          Icons.filter_list,
                          color:
                              productController.selectedProductFilter ==
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
          ),

          AllProductsWidget(isTablet: isTablet, scrollController: _scrollController),
        ],
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
                      // Food / Shop switch (only when both modules are enabled)
                      const Align(
                        alignment: Alignment.centerRight,
                        child: ModuleToggle(onGradient: true),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Greeting
                          Expanded(
                            child: GetBuilder<ProfileController>(
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
                                        color: ColorResource.textWhite
                                            .withValues(alpha: 0.9),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      greeting.taglineKey.tr,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: poppinsBold.copyWith(
                                        fontSize: Constants.fontSizeExtraLarge,
                                        color: ColorResource.textWhite,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),

                          GetBuilder<NotificationController>(
                            builder: (notificationController) {
                              final hasUnreadNotifications =
                                  notificationController.unreadCount > 0;

                              return InkWell(
                                borderRadius: BorderRadius.circular(
                                  Constants.radiusDefault,
                                ),
                                onTap: () => Get.to(
                                  () => const NotificationScreen(),
                                ),
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
                          ),
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

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => Get.to(() => const SearchPage()),
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
    return GetBuilder<BannerController>(
      builder: (bannerController) {
        return PromotionalBanner(
          banners: bannerController.banners,
          isLoading: bannerController.isLoading,
          errorMessage: bannerController.errorMessage,
          onRetry: () => bannerController.getBanners(),
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
