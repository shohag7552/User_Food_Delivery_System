import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:appwrite_user_app/app/controllers/notification_controller.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/common/widgets/web_footer.dart';
import 'package:appwrite_user_app/app/controllers/banner_controller.dart';
import 'package:appwrite_user_app/app/controllers/brand_controller.dart';
import 'package:appwrite_user_app/app/controllers/category_controller.dart';
import 'package:appwrite_user_app/app/controllers/flash_sale_controller.dart';
import 'package:appwrite_user_app/app/controllers/module_controller.dart';
import 'package:appwrite_user_app/app/controllers/product_controller.dart';
import 'package:appwrite_user_app/app/helper/localization_extension_helper.dart';
import 'package:appwrite_user_app/app/helper/nav_bar_visibility.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/models/brand_model.dart';
import 'package:appwrite_user_app/app/models/product_model.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/promotional_banner.dart';
import 'package:appwrite_user_app/app/modules/ecommerce/widgets/all_products_header.dart';
import 'package:appwrite_user_app/app/modules/ecommerce/widgets/ecommerce_product_card.dart';
import 'package:appwrite_user_app/app/modules/flash_sale/widgets/flash_sale_section.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/images.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class EcommerceHomeView extends StatefulWidget {
  const EcommerceHomeView({super.key});

  @override
  State<EcommerceHomeView> createState() => _EcommerceHomeViewState();
}

