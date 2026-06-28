import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/controllers/banner_controller.dart';
import 'package:appwrite_user_app/app/controllers/brand_controller.dart';
import 'package:appwrite_user_app/app/controllers/category_controller.dart';
import 'package:appwrite_user_app/app/controllers/module_controller.dart';
import 'package:appwrite_user_app/app/controllers/product_controller.dart';
import 'package:appwrite_user_app/app/helper/localization_extension_helper.dart';
import 'package:appwrite_user_app/app/models/brand_model.dart';
import 'package:appwrite_user_app/app/modules/categories/screens/category_products_page.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/promotional_banner.dart';
import 'package:appwrite_user_app/app/modules/ecommerce/widgets/ecommerce_product_card.dart';
import 'package:appwrite_user_app/app/modules/search/screens/search_page.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EcommerceHomeView extends StatefulWidget {
  const EcommerceHomeView({super.key});

  @override
  State<EcommerceHomeView> createState() => _EcommerceHomeViewState();
}

class _EcommerceHomeViewState extends State<EcommerceHomeView>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

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
      productController.getPopularProducts(reload: reload),
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
          _buildSliverAppBar(context, hPad),
          SliverToBoxAdapter(child: _buildBanners(hPad)),
          SliverToBoxAdapter(child: _buildCategories(hPad)),
          if (isWide)
            SliverToBoxAdapter(child: _buildPromosBrandsRow(hPad))
          else ...[
            SliverToBoxAdapter(child: _buildPromotionalBanners(hPad)),
            SliverToBoxAdapter(child: _buildBrands(hPad)),
          ],
          SliverToBoxAdapter(child: _buildPopular(hPad)),
          SliverToBoxAdapter(
            child: _sectionHeader('all_products'.tr, hPad),
          ),
          _buildAllProductsGrid(crossAxisCount, hPad),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  /// Web/desktop layout: Promotions (left, wider) and Brands (right) in one row.
  /// Falls back to a single full-width section when only one of them has data.
  Widget _buildPromosBrandsRow(double hPad) {
    return GetBuilder<BannerController>(
      builder: (bannerController) {
        final promos = bannerController.banners
            .where((b) =>
                b.moduleType == ModuleController.ecommerce && b.isPromotional)
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
                  // Promotions — the visual focus, so it takes the larger share.
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader('promotions'.tr, 0),
                        PromotionalBanner(
                          banners: promos,
                          isLoading: false,
                          errorMessage: null,
                          onRetry: () => bannerController.getBanners(reload: true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Brands — a compact panel of chips beside the promotions.
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader('brands'.tr, 0),
                        _brandsPanel(brands),
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
  Widget _brandsPanel(List<BrandModel> brands) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisExtent: 66,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: brands.length,
      itemBuilder: (context, index) => _brandTile(brands[index]),
    );
  }

  Widget _brandTile(BrandModel brand) {
    final hasLogo = (brand.logoUrl ?? '').isNotEmpty;
    return Container(
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
    );
  }

  /// Sticky, collapsing storefront header. Expanded it shows the "Shop" title
  /// over a gradient with a search bar; once scrolled past, it pins to the top
  /// and keeps the search bar accessible as the toolbar title.
  Widget _buildSliverAppBar(BuildContext context, double hPad) {
    const double expandedHeight = 156;
    // Keep the search field a comfortable reading width on desktop instead of
    // stretching it across the whole content area.
    const double searchMaxWidth = 560;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      elevation: 0,
      backgroundColor: ColorResource.primaryDark,
      automaticallyImplyLeading: false,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final double appBarHeight = constraints.maxHeight;
          final double statusBarHeight = MediaQuery.of(context).padding.top;
          final double minHeight = kToolbarHeight + statusBarHeight;
          final double collapseRatio =
              ((appBarHeight - minHeight) / (expandedHeight - minHeight))
                  .clamp(0.0, 1.0);
          // Once nearly collapsed, surface the search bar as the pinned title so
          // it never scrolls away.
          final bool isCollapsed = collapseRatio < 0.1;

          return FlexibleSpaceBar(
            titlePadding: isCollapsed
                ? EdgeInsets.fromLTRB(hPad, 8, hPad, 8)
                : EdgeInsets.zero,
            title: isCollapsed
                ? _constrained(searchMaxWidth, _buildSearchBar())
                : null,
            background: Container(
              decoration: BoxDecoration(gradient: ColorResource.primaryGradient),
              child: SafeArea(
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
                      const SizedBox(height: 12),
                      // Hidden while collapsed to avoid doubling with the title.
                      Opacity(
                        opacity: collapseRatio,
                        child: _constrained(searchMaxWidth, _buildSearchBar()),
                      ),
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
      onTap: () => Get.to(() => const SearchPage()),
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
            .where((b) =>
                b.moduleType == ModuleController.ecommerce && !b.isPromotional)
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
            .where((b) =>
                b.moduleType == ModuleController.ecommerce && b.isPromotional)
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
                    onTap: () => Get.to(
                      () => CategoryProductsPage(category: category),
                    ),
                    child: SizedBox(
                      width: 68,
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: ColorResource.primaryDark
                                  .withValues(alpha: 0.08),
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
                  return Container(
                    width: 110,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: ColorResource.cardBackground,
                      borderRadius: BorderRadius.circular(Constants.radiusLarge),
                      border: Border.all(
                        color: ColorResource.textLight.withValues(alpha: 0.15),
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
              (context, index) => EcommerceProductCard(
                product: controller.products[index],
              ),
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
