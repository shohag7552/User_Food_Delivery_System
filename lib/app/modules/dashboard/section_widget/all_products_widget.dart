import 'package:appwrite_user_app/app/common/widgets/custom_clickable_widget.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/common/widgets/favorite_button.dart';
import 'package:appwrite_user_app/app/common/widgets/rating_stars.dart';
import 'package:appwrite_user_app/app/controllers/cart_controller.dart';
import 'package:appwrite_user_app/app/controllers/product_controller.dart';
import 'package:appwrite_user_app/app/helper/cart_helper.dart';
import 'package:appwrite_user_app/app/helper/localization_extension_helper.dart';
import 'package:appwrite_user_app/app/helper/price_helper.dart';
import 'package:appwrite_user_app/app/models/product_model.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/dashboard_shimmer.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/product_detail_bottomsheet.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AllProductsWidget extends StatelessWidget {
  final bool isTablet;
  final ScrollController scrollController;

  /// Overrides the phone/tablet column count (used by the web layout).
  final int? crossAxisCount;

  /// Side padding around the grid — the web layout passes computed gutters
  /// that center the grid within its max content width.
  final double horizontalPadding;

  const AllProductsWidget({
    super.key,
    this.isTablet = false,
    required this.scrollController,
    this.crossAxisCount,
    this.horizontalPadding = 20,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProductController>(
      builder: (controller) {
        // Loading State (initial)
        if (controller.isLoading && controller.products.isEmpty) {
          return AllProductsGridShimmer(isTablet: isTablet);
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
              padding:
                  EdgeInsets.symmetric(horizontal: horizontalPadding),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount ?? (isTablet ? 3 : 2),
                  childAspectRatio:
                      (crossAxisCount ?? (isTablet ? 3 : 2)) >= 3 ? 0.75 : 0.65,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final ProductModel product = controller.products[index];
                  return GetBuilder<CartController>(
                    builder: (cartController) {
                      final cartQuantity = CartHelper.getProductCartQuantity(
                        product.id,
                      );
                      return _buildProductCard(
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
                }, childCount: controller.products.length),
              ),
            ),

            // Load More Indicator
            if (controller.isLoadingMore)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: const Center(child: LoadMoreShimmer()),
                ),
              ),

            // Bottom spacing (clears the floating bottom nav bar)
            const SliverToBoxAdapter(
              child: SizedBox(height: Constants.bottomNavSpace),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductCard({
    required ProductModel product,
    required VoidCallback onTap,
    required VoidCallback onAddToCart,
    required int? cartQuantity,
    required Function(bool isIncrement) onQuantityChanged,
  }) {
    final hasDiscount = product.hasDiscount;

    return CustomClickableWidget(
      onTap: onTap,
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
                  child: CustomNetworkImage(
                    image: product.imageId,
                    height: 160,
                    width: double.infinity,
                  ),
                ),

                // Discount Badge
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
                          Constants.radiusLarge,
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
                // Favorite button (top-right corner)
                Positioned(
                  top: 8,
                  right: 8,
                  child: FavoriteButton(product: product, size: 18),
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
                  product.nameMap.trLanguage,
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeDefault,
                    color: ColorResource.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                RatingStars(
                  rating: product.avgRating,
                  reviewCount: product.ratingCount,
                  size: 13,
                ),
                const SizedBox(height: 8),

                // // Description
                // Text(
                //   product.descriptionMap.trLanguage,
                //   style: poppinsRegular.copyWith(
                //     fontSize: Constants.fontSizeSmall,
                //     color: ColorResource.textSecondary,
                //   ),
                //   maxLines: 2,
                //   overflow: TextOverflow.ellipsis,
                // ),
                //
                // const SizedBox(height: 8),

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
                            PriceHelper.formatPrice(product.finalPrice),
                            style: poppinsBold.copyWith(
                              fontSize: Constants.fontSizeLarge,
                              color: ColorResource.primaryDark,
                            ),
                          ),
                          if (hasDiscount)
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
                    // Quantity selector or Add Button
                    cartQuantity != null
                        ? _buildQuantitySelector(
                            cartQuantity,
                            onQuantityChanged,
                          )
                        : _buildAddButton(onAddToCart),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build simple add button for grid cards
  Widget _buildAddButton(VoidCallback onAddToCart) {
    return GestureDetector(
      onTap: onAddToCart,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: ColorResource.primaryGradient,
          borderRadius: BorderRadius.circular(Constants.radiusDefault),
          boxShadow: [
            BoxShadow(
              color: ColorResource.primaryMedium.withValues(alpha: 0.4),
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
    );
  }

  /// Build quantity selector for grid cards
  Widget _buildQuantitySelector(
    int quantity,
    Function(bool isIncrement) onQuantityChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: ColorResource.primaryGradient,
        borderRadius: BorderRadius.circular(Constants.radiusDefault),
        boxShadow: [
          BoxShadow(
            color: ColorResource.primaryMedium.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => onQuantityChanged(false),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.remove,
                color: ColorResource.textWhite,
                size: 14,
              ),
            ),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 20),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Center(
              child: Text(
                '$quantity',
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeSmall,
                  color: ColorResource.textWhite,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => onQuantityChanged(true),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.add, color: ColorResource.textWhite, size: 14),
            ),
          ),
        ],
      ),
    );
  }
}
