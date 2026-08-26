import 'package:appwrite_user_app/app/common/widgets/auth_gate.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_appbar.dart';
import 'package:appwrite_user_app/app/common/widgets/directional_flip.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_clickable_widget.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/common/widgets/hover_lift.dart';
import 'package:appwrite_user_app/app/common/widgets/rating_stars.dart';
import 'package:appwrite_user_app/app/common/widgets/web_footer.dart';
import 'package:appwrite_user_app/app/common/widgets/web_top_nav.dart';
import 'package:appwrite_user_app/app/controllers/favorites_controller.dart';
import 'package:appwrite_user_app/app/controllers/module_controller.dart';
import 'package:appwrite_user_app/app/helper/dashboard_tab_bus.dart';
import 'package:appwrite_user_app/app/helper/localization_extension_helper.dart';
import 'package:appwrite_user_app/app/helper/nav_bar_visibility.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/web_profile_drawer.dart';
import 'package:appwrite_user_app/app/models/product_model.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/product_detail_bottomsheet.dart';
import 'package:appwrite_user_app/app/modules/ecommerce/widgets/ecommerce_product_card.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/helper/price_helper.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class FavoritesScreen extends StatefulWidget {
  final bool? isFromMenu;
  const FavoritesScreen({super.key, this.isFromMenu = false});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  // Web/desktop layout kicks in above this width — the same one the shared
  // top-nav uses, so the page changes shape when the chrome does.
  static const double _webBreakpoint = WebTopNav.wideBreakpoint;

  /// Side padding and the width left inside it. Both layouts and the loading
  /// skeleton read these, so a grid and the skeleton standing in for it can
  /// never be measured differently.
  double _sidePadding(double width) => WebTopNav.bodySidePadding(width);

  double _contentWidth(double width) => width - _sidePadding(width) * 2;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Widest the shop grid goes on desktop web.
  static const int _maxEcommerceColumns = 4;

  static const List<double> _staggerRatios = [1, 0.82, 1, 0.75, 0.9, 1, 0.8];

  double _imageRatioFor(int index) =>
      _staggerRatios[index % _staggerRatios.length];

  @override
  void initState() {
    super.initState();

    Get.find<FavoritesController>().fetchFavorites(
      canUpdate: false,
      loadWithProduct: true,
    );
  }

  /// True on desktop web (the layout gets the centred, capped grid + inline
  /// title regardless of how the screen was reached).
  bool get _isWebLayout => WebTopNav.isEnabled(context);

  /// Whether the shop storefront is the active one.
  bool get _isEcommerce => Get.find<ModuleController>().isEcommerce;

  /// Columns for the wide grid.
  ///
  /// The shop caps at [_maxEcommerceColumns]: its cards carry a brand line, a
  /// two-line name, a rating row, and a price beside an inline cart control,
  /// and a fifth column squeezes that block past the width it stays readable
  /// at. Food tiles hold less and keep their five.
  int _crossAxisCount(double width) {
    if (width < _webBreakpoint) return 2;
    if (width >= 1100) return _isEcommerce ? _maxEcommerceColumns : 5;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    final showWebNav = WebTopNav.isEnabled(context);
    final isFromMenu = widget.isFromMenu == true;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: context.scaffoldBackground,
      // On web: pushed-from-menu shows the shared top-nav shell + account
      // drawer; as a dashboard tab the shell already provides it (so no own
      // app bar). Mobile keeps the plain app bar (with a back button when
      // opened from the menu).
      appBar: showWebNav
          ? (isFromMenu
                ? WebTopNav(
                    selectedIndex: null,
                    onDestinationSelected: (index) =>
                        DashboardTabs.open(context, index),
                    onMenuTap: () => _scaffoldKey.currentState?.openEndDrawer(),
                  )
                : null)
          : CustomAppbar(title: 'my_favorites'.tr, showBackButton: isFromMenu),
      endDrawer: (showWebNav && isFromMenu) ? const WebProfileDrawer() : null,
      body: AuthGate(
        child: GetBuilder<FavoritesController>(
          builder: (controller) {
            if (controller.isLoading) {
              return _buildLoadingState(context);
            }

            // Scope favorites to the active storefront so Food and Shop each show
            // only their own saved items.
            final activeModule = Get.find<ModuleController>().activeModule;
            final favorites = controller.favorites
                .where(
                  (f) =>
                      f.product != null &&
                      f.product!.moduleType == activeModule,
                )
                .toList();

            if (favorites.isEmpty) {
              return _buildEmptyState();
            }

            return _buildFavoritesBody(context, controller, favorites);
          },
        ),
      ),
    );
  }

  Widget _buildFavoritesBody(
    BuildContext context,
    FavoritesController controller,
    List favorites,
  ) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= _webBreakpoint;
    // On web the grid stays FULL-WIDTH (so dragging anywhere — including the
    // letterboxed side gutters — scrolls); the content is centred within the
    // nav's band by padding the sides instead of wrapping in a ConstrainedBox
    // (which would trap the scroll to the centre column). At 1100 with no
    // inset the grid sat wider than the bar above it *and* started 20px
    // outside its logo.
    final double sidePadding = _sidePadding(width);
    final crossAxisCount = _crossAxisCount(_contentWidth(width));

    final grid = NavClearance(
      // A CustomScrollView so the web footer can sit below the grid as a sliver
      // (empty/no-op on mobile). AlwaysScrollable keeps pull-to-refresh working
      // even when the grid doesn't fill the viewport.
      builder: (context, bottom) => CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              sidePadding,
              _isWebLayout ? 8 : 16,
              sidePadding,
              // Nav-bar clearance + a small breathing space at the very bottom.
              bottom + 20,
            ),
            sliver:
                Get.find<ModuleController>().activeModule ==
                    ModuleController.ecommerce
                ? SliverMasonryGrid.count(
                    crossAxisCount: isWide ? crossAxisCount : 2,
                    crossAxisSpacing: isWide ? 20 : 16,
                    mainAxisSpacing: isWide ? 20 : 16,
                    childCount: favorites.length,
                    itemBuilder: (context, index) {
                      final favorite = favorites[index];
                      final product = favorite.product!;
                      return EcommerceProductCard(
                        product: product,
                        imageAspectRatio: _imageRatioFor(index),
                      );
                    },
                  )
                : SliverGrid(
                    gridDelegate: isWide
                        ? SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            childAspectRatio: 0.66,
                          )
                        : const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            // Tall enough for the image + a 2-line name, rating and
                            // price so the card content never overflows/overlaps.
                            mainAxisExtent: 250,
                          ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final favorite = favorites[index];
                      final product = favorite.product!;
                      final card = _buildProductCard(
                        context,
                        product,
                        favorite.id,
                        controller,
                      );
                      return kIsWeb ? HoverLift(child: card) : card;
                    }, childCount: favorites.length),
                  ),
          ),
          WebFooter.sliver(),
        ],
      ),
    );

    final refreshable = RefreshIndicator(
      onRefresh: () => controller.fetchFavorites(),
      color: ColorResource.primaryDark,
      child: grid,
    );

    if (!isWide) return refreshable;

    // Web: an inline page title (when the shared shell nav owns the app bar),
    // then the full-width scrollable grid.
    return Column(
      children: [
        if (_isWebLayout)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: sidePadding),
            child: _buildInlineTitle(favorites.length),
          ),
        Expanded(child: refreshable),
      ],
    );
  }

  Widget _buildInlineTitle(int count) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            'my_favorites'.tr,
            style: poppinsBold.copyWith(
              fontSize: Constants.fontSizeOverLarge,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '($count)',
            style: poppinsMedium.copyWith(
              fontSize: Constants.fontSizeLarge,
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= _webBreakpoint;
    final double sidePadding = _sidePadding(width);
    final crossAxisCount = _crossAxisCount(_contentWidth(width));
    final activeModule = Get.find<ModuleController>().activeModule;

    if (activeModule == ModuleController.ecommerce) {
      return MasonryGridView.count(
        padding: EdgeInsets.fromLTRB(
          sidePadding,
          _isWebLayout ? 8 : 16,
          sidePadding,
          Constants.bottomNavSpace,
        ),
        crossAxisCount: isWide ? crossAxisCount : 2,
        crossAxisSpacing: isWide ? 20 : 16,
        mainAxisSpacing: isWide ? 20 : 16,
        itemCount: isWide ? 10 : 6,
        itemBuilder: (context, index) =>
            _buildSkeletonCard(imageAspectRatio: _imageRatioFor(index)),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
        sidePadding,
        _isWebLayout ? 8 : 16,
        sidePadding,
        Constants.bottomNavSpace,
      ),
      gridDelegate: isWide
          ? SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 0.66,
            )
          : const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
      itemCount: isWide ? 10 : 6,
      itemBuilder: (context, index) => _buildSkeletonCard(),
    );
  }

  Widget _buildSkeletonCard({double? imageAspectRatio}) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: ColorResource.customShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: imageAspectRatio == null
            ? MainAxisSize.max
            : MainAxisSize.min,
        children: [
          // Image skeleton
          if (imageAspectRatio == null)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: context.textLight.withValues(alpha: 0.2),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(Constants.radiusLarge),
                  ),
                ),
              ),
            )
          else
            AspectRatio(
              aspectRatio: imageAspectRatio,
              child: Container(
                decoration: BoxDecoration(
                  color: context.textLight.withValues(alpha: 0.2),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(Constants.radiusLarge),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.textLight.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 14,
                  width: 80,
                  decoration: BoxDecoration(
                    color: context.textLight.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: ColorResource.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_outline,
                size: 60,
                color: ColorResource.textWhite,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'no_favorites_yet'.tr,
              style: poppinsBold.copyWith(
                fontSize: 24,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'start_adding_favorites'.tr,
              textAlign: TextAlign.center,
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: context.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: DirectionalFlip(
                child: Icon(Icons.arrow_back, color: ColorResource.textWhite),
              ),
              label: Text(
                'browse_products'.tr,
                style: poppinsMedium.copyWith(color: ColorResource.textWhite),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorResource.primaryDark,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    ProductModel product,
    String favoriteId,
    FavoritesController controller,
  ) {
    final bool isVeg = product.isVeg;
    final bool hasDiscount = product.hasDiscount;

    return CustomClickableWidget(
      onTap: () {
        ProductDetailBottomSheet.show(context, product);
      },
      isBackgroundTransparent: true,
      child: Container(
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: BorderRadius.circular(Constants.radiusLarge),
          boxShadow: ColorResource.customShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with badges
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(Constants.radiusLarge),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CustomNetworkImage(
                            image: product.imageId,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.15),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Veg/Non-veg badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: ColorResource.textWhite,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isVeg ? Colors.green : Colors.red,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.circle,
                        size: 8,
                        color: isVeg ? Colors.green : Colors.red,
                      ),
                    ),
                  ),

                  // Discount badge
                  if (hasDiscount)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: ColorResource.discountBadge,
                          borderRadius: BorderRadius.circular(
                            Constants.radiusLarge,
                          ),
                        ),
                        child: Text(
                          product.discountType == 'percentage'
                              ? '${product.discountValue!.toInt()}% OFF'
                              : '${PriceHelper.formatPrice(product.discountValue!.toDouble())} OFF',
                          style: poppinsBold.copyWith(
                            fontSize: 10,
                            color: ColorResource.textWhite,
                          ),
                        ),
                      ),
                    ),

                  // Favorite button
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () =>
                          controller.removeFavoriteById(favoriteId, product.id),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ColorResource.textWhite,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: controller.isToggleLoading(product.id)
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    ColorResource.primaryDark,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.favorite,
                                size: 20,
                                color: ColorResource.error,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Product Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.nameMap.trLanguage,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: poppinsMedium.copyWith(
                      fontSize: Constants.fontSizeDefault,
                      color: context.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),

                  RatingStars(
                    rating: product.avgRating,
                    reviewCount: product.ratingCount,
                    size: 13,
                  ),
                  const SizedBox(height: 8),

                  // Price
                  Row(
                    children: [
                      if (hasDiscount) ...[
                        Text(
                          PriceHelper.formatPrice(product.price),
                          style: poppinsRegular.copyWith(
                            fontSize: Constants.fontSizeSmall,
                            color: context.textLight,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        PriceHelper.formatPrice(product.finalPrice),
                        style: poppinsBold.copyWith(
                          fontSize: Constants.fontSizeDefault + 2,
                          color: ColorResource.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
