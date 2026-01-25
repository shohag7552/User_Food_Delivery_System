import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/controllers/favorites_controller.dart';
import 'package:appwrite_user_app/app/models/product_model.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/product_detail_bottomsheet.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {

  @override
  void initState() {
    super.initState();

    Get.find<FavoritesController>().fetchFavorites(canUpdate: false, loadWithProduct: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorResource.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          'My Favorites',
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeLarge,
            color: ColorResource.textWhite,
          ),
        ),
        backgroundColor: ColorResource.primaryDark,
        elevation: 0,
      ),
      body: GetBuilder<FavoritesController>(
        builder: (controller) {
          print('========ggg===> ${controller.favorites.length}');

          if (controller.isLoading) {
            return _buildLoadingState();
          }

          if (!controller.hasFavorites) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => controller.fetchFavorites(),
            color: ColorResource.primaryDark,
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: controller.favorites.length,
              itemBuilder: (context, index) {
                final product = controller.favorites[index].product;
                final favorite = controller.favorites[index];
                return _buildProductCard(context, product!, favorite.id, controller);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => _buildSkeletonCard(),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      decoration: BoxDecoration(
        color: ColorResource.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: ColorResource.customShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image skeleton
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: ColorResource.textLight.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(Constants.radiusLarge),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: ColorResource.textLight.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 14,
                  width: 80,
                  decoration: BoxDecoration(
                    color: ColorResource.textLight.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: ColorResource.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_outline,
                size: 60,
                color: ColorResource.textWhite,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Favorites Yet',
              style: poppinsBold.copyWith(
                fontSize: 24,
                color: ColorResource.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start adding your favorite products\nto see them here',
              textAlign: TextAlign.center,
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: ColorResource.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Get.back(),
              icon: Icon(Icons.arrow_back, color: ColorResource.textWhite),
              label: Text(
                'Browse Products',
                style: poppinsMedium.copyWith(color: ColorResource.textWhite),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorResource.primaryDark,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product, String favoriteId, FavoritesController controller) {
    final bool isVeg = product.isVeg;
    final bool hasDiscount = product.hasDiscount;

    return GestureDetector(
      onTap: () {
        ProductDetailBottomSheet.show(context, product);
      },
      child: Container(
        decoration: BoxDecoration(
          color: ColorResource.cardBackground,
          borderRadius: BorderRadius.circular(Constants.radiusLarge),
          boxShadow: ColorResource.customShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with badges
            Stack(
              children: [
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(Constants.radiusLarge),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(Constants.radiusLarge),
                    ),
                    child: CustomNetworkImage(
                      image: product.imageId,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),

                // Veg/Non-veg badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: ColorResource.textWhite,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isVeg ? Colors.green : Colors.red,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.circle,
                      size: 8,
                      color: isVeg ? Colors.green : Colors.red,
                    ),
                  ),
                ),

                // Discount badge
                if (hasDiscount)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: ColorResource.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.discountType == 'percentage'
                            ? '${product.discountValue!.toInt()}% OFF'
                            : '\$${product.discountValue!.toStringAsFixed(0)} OFF',
                        style: poppinsBold.copyWith(
                          fontSize: 10,
                          color: ColorResource.textWhite,
                        ),
                      ),
                    ),
                  ),

                // Favorite button
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => controller.removeFavoriteById(favoriteId, product.id),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ColorResource.textWhite,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: controller.isToggleLoading(product.id)
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  ColorResource.primaryDark,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.favorite,
                              size: 20,
                              color: ColorResource.error,
                            ),
                    ),
                  ),
                ),
              ],
            ),

            // Product Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: poppinsMedium.copyWith(
                            fontSize: Constants.fontSizeDefault,
                            color: ColorResource.textPrimary,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),

                    // Price
                    Row(
                      children: [
                        if (hasDiscount) ...[
                          Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: poppinsRegular.copyWith(
                              fontSize: Constants.fontSizeSmall,
                              color: ColorResource.textLight,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          '\$${product.finalPrice.toStringAsFixed(2)}',
                          style: poppinsBold.copyWith(
                            fontSize: Constants.fontSizeDefault + 2,
                            color: ColorResource.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
