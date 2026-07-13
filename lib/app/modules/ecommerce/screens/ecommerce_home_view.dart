import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/controllers/banner_controller.dart';
import 'package:appwrite_user_app/app/controllers/brand_controller.dart';
import 'package:appwrite_user_app/app/controllers/category_controller.dart';
import 'package:appwrite_user_app/app/controllers/flash_sale_controller.dart';
import 'package:appwrite_user_app/app/controllers/module_controller.dart';
import 'package:appwrite_user_app/app/controllers/product_controller.dart';
import 'package:appwrite_user_app/app/helper/localization_extension_helper.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/models/brand_model.dart';
import 'package:appwrite_user_app/app/models/product_model.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/promotional_banner.dart';
import 'package:appwrite_user_app/app/modules/ecommerce/widgets/ecommerce_product_card.dart';
import 'package:appwrite_user_app/app/modules/flash_sale/widgets/flash_sale_section.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/images.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class EcommerceHomeView extends StatefulWidget {
  const EcommerceHomeView({super.key});

  @override
  State<EcommerceHomeView> createState() => _EcommerceHomeViewState();
}

class _EcommerceHomeViewState extends State<EcommerceHomeView>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  // Drives the Top Products carousel (used by the web scroll-arrow buttons).
  final ScrollController _topScrollController = ScrollController();
  // Scroll arrows only reveal while a pointer hovers the Top Products strip.
  bool _topHovered = false;
  // Same pair for the Offer Products carousel.
  final ScrollController _offerScrollController = ScrollController();
  bool _offerHovered = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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
          SliverToBoxAdapter(child: _sectionHeader('all_products'.tr, hPad)),
          _buildAllProductsGrid(crossAxisCount, hPad),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
          color: ColorResource.cardBackground,
          borderRadius: BorderRadius.circular(Constants.radiusLarge),
          border: Border.all(
            color: ColorResource.textLight.withValues(alpha: 0.15),
          ),
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
                  color: ColorResource.textPrimary,
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
        color: ColorResource.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        border: Border.all(
          color: ColorResource.textLight.withValues(alpha: 0.15),
        ),
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
        color: ColorResource.textLight.withValues(alpha: 0.10),
      ),
      itemBuilder: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: ColorResource.textLight.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  color: ColorResource.textLight.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: ColorResource.textLight.withValues(alpha: 0.08),
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
              color: ColorResource.textLight.withValues(alpha: 0.10),
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
                            color: ColorResource.textPrimary,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: ColorResource.textLight,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (hasMore) ...[
          Divider(
            height: 1,
            color: ColorResource.textLight.withValues(alpha: 0.10),
          ),
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
                  child: _constrained(searchMaxWidth, _buildSearchBar()),
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
                  child: _constrained(searchMaxWidth, _buildSearchBar()),
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

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () => context.pushNamed(RouteNames.search),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: ColorResource.cardBackground,
          borderRadius: BorderRadius.circular(Constants.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: ColorResource.textSecondary),
            const SizedBox(width: 12),
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
                              color: ColorResource.textPrimary,
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
                        color: ColorResource.cardBackground,
                        borderRadius: BorderRadius.circular(
                          Constants.radiusLarge,
                        ),
                        border: Border.all(
                          color: ColorResource.textLight.withValues(
                            alpha: 0.15,
                          ),
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
                                color: ColorResource.textPrimary,
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
        color: ColorResource.cardBackground,
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

  Widget _buildAllProductsGrid(int crossAxisCount, double hPad) {
    return GetBuilder<ProductController>(
      builder: (controller) {
        if (controller.products.isEmpty && controller.isLoading) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (controller.products.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'no_products_available'.tr,
                  style: poppinsMedium.copyWith(
                    color: ColorResource.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }
        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 0.6,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) =>
                  EcommerceProductCard(product: controller.products[index]),
              childCount: controller.products.length,
            ),
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title, double hPad) {
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 12),
      child: Text(
        title,
        style: poppinsBold.copyWith(
          fontSize: Constants.fontSizeExtraLarge,
          color: ColorResource.textPrimary,
        ),
      ),
    );
  }
}
