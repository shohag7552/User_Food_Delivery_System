import 'package:appwrite_user_app/app/common/widgets/auth_gate.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_appbar.dart';
import 'package:appwrite_user_app/app/common/widgets/directional_flip.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_clickable_widget.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/common/widgets/hover_lift.dart';
import 'package:appwrite_user_app/app/common/widgets/rating_stars.dart';
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
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class FavoritesScreen extends StatefulWidget {
  final bool? isFromMenu;
  const FavoritesScreen({super.key, this.isFromMenu = false});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  // Web/desktop layout kicks in above this width.
  static const double _webBreakpoint = 900;
  static const double _maxContentWidth = 1100;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    Get.find<FavoritesController>().fetchFavorites(canUpdate: false, loadWithProduct: true);
  }

  /// True on desktop web (the layout gets the centred, capped grid + inline
  /// title regardless of how the screen was reached).
  bool get _isWebLayout => WebTopNav.isEnabled(context);

  int _crossAxisCount(double width) {
    if (width < _webBreakpoint) return 2;
    if (width >= 1400) return 5;
    if (width >= 1100) return 4;
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
          : CustomAppbar(
              title: 'my_favorites'.tr,
              showBackButton: isFromMenu,
            ),
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
                .where((f) =>
                    f.product != null && f.product!.moduleType == activeModule)
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
    // letterboxed side gutters — scrolls); the content is centred within
    // [_maxContentWidth] by padding the sides instead of wrapping in a
    // ConstrainedBox (which would trap the scroll to the centre column).
    final double contentWidth =
        isWide && width > _maxContentWidth ? _maxContentWidth : width;
    final double sidePadding = isWide
        ? (width > _maxContentWidth ? (width - _maxContentWidth) / 2 : 24)
        : 16;
    final crossAxisCount = _crossAxisCount(contentWidth);

    final grid = NavClearance(
      builder: (context, bottom) => GridView.builder(
      padding: EdgeInsets.fromLTRB(
        sidePadding,
        _isWebLayout ? 8 : 16,
        sidePadding,
        // Nav-bar clearance + a small breathing space at the very bottom.
        bottom + 20,
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
              // Tall enough for the image + a 2-line name, rating and price so
              // the card content never overflows/overlaps.
              mainAxisExtent: 250,
            ),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final favorite = favorites[index];
        final product = favorite.product!;
        // Ecommerce products use the storefront card (has its own hover);
        // food keeps its own card, wrapped with hover on web.
        if (product.moduleType == ModuleController.ecommerce) {
          return EcommerceProductCard(product: product);
        }
        final card =
            _buildProductCard(context, product, favorite.id, controller);
        return kIsWeb ? HoverLift(child: card) : card;
      },
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
    final double contentWidth =
        isWide && width > _maxContentWidth ? _maxContentWidth : width;
    final double sidePadding = isWide
        ? (width > _maxContentWidth ? (width - _maxContentWidth) / 2 : 24)
        : 16;

    // Full-width grid (content centred via side padding) so the skeleton
    // matches the loaded layout exactly.
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
        sidePadding,
        _isWebLayout ? 8 : 16,
        sidePadding,
        Constants.bottomNavSpace,
      ),
      gridDelegate: isWide
          ? SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _crossAxisCount(contentWidth),
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

  Widget _buildSkeletonCard() {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: ColorResource.customShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image skeleton
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: context.textLight.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(Constants.radiusLarge),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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

  Widget _buildProductCard(BuildContext context, ProductModel product, String favoriteId, FavoritesController controller) {
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
            Stack(
              children: [
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(Constants.radiusLarge),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(Constants.radiusLarge),
                      ),
                      child: CustomNetworkImage(
                        image: product.imageId,
                        fit: BoxFit.cover,
                        width: double.infinity,
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ColorResource.discountBadge,
                        borderRadius: BorderRadius.circular(Constants.radiusLarge),
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
                    onTap: () => controller.removeFavoriteById(favoriteId, product.id),
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

            // Product Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                      ],
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
            ),
          ],
        ),
      ),
    );
  }
}
