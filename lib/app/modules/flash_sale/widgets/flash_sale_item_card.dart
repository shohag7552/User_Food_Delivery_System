import 'dart:async';

import 'package:appwrite_user_app/app/common/widgets/auth_dialog.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:appwrite_user_app/app/controllers/auth_controller.dart';
import 'package:appwrite_user_app/app/controllers/cart_controller.dart';
import 'package:appwrite_user_app/app/controllers/module_controller.dart';
import 'package:appwrite_user_app/app/helper/cart_helper.dart';
import 'package:appwrite_user_app/app/helper/localization_extension_helper.dart';
import 'package:appwrite_user_app/app/helper/price_helper.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/helper/session_manager.dart';
import 'package:appwrite_user_app/app/models/cart_item_model.dart';
import 'package:appwrite_user_app/app/models/flash_sale_item_model.dart';
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

/// Product card for a flash sale item: flash price vs original, discount
/// badge, a sold progress bar with urgency, and an add-to-cart that charges
/// the flash price (capped at the sale's remaining stock).
///
/// On web/desktop the image band supports pointer scrubbing through the
/// product's gallery, exactly like [EcommerceProductCard].
class FlashSaleItemCard extends StatefulWidget {
  final FlashSaleItemModel item;
  final double? imageAspectRatio;

  /// Overrides the desktop-web test that gates pointer scrubbing.
  /// Only useful in widget tests where [kIsWeb] is always false.
  @visibleForTesting
  final bool? enableHoverGallery;

  const FlashSaleItemCard({
    super.key,
    required this.item,
    this.imageAspectRatio,
    this.enableHoverGallery,
  });

  @override
  State<FlashSaleItemCard> createState() => _FlashSaleItemCardState();
}

class _FlashSaleItemCardState extends State<FlashSaleItemCard> {
  // ── Hover-gallery constants (mirrors EcommerceProductCard) ──────────────────
  static const Duration _indicatorFade = Duration(milliseconds: 160);
  static const Duration _preloadDelay = Duration(milliseconds: 120);
  static const Duration _imageFade = Duration(milliseconds: 180);
  static const double _indicatorHeight = 3;

  // ── Hover state ─────────────────────────────────────────────────────────────
  bool _hovered = false;
  int _hoverIndex = 0;
  bool _galleryPreloaded = false;
  Timer? _preloadTimer;

  FlashSaleItemModel get item => widget.item;
  ProductModel get product => item.product!;

  List<String> get _galleryImages => hoverGalleryImages(product);

  bool get _canScrub =>
      (widget.enableHoverGallery ?? kIsWeb) && _galleryImages.length > 1;

