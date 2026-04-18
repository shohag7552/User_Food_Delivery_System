import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:appwrite_user_app/app/common/widgets/rating_stars.dart';
import 'package:appwrite_user_app/app/controllers/auth_controller.dart';
import 'package:appwrite_user_app/app/controllers/cart_animation_controller.dart';
import 'package:appwrite_user_app/app/helper/localization_extension_helper.dart';
import 'package:appwrite_user_app/app/helper/price_helper.dart';
import 'package:appwrite_user_app/app/models/product_model.dart';
import 'package:appwrite_user_app/app/models/cart_item_model.dart';
import 'package:appwrite_user_app/app/controllers/cart_controller.dart';
import 'package:appwrite_user_app/app/modules/cart/screens/cart_page.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/full_screen_image_viewer.dart';
import 'package:appwrite_user_app/app/modules/reviews/widgets/review_list_section.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProductDetailBottomSheet extends StatefulWidget {
  final ProductModel product;
  final CartItemModel? cartItem; // Add cartItem to constructor

  const ProductDetailBottomSheet({
    super.key,
    required this.product,
    this.cartItem,
  });

  @override
  State<ProductDetailBottomSheet> createState() =>
      _ProductDetailBottomSheetState();

  static void show(BuildContext context, ProductModel product, {CartItemModel? cartItem}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductDetailBottomSheet(
        product: product, 
        cartItem: cartItem,
      ),
    );
  }
}

