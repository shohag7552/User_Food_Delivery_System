import 'dart:async';

import 'package:appwrite_user_app/app/common/widgets/custom_clickable_widget.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/common/widgets/favorite_button.dart';
import 'package:appwrite_user_app/app/common/widgets/rating_stars.dart';
import 'package:appwrite_user_app/app/controllers/brand_controller.dart';
import 'package:appwrite_user_app/app/controllers/cart_controller.dart';
import 'package:appwrite_user_app/app/helper/cart_helper.dart';
import 'package:appwrite_user_app/app/helper/localization_extension_helper.dart';
import 'package:appwrite_user_app/app/helper/price_helper.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/models/product_model.dart';
import 'package:appwrite_user_app/app/modules/ecommerce/domain/services/hover_gallery.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart' show PointerHoverEvent;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

/// Grid card for the ecommerce storefront: image + badges, brand, name,
/// rating, price and an inline cart control.
///
/// Layout notes — the card is rendered at several sizes (a 170px carousel
/// tile, a 0.6-ratio grid cell, a 250px favourites cell). The text block sizes
/// to its content and the image band takes the slack, so a one-line name gives
/// its card a slightly taller photo. Prices and cart buttons still line up
/// across a grid row: the price row is the last child, so it always sits on
/// the card's bottom padding.
class EcommerceProductCard extends StatefulWidget {
  final ProductModel product;

  /// Fixes the image band to this width:height ratio and lets the card size
  /// itself to its content — required by content-sized grids such as
  /// `SliverAlignedGrid`, which measure children against an unbounded height.
  ///
  /// Left null (the default) the image instead fills whatever height the
  /// parent imposes, which is what the fixed-height carousels rely on.
  final double? imageAspectRatio;

  /// Overrides the desktop-web test that gates pointer scrubbing.
  ///
  /// Exists only so a widget test can drive the hover path: [kIsWeb] is a
  /// compile-time constant that is false under `flutter test`, so without a
  /// seam the behaviour could only ever be checked by hand in a browser.
  /// No call site sets it.
  @visibleForTesting
  final bool? enableHoverGallery;

  const EcommerceProductCard({
    super.key,
    required this.product,
    this.imageAspectRatio,
    this.enableHoverGallery,
  });

  @override
  State<EcommerceProductCard> createState() => _EcommerceProductCardState();
}

class _EcommerceProductCardState extends State<EcommerceProductCard> {
  /// Stock at or below this count switches the card to its urgency state.
  static const int _lowStockThreshold = 5;

  static const double _ratingIconSize = 12;
  static const double _stepButtonWidth = 30;

  /// Fades the scrub indicator in, and how long the pointer must settle before
  /// the rest of the gallery is fetched.
  static const Duration _indicatorFade = Duration(milliseconds: 160);
  static const Duration _preloadDelay = Duration(milliseconds: 120);
  static const Duration _imageFade = Duration(milliseconds: 180);

  /// Height of the scrub indicator hugging the bottom of the image band.
  static const double _indicatorHeight = 3;

  // Pointer hover only fires on web/desktop; touch devices never set this,
  // so the mobile experience is byte-for-byte unchanged.
  bool _hovered = false;

  /// Which gallery image the pointer is over. Always 0 at rest, so the card
  /// shows its cover whenever nobody is pointing at it.
  int _hoverIndex = 0;

  /// Set once this card's gallery has been asked for, so sweeping back and
  /// forth over one card does not re-request it.
  bool _galleryPreloaded = false;
  Timer? _preloadTimer;

  ProductModel get product => widget.product;

  /// The images this card can scrub through, or empty when it has only its
  /// cover to show — which is every food product and every single-photo one.
  List<String> get _galleryImages => hoverGalleryImages(product);

  /// Scrubbing is desktop-web only: it is driven by a pointer, and there is no
  /// pointer anywhere else. Read here rather than inside the helpers so the
  /// swap itself stays reachable from a test.
  bool get _canScrub =>
      (widget.enableHoverGallery ?? kIsWeb) && _galleryImages.length > 1;

  @override
  void didUpdateWidget(covariant EcommerceProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A recycled card showing a different product must not keep pointing at
    // the old one's third photo.
    if (oldWidget.product.id != widget.product.id) {
      _hoverIndex = 0;
      _galleryPreloaded = false;
      _preloadTimer?.cancel();
      _preloadTimer = null;
    }
  }

  @override
  void dispose() {
    _preloadTimer?.cancel();
    super.dispose();
  }

  void _setHover(bool value) {
    if (_hovered != value) setState(() => _hovered = value);
  }

