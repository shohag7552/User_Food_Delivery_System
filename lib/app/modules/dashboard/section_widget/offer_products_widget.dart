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

/// Home "Offer Products" section — discounted items for the active module,
/// biggest discount first. Hides itself entirely when there are no offers.
class OfferProductsWidget extends StatelessWidget {
  const OfferProductsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProductController>(
      builder: (controller) {
        final bool loading = controller.isLoadingOffers;
        final bool hasError = controller.offersErrorMessage != null;

        // No offers (and nothing in flight): the section disappears rather
        // than showing an empty shell.
        if (!loading && !hasError && controller.offerProducts.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Own top spacing — the home column adds none for this section,
            // so nothing doubles up when the section hides itself.
            const SizedBox(height: Constants.spaceSection),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(
                    Icons.local_offer,
                    color: ColorResource.error,
                    size: 26,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'offer_products'.tr,
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeExtraLarge,
                      color: ColorResource.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Loading State
            if (loading)
              const HorizontalFoodListShimmer()
            // Error State
            else if (hasError)
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
                        'failed_to_load_offers'.tr,
                        style: poppinsMedium.copyWith(
                          fontSize: Constants.fontSizeDefault,
                          color: ColorResource.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => controller.getOfferProducts(),
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
            // Products List — hover-revealed scroll arrows on desktop web,
            // with cards sized exactly like the All Products grid cards.
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
                  builder: (context, carouselController) =>
                      ListView.separated(
                    controller: carouselController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    itemCount: controller.offerProducts.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final product = controller.offerProducts[index];

                      return GetBuilder<CartController>(
                        builder: (cartController) {
                          final cartQuantity =
                              CartHelper.getProductCartQuantity(product.id);

                          final card = FoodItemCard(
                            name: product.nameMap.trLanguage,
                            imageUrl: product.imageId,
                            description: product.descriptionMap.trLanguage,
                            price: product.finalPrice,
                            oldPrice:
                                product.hasDiscount ? product.price : null,
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
                            child:
                                isWebShell ? HoverLift(child: card) : card,
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