class _ProductDetailBottomSheetState extends State<ProductDetailBottomSheet>
    with SingleTickerProviderStateMixin {
  int _quantity = 1;
  final Map<String, dynamic> _selectedVariants = {};
  bool _isAddingToCart = false;
  CartItemModel? _matchingCartItem; // ADDED THIS LINE

  String get _productDescription =>
      widget.product.descriptionMap.trLanguage.trim();

  // int get _selectedVariantCount {
  //   int count = 0;
  //   for (final variant in widget.product.variants) {
  //     if (!_selectedVariants.containsKey(variant.title)) continue;

  //     if (variant.type == 'radio') {
  //       if (_selectedVariants[variant.title] != null) {
  //         count++;
  //       }
  //     } else {
  //       final options = _selectedVariants[variant.title] as List<VariantOption>?;
  //       count += options?.length ?? 0;
  //     }
  //   }
  //   return count;
  // }

  String get _imageHeroTag => 'product-image-${widget.product.id}';

  @override
  void initState() {
    super.initState();

    // Initialize with existing cart item data if available
    if (widget.cartItem != null) {
      _quantity = widget.cartItem!.quantity;
      for (var variant in widget.cartItem!.selectedVariants) {
        // Find matching variant group in product
        var productVariant = widget.product.variants.firstWhereOrNull((v) => v.title == variant.groupTitle);
        if (productVariant != null) {
          if (productVariant.type == 'radio') {
            if (variant.selections.isNotEmpty) {
              var sel = variant.selections.first;
              var matchingOption = productVariant.options.firstWhereOrNull((opt) => opt.name == sel.optionName);
              if (matchingOption != null) {
                _selectedVariants[variant.groupTitle] = matchingOption;
              }
            }
          } else {
            List<VariantOption> options = [];
            for (var sel in variant.selections) {
              var matchingOption = productVariant.options.firstWhereOrNull((opt) => opt.name == sel.optionName);
              if (matchingOption != null) {
                options.add(matchingOption);
              }
            }
            if (options.isNotEmpty) {
              _selectedVariants[variant.groupTitle] = options;
            }
          }
        }
      }
    }

    // Call check to see if we match an item in cart
    _checkExistingCartItem();
  }

  void _checkExistingCartItem() {
    final cartController = Get.find<CartController>();
    final currentSelectedVariants = _buildSelectedVariants();

    // Check if what we currently have configured matches anything in the cart
    final index = cartController.cartItems.indexWhere((existing) =>
        existing.productId == widget.product.id &&
        cartController.areVariantsIdentical(
            existing.selectedVariants, currentSelectedVariants));

    setState(() {
      if (index != -1) {
        _matchingCartItem = cartController.cartItems[index];
        // If it's a new match (user manually changed options to match an existing item), 
        // we might want to sync the quantity, but to avoid confusing jumps, 
        // we'll only sync quantity if we just opened the bottomsheet, 
        // or let the user increase exactly what they want to add.
        // Actually, for UPDATE we want to show the current total quantity.
        _quantity = _matchingCartItem!.quantity; 
      } else {
        _matchingCartItem = null;
        // If we unmatched, we might want to reset quantity to 1 for a "new" item.
        if (widget.cartItem == null) {
          _quantity = 1;
        }
      }
    });
  }

  double get _totalPrice {
    double basePrice = widget.product.finalPrice;
    double variantPrice = 0.0;

    // Add variant prices
    for (var variant in widget.product.variants) {
      if (_selectedVariants.containsKey(variant.title)) {
        if (variant.type == 'radio') {
          // Single selection
          VariantOption? selectedOption = _selectedVariants[variant.title];
          if (selectedOption != null) {
            variantPrice += selectedOption.price;
          }
        } else {
          // Multiple selection (checkbox)
          List<VariantOption> selectedOptions = _selectedVariants[variant.title] ?? [];
          for (var option in selectedOptions) {
            variantPrice += option.price;
          }
        }
      }
    }

    return (basePrice + variantPrice) * _quantity;
  }

  bool get _canAddToCart {
    // Block if out of stock
    if (widget.product.isOutOfStock) return false;
    // Check if all required variants are selected
    for (var variant in widget.product.variants) {
      if (variant.required && !_selectedVariants.containsKey(variant.title)) {
        return false;
      }
    }
    return true;
  }

  List<SelectedVariant> _buildSelectedVariants() {
    List<SelectedVariant> result = [];
    
    for (var variant in widget.product.variants) {
      if (_selectedVariants.containsKey(variant.title)) {
        List<VariantSelection> selections = [];
        
        if (variant.type == 'radio') {
          VariantOption? option = _selectedVariants[variant.title];
          if (option != null) {
            selections.add(VariantSelection(
              optionName: option.name,
              optionPrice: option.price,
            ));
          }
        } else {
          List<VariantOption> options = _selectedVariants[variant.title] ?? [];
          for (var option in options) {
            selections.add(VariantSelection(
              optionName: option.name,
              optionPrice: option.price,
            ));
          }
        }
        
        if (selections.isNotEmpty) {
          result.add(SelectedVariant(
            groupTitle: variant.title,
            groupType: variant.type,
            selections: selections,
          ));
        }
      }
    }
    
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.45,
        maxChildSize: 0.9,
        expand: false,
        builder: (BuildContext context, ScrollController scrollController) {
       return Container(
         decoration: BoxDecoration(
           color: ColorResource.cardBackground,
           borderRadius: const BorderRadius.only(
             topLeft: Radius.circular(Constants.radiusExtraLarge),
             topRight: Radius.circular(Constants.radiusExtraLarge),
           ),
         ),
         child: Column(
           mainAxisSize: MainAxisSize.min,
           children: [

             // Scrollable content
             Expanded(
               child: SingleChildScrollView(
                 controller: scrollController,
                 padding: const EdgeInsets.all(0),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     // Product Image with badges
                     _buildProductImage(),

                     // Product Details
                     Padding(
                       padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           _buildProductInfo(),
                           const SizedBox(height: Constants.paddingSizeDefault),

                           // Variants
                           if (widget.product.variants.isNotEmpty) ...[
                             _buildVariantsSection(),
                             const SizedBox(height: Constants.paddingSizeDefault),
                           ],

                            // Divider
                            Divider(
                              color: ColorResource.textLight.withValues(alpha: 0.2),
                              thickness: 1,
                            ),
                            const SizedBox(height: 18),

                            // Reviews Section
                            _buildReviewsSection(),
                            const SizedBox(height: 50), // Space for bottom button
                         ],
                       ),
                     ),
                   ],
                 ),
               ),
             ),

             // Fixed bottom: Add to Cart button
             _buildAddToCartButton(context),
           ],
         ),
       );
      }
    );
  }

  Widget _buildProductImage() {
    final hasDiscount = widget.product.hasDiscount;
    final discountPercentage = hasDiscount
        ? ((widget.product.price - widget.product.finalPrice) /
                    widget.product.price *
                    100)
                .toStringAsFixed(0)
        : null;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FullScreenImageViewer(
              imageUrl: widget.product.imageId,
              heroTag: _imageHeroTag,
            ),
          ),
        );
      },
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(Constants.radiusExtraLarge),
              topRight: Radius.circular(Constants.radiusExtraLarge),
            ),
            child: Hero(
              tag: _imageHeroTag,
              child: CustomNetworkImage(
                image: widget.product.imageId,
                height: 200,
                width: double.infinity,
              ),
            ),
          ),
      
          // Gradient overlay
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(Constants.radiusExtraLarge),
                topRight: Radius.circular(Constants.radiusExtraLarge),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),
      
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ColorResource.textWhite.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      
          if (widget.product.isOutOfStock)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(Constants.radiusExtraLarge),
                  topRight: Radius.circular(Constants.radiusExtraLarge),
                ),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.55),
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: ColorResource.error.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(Constants.radiusDefault),
                    ),
                    child: Text(
                      'OUT OF STOCK',
                      style: poppinsBold.copyWith(
                        fontSize: Constants.fontSizeDefault,
                        color: ColorResource.textWhite,
                      ),
                    ),
                  ),
                ),
              ),
            ),
      
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    hasDiscount ? _buildInfoChip(
                      color: ColorResource.error,
                      label: '$discountPercentage% OFF',
                      icon: null,
                    ) : const SizedBox(),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: ColorResource.textWhite.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: ColorResource.textWhite.withValues(alpha: 0.24),
                        ),
                      ),
                      child: Text(
                        widget.product.isOutOfStock
                            ? 'Unavailable'
                            : '${widget.product.stock} in stock',
                        style: poppinsMedium.copyWith(
                          fontSize: Constants.fontSizeSmall,
                          color: ColorResource.textWhite,
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
    );
  }

  Widget _buildProductInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Constants.paddingSizeSmall, vertical: Constants.paddingSizeDefault),
      decoration: BoxDecoration(
        color: ColorResource.scaffoldBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ColorResource.textLight.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.product.nameMap.trLanguage,
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeLarge,
            height: 1.2,
            color: ColorResource.textPrimary,
          ),
        ),
        const SizedBox(height: Constants.paddingSizeSmall),

        RatingStars(
          rating: widget.product.avgRating,
          reviewCount: widget.product.ratingCount,
          size: 14,
          showRating: true,
        ),
        const SizedBox(height: Constants.paddingSizeSmall),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildInfoChip(
              icon: null,
              color: ColorResource.primarySwatch,
              label: widget.product.isVeg ? 'VEG' : 'NON-VEG',
            ),
          ],
        ),
        const SizedBox(height: Constants.paddingSizeSmall),

        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              PriceHelper.formatPrice(widget.product.finalPrice),
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeExtraLarge,
                color: Theme.of(context).textTheme.bodyLarge!.color,
              ),
            ),
            if (widget.product.hasDiscount) ...[
              const SizedBox(width: 8),
              Text(
                PriceHelper.formatPrice(widget.product.price),
                style: poppinsRegular.copyWith(
                  fontSize: Constants.fontSizeDefault,
                  color: ColorResource.textLight,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
            const Spacer(),
            if (widget.product.hasDiscount)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: ColorResource.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Save ${PriceHelper.formatPrice(widget.product.price - widget.product.finalPrice)}',
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeExtraSmall,
                    color: ColorResource.success,
                  ),
                ),
              ),
          ],
        ),
        if (_productDescription.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            _productDescription,
            style: poppinsRegular.copyWith(
              fontSize: Constants.fontSizeSmall,
              color: ColorResource.textSecondary,
            ),
          ),
        ],
      ],
    ),
    );
  }

  Widget _buildVariantsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorResource.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ColorResource.textLight.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Customize your order',
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeLarge,
                  color: ColorResource.textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: ColorResource.primarySwatch.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${widget.product.variants.length} groups',
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeExtraSmall,
                  color: ColorResource.primarySwatch,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Choose your preferred options to build the perfect order.',
          style: poppinsRegular.copyWith(
            fontSize: Constants.fontSizeSmall,
            color: ColorResource.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        ...widget.product.variants.map((variant) {
          return Padding(
            padding: const EdgeInsets.only(bottom: Constants.paddingSizeSmall),
            child: _buildVariantGroup(variant),
          );
        }),
      ],
    ),
    );
  }

  Widget _buildVariantGroup(VariantGroup variant) {
    return Container(
      padding: const EdgeInsets.all(Constants.paddingSizeSmall),
      decoration: BoxDecoration(
        color: ColorResource.scaffoldBackground.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                variant.title,
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeDefault,
                  color: ColorResource.textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: variant.required
                    ? ColorResource.error.withValues(alpha: 0.08)
                    : ColorResource.primaryDark.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                variant.required ? 'Required' : 'Optional',
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeExtraSmall,
                  color: variant.required
                      ? ColorResource.error
                      : ColorResource.primaryDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          variant.type == 'radio'
              ? 'Select one option'
              : 'Select one or more options',
          style: poppinsRegular.copyWith(
            fontSize: Constants.fontSizeExtraSmall,
            color: ColorResource.textSecondary,
          ),
        ),
        const SizedBox(height: 10),

        ...variant.options.map((option) {
          if (variant.type == 'radio') {
            return _buildRadioOption(variant, option);
          } else {
            return _buildCheckboxOption(variant, option);
          }
        }),
      ],
    ),
    );
  }

  Widget _buildRadioOption(VariantGroup variant, VariantOption option) {
    final isSelected = _selectedVariants[variant.title] == option;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedVariants[variant.title] = option;
        });
        _checkExistingCartItem(); // Add check here
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.green.withValues(alpha: 0.05)
              : ColorResource.scaffoldBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.green
                : ColorResource.textLight.withValues(alpha: 0.2),
            width: isSelected ? .7 : 0.5,
          ),
        ),
        child: Row(
          children: [
            // Radio button
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? ColorResource.primaryDark
                      : ColorResource.textLight,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ColorResource.primaryDark,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.name,
                    style: poppinsMedium.copyWith(
                      fontSize: Constants.fontSizeDefault,
                      color: ColorResource.textPrimary,
                    ),
                  ),
                  if (option.price <= 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Included at no extra cost',
                        style: poppinsRegular.copyWith(
                          fontSize: Constants.fontSizeExtraSmall,
                          color: ColorResource.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            if (option.price > 0)
              Text(
                '+${PriceHelper.formatPrice(option.price)}',
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeSmall,
                  color: ColorResource.primarySwatch,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxOption(VariantGroup variant, VariantOption option) {
    List<VariantOption> selectedOptions =
        _selectedVariants[variant.title] ?? [];
    final isSelected = selectedOptions.contains(option);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedOptions.remove(option);
            if (selectedOptions.isEmpty) {
              _selectedVariants.remove(variant.title);
            }
          } else {
            // For checkbox, add to list
            if (!_selectedVariants.containsKey(variant.title)) {
              _selectedVariants[variant.title] = <VariantOption>[];
            }
            (_selectedVariants[variant.title] as List<VariantOption>).add(option);
          }
        });
        _checkExistingCartItem(); // Add check here
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorResource.primaryDark.withValues(alpha: 0.08)
              : ColorResource.scaffoldBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? ColorResource.primaryDark
                : ColorResource.textLight.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected
                      ? ColorResource.primaryDark
                      : ColorResource.textLight,
                  width: 2,
                ),
                color: isSelected ? ColorResource.primaryDark : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: ColorResource.textWhite,
                      size: 14,
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.name,
                    style: poppinsMedium.copyWith(
                      fontSize: Constants.fontSizeDefault,
                      color: ColorResource.textPrimary,
                    ),
                  ),
                  if (option.price <= 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Included at no extra cost',
                        style: poppinsRegular.copyWith(
                          fontSize: Constants.fontSizeExtraSmall,
                          color: ColorResource.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            if (option.price > 0)
              Text(
                '+${PriceHelper.formatPrice(option.price)}',
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeSmall,
                  color: ColorResource.primaryDark,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled
              ? ColorResource.primaryDark
              : ColorResource.textLight.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: enabled ? ColorResource.textWhite : ColorResource.textLight,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildAddToCartButton(BuildContext context) {
    final bool outOfStock = widget.product.isOutOfStock;
    final bool isUpdate = _matchingCartItem != null || widget.cartItem != null;
    final screenSize = MediaQuery.of(context).size;
    final int maxQty = widget.product.stock;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
              decoration: BoxDecoration(
                color: ColorResource.scaffoldBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Total: ${PriceHelper.formatPrice(_totalPrice)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: poppinsBold.copyWith(
                        fontSize: Constants.fontSizeLarge,
                        color: ColorResource.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildFooterQuantityStepper(
                    outOfStock: outOfStock,
                    maxQty: maxQty,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: (_canAddToCart && !_isAddingToCart)
                  ? () async {
                      setState(() {
                        _isAddingToCart = true;
                      });

                      try {
                        String? userId = await Get.find<AuthController>().getUserId();
                        if (_matchingCartItem != null || widget.cartItem != null) {
                          final itemToUpdate = _matchingCartItem ?? widget.cartItem!;

                          final updatedCartItem = itemToUpdate.copyWith(
                            selectedVariants: _buildSelectedVariants(),
                            quantity: _quantity,
                            itemTotal: _totalPrice,
                          );
                          await Get.find<CartController>().updateCartItemDetails(updatedCartItem);
                        } else {
                          final cartItem = CartItemModel(
                            id: '',
                            userId: userId ?? '',
                            productId: widget.product.id,
                            productName: widget.product.nameMap.trLanguage,
                            productImage: widget.product.imageId,
                            basePrice: widget.product.price,
                            discountType: widget.product.discountType,
                            discountValue: widget.product.discountValue,
                            finalPrice: widget.product.finalPrice,
                            selectedVariants: _buildSelectedVariants(),
                            quantity: _quantity,
                            itemTotal: _totalPrice,
                          );

                          await Get.find<CartController>().addToCart(cartItem);
                        }

                        if (!mounted) return;

                        setState(() {
                          _isAddingToCart = false;
                        });

                        if (_matchingCartItem == null && widget.cartItem == null) {
                          Future.delayed(const Duration(milliseconds: 100), () {
                            if (mounted) {
                              Get.find<CartAnimationController>().animateAddToCart(
                                context: this.context,
                                productImageUrl: widget.product.imageId,
                                buttonPosition: Offset(
                                  screenSize.width / 2,
                                  screenSize.height - 150,
                                ),
                              );
                            }
                          });
                        }

                        Get.back();

                        if (_matchingCartItem == null && widget.cartItem == null) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${widget.product.nameMap.trLanguage} added to cart!',
                                style: poppinsMedium.copyWith(
                                  color: ColorResource.textWhite,
                                  fontSize: Constants.fontSizeDefault,
                                ),
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 3),
                              action: SnackBarAction(
                                label: 'View Cart',
                                textColor: ColorResource.textWhite,
                                onPressed: () {
                                  Get.to(() => const CartPage());
                                },
                              ),
                            ),
                          );
                        } else {
                          customToster('${widget.product.nameMap.trLanguage} updated!');
                        }
                      } catch (e) {
                        if (mounted) {
                          setState(() {
                            _isAddingToCart = false;
                          });
                        }
                        Get.back();
                        customToster('Failed to add to cart');
                      }
                    }
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: outOfStock
                      ? LinearGradient(
                          colors: [
                            ColorResource.error.withValues(alpha: 0.78),
                            ColorResource.error.withValues(alpha: 0.78),
                          ],
                        )
                      : _canAddToCart
                          ? ColorResource.primaryGradient
                          : LinearGradient(
                              colors: [
                                ColorResource.textLight.withValues(alpha: 0.5),
                                ColorResource.textLight.withValues(alpha: 0.5),
                              ],
                            ),
                  borderRadius: BorderRadius.circular(Constants.radiusLarge),
                  boxShadow: (!outOfStock && _canAddToCart)
                      ? [
                          BoxShadow(
                            color: ColorResource.primaryMedium.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : [],
                ),
                child: _isAddingToCart
                    ? const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: ColorResource.textWhite,
                            strokeWidth: 3,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            outOfStock
                                ? Icons.remove_shopping_cart_outlined
                                : isUpdate
                                    ? Icons.edit_outlined
                                    : Icons.shopping_bag_outlined,
                            color: ColorResource.textWhite,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            outOfStock
                                ? 'Out of stock'
                                : isUpdate
                                    ? 'Update cart'
                                    : 'Add to cart',
                            style: poppinsBold.copyWith(
                              fontSize: Constants.fontSizeDefault,
                              color: ColorResource.textWhite,
                            ),
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

  Widget _buildFooterQuantityStepper({
    required bool outOfStock,
    required int maxQty,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: ColorResource.cardBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQuantityButton(
            icon: Icons.remove,
            onTap: () {
              if (_quantity > 1) {
                setState(() => _quantity--);
              }
            },
            enabled: !outOfStock && _quantity > 1,
          ),
          SizedBox(
            width: 34,
            child: Center(
              child: Text(
                outOfStock ? '0' : '$_quantity',
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeDefault,
                  color: outOfStock
                      ? ColorResource.textLight
                      : ColorResource.textPrimary,
                ),
              ),
            ),
          ),
          _buildQuantityButton(
            icon: Icons.add,
            onTap: () {
              if (_quantity < maxQty) {
                setState(() => _quantity++);
              }
            },
            enabled: !outOfStock && _quantity < maxQty,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    final authController = Get.find<AuthController>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorResource.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ColorResource.textLight.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customer reviews',
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeLarge,
            color: ColorResource.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'See what other customers are saying before you order.',
          style: poppinsRegular.copyWith(
            fontSize: Constants.fontSizeSmall,
            color: ColorResource.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<String?>(
          future: authController.getUserId(),
          builder: (context, snapshot) {
            final currentUserId = snapshot.data;
            return ReviewListSection(
              productId: widget.product.id,
              currentUserId: currentUserId,
            );
          },
        ),
      ],
    ),
    );
  }

  Widget _buildInfoChip({required IconData? icon, required String label, Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color ?? ColorResource.cardBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if(icon != null)...[
            Icon(icon, size: 16, color: ColorResource.primaryDark),
            const SizedBox(width: 6),
          ],
          
          Text(
            label,
            style: poppinsMedium.copyWith(
              fontSize: Constants.fontSizeExtraSmall,
              color: color != null ? Theme.of(context).cardColor : ColorResource.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