  /// Tracks the pointer across the image band, one image per equal slice.
  void _onImageHover(PointerHoverEvent event, double bandWidth) {
    final images = _galleryImages;
    if (images.length < 2) return;

    _schedulePreload(images);

    final index = hoverIndexFor(
      localDx: event.localPosition.dx,
      width: bandWidth,
      count: images.length,
    );
    if (index != _hoverIndex) setState(() => _hoverIndex = index);
  }

  /// Fetches the rest of the gallery once the pointer has settled.
  ///
  /// Delayed on purpose: a shopper sweeping across a grid row crosses a dozen
  /// cards in a moment, and firing on the first hover event would pull every
  /// gallery they brushed past. Waiting for [_preloadDelay] means only a card
  /// someone actually stopped on costs anything.
  void _schedulePreload(List<String> images) {
    if (_galleryPreloaded || _preloadTimer != null) return;

    _preloadTimer = Timer(_preloadDelay, () {
      _preloadTimer = null;
      if (!mounted || _galleryPreloaded) return;
      _galleryPreloaded = true;
      // The cover is already on screen; only the rest needs fetching.
      for (final url in images.skip(1)) {
        precacheImage(
          CachedNetworkImageProvider(url),
          context,
          // A preload is an optimisation; a dead URL must not surface as an
          // error. The image widget falls back on its own when scrubbed to.
          onError: (_, _) {},
        );
      }
    });
  }

  /// Back to the cover when the pointer leaves, so a card at rest is always
  /// the card the grid was laid out with.
  void _resetScrub() {
    _preloadTimer?.cancel();
    _preloadTimer = null;
    if (_hoverIndex != 0) setState(() => _hoverIndex = 0);
  }

