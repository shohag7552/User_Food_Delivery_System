import 'package:appwrite_user_app/app/common/widgets/custom_clickable_widget.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/controllers/product_controller.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/product_detail_bottomsheet.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AllProductsWidget extends StatelessWidget {
  final bool isTablet;
  final ScrollController scrollController;
  
  const AllProductsWidget({super.key, this.isTablet = false, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProductController>(
      builder: (controller) {
        // Loading State (initial)
        if (controller.isLoading && controller.products.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(
                color: ColorResource.primaryDark,
              ),
            ),
          );
        }
        
        // Error State
        if (controller.errorMessage != null && controller.products.isEmpty) {
          return SliverFillRemaining(
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
                    'Failed to load products',
                    style: poppinsMedium.copyWith(
                      fontSize: Constants.fontSizeDefault,
                      color: ColorResource.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => controller.getProducts(refresh: true),
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
          );
        }
        
        // Empty State
        if (controller.products.isEmpty) {
          return SliverFillRemaining(
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
                    'No products available',
                    style: poppinsMedium.copyWith(
                      fontSize: Constants.fontSizeDefault,
                      color: ColorResource.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        // Return a MultiSliver containing the grid and loading indicator
        return SliverMainAxisGroup(
          slivers: [
            // Products Grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isTablet ? 3 : 2,
                  childAspectRatio: isTablet ? 0.75 : 0.65,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = controller.products[index];
                    return _buildProductCard(
                      product: product,
                      onTap: () {
                        ProductDetailBottomSheet.show(context, product);
                      },
                      onAddToCart: () {
                        ProductDetailBottomSheet.show(context, product);
                      },
                    );
                  },
                  childCount: controller.products.length,
                ),
              ),
            ),
            
            // Load More Indicator
            if (controller.isLoadingMore)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: ColorResource.primaryDark,
                    ),
                  ),
                ),
              ),
            
            // Bottom spacing
            const SliverToBoxAdapter(
              child: SizedBox(height: 20),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductCard({
    required product,
    required VoidCallback onTap,
    required VoidCallback onAddToCart,
  }) {
    final hasDiscount = product.hasDiscount;
    final discountPercentage = hasDiscount
        ? ((product.price - product.finalPrice) / product.price * 100).toStringAsFixed(0)
        : null;

    return CustomClickableWidget(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: ColorResource.cardBackground,
          borderRadius: BorderRadius.circular(Constants.radiusLarge),
          boxShadow: ColorResource.customShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with badges
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(Constants.radiusLarge),
                      topRight: Radius.circular(Constants.radiusLarge),
                    ),
                    child: CustomNetworkImage(image: product.imageId, height: 160, width: double.infinity),
                  ),

                  // Discount Badge
                  if (hasDiscount)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: ColorResource.error,
                          borderRadius: BorderRadius.circular(Constants.radiusSmall),
                        ),
                        child: Text(
                          '$discountPercentage% OFF',
                          style: poppinsBold.copyWith(
                            fontSize: Constants.fontSizeExtraSmall,
                            color: ColorResource.textWhite,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Product Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    product.name,
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeDefault,
                      color: ColorResource.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Description
                  Text(
                    product.description,
                    style: poppinsRegular.copyWith(
                      fontSize: Constants.fontSizeSmall,
                      color: ColorResource.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Price and Add Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '\$${product.finalPrice.toStringAsFixed(2)}',
                              style: poppinsBold.copyWith(
                                fontSize: Constants.fontSizeLarge,
                                color: ColorResource.primaryDark,
                              ),
                            ),
                            if (hasDiscount)
                              Text(
                                '\$${product.price.toStringAsFixed(2)}',
                                style: poppinsRegular.copyWith(
                                  fontSize: Constants.fontSizeSmall,
                                  color: ColorResource.textLight,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Add Button
                      GestureDetector(
                        onTap: onAddToCart,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: ColorResource.primaryGradient,
                            borderRadius: BorderRadius.circular(
                              Constants.radiusDefault,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: ColorResource.primaryMedium
                                    .withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
