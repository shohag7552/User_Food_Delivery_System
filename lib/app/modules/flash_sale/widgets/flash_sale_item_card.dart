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
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

/// Product card for a flash sale item: flash price vs original, discount
/// badge, a sold progress bar with urgency, and an add-to-cart that charges
/// the flash price (capped at the sale's remaining stock).
class FlashSaleItemCard extends StatelessWidget {
  final FlashSaleItemModel item;

  const FlashSaleItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final product = item.product!;
    final bool soldOut = item.remainingStock <= 0;

    return GestureDetector(
      onTap: () => context.pushNamed(
        RouteNames.productDetail,
        pathParameters: {'id': product.id},
        extra: product,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: ColorResource.cardBackground,
          borderRadius: BorderRadius.circular(Constants.radiusLarge),
          boxShadow: ColorResource.customShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with the discount badge.
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomNetworkImage(
                    image: product.imageId,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  if (item.discountPercent > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: ColorResource.primaryGradient,
                          borderRadius:
                              BorderRadius.circular(Constants.radiusLarge),
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
              ),
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
                      color: ColorResource.textPrimary,
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
                                  color: ColorResource.textLight,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Add at the flash price.
                      GestureDetector(
                        onTap: soldOut ? null : () => _addToCart(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient:
                                soldOut ? null : ColorResource.primaryGradient,
                            color: soldOut
                                ? ColorResource.textLight
                                    .withValues(alpha: 0.3)
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
    );
  }

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
            backgroundColor: ColorResource.primaryDark.withValues(alpha: 0.12),
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

  /// Adds one unit at the flash price. The flash price is written into the
  /// cart as a fixed discount, so cart totals / checkout / order records work
  /// completely unchanged.
  Future<void> _addToCart(BuildContext context) async {
    if (!isUserLoggedIn()) {
      AuthFlow.openLogin(context);
      return;
    }

    final product = item.product!;
    final existingQty = CartHelper.getProductCartQuantity(product.id) ?? 0;
    if (existingQty + 1 > item.remainingStock) {
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