  @override
  Widget build(BuildContext context) {
    final outOfStock = product.isOutOfStock;
    // Local copy so the null check promotes it for the AspectRatio below.
    final aspectRatio = widget.imageAspectRatio;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHover(true),
      onExit: (_) {
        _setHover(false);
        _resetScrub();
      },
      child: AnimatedScale(
        scale: _hovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: CustomClickableWidget(
          // The surface is painted here instead of by the shared wrapper so the
          // card can clip its children to its own radius — without that the
          // image's square corners bleed past the rounded card edge.
          isBackgroundTransparent: true,
          onTap: () => context.pushNamed(
            RouteNames.productDetail,
            pathParameters: {'id': product.id},
            extra: product,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: context.cardBackground,
              borderRadius: BorderRadius.circular(Constants.radiusCard),
              // A hairline keeps the card readable in dark mode, where a drop
              // shadow alone gives no edge against the near-black scaffold.
              border: Border.all(
                color: context.textLight.withValues(alpha: _hovered ? 0.3 : 0.15),
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: ColorResource.shadowDark,
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : ColorResource.customShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: aspectRatio == null
                  ? MainAxisSize.max
                  : MainAxisSize.min,
              children: [
                if (aspectRatio == null)
                  Expanded(child: _buildImageBand(context, outOfStock))
                else
                  AspectRatio(
                    aspectRatio: aspectRatio,
                    child: _buildImageBand(context, outOfStock),
                  ),
                _buildDetails(context, outOfStock),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Image plus its overlays: discount badge, favourite toggle, and either the
  /// low-stock hint or the out-of-stock scrim.
  Widget _buildImageBand(BuildContext context, bool outOfStock) {
    final isLowStock = !outOfStock && product.stock <= _lowStockThreshold;

    return Stack(
      fit: StackFit.expand,
      children: [
        // A neutral plate behind the photo so cut-out/transparent product
        // shots read as intentional instead of floating on the card colour.
        Container(
          color: context.scaffoldBackground,
          child: AnimatedScale(
            scale: _hovered ? 1.06 : 1.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: _buildPhoto(),
          ),
        ),

        // Scrub indicator, sitting inside the bottom of the photo.
        //
        // Inset by the same padding the badges use rather than flush to the
        // band's edge, so it reads as part of the picture instead of as a
        // seam between the photo and the details block below it.
        if (_canScrub)
          Positioned(
            left: Constants.paddingSizeSmall,
            right: Constants.paddingSizeSmall,
            bottom: Constants.paddingSizeSmall,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _hovered ? 1 : 0,
                duration: _indicatorFade,
                curve: Curves.easeOut,
                child: _buildScrubIndicator(context),
              ),
            ),
          ),

        if (product.hasDiscount)
          Positioned(
            top: Constants.paddingSizeSmall,
            left: Constants.paddingSizeSmall,
            child: _badge(
              label: product.discountType == 'percentage'
                  ? '${product.discountValue!.toInt()}% ${'off'.tr}'
                  : '${PriceHelper.formatPrice(product.discountValue!.toDouble())} ${'off'.tr}',
              background: ColorResource.discountBadge,
            ),
          ),

        Positioned(
          top: Constants.paddingSizeExtraSmall,
          right: Constants.paddingSizeExtraSmall,
          child: FavoriteButton(product: product, size: 18),
        ),

        if (isLowStock)
          Positioned(
            bottom: Constants.paddingSizeSmall,
            left: Constants.paddingSizeSmall,
            // The indicator now occupies this strip while the pointer is on
            // the card. The badge is the card's resting state and the
            // indicator only exists during a hover, so the badge yields —
            // fading rather than vanishing, since they cross over.
            child: AnimatedOpacity(
              opacity: _canScrub && _hovered ? 0 : 1,
              duration: _indicatorFade,
              curve: Curves.easeOut,
              child: _badge(
                label: 'only_n_left'.trParams({'count': '${product.stock}'}),
                background: ColorResource.warning,
              ),
            ),
          ),

        if (outOfStock)
          Positioned.fill(
            child: Container(
              color: ColorResource.overlayDark,
              alignment: Alignment.center,
              child: _badge(
                label: 'out_of_stock'.tr,
                background: context.cardBackground,
                foreground: context.textPrimary,
              ),
            ),
          ),
      ],
    );
  }

  /// The photo itself.
  ///
  /// Without a gallery to scrub this is the very same single
  /// [CustomNetworkImage] the card has always rendered — no MouseRegion, no
  /// switcher, no extra layer — so food products, single-photo products and
  /// every touch device keep their existing decode path exactly.
  Widget _buildPhoto() {
    final images = _galleryImages;

    if (!_canScrub) {
      return CustomNetworkImage(
        image: product.imageId,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    }

    final index = _hoverIndex.clamp(0, images.length - 1);

    return LayoutBuilder(
      builder: (context, constraints) {
        return MouseRegion(
          // Nested inside the card's own MouseRegion, which keeps owning the
          // 1.02 lift. Hover events are delivered to every region under the
          // pointer, so neither cancels the other — and the favourite button
          // sitting above this one does not block scrubbing either.
          opaque: false,
          onHover: (event) => _onImageHover(event, constraints.maxWidth),
          onExit: (_) => _resetScrub(),
          child: AnimatedSwitcher(
            duration: _imageFade,
            // Cross-dissolve in place: the outgoing photo must not slide or
            // scale, or it would fight the 1.06 zoom wrapping this whole tree.
            layoutBuilder: (currentChild, previousChildren) => Stack(
              fit: StackFit.expand,
              children: [...previousChildren, ?currentChild],
            ),
            child: CustomNetworkImage(
              // Keyed on the URL so the switcher animates a changed photo and
              // ignores an unchanged one.
              key: ValueKey<String>(images[index]),
              image: images[index],
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }

  /// One segment per gallery image, the current one filled.
  ///
  /// Reads left to right in the same order the pointer scrubs, so the segment
  /// under the cursor is the photo on screen.
  Widget _buildScrubIndicator(BuildContext context) {
    final count = _galleryImages.length;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        // A track behind the segments, because they float over the product
        // photo: on a white-background shot, pale segments alone would leave
        // nothing to read.
        color: ColorResource.overlayDark,
        borderRadius: BorderRadius.circular(Constants.radiusSmall),
      ),
      child: Row(
        children: List<Widget>.generate(count, (index) {
          final isActive = index == _hoverIndex;
          return Expanded(
            child: AnimatedContainer(
              duration: _indicatorFade,
              curve: Curves.easeOut,
              height: _indicatorHeight,
              margin: EdgeInsets.only(right: index == count - 1 ? 0 : 3),
              decoration: BoxDecoration(
                color: isActive
                    ? ColorResource.textWhite
                    : ColorResource.textWhite.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(Constants.radiusSmall),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDetails(BuildContext context, bool outOfStock) {
    final nameStyle = poppinsBold.copyWith(
      fontSize: Constants.fontSizeDefault,
      height: 1.25,
      color: context.textPrimary,
    );

    return Padding(
      padding: const EdgeInsets.all(Constants.paddingSizeSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Brand — small caps with tracking reads as a label rather than
          // competing with the product name for attention.
          GetBuilder<BrandController>(
            builder: (brandController) {
              final brand = brandController.brandById(product.brandId);
              if (brand == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(
                  bottom: Constants.paddingSizeExtraSmall / 2,
                ),
                child: Text(
                  brand.nameMap.trLanguage.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: poppinsMedium.copyWith(
                    fontSize: Constants.fontSizeExtraSmall,
                    letterSpacing: 0.6,
                    color: context.textSecondary,
                  ),
                ),
              );
            },
          ),

          Text(
            product.nameMap.trLanguage,
            style: nameStyle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          if (product.avgRating > 0)
            Padding(
              padding: const EdgeInsets.only(
                top: Constants.paddingSizeExtraSmall / 2,
              ),
              child: RatingStars(
                rating: product.avgRating,
                reviewCount: product.ratingCount,
                size: _ratingIconSize,
              ),
            ),
          const SizedBox(height: Constants.paddingSizeExtraSmall),

          Row(
            children: [
              Expanded(child: _buildPrice(context)),
              const SizedBox(width: Constants.paddingSizeExtraSmall),
              if (!outOfStock) _buildCartControl(context),
            ],
          ),
        ],
      ),
    );
  }

  /// Current price with the struck-through original beside it. Scaled down
  /// rather than ellipsised — a truncated price is worse than a smaller one.
  Widget _buildPrice(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            PriceHelper.formatPrice(product.finalPrice),
            maxLines: 1,
            style: poppinsBold.copyWith(
              fontSize: Constants.fontSizeLarge,
              color: ColorResource.primaryDark,
            ),
          ),
          if (product.hasDiscount) ...[
            const SizedBox(width: Constants.paddingSizeExtraSmall),
            Text(
              PriceHelper.formatPrice(product.price),
              maxLines: 1,
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeSmall,
                color: context.textLight,
                decoration: TextDecoration.lineThrough,
                decorationColor: context.textLight,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCartControl(BuildContext context) {
    return GetBuilder<CartController>(
      builder: (_) {
        final quantity = CartHelper.getProductCartQuantity(product.id);

        if (quantity == null) {
          return _gradientSurface(
            width: Constants.minTapTarget,
            child: _tapTarget(
              onTap: () => CartHelper.handleAddToCart(product, context),
              semanticLabel: 'add_to_cart'.tr,
              width: Constants.minTapTarget,
              icon: Icons.add_rounded,
              iconSize: 22,
            ),
          );
        }

        return _gradientSurface(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _tapTarget(
                onTap: () => CartHelper.decrementQuantity(product, context),
                semanticLabel: 'decrease_quantity'.tr,
                width: _stepButtonWidth,
                icon: Icons.remove_rounded,
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 22),
                alignment: Alignment.center,
                child: Text(
                  '$quantity',
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeSmall,
                    color: ColorResource.textWhite,
                  ),
                ),
              ),
              _tapTarget(
                onTap: () => CartHelper.incrementQuantity(product, context),
                semanticLabel: 'increase_quantity'.tr,
                width: _stepButtonWidth,
                icon: Icons.add_rounded,
              ),
            ],
          ),
        );
      },
    );
  }

  /// Brand-gradient pill used by both cart states, sized to the accessible
  /// minimum tap height.
  Widget _gradientSurface({required Widget child, double? width}) {
    return Container(
      width: width,
      height: Constants.minTapTarget,
      // Keeps the ripple inside the pill's rounded corners.
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: ColorResource.primaryGradient,
        borderRadius: BorderRadius.circular(Constants.radiusDefault),
        boxShadow: [
          BoxShadow(
            color: ColorResource.primaryDark.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      // Transparent Material hosts the ripple so taps read as pressed even
      // though the fill is a gradient.
      child: Material(color: Colors.transparent, child: child),
    );
  }

  Widget _tapTarget({
    required VoidCallback onTap,
    required String semanticLabel,
    required double width,
    required IconData icon,
    double iconSize = 18,
  }) {
    return Tooltip(
      message: semanticLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Constants.radiusDefault),
        child: SizedBox(
          width: width,
          height: Constants.minTapTarget,
          child: Icon(icon, color: ColorResource.textWhite, size: iconSize),
        ),
      ),
    );
  }

  Widget _badge({
    required String label,
    required Color background,
    Color foreground = ColorResource.textWhite,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Constants.paddingSizeExtraSmall + 1,
        vertical: Constants.paddingSizeExtraSmall / 2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Constants.radiusSmall),
        boxShadow: ColorResource.customShadow,
      ),
      child: Text(
        label,
        style: poppinsBold.copyWith(
          fontSize: Constants.fontSizeExtraSmall,
          color: foreground,
        ),
      ),
    );
  }
}
