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
import 'package:appwrite_user_app/app/helper/localization_extension_helper.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'dart:ui' show ImageFilter;
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  static const Duration _reconnectReloadDelay = Duration(seconds: 1);
  static const int _maxReconnectReloadAttempts = 3;

  final ScrollController _scrollController = ScrollController();
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _reconnectReloadTimer;
  bool _hadConnection = true;
  bool _isReloadingAfterReconnect = false;
  // Tracks the desktop-web shell so scroll-driven pagination stays mobile-only;
  // web loads the next page via the explicit "View more" button instead.
  bool _isWebShell = false;

  /// One-shot staggered entrance for the header (badge → greeting → search).
  late final AnimationController _introController;

  /// Slow, subtle loop that pulses the unread-notification indicator.
  late final AnimationController _bellPulseController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..forward();
    _bellPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

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
    // Web paginates via the "View more" button, so skip scroll auto-load there.
    if (_isWebShell) return;
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
    _introController.dispose();
    _bellPulseController.dispose();
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

  /// One curated home section as its own sliver (so it builds lazily as it
  /// scrolls into view), width-capped for web.
  Widget _sectionSliver(Widget child) =>
      SliverToBoxAdapter(child: _capped(child));

  /// A vertical gap between sections, expressed as a sliver.
  Widget _gapSliver(double height) =>
      SliverToBoxAdapter(child: SizedBox(height: height));

  /// The ordered curated sections with a single, tokenized vertical rhythm
  /// (`spaceSection` between sections, `paddingSizeLarge` at the ends).
  ///
  /// [OfferProductsWidget] owns its own top gap and collapses to nothing when
  /// there are no offers, so it deliberately gets no leading gap here — the
  /// rhythm stays even whether or not it renders.
  List<Widget> _buildContentSlivers() => [
        _gapSliver(Constants.paddingSizeLarge),
        _sectionSliver(_buildPromotionalBanners()),
        _gapSliver(Constants.spaceSection),
        _sectionSliver(CategorySectionWidget()),
        _gapSliver(Constants.spaceSection),
        _sectionSliver(const TodaysSpecialsWidget()),
        _gapSliver(Constants.spaceSection),
        _sectionSliver(const PopularDishesWidget()),
        _sectionSliver(const OfferProductsWidget()),
        _gapSliver(Constants.spaceSection),
        _sectionSliver(const NewItemsWidget()),
        _gapSliver(Constants.paddingSizeLarge),
      ];

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    // Desktop web gets a hero card + width-capped sections; the shared
    // WebTopNav above owns search, so no in-page search bar there.
    final isWebShell = WebTopNav.isEnabled(context);
    _isWebShell = isWebShell;
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

          // Curated content sections. Each is its own sliver so off-screen
          // sections build lazily, with the vertical rhythm owned by a single
          // consistent gap helper instead of scattered literals.
          ..._buildContentSlivers(),

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

          // Small breathing space at the very bottom of the page.
          _gapSliver(Constants.paddingSizeLarge),
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
      backgroundColor: context.scaffoldBackground,
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
                    color: context.textPrimary,
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
                        ? context.textPrimary
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
      backgroundColor: context.scaffoldBackground,
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
                        color: context.textPrimary,
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
      padding: const EdgeInsetsDirectional.only(start: 8),
      child: InkWell(
        onTap: () => controller.setProductFilter(filter),
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: selected ? ColorResource.primaryGradient : null,
            color: selected ? null : context.cardBackground,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : context.textLight.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            label,
            style: (selected ? poppinsBold : poppinsMedium).copyWith(
              fontSize: Constants.fontSizeSmall,
              color: selected
                  ? ColorResource.textWhite
                  : context.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  /// Re-imagined mobile header: a layered gradient hero whose time-aware
  /// greeting parallax-fades on scroll, above a floating glass search pill +
  /// notification bell that stays docked (and tappable) when collapsed.
  /// Header content height *below* the status bar. The expanded height is this
  /// plus the device status bar, so the greeting + search fit snugly with no
  /// wasted space regardless of status-bar/notch size.
  static const double _appBarContentHeight = 120;
  static const double _appBarCollapsedHeight = 68;

  Widget _buildSliverAppBar(BuildContext context) {
    final double statusBar = MediaQuery.of(context).padding.top;
    final double expandedHeight = statusBar + _appBarContentHeight;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      collapsedHeight: _appBarCollapsedHeight,
      floating: false,
      pinned: true,
      stretch: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: ColorResource.primaryDark,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      automaticallyImplyLeading: false,
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double appBarHeight = constraints.maxHeight;
          final double minHeight = _appBarCollapsedHeight + statusBar;
          // 1.0 = fully expanded, 0.0 = fully collapsed.
          final double ratio =
              ((appBarHeight - minHeight) / (expandedHeight - minHeight))
                  .clamp(0.0, 1.0);

          return ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Base gradient.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: ColorResource.primaryGradient,
                  ),
                ),
                // Soft decorative depth blobs.
                Positioned(
                  top: -46,
                  right: -34,
                  child: _headerBlob(150, 0.08),
                ),
                Positioned(
                  bottom: -54,
                  left: -46,
                  child: _headerBlob(168, 0.06),
                ),

                // Greeting — fades + slides up as the bar collapses.
                Positioned(
                  top: statusBar + 14,
                  left: 20,
                  right: 20,
                  child: IgnorePointer(
                    ignoring: ratio < 0.5,
                    child: Opacity(
                      opacity: ratio,
                      child: Transform.translate(
                        offset: Offset(0, (1 - ratio) * -12),
                        child: Row(
                          children: [
                            _intro(0, _buildProfileAvatar()),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _intro(
                                1,
                                _buildGreetingTexts(
                                  Constants.fontSizeExtraLarge,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Docked search pill + bell — stays pinned when collapsed.
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 11,
                  child: _intro(
                    2,
                    Row(
                      children: [
                        Expanded(child: _buildSearchBar()),
                        const SizedBox(width: 12),
                        _buildNotificationBell(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// A large, faint circle used to add subtle depth to the header gradient.
  Widget _headerBlob(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }

  /// Wraps [child] in the staggered fade-and-slide entrance driven by
  /// [_introController]. [order] shifts each element's start so they cascade.
  Widget _intro(int order, Widget child) {
    final double start = (order * 0.12).clamp(0.0, 0.5);
    final double end = (start + 0.5).clamp(0.0, 1.0);
    final Animation<double> anim = CurvedAnimation(
      parent: _introController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (context, c) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
          offset: Offset(0, (1 - anim.value) * 14),
          child: c,
        ),
      ),
      child: child,
    );
  }

  /// Frosted-glass surface for the interactive header controls (search pill +
  /// notification bell), mirroring the dashboard nav-bar container: a blurred,
  /// translucent [cardBackground] fill with a soft light border and shadow so
  /// the gradient reads faintly through it.
  Widget _frostedHeaderTile({
    required EdgeInsetsGeometry padding,
    required Widget child,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(Constants.radiusLarge),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: context.cardBackground
                .withValues(alpha: isDark ? 0.72 : 0.82),
            borderRadius: BorderRadius.circular(Constants.radiusLarge),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.white.withValues(alpha: 0.55),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.30)
                    : ColorResource.shadowDark,
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  /// Profile avatar beside the greeting — the user's photo when set, otherwise
  /// their initials (or a person glyph if the name is unknown). A solid,
  /// bordered circle that reads as its own element, distinct from the frosted
  /// search/bell controls.
  Widget _buildProfileAvatar() {
    return GetBuilder<ProfileController>(
      builder: (profileController) {
        final user = profileController.userProfile;
        final String? imageUrl = user?.profileImageUrl;
        final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;

        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: hasImage
                ? Image.network(
                    imageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    // Show the initials/person fallback while loading and if the
                    // image fails, so the slot is never blank.
                    loadingBuilder: (context, child, progress) =>
                        progress == null ? child : _avatarFallback(user),
                    errorBuilder: (context, error, stackTrace) =>
                        _avatarFallback(user),
                  )
                : _avatarFallback(user),
          ),
        );
      },
    );
  }

  /// Gradient circle showing the user's initials, or a person glyph when no
  /// usable name is available.
  Widget _avatarFallback(dynamic user) {
    final String initials = user?.initials ?? '?';
    final bool hasInitials = initials.isNotEmpty && initials != '?';

    return Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: ColorResource.primaryGradient,
      ),
      child: hasInitials
          ? Text(
              initials,
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeLarge,
                color: ColorResource.textWhite,
              ),
            )
          : const Icon(
              Icons.person_rounded,
              color: ColorResource.textWhite,
              size: 26,
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
          mainAxisSize: MainAxisSize.min,
          children: [
            // Short "Good morning, <first name> 👋" line — kept to one line
            // (first name only, so it rarely needs more).
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
            // Tagline is the headline — wraps to two lines so it always shows
            // in full (every configured tagline fits within two), instead of
            // being clipped to a single line with an ellipsis.
            Text(
              greeting.taglineKey.tr,
              softWrap: true,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: poppinsBold.copyWith(
                fontSize: taglineFontSize,
                height: 1.2,
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
          borderRadius: BorderRadius.circular(Constants.radiusLarge),
          onTap: () => context.pushNamed(RouteNames.notifications),
          child: Stack(
            children: [
              _frostedHeaderTile(
                padding: const EdgeInsets.all(Constants.paddingSizeSmall),
                child: Icon(
                  CupertinoIcons.bell,
                  color: ColorResource.primaryDark,
                  size: 24,
                ),
              ),
              if (hasUnreadNotifications)
                Positioned(
                  top: 7,
                  right: 7,
                  child: IgnorePointer(
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.82, end: 1.18).animate(
                        CurvedAnimation(
                          parent: _bellPulseController,
                          curve: Curves.easeInOut,
                        ),
                      ),
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: ColorResource.error,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.cardBackground,
                            width: 1.6,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  ColorResource.error.withValues(alpha: 0.6),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
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

  /// Search pill on the shared solid header-tile surface (matches the time
  /// badge and notification bell). Taps through to the search page.
  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () => context.pushNamed(RouteNames.search),
      child: _frostedHeaderTile(
        padding: const EdgeInsets.symmetric(horizontal: Constants.paddingSizeDefault, vertical: Constants.paddingSizeSmall),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.search,
              color: ColorResource.primaryDark,
              size: 22,
            ),
            const SizedBox(width: 12),
            const Expanded(child: _AnimatedSearchHint()),
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
                  : context.textPrimary,
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

/// Search-bar placeholder that cycles through the store's category names with a
/// gentle vertical roll ("Search for Pizza" → "Search for Burger" …). Falls
/// back to the static hint until categories have loaded.
class _AnimatedSearchHint extends StatefulWidget {
  const _AnimatedSearchHint();

  @override
  State<_AnimatedSearchHint> createState() => _AnimatedSearchHintState();
}

class _AnimatedSearchHintState extends State<_AnimatedSearchHint> {
  static const Duration _interval = Duration(milliseconds: 2600);

  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_interval, (_) {
      if (!mounted) return;
      final count = _hintNames().length;
      if (count == 0) return;
      setState(() => _index = (_index + 1) % count);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Non-empty, localized category names in display order.
  List<String> _hintNames() {
    if (!Get.isRegistered<CategoryController>()) return const [];
    return Get.find<CategoryController>()
        .categories
        .map((c) => c.nameMap.trLanguage)
        .where((n) => n.trim().isNotEmpty)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    // Fixed "Search for" prefix stays muted; the animating category reads as
    // the emphasised black term.
    final TextStyle prefixStyle = poppinsRegular.copyWith(
      fontSize: Constants.fontSizeDefault,
      color: context.textSecondary,
    );
    final TextStyle categoryStyle = poppinsMedium.copyWith(
      fontSize: Constants.fontSizeDefault,
      color: context.textPrimary,
    );

    return GetBuilder<CategoryController>(
      builder: (_) {
        final names = _hintNames();

        // No categories yet → keep the plain, always-readable placeholder.
        if (names.isEmpty) {
          return Text(
            'search_for_dishes'.tr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: prefixStyle,
          );
        }

        final name = names[_index % names.length];

        return Row(
          children: [
            Text('search_for'.tr, style: prefixStyle),
            const SizedBox(width: 5),
            // Only the category term animates — a clean vertical roll with a
            // soft fade, one word swapping in place beside the fixed prefix.
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 550),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                layoutBuilder: (currentChild, previousChildren) => Stack(
                  alignment: AlignmentDirectional.centerStart,
                  children: [
                    ...previousChildren,
                    ?currentChild,
                  ],
                ),
                transitionBuilder: (child, animation) {
                  final bool isIncoming = child.key == ValueKey<String>(name);
                  // Incoming term rises from just below; the outgoing one lifts
                  // up and out — a professional split-flap style roll.
                  final Animation<Offset> slide = Tween<Offset>(
                    begin: Offset(0, isIncoming ? 0.55 : -0.55),
                    end: Offset.zero,
                  ).animate(animation);
                  return ClipRect(
                    child: FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: slide, child: child),
                    ),
                  );
                },
                child: Text(
                  name,
                  key: ValueKey<String>(name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: categoryStyle,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
