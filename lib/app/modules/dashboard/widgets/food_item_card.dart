import 'package:appwrite_user_app/app/common/widgets/custom_clickable_widget.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/common/widgets/favorite_button.dart';
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
  final Function(bool isIncrement)? onQuantityChanged; // Callback for quantity changes

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
  });

  @override
  State<FoodItemCard> createState() => _FoodItemCardState();
}

class _FoodItemCardState extends State<FoodItemCard> {


  double get discountPercentage {
    if (widget.oldPrice != null && widget.oldPrice! > widget.price) {
      return ((widget.oldPrice! - widget.price) / widget.oldPrice!) * 100;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16, bottom: Constants.paddingSizeSmall),
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
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(Constants.radiusLarge),
                        topRight: Radius.circular(Constants.radiusLarge),
                      ),
                      child: CustomNetworkImage(image: widget.imageUrl, height: 160, width: double.infinity),
                    ),
                    // Discount badge
                    if (discountPercentage > 0)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: ColorResource.discountBadge,
                            borderRadius: BorderRadius.circular(
                              Constants.radiusSmall,
                            ),
                          ),
                          child: Text(
                            '${discountPercentage.toStringAsFixed(0)}% OFF',
                            style: poppinsBold.copyWith(
                              fontSize: Constants.fontSizeSmall,
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
                    const SizedBox(height: 4),
                    // // Description
                    // Text(
                    //   widget.description,
                    //   style: poppinsRegular.copyWith(
                    //     fontSize: Constants.fontSizeSmall,
                    //     color: ColorResource.textSecondary,
                    //   ),
                    //   maxLines: 2,
                    //   overflow: TextOverflow.ellipsis,
                    // ),
                    // const SizedBox(height: 12),
                    // Price and add button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '\$${widget.price.toStringAsFixed(2)}',
                              style: poppinsBold.copyWith(
                                fontSize: Constants.fontSizeLarge,
                                color: ColorResource.primaryDark,
                              ),
                            ),
                            if (widget.oldPrice != null &&
                                widget.oldPrice! > widget.price)
                              Text(
                                '\$${widget.oldPrice!.toStringAsFixed(2)}',
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
              color: ColorResource.primaryMedium.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.add,
          color: ColorResource.textWhite,
          size: 20,
        ),
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
            color: ColorResource.primaryMedium.withOpacity(0.4),
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
        child: Icon(
          icon,
          color: ColorResource.textWhite,
          size: 18,
        ),
      ),
    );
  }
}
