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
import 'package:carousel_slider/carousel_slider.dart';
import 'package:get/get.dart';

class PopularDishesWidget extends StatefulWidget {
  const PopularDishesWidget({super.key});

  @override
  State<PopularDishesWidget> createState() => _PopularDishesWidgetState();
}

class _PopularDishesWidgetState extends State<PopularDishesWidget> {
  // Lets the web hover arrows page the auto-playing carousel.
  final CarouselSliderController _carouselController =
      CarouselSliderController();

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
                  Icon(
                    Icons.trending_up,
                    color: ColorResource.success,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'popular_dishes'.tr,
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
            if (controller.isLoadingPopular)
              const HorizontalFoodListShimmer(isPopular: true)
            // Error State
            else if (controller.popularErrorMessage != null)
              SizedBox(
                height: 290,
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
                        'failed_to_load_popular_dishes'.tr,
                        style: poppinsMedium.copyWith(
                          fontSize: Constants.fontSizeDefault,
                          color: context.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => controller.getPopularProducts(),
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
            else if (controller.popularProducts.isEmpty)
              SizedBox(
                height: 290,
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
                        'no_popular_dishes_available'.tr,
                        style: poppinsMedium.copyWith(
                          fontSize: Constants.fontSizeDefault,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            // Products List
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final products = controller.popularProducts;
                  final width = constraints.maxWidth;
                  final isWebShell = WebTopNav.isEnabled(context);
                  final screenWidth = MediaQuery.of(context).size.width;
                  // Web: cards match the All Products grid size (the item's
                  // 6px side paddings make the card = fraction·width − 12).
                  final double viewportFraction = isWebShell
                      ? ((FoodCardMetrics.webCardWidth(screenWidth) + 12) /
                              width)
                          .clamp(0.15, 0.95)
                      : width >= 900
                      ? 0.30
                      : width >= 600
                      ? 0.40
                      : 0.56;
                  // +8 covers the item's vertical padding (4 top + 4 bottom).
                  final double carouselHeight = isWebShell
                      ? FoodCardMetrics.webCardHeight(screenWidth) + 8
                      : 250;

                  // Hover-revealed arrows page the carousel on desktop web —
                  // hidden when every dish already fits in the viewport
                  // (items × fraction ≤ 1 means nothing to page through).
                  return HoverArrows(
                    onLeft: () => _carouselController.previousPage(),
                    onRight: () => _carouselController.nextPage(),
                    canScroll: () =>
                        products.length * viewportFraction > 1.001,
                    child: CarouselSlider.builder(
                    carouselController: _carouselController,
                    itemCount: products.length,
                    itemBuilder: (context, index, realIndex) {
                      final product = products[index];

                      return GetBuilder<CartController>(
                        builder: (cartController) {
                          final cartQuantity = CartHelper.getProductCartQuantity(product.id);

                          final card = FoodItemCard(
                              name: product.nameMap.trLanguage,
                              isPopular: true,
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

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            // Web-only hover lift; touch gets the bare card.
                            child: isWebShell ? HoverLift(child: card) : card,
                          );
                        },
                      );
                    },
                    options: CarouselOptions(
                      height: carouselHeight,
                      viewportFraction: viewportFraction,
                      padEnds: true,
                      // The center-zoom is a touch affordance; on web the
                      // cards stay uniform so they match the grid size.
                      enlargeCenterPage: !isWebShell,
                      enlargeFactor: 0.2,
                      enlargeStrategy: CenterPageEnlargeStrategy.zoom,
                      enableInfiniteScroll: products.length > 1,
                      autoPlay: products.length > 1,
                      autoPlayInterval: const Duration(seconds: 5),
                      autoPlayAnimationDuration: const Duration(
                        milliseconds: 1000,
                      ),
                      autoPlayCurve: Curves.linear,
                      pauseAutoPlayOnTouch: true,
                      pauseAutoPlayOnManualNavigate: true,
                      pauseAutoPlayInFiniteScroll: false,
                    ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}
