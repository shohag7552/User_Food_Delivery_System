import 'package:appwrite_user_app/app/common/widgets/custom_appbar.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/common/widgets/favorite_button.dart';
import 'package:appwrite_user_app/app/common/widgets/rating_stars.dart';
import 'package:appwrite_user_app/app/controllers/auth_controller.dart';
import 'package:appwrite_user_app/app/controllers/brand_controller.dart';
import 'package:appwrite_user_app/app/controllers/cart_controller.dart';
import 'package:appwrite_user_app/app/helper/cart_helper.dart';
import 'package:appwrite_user_app/app/helper/localization_extension_helper.dart';
import 'package:appwrite_user_app/app/helper/price_helper.dart';
import 'package:appwrite_user_app/app/models/product_model.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/full_screen_image_viewer.dart';
import 'package:appwrite_user_app/app/modules/reviews/widgets/review_list_section.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EcommerceProductDetailPage extends StatefulWidget {
  final ProductModel product;

  const EcommerceProductDetailPage({super.key, required this.product});

  @override
  State<EcommerceProductDetailPage> createState() =>
      _EcommerceProductDetailPageState();
}

class _EcommerceProductDetailPageState
    extends State<EcommerceProductDetailPage> {
  final PageController _galleryController = PageController();
  int _currentImage = 0;
  bool _descExpanded = false;

  ProductModel get product => widget.product;

  List<String> get _images => product.imageGallery.isNotEmpty
      ? product.imageGallery
      : [product.imageId];

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasDiscount = product.hasDiscount;
    final description = product.descriptionMap.trLanguage.trim();

    return Scaffold(
      backgroundColor: ColorResource.scaffoldBackground,
      appBar: CustomAppbar(title: product.nameMap.trLanguage),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildGallery(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBrand(),
                Text(
                  product.nameMap.trLanguage,
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeExtraLarge,
                    color: ColorResource.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                RatingStars(
                  rating: product.avgRating,
                  reviewCount: product.ratingCount,
                  size: 16,
                  showRating: true,
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      PriceHelper.formatPrice(product.finalPrice),
                      style: poppinsBold.copyWith(
                        fontSize: Constants.fontSizeOverLarge,
                        color: ColorResource.primaryDark,
                      ),
                    ),
                    if (hasDiscount) ...[
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          PriceHelper.formatPrice(product.price),
                          style: poppinsRegular.copyWith(
                            fontSize: Constants.fontSizeDefault,
                            color: ColorResource.textLight,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                _buildStockChip(),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'description'.tr,
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeLarge,
                      color: ColorResource.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    maxLines: _descExpanded ? null : 4,
                    overflow: _descExpanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: poppinsRegular.copyWith(
                      fontSize: Constants.fontSizeDefault,
                      color: ColorResource.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  if (description.length > 160)
                    GestureDetector(
                      onTap: () =>
                          setState(() => _descExpanded = !_descExpanded),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _descExpanded ? 'see_less'.tr : 'see_more'.tr,
                          style: poppinsBold.copyWith(
                            fontSize: Constants.fontSizeSmall,
                            color: ColorResource.primaryDark,
                          ),
                        ),
                      ),
                    ),
                ],
                _buildSpecs(),
                if (product.ratingCount > 0) ...[
                  const SizedBox(height: 20),
                  Divider(
                    color: ColorResource.textLight.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'customer_reviews'.tr,
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeLarge,
                      color: ColorResource.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<String?>(
                    future: Get.find<AuthController>().getUserId(),
                    builder: (context, snapshot) => ReviewListSection(
                      productId: product.id,
                      currentUserId: snapshot.data,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildGallery() {
    final images = _images;
    return SizedBox(
      height: 320,
      child: Stack(
        children: [
          PageView.builder(
            controller: _galleryController,
            itemCount: images.length,
            onPageChanged: (i) => setState(() => _currentImage = i),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FullScreenImageViewer(
                      imageUrl: images[index],
                      heroTag: 'ecom-${product.id}-$index',
                    ),
                  ),
                ),
                child: CustomNetworkImage(
                  image: images[index],
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              decoration: BoxDecoration(
                color: ColorResource.cardBackground,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: FavoriteButton(product: product, size: 22),
            ),
          ),
          if (images.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentImage == index ? 20 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _currentImage == index
                          ? ColorResource.primaryDark
                          : ColorResource.textLight.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBrand() {
    return GetBuilder<BrandController>(
      builder: (brandController) {
        final brand = brandController.brandById(product.brandId);
        if (brand == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            brand.nameMap.trLanguage.toUpperCase(),
            style: poppinsMedium.copyWith(
              fontSize: Constants.fontSizeSmall,
              color: ColorResource.primaryDark,
              letterSpacing: 0.5,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStockChip() {
    final outOfStock = product.isOutOfStock;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (outOfStock ? ColorResource.error : ColorResource.success)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        outOfStock ? 'out_of_stock'.tr : '${product.stock} ${'in_stock'.tr}',
        style: poppinsMedium.copyWith(
          fontSize: Constants.fontSizeSmall,
          color: outOfStock ? ColorResource.error : ColorResource.success,
        ),
      ),
    );
  }

  Widget _buildSpecs() {
    final rows = <Widget>[];
    if ((product.sku ?? '').isNotEmpty) {
      rows.add(_specRow('sku'.tr, product.sku!));
    }
    if (product.weight != null) {
      rows.add(_specRow(
        'weight'.tr,
        '${product.weight}${product.weightUnit ?? ''}',
      ));
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows),
    );
  }

  Widget _specRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeSmall,
                color: ColorResource.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: poppinsMedium.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: ColorResource.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: ColorResource.cardBackground,
        boxShadow: [
          BoxShadow(
            color: ColorResource.shadowMedium,
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: GetBuilder<CartController>(
          builder: (_) {
            if (product.isOutOfStock) {
              return _disabledButton('out_of_stock'.tr);
            }
            final quantity = CartHelper.getProductCartQuantity(product.id);
            if (quantity == null) {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      CartHelper.handleAddToCart(product, context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorResource.primaryDark,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Constants.radiusLarge),
                    ),
                  ),
                  icon: const Icon(
                    Icons.shopping_bag_outlined,
                    color: ColorResource.textWhite,
                    size: 20,
                  ),
                  label: Text(
                    'add_to_cart'.tr,
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeLarge,
                      color: ColorResource.textWhite,
                    ),
                  ),
                ),
              );
            }
            return Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: ColorResource.scaffoldBackground,
                    borderRadius: BorderRadius.circular(Constants.radiusLarge),
                    border: Border.all(
                      color: ColorResource.textLight.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      _qtyButton(
                        Icons.remove,
                        () => CartHelper.decrementQuantity(product, context),
                      ),
                      SizedBox(
                        width: 36,
                        child: Center(
                          child: Text(
                            '$quantity',
                            style: poppinsBold.copyWith(
                              fontSize: Constants.fontSizeLarge,
                              color: ColorResource.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      _qtyButton(
                        Icons.add,
                        () => CartHelper.incrementQuantity(product, context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: ColorResource.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(Constants.radiusLarge),
                    ),
                    child: Text(
                      'added_to_cart'.tr,
                      style: poppinsBold.copyWith(
                        fontSize: Constants.fontSizeDefault,
                        color: ColorResource.success,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(icon, size: 18, color: ColorResource.primaryDark),
      ),
    );
  }

  Widget _disabledButton(String label) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor:
              ColorResource.textLight.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Constants.radiusLarge),
          ),
        ),
        child: Text(
          label,
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeLarge,
            color: ColorResource.textWhite,
          ),
        ),
      ),
    );
  }
}
