import 'package:appwrite_user_app/app/controllers/cart_controller.dart';
import 'package:appwrite_user_app/app/controllers/product_controller.dart';
import 'package:appwrite_user_app/app/helper/cart_helper.dart';
import 'package:appwrite_user_app/app/helper/localization_extension_helper.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/food_item_card.dart';
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
                      color: ColorResource.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Loading State
            if (controller.isLoadingPopular)
              SizedBox(
                height: 290,
                child: Center(
                  child: CircularProgressIndicator(
                    color: ColorResource.primaryDark,
                  ),
                ),
              )
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
                          color: ColorResource.textSecondary,
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
                        color: ColorResource.textLight,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'no_popular_dishes_available'.tr,
                        style: poppinsMedium.copyWith(
                          fontSize: Constants.fontSizeDefault,
                          color: ColorResource.textSecondary,
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
                  final viewportFraction = width >= 900
                      ? 0.28
                      : width >= 600
                      ? 0.38
                      : 0.58;

                  return CarouselSlider.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index, realIndex) {
                      final product = products[index];

                      return GetBuilder<CartController>(
                        builder: (cartController) {
                          final cartQuantity = CartHelper.getProductCartQuantity(product.id);

                          return FoodItemCard(
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
                        },
                      );
                    },
                    options: CarouselOptions(
                      height: 266,
                      viewportFraction: viewportFraction,
                      padEnds: true,
                      enlargeCenterPage: true,
                      enlargeFactor: 0.25,
                      enlargeStrategy: CenterPageEnlargeStrategy.zoom,
                      enableInfiniteScroll: products.length > 1,
                      autoPlay: products.length > 1,
                      autoPlayInterval: const Duration(seconds: 25),
                      autoPlayAnimationDuration: const Duration(
                        milliseconds: 1000,
                      ),
                      autoPlayCurve: Curves.linear,
                      pauseAutoPlayOnTouch: true,
                      pauseAutoPlayOnManualNavigate: true,
                      pauseAutoPlayInFiniteScroll: false,
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
