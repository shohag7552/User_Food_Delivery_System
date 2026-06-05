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

class FoodItemCard extends StatefulWidget {
  final String name;
  final String imageUrl;
  final String description;
  final double price;
  final double? oldPrice;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;
  final ProductModel? product;
  final int? cartQuantity; // Quantity in cart (null if not in cart)
  final Function(bool isIncrement)?
  onQuantityChanged; // Callback for quantity changes
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

  @override
  State<FoodItemCard> createState() => _FoodItemCardState();
}

class _FoodItemCardState extends State<FoodItemCard> {
  // double get discountPercentage {
  //   if (widget.oldPrice != null && widget.oldPrice! > widget.price) {
  //     return ((widget.oldPrice! - widget.price) / widget.oldPrice!) * 100;
  //   }
  //   return 0;
  // }

  @override
  Widget build(BuildContext context) {
    bool hasDiscount = widget.product?.hasDiscount?? false;
    String discount = widget.product?.discountType == 'percentage'
        ? '${widget.product?.discountValue?.toInt()}% OFF'
        : '${PriceHelper.formatPrice(widget.product?.discountValue?.toDouble()??0)} OFF';

    if (widget.isPopular!) {
      return Padding(
        padding: const EdgeInsets.only(
          top: 8,
          bottom: Constants.paddingSizeSmall,
        ),
        child: CustomClickableWidget(
          onTap: widget.onTap,
          child: Container(
            width: 208,
            decoration: BoxDecoration(
              color: ColorResource.cardBackground,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPopularImageSection(hasDiscount, discount),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.name,
                          style: poppinsBold.copyWith(
                            fontSize: 17,
                            color: ColorResource.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.product != null) ...[
                          const SizedBox(height: 6),
                          RatingStars(
                            rating: widget.product!.avgRating,
                            reviewCount: widget.product!.ratingCount,
                            size: 14,
                          ),
                        ],
                        const Spacer(),
                        // const SizedBox(height: Constants.paddingSizeSmall),
                        
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    PriceHelper.formatPrice(widget.price),
                                    style: poppinsBold.copyWith(
                                      fontSize: 16,
                                      color: ColorResource.primaryDark,
                                    ),
                                  ),
                                  if (widget.oldPrice != null &&
                                      widget.oldPrice! > widget.price)
                                    Text(
                                      PriceHelper.formatPrice(widget.oldPrice!),
                                      style: poppinsRegular.copyWith(
                                        fontSize: Constants.fontSizeSmall,
                                        color: ColorResource.textLight,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            widget.cartQuantity != null
                                ? _buildPopularQuantitySelector()
                                : _buildPopularAddButton(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (widget.isSpecial) {
      return Padding(
        padding: const EdgeInsets.only(
          top: 8,
          right: 18,
          bottom: Constants.paddingSizeSmall,
        ),
        child: CustomClickableWidget(
          onTap: widget.onTap,
          child: Container(
            width: 210,
            decoration: BoxDecoration(
              color: ColorResource.cardBackground,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSpecialImageSection(hasDiscount, discount),
                  const SizedBox(height: Constants.paddingSizeSmall),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        widget.name,
                        style: poppinsBold,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.product != null) ...[
                        const SizedBox(height: Constants.paddingSizeSmall),
                        RatingStars(
                          rating: widget.product!.avgRating,
                          reviewCount: widget.product!.ratingCount,
                          size: 14,
                          showRating: true,
                        ),
                      ],
                      const SizedBox(height: Constants.paddingSizeSmall),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    PriceHelper.formatPrice(widget.price),
                                    style: poppinsBold.copyWith(
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (widget.oldPrice != null &&
                                      widget.oldPrice! > widget.price)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        PriceHelper.formatPrice(widget.oldPrice!),
                                        style: poppinsRegular.copyWith(
                                          fontSize: 11.5,
                                          color: ColorResource.textLight,
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            widget.cartQuantity != null
                                ? _buildSpecialQuantitySelector()
                                : _buildSpecialAddButton(),
                          ],
                        ),
                      ),
                    ]),
                  ),

                ],
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(
        right: 16,
        bottom: Constants.paddingSizeSmall,
      ),
      child: CustomClickableWidget(
        onTap: widget.onTap,
        child: SizedBox(
          width: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with discount badge
              Expanded(
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(2),
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(Constants.radiusLarge),
                          topRight: Radius.circular(Constants.radiusLarge),
                        ),
                        child: CustomNetworkImage(
                          image: widget.imageUrl,
                          height: 160,
                          width: double.infinity,
                        ),
                      ),
                    ),
                    // Discount badge
                    if (hasDiscount)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: ColorResource.discountBadge,
                            borderRadius: BorderRadius.circular(
                              Constants.radiusSmall,
                            ),
                          ),
                          child: Text(
                            discount,
                            style: poppinsBold.copyWith(
                              fontSize: Constants.fontSizeExtraSmall,
                              color: ColorResource.textWhite,
                            ),
                          ),
                        ),
                      ),
                    // Favorite button (top-right corner)
                    if (widget.product != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: FavoriteButton(
                          product: widget.product!,
                          size: 18,
                        ),
                      ),
                  ],
                ),
              ),
              // Food details
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      widget.name,
                      style: poppinsBold.copyWith(
                        fontSize: Constants.fontSizeDefault,
                        color: ColorResource.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.product != null) ...[
                      const SizedBox(height: 6),
                      RatingStars(
                        rating: widget.product!.avgRating,
                        reviewCount: widget.product!.ratingCount,
                        size: 13,
                      ),
                    ],
                    const SizedBox(height: 4),
                    // Price and add button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              PriceHelper.formatPrice(widget.price),
                              style: poppinsBold.copyWith(
                                fontSize: Constants.fontSizeLarge,
                                color: ColorResource.primaryDark,
                              ),
                            ),
                            if (widget.oldPrice != null &&
                                widget.oldPrice! > widget.price)
                              Text(
                                PriceHelper.formatPrice(widget.oldPrice!),
                                style: poppinsRegular.copyWith(
                                  fontSize: Constants.fontSizeSmall,
                                  color: ColorResource.textLight,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                          ],
                        ),
                        // Quantity selector or Add button
                        widget.cartQuantity != null
                            ? _buildQuantitySelector()
                            : _buildAddButton(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build simple add button
  Widget _buildAddButton() {
    return GestureDetector(
      onTap: widget.onAddToCart,
      child: Container(
        padding: const EdgeInsets.all(10),
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
        child: Icon(Icons.add, color: ColorResource.textWhite, size: 20),
      ),
    );
  }

  Widget _buildPopularImageSection(bool hasDiscount, String discount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      child: SizedBox(
        height: 122,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(Constants.radiusLarge),
                topLeft: Radius.circular(Constants.radiusLarge),
                bottomRight: Radius.circular(Constants.radiusExtraLarge),
                bottomLeft: Radius.circular(Constants.radiusExtraLarge),
              ),
              child: CustomNetworkImage(
                image: widget.imageUrl,
                height: 122,
                width: double.infinity,
              ),
            ),
            if (hasDiscount)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: ColorResource.discountBadge.withValues(alpha: 0.9),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(15),
                      bottomLeft: Radius.circular(18),
                    ),
                  ),
                  child: Text(
                    discount,
                    style: poppinsMedium.copyWith(
                      fontSize: Constants.fontSizeSmall,
                      color: ColorResource.textWhite,
                    ),
                  ),
                ),
              ),
            if (widget.product != null)
              Positioned(
                right: 12,
                bottom: 10,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: ColorResource.textWhite,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: FavoriteButton(product: widget.product!, size: 17),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularAddButton() {
    return GestureDetector(
      onTap: widget.onAddToCart,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).primaryColor,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: ColorResource.textWhite, size: 28),
      ),
    );
  }

  Widget _buildSpecialImageSection(bool hasDiscount, String discount) {
    return Expanded(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(Constants.radiusLarge),
            child: CustomNetworkImage(
              image: widget.imageUrl,
              fit: BoxFit.cover,
              height: double.infinity,
              width: double.infinity,
            ),
          ),

          if (hasDiscount)
            Positioned(
              left: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: ColorResource.discountBadge.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  discount,
                  style: poppinsBold.copyWith(
                    fontSize: 10.5,
                    letterSpacing: 0.2,
                    color: ColorResource.textWhite,
                  ),
                ),
              ),
            ),
          if (widget.product != null)
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: ColorResource.textWhite,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: FavoriteButton(
                  product: widget.product!,
                  size: 20,
                  activeColor: Theme.of(context).primaryColor,
                  inactiveColor: Theme.of(context).primaryColor,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSpecialAddButton() {
    return GestureDetector(
      onTap: widget.onAddToCart,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: ColorResource.textWhite,
          size: 26,
        ),
      ),
    );
  }

  Widget _buildSpecialQuantitySelector() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: ColorResource.primaryDark,
        borderRadius: BorderRadius.circular(21),
        boxShadow: [
          BoxShadow(
            color: ColorResource.primaryDark.withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSpecialQuantityButton(
            icon: Icons.remove_rounded,
            onTap: () => widget.onQuantityChanged?.call(false),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              '${widget.cartQuantity}',
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: ColorResource.textWhite,
              ),
            ),
          ),
          _buildSpecialQuantityButton(
            icon: Icons.add_rounded,
            onTap: () => widget.onQuantityChanged?.call(true),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 32,
        height: 42,
        child: Icon(icon, color: ColorResource.textWhite, size: 18),
      ),
    );
  }

  Widget _buildPopularQuantitySelector() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: ColorResource.primaryDark,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: ColorResource.primaryDark.withValues(alpha: 0.24),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPopularQuantityButton(
            icon: Icons.remove,
            onTap: () => widget.onQuantityChanged?.call(false),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '${widget.cartQuantity}',
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: ColorResource.textWhite,
              ),
            ),
          ),
          _buildPopularQuantityButton(
            icon: Icons.add,
            onTap: () => widget.onQuantityChanged?.call(true),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 34,
        height: 44,
        child: Icon(icon, color: ColorResource.textWhite, size: 18),
      ),
    );
  }

  /// Build quantity selector [- Qty +]
  Widget _buildQuantitySelector() {
    return Container(
      height: 40,
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
          // Decrement button
          _buildQuantityButton(
            icon: Icons.remove,
            onTap: () => widget.onQuantityChanged?.call(false),
          ),

          // Quantity display
          Container(
            constraints: const BoxConstraints(minWidth: 30),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Text(
                '${widget.cartQuantity}',
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeDefault,
                  color: ColorResource.textWhite,
                ),
              ),
            ),
          ),

          // Increment button
          _buildQuantityButton(
            icon: Icons.add,
            onTap: () => widget.onQuantityChanged?.call(true),
          ),
        ],
      ),
    );
  }

  /// Build individual quantity button (+ or -)
  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: ColorResource.textWhite, size: 18),
      ),
    );
  }
}
