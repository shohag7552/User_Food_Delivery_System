import 'package:appwrite_user_app/app/controllers/cart_controller.dart';
import 'package:appwrite_user_app/app/controllers/product_controller.dart';
import 'package:appwrite_user_app/app/helper/cart_helper.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/food_item_card.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/product_detail_bottomsheet.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PopularDishesWidget extends StatelessWidget {
  const PopularDishesWidget({super.key});

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
                    'Popular Dishes',
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
                height: 220,
                child: Center(
                  child: CircularProgressIndicator(
                    color: ColorResource.primaryDark,
                  ),
                ),
              )
            
            // Error State
            else if (controller.popularErrorMessage != null)
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
                        'Failed to load popular dishes',
                        style: poppinsMedium.copyWith(
                          fontSize: Constants.fontSizeDefault,
                          color: ColorResource.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => controller.getPopularProducts(),
                        child: Text(
                          'Retry',
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
                height: 220,
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
                        'No popular dishes available',
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
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: controller.popularProducts.length,
                  itemBuilder: (context, index) {
                    final product = controller.popularProducts[index];

                    return GetBuilder<CartController>(
                      builder: (cartController) {
                        final cartQuantity = CartHelper.getProductCartQuantity(product.id);
                        
                        return FoodItemCard(
                          name: product.name,
                          imageUrl: product.imageId,
                          description: product.description,
                          price: product.finalPrice,
                          oldPrice: product.hasDiscount ? product.price : null,
                          product: product,
                          cartQuantity: cartQuantity,
                          onTap: () {
                            ProductDetailBottomSheet.show(context, product);
                          },
                          onAddToCart: () => CartHelper.handleAddToCart(product, context),
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
                ),
              ),
          ],
        );
      },
    );
  }
}