  @override
  void didUpdateWidget(covariant FlashSaleItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.product?.id != widget.item.product?.id) {
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

  void _schedulePreload(List<String> images) {
    if (_galleryPreloaded || _preloadTimer != null) return;

    _preloadTimer = Timer(_preloadDelay, () {
      _preloadTimer = null;
      if (!mounted || _galleryPreloaded) return;
      _galleryPreloaded = true;
      for (final url in images.skip(1)) {
        precacheImage(
          CachedNetworkImageProvider(url),
          context,
          onError: (_, _) {},
        );
      }
    });
  }

  void _resetScrub() {
    _preloadTimer?.cancel();
    _preloadTimer = null;
    if (_hoverIndex != 0) setState(() => _hoverIndex = 0);
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool soldOut = item.remainingStock <= 0 || product.isOutOfStock;
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
        child: GestureDetector(
          onTap: () => _openProductDetail(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: context.cardBackground,
              borderRadius: BorderRadius.circular(Constants.radiusLarge),
              border: Border.all(
                color: context.textLight
                    .withValues(alpha: _hovered ? 0.3 : 0.15),
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
              mainAxisSize:
                  aspectRatio == null ? MainAxisSize.max : MainAxisSize.min,
              children: [
                // Image with the discount / sold-out overlays + scrub gallery.
                if (aspectRatio == null)
                  Expanded(
                    child: _buildImageBand(context, soldOut),
                  )
                else
                  AspectRatio(
                    aspectRatio: aspectRatio,
                    child: _buildImageBand(context, soldOut),
                  ),

                // Details
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.nameMap.trLanguage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: poppinsMedium.copyWith(
                          fontSize: Constants.fontSizeDefault,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  PriceHelper.formatPrice(item.flashPrice),
                                  style: poppinsBold.copyWith(
                                    fontSize: Constants.fontSizeLarge,
                                    color: ColorResource.primaryDark,
                                  ),
                                ),
                                if (item.flashPrice < product.price)
                                  Text(
                                    PriceHelper.formatPrice(product.price),
                                    style: poppinsRegular.copyWith(
                                      fontSize: Constants.fontSizeSmall,
                                      color: context.textLight,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Add at the flash price.
                          GestureDetector(
                            onTap: soldOut
                                ? null
                                : () => _addToCart(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: soldOut
                                    ? null
                                    : ColorResource.primaryGradient,
                                color: soldOut
                                    ? context.textLight.withValues(alpha: 0.3)
                                    : null,
                                borderRadius: BorderRadius.circular(
                                  Constants.radiusDefault,
                                ),
                              ),
                              child: Icon(
                                Icons.add_shopping_cart,
                                color: ColorResource.textWhite,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildSoldBar(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Image band ───────────────────────────────────────────────────────────────

  Widget _buildImageBand(BuildContext context, bool soldOut) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Neutral plate + animated zoom identical to EcommerceProductCard.
        Container(
          color: context.scaffoldBackground,
          child: AnimatedScale(
            scale: _hovered ? 1.06 : 1.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: _buildPhoto(),
          ),
        ),

        // Scrub indicator — only while hovering on web, same as the main card.
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

        // Discount badge.
        if (item.discountPercent > 0)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: ColorResource.primaryGradient,
                borderRadius: BorderRadius.circular(Constants.radiusLarge),
              ),
              child: Text(
                '-${item.discountPercent}%',
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeExtraSmall,
                  color: ColorResource.textWhite,
                ),
              ),
            ),
          ),

        // Sold-out scrim.
        if (soldOut)
          Container(
            color: Colors.black.withValues(alpha: 0.55),
            alignment: Alignment.center,
            child: Text(
              'sold_out'.tr,
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeLarge,
                color: ColorResource.textWhite,
              ),
            ),
          ),
      ],
    );
  }

  /// Photo: single image on mobile / no gallery; scrubbing gallery on web.
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
          opaque: false,
          onHover: (event) => _onImageHover(event, constraints.maxWidth),
          onExit: (_) => _resetScrub(),
          child: AnimatedSwitcher(
            duration: _imageFade,
            layoutBuilder: (currentChild, previousChildren) => Stack(
              fit: StackFit.expand,
              children: [...previousChildren, ?currentChild],
            ),
            child: CustomNetworkImage(
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

  /// One segment per gallery image — same design as EcommerceProductCard.
  Widget _buildScrubIndicator(BuildContext context) {
    final count = _galleryImages.length;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
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

  // ── Sold bar ─────────────────────────────────────────────────────────────────

  /// "Sold X" progress bar with a "Y left" urgency label (only when the sale
  /// caps this item's stock).
  Widget _buildSoldBar() {
    if (item.flashStock == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: item.soldRatio,
            minHeight: 6,
            backgroundColor:
                ColorResource.primaryDark.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(
              ColorResource.primaryMedium,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${'sold'.tr} ${item.soldCount} • ${item.remainingStock} ${'left'.tr}',
          style: poppinsRegular.copyWith(
            fontSize: Constants.fontSizeExtraSmall,
            color: ColorResource.textSecondary,
          ),
        ),
      ],
    );
  }

  // ── Navigation / cart ────────────────────────────────────────────────────────

  void _openProductDetail(BuildContext context) {
    context.pushNamed(
      RouteNames.productDetail,
      pathParameters: {'id': item.product!.id},
      extra: item.product,
    );
  }

  Future<void> _addToCart(BuildContext context) async {
    if (!isUserLoggedIn()) {
      AuthFlow.openLogin(context);
      return;
    }

    final product = item.product!;

    if (product.variants.isNotEmpty) {
      _openProductDetail(context);
      return;
    }

    if (product.isOutOfStock) {
      customToster('out_of_stock'.tr, isSuccess: false);
      return;
    }

    final existingQty = CartHelper.getProductCartQuantity(product.id) ?? 0;
    final int maxAllowed = item.remainingStock < product.stock
        ? item.remainingStock
        : product.stock;
    if (existingQty + 1 > maxAllowed) {
      customToster('flash_sale_limit_reached'.tr, isSuccess: false);
      return;
    }

    final userId = await Get.find<AuthController>().getUserId();
    final double flashDiscount = product.price > item.flashPrice
        ? product.price - item.flashPrice
        : 0;

    final cartItem = CartItemModel(
      id: '',
      userId: userId ?? '',
      productId: product.id,
      productName: product.nameMap.trLanguage,
      productImage: product.imageId,
      basePrice: product.price,
      discountType: 'fixed',
      discountValue: flashDiscount,
      finalPrice: item.flashPrice,
      selectedVariants: const [],
      quantity: 1,
      itemTotal: item.flashPrice,
      moduleType: ModuleController.ecommerce,
    );

    try {
      await Get.find<CartController>().addToCart(cartItem);
      customToster('added_to_cart'.tr, isSuccess: true);
    } catch (_) {
      // CartController surfaces its own stock/identical-item messages.
    }
  }
}
