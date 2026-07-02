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
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

/// Grid card for the ecommerce storefront: brand + name + rating + price.
class EcommerceProductCard extends StatefulWidget {
  final ProductModel product;

  const EcommerceProductCard({super.key, required this.product});

  @override
  State<EcommerceProductCard> createState() => _EcommerceProductCardState();
}

class _EcommerceProductCardState extends State<EcommerceProductCard> {
  // Pointer hover only fires on web/desktop; touch devices never set this,
  // so the mobile experience is byte-for-byte unchanged.
  bool _hovered = false;

  ProductModel get product => widget.product;

  void _setHover(bool value) {
    if (_hovered != value) setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final hasDiscount = product.hasDiscount;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: AnimatedScale(
        scale: _hovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Constants.radiusLarge + 4),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: ColorResource.primaryDark.withValues(alpha: 0.18),
                      blurRadius: 22,
                      spreadRadius: 1,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : const [],
          ),
          child: CustomClickableWidget(
            onTap: () => context.pushNamed(
              RouteNames.productDetail,
              pathParameters: {'id': product.id},
              extra: product,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image with badges
                Expanded(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(Constants.radiusLarge),
                        ),
                        child: AnimatedScale(
                          scale: _hovered ? 1.06 : 1.0,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          child: CustomNetworkImage(
                            image: product.imageId,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                if (hasDiscount)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ColorResource.discountBadge,
                        borderRadius: BorderRadius.circular(
                          Constants.radiusSmall,
                        ),
                      ),
                      child: Text(
                        product.discountType == 'percentage'
                            ? '${product.discountValue!.toInt()}% OFF'
                            : '${PriceHelper.formatPrice(product.discountValue!.toDouble())} OFF',
                        style: poppinsBold.copyWith(
                          fontSize: Constants.fontSizeExtraSmall,
                          color: ColorResource.textWhite,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: FavoriteButton(product: product, size: 18),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand
                GetBuilder<BrandController>(
                  builder: (brandController) {
                    final brand = brandController.brandById(product.brandId);
                    if (brand == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        brand.nameMap.trLanguage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: poppinsMedium.copyWith(
                          fontSize: Constants.fontSizeExtraSmall,
                          color: ColorResource.primaryDark,
                        ),
                      ),
                    );
                  },
                ),
                Text(
                  product.nameMap.trLanguage,
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeDefault,
                    color: ColorResource.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if(product.avgRating > 0)...[
                  const SizedBox(height: 4),
                  RatingStars(
                    rating: product.avgRating,
                    reviewCount: product.ratingCount,
                    size: 12,
                  ),

                ],
                
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            PriceHelper.formatPrice(product.finalPrice),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: poppinsBold.copyWith(
                              fontSize: Constants.fontSizeLarge,
                              color: ColorResource.primaryDark,
                            ),
                          ),
                          if (hasDiscount)
                            Text(
                              PriceHelper.formatPrice(product.price),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: poppinsRegular.copyWith(
                                fontSize: Constants.fontSizeSmall,
                                color: ColorResource.textLight,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildCartControl(context),
                  ],
                ),
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

  Widget _buildCartControl(BuildContext context) {
    return GetBuilder<CartController>(
      builder: (_) {
        final quantity = CartHelper.getProductCartQuantity(product.id);
        if (product.isOutOfStock) {
          return const SizedBox.shrink();
        }
        if (quantity == null) {
          return GestureDetector(
            onTap: () => CartHelper.handleAddToCart(product, context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: ColorResource.primaryGradient,
                borderRadius: BorderRadius.circular(Constants.radiusDefault),
              ),
              child: const Icon(
                Icons.add_shopping_cart,
                color: ColorResource.textWhite,
                size: 18,
              ),
            ),
          );
        }
        return Container(
          decoration: BoxDecoration(
            gradient: ColorResource.primaryGradient,
            borderRadius: BorderRadius.circular(Constants.radiusDefault),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _stepButton(
                Icons.remove,
                () => CartHelper.decrementQuantity(product, context),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 20),
                alignment: Alignment.center,
                child: Text(
                  '$quantity',
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeSmall,
                    color: ColorResource.textWhite,
                  ),
                ),
              ),
              _stepButton(
                Icons.add,
                () => CartHelper.incrementQuantity(product, context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _stepButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, color: ColorResource.textWhite, size: 16),
      ),
    );
  }
}