class _EcommerceHomeViewState extends State<EcommerceHomeView>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  // Drives the Top Products carousel (used by the web scroll-arrow buttons).
  final ScrollController _topScrollController = ScrollController();
  // Scroll arrows only reveal while a pointer hovers the Top Products strip.
  bool _topHovered = false;
  // Same pair for the Offer Products carousel.
  final ScrollController _offerScrollController = ScrollController();
  bool _offerHovered = false;
  // Tracks the current layout so scroll-driven pagination stays mobile-only —
  // web loads the next page via the explicit "View more" button instead.
  bool _isWide = false;

  @override
  bool get wantKeepAlive => true;

  late final AnimationController _bellPulseController;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _bellPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _loadData();
  }

  Future<void> _loadData({bool reload = false}) async {
    final categoryController = Get.find<CategoryController>();
    final bannerController = Get.find<BannerController>();
    final brandController = Get.find<BrandController>();
    final productController = Get.find<ProductController>();

    await Future.wait([
      bannerController.getBanners(reload: reload),
      categoryController.getCategories(reload: reload),
      brandController.getBrands(reload: reload),
      Get.find<FlashSaleController>().getFlashSale(reload: reload),
      productController.getPopularProducts(reload: reload),
      productController.getTopProducts(reload: reload),
      productController.getOfferProducts(reload: reload),
      productController.getProducts(reload: reload),
    ]);
  }

  void _onScroll() {
    // Web paginates via the "View more" button, so skip scroll auto-load there.
    if (_isWide) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      Get.find<ProductController>().loadMoreProducts();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _topScrollController.dispose();
    _offerScrollController.dispose();
    _bellPulseController.dispose();
    super.dispose();
  }

  /// Desktop content never grows past this; beyond it we letterbox with
  /// symmetric gutters so the storefront stays centered and readable.
  static const double _maxContentWidth = 1200;

  /// Side gutter that centers content within [_maxContentWidth] on wide screens
  /// and falls back to the standard 16px inset on phones/tablets.
  double _sidePadding(double width) =>
      width > _maxContentWidth + 32 ? (width - _maxContentWidth) / 2 : 16;

  /// Columns for the product grid, derived from the available content width
  /// (~210px target per card) so it scales from 2 on mobile up to 6 on desktop.
  int _gridColumns(double contentWidth) =>
      (contentWidth / 210).floor().clamp(2, 6);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final width = MediaQuery.of(context).size.width;
    final hPad = _sidePadding(width);
    final contentWidth = width - hPad * 2;
    final crossAxisCount = _gridColumns(contentWidth);
    // On wide (web/desktop) layouts the Promotions and Brands sit side by side;
    // narrow layouts keep them stacked.
    final bool isWide = width >= 900;
    _isWide = isWide;

    return RefreshIndicator(
      color: ColorResource.primaryDark,
      onRefresh: () => _loadData(reload: true),
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context, hPad, isWide),
          // On web the hero already embeds both the banner and category sidebar.
          if (!isWide) SliverToBoxAdapter(child: _buildBanners(hPad)),
          if (!isWide) SliverToBoxAdapter(child: _buildCategories(hPad)),
          // Flash sale — renders only while a sale is live.
          SliverToBoxAdapter(child: FlashSaleSection(isWide: isWide)),
          SliverToBoxAdapter(child: _buildTopProducts(isWide)),
          SliverToBoxAdapter(child: _buildOfferProducts(isWide)),
          if (isWide)
            SliverToBoxAdapter(child: _buildPromosBrandsRow(hPad))
          else ...[
            SliverToBoxAdapter(child: _buildPromotionalBanners(hPad)),
            SliverToBoxAdapter(child: _buildBrands(hPad)),
          ],
          SliverToBoxAdapter(child: _buildPopular(hPad)),
          // Pinned: the title and its filter controls stay put while the grid
          // scrolls under them.
          SliverPersistentHeader(
            pinned: true,
            delegate: AllProductsHeaderDelegate(horizontalPadding: hPad),
          ),
          _buildAllProductsGrid(crossAxisCount, hPad),
          _buildGridFooter(hPad, isWide),
          _buildViewMoreButton(hPad, isWide),
          if (isWide)
            const SliverToBoxAdapter(child: SizedBox(height: 32))
          else
            SliverToBoxAdapter(
              child: NavClearance(
                builder: (context, bottom) => SizedBox(height: bottom),
              ),
            ),

          // Professional site footer — renders only on desktop web.
          WebFooter.sliver(),
        ],
      ),
    );
  }

  /// Web/desktop layout: Promotions (left, wider) and Brands (right) in one row.
  /// Falls back to a single full-width section when only one of them has data.
  /// Shared content height for the promotions + brands row — exactly three
  /// 66px brand rows plus the two 12px gaps (3×66 + 2×12), so the promo
  /// banner and the 2×3 brands grid align top and bottom like the hero row.
  static const double _promosBrandsHeight = 222;

  /// Max brand tiles shown in the web brands panel (2 columns × 3 rows).
  static const int _maxBrandTiles = 6;

  Widget _buildPromosBrandsRow(double hPad) {
    return GetBuilder<BannerController>(
      builder: (bannerController) {
        final promos = bannerController.banners
            .where(
              (b) =>
                  b.moduleType == ModuleController.ecommerce && b.isPromotional,
            )
            .toList();
        return GetBuilder<BrandController>(
          builder: (brandController) {
            final List<BrandModel> brands = brandController.brands;
            final hasPromos = promos.isNotEmpty;
            final hasBrands = brands.isNotEmpty;

            if (!hasPromos && !hasBrands) return const SizedBox.shrink();
            if (hasPromos && !hasBrands) return _buildPromotionalBanners(hPad);
            if (!hasPromos && hasBrands) return _buildBrands(hPad);

            return Padding(
              padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Promotions — the visual focus, so it takes the larger
                  // share; its banner is sized to exactly match the brands
                  // panel so the two align top and bottom (hero-style row).
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader('promotions'.tr, 0),
                        PromotionalBanner(
                          banners: promos,
                          height: _promosBrandsHeight,
                          isLoading: false,
                          errorMessage: null,
                          onRetry: () =>
                              bannerController.getBanners(reload: true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Brands — a compact 2-column panel beside the promotions,
                  // capped at 6 entries.
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader('brands'.tr, 0),
                        SizedBox(
                          height: _promosBrandsHeight,
                          child: _brandsPanel(brands),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Brands rendered as a responsive grid (web row layout). Columns auto-fit the
  /// available width via [SliverGridDelegateWithMaxCrossAxisExtent], and the grid
  /// sizes to its content so it sits inside the surrounding column.
  /// Brands rendered as a fixed 2-column grid, capped at [_maxBrandTiles]
  /// entries (2×3) so the panel height always matches [_promosBrandsHeight].
  Widget _brandsPanel(List<BrandModel> brands) {
    final visibleBrands = brands.take(_maxBrandTiles).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 66,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: visibleBrands.length,
      itemBuilder: (context, index) => _brandTile(visibleBrands[index]),
    );
  }

  /// Opens the brand's products page (`/brand/<id>`), passing the loaded
  /// model as `extra` for instant render.
  void _openBrand(BrandModel brand) {
    context.pushNamed(
      RouteNames.brand,
      pathParameters: {'id': brand.id},
      extra: brand,
    );
  }

  Widget _brandTile(BrandModel brand) {
    final hasLogo = (brand.logoUrl ?? '').isNotEmpty;
    return InkWell(
      onTap: () => _openBrand(brand),
      borderRadius: BorderRadius.circular(Constants.radiusLarge),
      hoverColor: ColorResource.primaryDark.withValues(alpha: 0.04),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: BorderRadius.circular(Constants.radiusLarge),
          border: Border.all(color: context.textLight.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            // Logo, or a branded placeholder when none is set.
            Container(
              width: 40,
              height: 40,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: ColorResource.primaryDark.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: hasLogo
                  ? CustomNetworkImage(
                      image: brand.logoUrl!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    )
                  : Icon(
                      Icons.storefront_outlined,
                      size: 20,
                      color: ColorResource.primaryDark,
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                brand.nameMap.trLanguage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeDefault,
                  color: context.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dispatches to a platform-appropriate hero: a static two-column layout on
  /// web (editorial, image-right) and a collapsing SliverAppBar on mobile.
  Widget _buildSliverAppBar(BuildContext context, double hPad, bool isWide) {
    return isWide ? _buildWebHero(hPad) : _buildMobileAppBar(hPad);
  }

  static const double _heroHeight = 300.0;
  static const double _categoryPanelWidth = 220.0;

  /// Web hero — category sidebar (left) + full-height banner carousel (right).
  Widget _buildWebHero(double hPad) {
    return SliverToBoxAdapter(
      child: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: double.infinity),
            child: Padding(
              padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 8),
              child: SizedBox(
                height: _heroHeight,
                child: GetBuilder<CategoryController>(
                  builder: (catController) {
                    final showPanel =
                        catController.categories.isNotEmpty ||
                        catController.isLoading;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showPanel) ...[
                          SizedBox(
                            width: _categoryPanelWidth,
                            child: _buildWebCategoryList(catController),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(child: _buildWebBannerPanel()),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Left panel: category list or loading skeleton.
  Widget _buildWebCategoryList(CategoryController controller) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        border: Border.all(color: context.textLight.withValues(alpha: 0.15)),
      ),
      clipBehavior: Clip.antiAlias,
      child: controller.isLoading && controller.categories.isEmpty
          ? _buildCategoryLoadingSkeleton()
          : _buildCategoryListView(controller),
    );
  }

  Widget _buildCategoryLoadingSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 9,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        indent: 14,
        endIndent: 14,
        color: context.textLight.withValues(alpha: 0.10),
      ),
      itemBuilder: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: context.textLight.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  color: context.textLight.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: context.textLight.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryListView(CategoryController controller) {
    final cats = controller.categories;
    final visibleCount = cats.length.clamp(0, 9);
    final hasMore = cats.length > 9;
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 6),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visibleCount,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              indent: 14,
              endIndent: 14,
              color: context.textLight.withValues(alpha: 0.10),
            ),
            itemBuilder: (context, index) {
              final category = cats[index];
              return InkWell(
                onTap: () => context.pushNamed(
                  RouteNames.category,
                  pathParameters: {'id': category.id},
                  extra: category,
                ),
                hoverColor: ColorResource.primaryDark.withValues(alpha: 0.04),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: ColorResource.primaryDark.withValues(
                            alpha: 0.07,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: (category.imagePath?.isNotEmpty ?? false)
                            ? CustomNetworkImage(
                                image: category.imagePath!,
                                width: 30,
                                height: 30,
                                fit: BoxFit.cover,
                              )
                            : Icon(
                                Icons.category_outlined,
                                size: 16,
                                color: ColorResource.primaryDark,
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          category.nameMap.trLanguage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: poppinsMedium.copyWith(
                            fontSize: Constants.fontSizeDefault,
                            color: context.textPrimary,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: context.textLight,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (hasMore) ...[
          Divider(height: 1, color: context.textLight.withValues(alpha: 0.10)),
          InkWell(
            onTap: () {},
            hoverColor: ColorResource.primaryDark.withValues(alpha: 0.04),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'all_categories'.tr,
                    style: poppinsMedium.copyWith(
                      fontSize: Constants.fontSizeDefault,
                      color: ColorResource.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_right_rounded,
                    size: 16,
                    color: ColorResource.primaryDark,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Right panel: full-height banner carousel with shopping-image fallback.
  Widget _buildWebBannerPanel() {
    return GetBuilder<BannerController>(
      builder: (bannerController) {
        final banners = bannerController.banners
            .where(
              (b) =>
                  b.moduleType == ModuleController.ecommerce &&
                  !b.isPromotional,
            )
            .toList();

        return ClipRRect(
          borderRadius: BorderRadius.circular(Constants.radiusLarge),
          child: (banners.isEmpty && !bannerController.isLoading)
              ? Image.asset(
                  Images.shoppingBanner,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: _heroHeight,
                )
              : PromotionalBanner(
                  banners: banners,
                  isLoading: bannerController.isLoading,
                  errorMessage: bannerController.errorMessage,
                  onRetry: () => bannerController.getBanners(reload: true),
                  height: _heroHeight,
                ),
        );
      },
    );
  }

  /// Mobile — collapsing SliverAppBar: banner image with gradient scrim,
  /// title, tagline and search bar. Pinned with the search field in the toolbar.
  Widget _buildMobileAppBar(double hPad) {
    const double expandedHeight = 210;
    const double searchMaxWidth = 560;
    // Pinned strip height (below the status bar). Tall enough for the
    // full-size search field (~50px) + 8px bottom padding + ~12px of top
    // clearance, so the collapsed field sits comfortably under the status bar.
    const double collapsedBarHeight = 70;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      collapsedHeight: collapsedBarHeight,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: ColorResource.primaryDark,
      automaticallyImplyLeading: false,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final double appBarHeight = constraints.maxHeight;
          final double statusBarHeight = MediaQuery.of(context).padding.top;
          const double minHeight = collapsedBarHeight;
          final double collapseRatio =
              ((appBarHeight - minHeight - statusBarHeight) /
                      (expandedHeight - minHeight - statusBarHeight))
                  .clamp(0.0, 1.0);
          final bool isCollapsed = collapseRatio < 0.1;

          return Stack(
            fit: StackFit.expand,
            children: [
              FlexibleSpaceBar(
                stretchModes: const [
                  StretchMode.zoomBackground,
                  StretchMode.blurBackground,
                ],
                background: _buildMobileAppBarBackground(
                  hPad,
                  collapseRatio,
                  searchMaxWidth,
                ),
              ),
              // Collapsed search — anchored to the bottom edge of the pinned
              // bar (FlexibleSpaceBar's title metrics float it mid-bar).
              if (isCollapsed)
                Positioned(
                  left: hPad,
                  right: hPad,
                  bottom: 10,
                  child: _constrained(
                    searchMaxWidth,
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
          );
        },
      ),
    );
  }

  /// Expanded-state background of the mobile app bar: banner image, gradient
  /// scrim, title/tagline and the in-banner search field.
  Widget _buildMobileAppBarBackground(
    double hPad,
    double collapseRatio,
    double searchMaxWidth,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(Images.shoppingBanner, fit: BoxFit.cover),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.22),
                ColorResource.primaryDark.withValues(alpha: 0.84),
              ],
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'shop'.tr,
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeOverLarge,
                    color: ColorResource.textWhite,
                  ),
                ),
                const SizedBox(height: 2),
                Opacity(
                  opacity: collapseRatio,
                  child: Text(
                    'shop_tagline'.tr,
                    style: poppinsRegular.copyWith(
                      fontSize: Constants.fontSizeSmall,
                      color: ColorResource.textWhite.withValues(alpha: 0.80),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Opacity(
                  opacity: collapseRatio,
                  child: _constrained(
                    searchMaxWidth,
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
          ),
        ),
      ],
    );
  }

  /// Left-aligns [child] and caps its width — used to keep the search field
  /// from stretching edge-to-edge on wide screens.
  Widget _constrained(double maxWidth, Widget child) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }

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
            color: context.cardBackground.withValues(
              alpha: isDark ? 0.72 : 0.82,
            ),
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

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () => context.pushNamed(RouteNames.search),
      child: _frostedHeaderTile(
        padding: const EdgeInsets.symmetric(
          horizontal: Constants.paddingSizeDefault,
          vertical: Constants.paddingSizeSmall,
        ),
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
                              color: ColorResource.error.withValues(alpha: 0.6),
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

  Widget _buildBanners(double hPad) {
    return GetBuilder<BannerController>(
      builder: (bannerController) {
        // Shop hero slider: strictly ecommerce-tagged hero banners (promotional
        // banners are shown separately in their own section below).
        final banners = bannerController.banners
            .where(
              (b) =>
                  b.moduleType == ModuleController.ecommerce &&
                  !b.isPromotional,
            )
            .toList();

        if (banners.isEmpty && !bannerController.isLoading) {
          return const SizedBox(height: 16);
        }
        // The carousel self-margins its slides, so on mobile it stays full-bleed
        // (extra = 0); on desktop the extra gutter centers it with the content.
        final extra = hPad - 16;
        return Padding(
          padding: EdgeInsets.fromLTRB(extra, 16, extra, 0),
          child: PromotionalBanner(
            banners: banners,
            isLoading: bannerController.isLoading,
            errorMessage: bannerController.errorMessage,
            onRetry: () => bannerController.getBanners(reload: true),
          ),
        );
      },
    );
  }

  /// Ecommerce-only promotional banners, shown in their own section beneath the
  /// categories. Renders nothing when there are no promotional banners.
  Widget _buildPromotionalBanners(double hPad) {
    return GetBuilder<BannerController>(
      builder: (bannerController) {
        final promos = bannerController.banners
            .where(
              (b) =>
                  b.moduleType == ModuleController.ecommerce && b.isPromotional,
            )
            .toList();

        if (promos.isEmpty) return const SizedBox.shrink();

        final extra = hPad - 16;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('promotions'.tr, hPad),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: extra),
              child: PromotionalBanner(
                banners: promos,
                isLoading: false,
                errorMessage: null,
                onRetry: () => bannerController.getBanners(reload: true),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategories(double hPad) {
    return GetBuilder<CategoryController>(
      builder: (controller) {
        if (controller.categories.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('categories'.tr, hPad),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: hPad),
                itemCount: controller.categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final category = controller.categories[index];
                  return GestureDetector(
                    onTap: () => context.pushNamed(
                      RouteNames.category,
                      pathParameters: {'id': category.id},
                      extra: category,
                    ),
                    child: SizedBox(
                      width: 68,
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: ColorResource.primaryDark.withValues(
                                alpha: 0.08,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: (category.imagePath?.isNotEmpty ?? false)
                                ? CustomNetworkImage(
                                    image: category.imagePath!,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  )
                                : Icon(
                                    Icons.category_outlined,
                                    color: ColorResource.primaryDark,
                                  ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            category.nameMap.trLanguage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: poppinsMedium.copyWith(
                              fontSize: Constants.fontSizeExtraSmall,
                              color: context.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBrands(double hPad) {
    return GetBuilder<BrandController>(
      builder: (controller) {
        if (controller.brands.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('brands'.tr, hPad),
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: hPad),
                itemCount: controller.brands.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final brand = controller.brands[index];
                  return GestureDetector(
                    onTap: () => _openBrand(brand),
                    child: Container(
                      width: 110,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: context.cardBackground,
                        borderRadius: BorderRadius.circular(
                          Constants.radiusLarge,
                        ),
                        border: Border.all(
                          color: context.textLight.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          if ((brand.logoUrl ?? '').isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CustomNetworkImage(
                                image: brand.logoUrl!,
                                width: 32,
                                height: 32,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              brand.nameMap.trLanguage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: poppinsMedium.copyWith(
                                fontSize: Constants.fontSizeSmall,
                                color: context.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPopular(double hPad) {
    return GetBuilder<ProductController>(
      builder: (controller) {
        if (controller.popularProducts.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('popular'.tr, hPad),
            SizedBox(
              height: 280,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 8),
                itemCount: controller.popularProducts.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, index) => SizedBox(
                  width: 170,
                  child: EcommerceProductCard(
                    product: controller.popularProducts[index],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Top (highest-rated) products as a horizontal highlight strip. The whole
  /// section is centered within [_maxContentWidth] so it never spans the full
  /// screen width on web, and shows scroll-arrow buttons on wide layouts.
  Widget _buildTopProducts(bool isWide) {
    return GetBuilder<ProductController>(
      builder: (controller) {
        return _buildProductCarousel(
          isWide: isWide,
          title: 'top_products'.tr,
          loading: controller.isLoadingTop && controller.topProducts.isEmpty,
          products: controller.topProducts,
          scrollController: _topScrollController,
          hovered: _topHovered,
          onHoverChanged: (value) => setState(() => _topHovered = value),
        );
      },
    );
  }

  Widget _buildOfferProducts(bool isWide) {
    return GetBuilder<ProductController>(
      builder: (controller) {
        return _buildProductCarousel(
          isWide: isWide,
          title: 'offer_products'.tr,
          loading:
              controller.isLoadingOffers && controller.offerProducts.isEmpty,
          products: controller.offerProducts,
          scrollController: _offerScrollController,
          hovered: _offerHovered,
          onHoverChanged: (value) => setState(() => _offerHovered = value),
        );
      },
    );
  }

  /// Shared horizontal product carousel (Top / Offer sections): a centered,
  /// width-capped strip with hover-revealed scroll arrows on web.
  Widget _buildProductCarousel({
    required bool isWide,
    required String title,
    required bool loading,
    required List<ProductModel> products,
    required ScrollController scrollController,
    required bool hovered,
    required ValueChanged<bool> onHoverChanged,
  }) {
    if (!loading && products.isEmpty) {
      return const SizedBox.shrink();
    }

    return Center(
      // maxContentWidth + 32 keeps the inner 16px padding aligned exactly
      // with the other hPad-gutter sections, while capping the width so the
      // carousel stays inside the content column (no full-bleed scrolling).
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth + 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(title, 16),
            MouseRegion(
              onEnter: (_) {
                if (!hovered) onHoverChanged(true);
              },
              onExit: (_) {
                if (hovered) onHoverChanged(false);
              },
              child: SizedBox(
                height: isWide ? 350 : 280,
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : Stack(
                        children: [
                          ListView.separated(
                            controller: scrollController,
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                            itemCount: products.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 14),
                            itemBuilder: (context, index) => SizedBox(
                              width: isWide ? 230 : 170,
                              child: EcommerceProductCard(
                                product: products[index],
                              ),
                            ),
                          ),
                          // Scroll arrows — reveal only while hovered (web),
                          // and only when the strip actually overflows.
                          // Hover triggers a rebuild, so the laid-out scroll
                          // extent is available by the time this matters.
                          if (isWide &&
                              _carouselHasOverflow(scrollController)) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: _animatedArrow(
                                isLeft: true,
                                hovered: hovered,
                                scrollController: scrollController,
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: _animatedArrow(
                                isLeft: false,
                                hovered: hovered,
                                scrollController: scrollController,
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Fades + slides the scroll arrow in while the strip is hovered, and out
  /// (non-interactive) otherwise.
  Widget _animatedArrow({
    required bool isLeft,
    required bool hovered,
    required ScrollController scrollController,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      opacity: hovered ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        offset: hovered ? Offset.zero : Offset(isLeft ? -0.4 : 0.4, 0),
        child: IgnorePointer(
          ignoring: !hovered,
          child: _scrollArrow(
            isLeft: isLeft,
            scrollController: scrollController,
          ),
        ),
      ),
    );
  }

  /// Circular scroll button for a product carousel.
  Widget _scrollArrow({
    required bool isLeft,
    required ScrollController scrollController,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: context.cardBackground,
        shape: const CircleBorder(),
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _scrollCarouselBy(scrollController, isLeft ? -380 : 380),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              isLeft ? Icons.chevron_left : Icons.chevron_right,
              color: ColorResource.primaryDark,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  /// Whether a horizontal strip actually overflows its viewport. Checked at
  /// build time — the hover that reveals the arrows triggers a rebuild, so
  /// the laid-out extent is available when it matters.
  bool _carouselHasOverflow(ScrollController controller) =>
      controller.hasClients && controller.position.maxScrollExtent > 1;

  void _scrollCarouselBy(ScrollController controller, double delta) {
    if (!controller.hasClients) return;
    final target = (controller.offset + delta).clamp(
      0.0,
      controller.position.maxScrollExtent,
    );
    controller.animateTo(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  /// Gap between product tiles, used for both grid axes.
  static const double _gridSpacing = Constants.paddingSizeDefault;

  /// Image shapes cycled through the masonry grid, as width ÷ height — `1` is
  /// square, below `1` is portrait. Staggering the *image* is what gives the
  /// grid its rhythm, since the text block under it is a near-constant height.
  ///
  /// The cycle is **seven** long on purpose: 7 is coprime with every column
  /// count the storefront uses (2–6), so a given ratio never lands in the same
  /// column twice in a row. A shorter cycle would re-align into flat rows at
  /// some breakpoints and the stagger would disappear.
  ///
  /// Nothing here is random — the ratio is derived from the item index, so a
  /// tile keeps its shape across rebuilds, scrolling and pagination.
  static const List<double> _staggerRatios = [1, 0.82, 1, 0.75, 0.9, 1, 0.8];

  double _imageRatioFor(int index) =>
      _staggerRatios[index % _staggerRatios.length];

  /// Placeholder tiles rendered during the first load, so the section keeps
  /// its shape instead of collapsing to a lone spinner.
  static const int _skeletonTileCount = 8;

  /// The storefront's main product grid — a true masonry layout.
  ///
  /// [SliverMasonryGrid] drops each tile into whichever column is currently
  /// shortest, so tiles of different heights interlock instead of being forced
  /// onto a shared row baseline. Tiles size to their own content, so a
  /// two-line product name costs only its own card — no `childAspectRatio` to
  /// guess, and no wasted space under the shorter cards in a row.
  Widget _buildAllProductsGrid(int crossAxisCount, double hPad) {
    return GetBuilder<ProductController>(
      builder: (controller) {
        if (controller.products.isEmpty) {
          return SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            sliver: controller.isLoading
                ? _buildSkeletonGrid(crossAxisCount)
                : SliverToBoxAdapter(child: _buildEmptyState(controller)),
          );
        }

        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: _gridSpacing,
            crossAxisSpacing: _gridSpacing,
            childCount: controller.products.length,
            itemBuilder: (context, index) => EcommerceProductCard(
              product: controller.products[index],
              imageAspectRatio: _imageRatioFor(index),
            ),
          ),
        );
      },
    );
  }

  /// Same masonry rhythm as the real grid, so the loading state has the shape
  /// the content will arrive in rather than snapping into place.
  Widget _buildSkeletonGrid(int crossAxisCount) {
    return SliverMasonryGrid.count(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: _gridSpacing,
      crossAxisSpacing: _gridSpacing,
      childCount: _skeletonTileCount,
      itemBuilder: (context, index) =>
          _buildSkeletonTile(_imageRatioFor(index)),
    );
  }

  /// A product card reduced to its blocks — same silhouette, no content.
  Widget _buildSkeletonTile(double imageRatio) {
    Widget bar(double widthFactor, double height) => FractionallySizedBox(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: context.textLight.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(Constants.radiusSmall),
        ),
      ),
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusCard),
        border: Border.all(color: context.textLight.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: imageRatio,
            child: ColoredBox(color: context.textLight.withValues(alpha: 0.10)),
          ),
          Padding(
            padding: const EdgeInsets.all(Constants.paddingSizeSmall),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                bar(0.45, 10),
                const SizedBox(height: Constants.paddingSizeSmall),
                bar(0.9, 12),
                const SizedBox(height: Constants.paddingSizeExtraSmall),
                bar(0.6, 12),
                const SizedBox(height: Constants.paddingSizeDefault),
                bar(0.5, 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Empty state. A filtered-to-nothing list is a different problem from an
  /// empty catalogue — it is the user's own filter, and it needs a way out.
  Widget _buildEmptyState(ProductController controller) {
    final isFiltered = controller.productFilter.isActive;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: Constants.paddingSizeExtraLarge * 2,
      ),
      child: Column(
        children: [
          Icon(
            isFiltered
                ? Icons.filter_alt_off_outlined
                : Icons.inventory_2_outlined,
            size: 56,
            color: context.textLight,
          ),
          const SizedBox(height: Constants.paddingSizeDefault),
          Text(
            isFiltered ? 'no_products_match'.tr : 'no_products_available'.tr,
            textAlign: TextAlign.center,
            style: poppinsBold.copyWith(
              fontSize: Constants.fontSizeLarge,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: Constants.paddingSizeExtraSmall),
          Text(
            isFiltered ? 'try_different_filters'.tr : 'check_back_soon'.tr,
            textAlign: TextAlign.center,
            style: poppinsRegular.copyWith(
              fontSize: Constants.fontSizeDefault,
              color: context.textSecondary,
            ),
          ),
          if (isFiltered) ...[
            const SizedBox(height: Constants.paddingSizeDefault),
            OutlinedButton.icon(
              onPressed: controller.clearProductFilter,
              icon: const Icon(Icons.close_rounded, size: 18),
              label: Text(
                'clear_filters'.tr,
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeDefault,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorResource.primaryDark,
                side: const BorderSide(color: ColorResource.primaryDark),
                padding: const EdgeInsets.symmetric(
                  horizontal: Constants.paddingSizeLarge,
                  vertical: Constants.paddingSizeSmall,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Constants.radiusDefault),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Mobile pagination feedback. Infinite scroll used to append pages with no
  /// visible signal at all — this shows the fetch in progress and says so when
  /// the last page has landed. Web uses the "View more" button instead.
  Widget _buildGridFooter(double hPad, bool isWide) {
    if (isWide) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return GetBuilder<ProductController>(
      builder: (controller) {
        if (controller.products.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              hPad,
              Constants.paddingSizeLarge,
              hPad,
              0,
            ),
            child: Center(
              child: controller.isLoadingMore
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: ColorResource.primaryDark,
                      ),
                    )
                  : controller.hasMore
                  ? const SizedBox.shrink()
                  : Text(
                      'no_more_products'.tr,
                      style: poppinsRegular.copyWith(
                        fontSize: Constants.fontSizeSmall,
                        color: context.textLight,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  /// Web-only pagination control beneath the all-products grid. Tapping it
  /// appends the next page (offset) and keeps working continuously while more
  /// pages remain. It renders nothing on mobile (infinite scroll handles it),
  /// when there are no products, or once the final page has loaded.
  Widget _buildViewMoreButton(double hPad, bool isWide) {
    if (!isWide) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return GetBuilder<ProductController>(
      builder: (controller) {
        if (controller.products.isEmpty || !controller.hasMore) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              hPad,
              Constants.paddingSizeLarge,
              hPad,
              0,
            ),
            child: Center(
              // Fixed height keeps the layout stable while the label swaps to
              // the loading spinner and back.
              child: SizedBox(
                height: 48,
                child: Center(
                  child: controller.isLoadingMore
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: ColorResource.primaryDark,
                          ),
                        )
                      : _viewMoreButton(controller.loadMoreProducts),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Outlined pill button used by [_buildViewMoreButton].
  Widget _viewMoreButton(VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: ColorResource.primaryDark.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          hoverColor: ColorResource.primaryDark.withValues(alpha: 0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: ColorResource.primaryDark, width: 1.8),
              color: context.cardBackground,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'view_more'.tr,
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeDefault,
                    color: ColorResource.primaryDark,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.keyboard_double_arrow_down_rounded,
                  size: 18,
                  color: ColorResource.primaryDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, double hPad) {
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 12),
      child: Text(
        title,
        style: poppinsBold.copyWith(
          fontSize: Constants.fontSizeExtraLarge,
          color: context.textPrimary,
        ),
      ),
    );
  }
}

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

  List<String> _hintNames() {
    if (!Get.isRegistered<CategoryController>()) return const [];
    return Get.find<CategoryController>().categories
        .map((c) => c.nameMap.trLanguage)
        .where((n) => n.trim().isNotEmpty)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
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

        if (names.isEmpty) {
          return Text(
            'search_products'.tr,
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
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 550),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                layoutBuilder: (currentChild, previousChildren) => Stack(
                  alignment: AlignmentDirectional.centerStart,
                  children: <Widget>[
                    ...previousChildren,
                    currentChild ?? const SizedBox.shrink(),
                  ],
                ),
                transitionBuilder: (child, animation) {
                  final inAnimation = Tween<Offset>(
                    begin: const Offset(0.0, 0.4),
                    end: Offset.zero,
                  ).animate(animation);
                  final outAnimation = Tween<Offset>(
                    begin: const Offset(0.0, -0.4),
                    end: Offset.zero,
                  ).animate(animation);

                  if (child.key == ValueKey<int>(_index)) {
                    return SlideTransition(
                      position: inAnimation,
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  } else {
                    return SlideTransition(
                      position: outAnimation,
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  }
                },
                child: Text(
                  name,
                  key: ValueKey<int>(_index),
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
