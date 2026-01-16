import 'package:appwrite_user_app/app/controllers/product_controller.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/food_item_card.dart';
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: ColorResource.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(Constants.radiusSmall),
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
                    'New Items',
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
            if (controller.isLoadingNew)
              SizedBox(
                height: 220,
                child: Center(
                  child: CircularProgressIndicator(
                    color: ColorResource.primaryDark,
                  ),
                ),
              )
            
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
                        'Failed to load new items',
                        style: poppinsMedium.copyWith(
                          fontSize: Constants.fontSizeDefault,
                          color: ColorResource.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => controller.getNewProducts(),
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
            else if (controller.newProducts.isEmpty)
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
                        'No new items available',
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
                  itemCount: controller.newProducts.length,
                  itemBuilder: (context, index) {
                    final product = controller.newProducts[index];

                    return FoodItemCard(
                      name: product.name,
                      imageUrl: product.imageId,
                      description: product.description,
                      price: product.finalPrice,
                      oldPrice: product.hasDiscount ? product.price : null,
                      onTap: () {
                        ProductDetailBottomSheet.show(context, product);
                      },
                      onAddToCart: () {
                        ProductDetailBottomSheet.show(context, product);
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
