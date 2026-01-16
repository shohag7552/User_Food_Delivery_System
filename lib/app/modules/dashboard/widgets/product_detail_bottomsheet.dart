import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/models/product_model.dart';
import 'package:appwrite_user_app/app/models/cart_item_model.dart';
import 'package:appwrite_user_app/app/controllers/cart_controller.dart';
import 'package:appwrite_user_app/app/modules/cart/screens/cart_page.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProductDetailBottomSheet extends StatefulWidget {
  final ProductModel product;

  const ProductDetailBottomSheet({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailBottomSheet> createState() =>
      _ProductDetailBottomSheetState();

  static void show(BuildContext context, ProductModel product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductDetailBottomSheet(product: product),
    );
  }
}

class _ProductDetailBottomSheetState extends State<ProductDetailBottomSheet>
    with SingleTickerProviderStateMixin {
  int _quantity = 1;
  final Map<String, dynamic> _selectedVariants = {};
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
                       padding: const EdgeInsets.all(20),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           _buildProductInfo(),
                           const SizedBox(height: 24),

                           // Variants
                           if (widget.product.variants.isNotEmpty) ...[
                             _buildVariantsSection(),
                             const SizedBox(height: 24),
                           ],

                           // Quantity Selector
                           _buildQuantitySelector(),
                           const SizedBox(height: 80), // Space for bottom button
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

    return Stack(
      children: [
        // Image
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(Constants.radiusExtraLarge),
            topRight: Radius.circular(Constants.radiusExtraLarge),
          ),
          child: CustomNetworkImage(
            image: widget.product.imageId,
            height: 200,
            width: double.infinity,
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

        // Drag handle
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: ColorResource.textLight.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        Positioned(
          top: 16,
          left: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Veg/Non-veg badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.product.isVeg
                      ? Colors.green
                      : ColorResource.error,
                  borderRadius: BorderRadius.circular(Constants.radiusSmall),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.product.isVeg
                          ? Icons.circle
                          : Icons.change_history,
                      color: ColorResource.textWhite,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.product.isVeg ? 'VEG' : 'NON-VEG',
                      style: poppinsBold.copyWith(
                        fontSize: Constants.fontSizeExtraSmall,
                        color: ColorResource.textWhite,
                      ),
                    ),
                  ],
                ),
              ),

              // Discount badge
              if (hasDiscount) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: ColorResource.discountBadge,
                    borderRadius: BorderRadius.circular(Constants.radiusSmall),
                  ),
                  child: Text(
                    '$discountPercentage% OFF',
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeSmall,
                      color: ColorResource.textWhite,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Name
        Text(
          widget.product.name,
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeExtraLarge + 4,
            color: ColorResource.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        // Price
        Row(
          children: [
            Text(
              '\$${widget.product.finalPrice.toStringAsFixed(2)}',
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeExtraLarge,
                color: ColorResource.primaryDark,
              ),
            ),
            if (widget.product.hasDiscount) ...[
              const SizedBox(width: 12),
              Text(
                '\$${widget.product.price.toStringAsFixed(2)}',
                style: poppinsRegular.copyWith(
                  fontSize: Constants.fontSizeDefault,
                  color: ColorResource.textLight,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 16),

        // Description
        Text(
          widget.product.description,
          style: poppinsRegular.copyWith(
            fontSize: Constants.fontSizeDefault,
            color: ColorResource.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildVariantsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customize Your Order',
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeLarge,
            color: ColorResource.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...widget.product.variants.map((variant) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _buildVariantGroup(variant),
          );
        }),
      ],
    );
  }

  Widget _buildVariantGroup(VariantGroup variant) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Variant title
        Row(
          children: [
            Text(
              variant.title,
              style: poppinsMedium.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: ColorResource.textPrimary,
              ),
            ),
            if (variant.required) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeDefault,
                  color: ColorResource.error,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),

        // Variant options
        ...variant.options.map((option) {
          if (variant.type == 'radio') {
            return _buildRadioOption(variant, option);
          } else {
            return _buildCheckboxOption(variant, option);
          }
        }),
      ],
    );
  }

  Widget _buildRadioOption(VariantGroup variant, VariantOption option) {
    final isSelected = _selectedVariants[variant.title] == option;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedVariants[variant.title] = option;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorResource.primaryDark.withValues(alpha: 0.1)
              : ColorResource.scaffoldBackground,
          borderRadius: BorderRadius.circular(Constants.radiusDefault),
          border: Border.all(
            color: isSelected
                ? ColorResource.primaryDark
                : ColorResource.textLight.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
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

            // Option name
            Expanded(
              child: Text(
                option.name,
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeDefault,
                  color: ColorResource.textPrimary,
                ),
              ),
            ),

            // Option price
            if (option.price > 0)
              Text(
                '+\$${option.price.toStringAsFixed(2)}',
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeDefault,
                  color: ColorResource.primaryDark,
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
            selectedOptions.add(option);
            _selectedVariants[variant.title] = selectedOptions;
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorResource.primaryDark.withOpacity(0.1)
              : ColorResource.scaffoldBackground,
          borderRadius: BorderRadius.circular(Constants.radiusDefault),
          border: Border.all(
            color: isSelected
                ? ColorResource.primaryDark
                : ColorResource.textLight.withOpacity(0.2),
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

            // Option name
            Expanded(
              child: Text(
                option.name,
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeDefault,
                  color: ColorResource.textPrimary,
                ),
              ),
            ),

            // Option price
            if (option.price > 0)
              Text(
                '+\$${option.price.toStringAsFixed(2)}',
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeDefault,
                  color: ColorResource.primaryDark,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quantity',
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeLarge,
            color: ColorResource.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: ColorResource.scaffoldBackground,
            borderRadius: BorderRadius.circular(Constants.radiusDefault),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Decrement button
              _buildQuantityButton(
                icon: Icons.remove,
                onTap: () {
                  if (_quantity > 1) {
                    setState(() => _quantity--);
                  }
                },
                enabled: _quantity > 1,
              ),

              // Quantity display
              Container(
                width: 60,
                alignment: Alignment.center,
                child: Text(
                  '$_quantity',
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeExtraLarge,
                    color: ColorResource.textPrimary,
                  ),
                ),
              ),

              // Increment button
              _buildQuantityButton(
                icon: Icons.add,
                onTap: () => setState(() => _quantity++),
                enabled: true,
              ),
            ],
          ),
        ),
      ],
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: enabled
              ? ColorResource.primaryDark
              : ColorResource.textLight.withOpacity(0.2),
          borderRadius: BorderRadius.circular(Constants.radiusDefault),
        ),
        child: Icon(
          icon,
          color: enabled ? ColorResource.textWhite : ColorResource.textLight,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildAddToCartButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        child: GestureDetector(
          onTap: _canAddToCart
              ? () async {
                  try {
                    // Create cart item
                    final cartItem = CartItemModel(
                      id: '', // Will be set by database
                      userId: 'user_001', // TODO: Get from auth controller
                      productId: widget.product.id,
                      productName: widget.product.name,
                      productImage: widget.product.imageId,
                      basePrice: widget.product.price,
                      discountType: widget.product.discountType,
                      discountValue: widget.product.discountValue,
                      finalPrice: widget.product.finalPrice,
                      selectedVariants: _buildSelectedVariants(),
                      quantity: _quantity,
                      itemTotal: _totalPrice,
                    );

                    // Add to cart
                    await Get.find<CartController>().addToCart(cartItem);
                    
                    Navigator.pop(context);
                    
                    // Show success with cart option
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${widget.product.name} added to cart!',
                          style: poppinsMedium.copyWith(
                            color: ColorResource.textWhite,
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
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to add to cart',
                          style: poppinsMedium.copyWith(
                            color: ColorResource.textWhite,
                          ),
                        ),
                        backgroundColor: ColorResource.error,
                      ),
                    );
                  }
                }
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: _canAddToCart
                  ? ColorResource.primaryGradient
                  : LinearGradient(
                      colors: [
                        ColorResource.textLight.withOpacity(0.5),
                        ColorResource.textLight.withOpacity(0.5),
                      ],
                    ),
              borderRadius: BorderRadius.circular(Constants.radiusLarge),
              boxShadow: _canAddToCart
                  ? [
                      BoxShadow(
                        color: ColorResource.primaryMedium.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart,
                  color: ColorResource.textWhite,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Add to Cart - \$${_totalPrice.toStringAsFixed(2)}',
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeLarge,
                    color: ColorResource.textWhite,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
