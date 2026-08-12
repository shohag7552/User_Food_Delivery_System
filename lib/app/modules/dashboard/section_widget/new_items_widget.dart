import 'package:appwrite_user_app/app/common/widgets/hover_arrow_carousel.dart';
import 'package:appwrite_user_app/app/common/widgets/hover_lift.dart';
import 'package:appwrite_user_app/app/common/widgets/web_top_nav.dart';
import 'package:appwrite_user_app/app/controllers/cart_controller.dart';
import 'package:appwrite_user_app/app/controllers/product_controller.dart';
import 'package:appwrite_user_app/app/helper/cart_helper.dart';
import 'package:appwrite_user_app/app/helper/localization_extension_helper.dart';
import 'package:appwrite_user_app/app/modules/dashboard/section_widget/food_card_metrics.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/food_item_card.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/dashboard_shimmer.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/product_detail_bottomsheet.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NewItemsWidget extends StatelessWidget {
  const NewItemsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProductController>(
      builder: (controller) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ColorResource.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        Constants.radiusSmall,
                      ),
                    ),
                    child: Text(
                      'NEW',
                      style: poppinsBold.copyWith(
                        fontSize: Constants.fontSizeSmall,
                        color: ColorResource.info,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'new_items'.tr,
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeExtraLarge,
                      color: context.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Loading State
            if (controller.isLoadingNew)
              const HorizontalFoodListShimmer()
            // Error State
            else if (controller.newErrorMessage != null)
              SizedBox(
                height: 220,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: ColorResource.error,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'failed_to_load_new_items'.tr,
                        style: poppinsMedium.copyWith(
                          fontSize: Constants.fontSizeDefault,
                          color: context.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => controller.getNewProducts(),
                        child: Text(
                          'retry'.tr,
                          style: poppinsBold.copyWith(
                            fontSize: Constants.fontSizeDefault,
                            color: ColorResource.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            // Empty State
            else if (controller.newProducts.isEmpty)
              SizedBox(
                height: 220,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        color: context.textLight,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'no_new_items_available'.tr,
                        style: poppinsMedium.copyWith(
                          fontSize: Constants.fontSizeDefault,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            // Products List — hover-revealed scroll arrows on desktop web,
            // with cards sized exactly like the All Products grid cards
            // (see FoodCardMetrics). Mobile keeps the original 180×250 strip.
            else
              Builder(builder: (context) {
                final isWebShell = WebTopNav.isEnabled(context);
                final screenWidth = MediaQuery.of(context).size.width;
                final double cardWidth = isWebShell
                    ? FoodCardMetrics.webCardWidth(screenWidth)
                    : 180;
                // +12 covers the list's vertical padding (4 top + 8 bottom).
                final double stripHeight = isWebShell
                    ? FoodCardMetrics.webCardHeight(screenWidth) + 12
                    : 250;

                return HoverArrowCarousel(
                height: stripHeight,
                builder: (context, carouselController) => ListView.separated(
                  controller: carouselController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  itemCount: controller.newProducts.length,
                  separatorBuilder: (_, _) => SizedBox(
                    // Web matches the All Products grid gutter so the
                    // page keeps one rhythm; mobile keeps its 14.
                    width: isWebShell ? FoodCardMetrics.spacing : 14,
                  ),
                  itemBuilder: (context, index) {
                    final product = controller.newProducts[index];

                    return GetBuilder<CartController>(
                      builder: (cartController) {
                        final cartQuantity = CartHelper.getProductCartQuantity(
                          product.id,
                        );

                        final card = FoodItemCard(
                            name: product.nameMap.trLanguage,
                            imageUrl: product.imageId,
                            description: product.descriptionMap.trLanguage,
                            price: product.finalPrice,
                            oldPrice: product.hasDiscount
                                ? product.price
                                : null,
                            product: product,
                            cartQuantity: cartQuantity,
                            onTap: () {
                              ProductDetailBottomSheet.show(context, product);
                            },
                            onAddToCart: () =>
                                CartHelper.handleAddToCart(product, context),
                            onQuantityChanged: (isIncrement) {
                              if (isIncrement) {
                                CartHelper.incrementQuantity(product, context);
                              } else {
                                CartHelper.decrementQuantity(product, context);
                              }
                            },
                          );

                        return SizedBox(
                          width: cardWidth,
                          // Web-only hover lift; touch gets the bare card.
                          child: isWebShell ? HoverLift(child: card) : card,
                        );
                      },
                    );
                  },
                ),
              );
              }),
          ],
        );
      },
    );
  }
}
