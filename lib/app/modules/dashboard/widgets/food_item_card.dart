import 'package:appwrite_user_app/app/common/widgets/custom_clickable_widget.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/helper/price_helper.dart';
import 'package:appwrite_user_app/app/common/widgets/favorite_button.dart';
import 'package:appwrite_user_app/app/common/widgets/rating_stars.dart';
import 'package:appwrite_user_app/app/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';

/// A single, consistent product card used by every horizontal home section
/// (Today's Specials, Popular Dishes, New Items).
///
/// The card has no fixed width/height of its own — it fills the box its
/// parent gives it (a [SizedBox] in a list, or a carousel slide). The image
/// flexes to fill the space left above a fixed-height details block, so the
/// layout stays clean regardless of the list height.
class FoodItemCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final String description;
  final double price;
  final double? oldPrice;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;
  final ProductModel? product;
  final int? cartQuantity; // Quantity in cart (null if not in cart)
  final Function(bool isIncrement)? onQuantityChanged;

  // Kept for API compatibility with the section widgets. The card renders
  // identically across sections so the home feed feels cohesive.
  final bool? isPopular;
  final bool isSpecial;

  const FoodItemCard({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.price,
    this.oldPrice,
    required this.onTap,
    required this.onAddToCart,
    this.product,
    this.cartQuantity,
    this.onQuantityChanged,
    this.isPopular = false,
    this.isSpecial = false,
  });

  static const double _imageRadius = Constants.radiusLarge + 4; // 19

  bool get _hasDiscount => product?.hasDiscount ?? false;

  String get _discountLabel {
    if (product?.discountType == 'percentage') {
      return '${product?.discountValue?.toInt()}% OFF';
    }
    return '${PriceHelper.formatPrice(product?.discountValue?.toDouble() ?? 0)} OFF';
  }

  bool get _hasOldPrice => oldPrice != null && oldPrice! > price;

  @override
  Widget build(BuildContext context) {
    return CustomClickableWidget(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image — flexes to fill the space above the details block.
          Expanded(child: _buildImage()),
          _buildDetails(),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(_imageRadius),
        topRight: Radius.circular(_imageRadius),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomNetworkImage(
            image: imageUrl,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),

          // Discount badge (top-left)
          if (_hasDiscount)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ColorResource.discountBadge,
                  borderRadius: BorderRadius.circular(Constants.radiusSmall),
                ),
                child: Text(
                  _discountLabel,
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeExtraSmall,
                    color: ColorResource.textWhite,
                  ),
                ),
              ),
            ),

          // Favorite button (top-right)
          if (product != null)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: ColorResource.cardBackground,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: FavoriteButton(product: product!, size: 17),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: poppinsBold.copyWith(
              fontSize: Constants.fontSizeDefault,
              color: ColorResource.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (product != null) ...[
            const SizedBox(height: 6),
            RatingStars(
              rating: product!.avgRating,
              reviewCount: product!.ratingCount,
              size: 13,
            ),
          ],
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _buildPrice()),
              const SizedBox(width: 8),
              cartQuantity != null
                  ? _buildQuantitySelector()
                  : _buildAddButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrice() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          PriceHelper.formatPrice(price),
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeLarge,
            color: ColorResource.primaryDark,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (_hasOldPrice)
          Text(
            PriceHelper.formatPrice(oldPrice!),
            style: poppinsRegular.copyWith(
              fontSize: Constants.fontSizeSmall,
              color: ColorResource.textLight,
              decoration: TextDecoration.lineThrough,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: onAddToCart,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: ColorResource.primaryGradient,
          borderRadius: BorderRadius.circular(Constants.radiusDefault),
          boxShadow: [
            BoxShadow(
              color: ColorResource.primaryMedium.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: ColorResource.textWhite, size: 20),
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        gradient: ColorResource.primaryGradient,
        borderRadius: BorderRadius.circular(Constants.radiusDefault),
        boxShadow: [
          BoxShadow(
            color: ColorResource.primaryMedium.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQuantityButton(
            icon: Icons.remove,
            onTap: () => onQuantityChanged?.call(false),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 24),
            alignment: Alignment.center,
            child: Text(
              '$cartQuantity',
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: ColorResource.textWhite,
              ),
            ),
          ),
          _buildQuantityButton(
            icon: Icons.add,
            onTap: () => onQuantityChanged?.call(true),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: ColorResource.textWhite, size: 18),
      ),
    );
  }
}
