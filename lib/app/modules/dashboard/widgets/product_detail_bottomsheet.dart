import 'package:appwrite_user_app/app/common/widgets/auth_dialog.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/common/widgets/web_top_nav.dart';
import 'package:appwrite_user_app/app/helper/session_manager.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:appwrite_user_app/app/common/widgets/rating_stars.dart';
import 'package:appwrite_user_app/app/controllers/auth_controller.dart';
import 'package:appwrite_user_app/app/controllers/cart_animation_controller.dart';
import 'package:appwrite_user_app/app/helper/localization_extension_helper.dart';
import 'package:appwrite_user_app/app/helper/price_helper.dart';
import 'package:appwrite_user_app/app/models/product_model.dart';
import 'package:appwrite_user_app/app/models/cart_item_model.dart';
import 'package:appwrite_user_app/app/controllers/cart_controller.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/modules/reviews/widgets/review_list_section.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/images.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class ProductDetailBottomSheet extends StatefulWidget {
  final ProductModel product;
  final CartItemModel? cartItem; // Add cartItem to constructor

  /// Renders as a centered dialog body (desktop web) instead of a draggable
  /// bottom sheet. Set by [show]; don't pass manually.
  final bool isDialog;

  const ProductDetailBottomSheet({
    super.key,
    required this.product,
    this.cartItem,
    this.isDialog = false,
  });

  @override
  State<ProductDetailBottomSheet> createState() =>
      _ProductDetailBottomSheetState();

  static void show(BuildContext context, ProductModel product, {CartItemModel? cartItem}) {
    // Desktop web: product details open as a centered dialog — a bottom
    // sheet is a touch idiom. Mobile/tablet keep the draggable sheet.
    if (WebTopNav.isEnabled(context)) {
      showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.55),
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 480,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Constants.radiusExtraLarge),
              child: ProductDetailBottomSheet(
                product: product,
                cartItem: cartItem,
                isDialog: true,
              ),
            ),
          ),
        ),
      );
      return;
    }

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
  bool _isExpanded = false; // true when the sheet is dragged to full screen
  bool _isDescriptionExpanded = false; // "see more" / "see less" toggle

  // Required-variant guidance: scroll to + highlight the next required group
  // that the user still needs to choose before adding to cart.
  final Map<String, GlobalKey> _variantKeys = {};
  String? _highlightedVariantTitle;
  bool _isGuidingVariants = false;

  // Content-based sizing: the sheet opens only as tall as its content needs,
  // instead of always taking a fixed fraction of the screen.
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  final GlobalKey _sheetContentKey = GlobalKey();
  final GlobalKey _bottomBarKey = GlobalKey();
  static const double _minSheetSize = 0.4; // floor
  static const double _maxSheetSize = 0.95; // manual drag ceiling
  static const double _maxAutoSheetSize = 0.9; // auto-open ceiling
  static const double _initialSheetSize = 0.7;

  String get _productDescription =>
      widget.product.descriptionMap.trLanguage.trim();

  // Reviews section is only shown when the product actually has reviews.
  bool get _hasReviews => widget.product.ratingCount > 0;

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

  // The sheet keeps its rounded top corners at every height; the expanded
  // header bar reuses the same radius so it sits flush with the sheet edge.
  static const BorderRadius _sheetTopRadius = BorderRadius.only(
    topLeft: Radius.circular(Constants.radiusExtraLarge),
    topRight: Radius.circular(Constants.radiusExtraLarge),
  );

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

    // Once laid out, shrink the sheet to fit the actual content height.
    WidgetsBinding.instance.addPostFrameCallback((_) => _sizeSheetToContent());
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  /// Resizes the sheet so it's only as tall as the product's content (image,
  /// info, variants, reviews) plus the bottom bar — clamped so small products
  /// stay compact and rich ones never exceed the auto-open ceiling.
  void _sizeSheetToContent() {
    if (!mounted || !_sheetController.isAttached) return;

    final contentCtx = _sheetContentKey.currentContext;
    final screenHeight = MediaQuery.of(context).size.height;
    if (contentCtx == null || screenHeight <= 0) return;

    final contentHeight = contentCtx.size?.height ?? 0;
    final bottomBarHeight = _bottomBarKey.currentContext?.size?.height ?? 150;

    final desired = (contentHeight + bottomBarHeight) / screenHeight;
    final target = desired
        .clamp(_minSheetSize, _maxAutoSheetSize)
        .toDouble();

    if ((_sheetController.size - target).abs() > 0.01) {
      _sheetController.jumpTo(target);
    }
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
    return _firstUnselectedRequiredVariant() == null;
  }

  /// The first required variant group the user has not chosen yet, or null
  /// when every required group is satisfied.
  VariantGroup? _firstUnselectedRequiredVariant() {
    for (var variant in widget.product.variants) {
      if (variant.required && !_selectedVariants.containsKey(variant.title)) {
        return variant;
      }
    }
    return null;
  }

  /// Triggered from the "Add to cart" button when required choices are still
  /// missing: starts the guided flow at the first unselected required group.
  void _startVariantGuidance() {
    final next = _firstUnselectedRequiredVariant();
    if (next == null) return;
    _isGuidingVariants = true;
    _guideToVariant(next.title);
  }

  /// Called after any variant selection. While guiding, advance to the next
  /// unselected required group, or end the flow once all are chosen.
  void _advanceGuidanceIfNeeded() {
    if (!_isGuidingVariants) return;

    final next = _firstUnselectedRequiredVariant();
    if (next == null) {
      _isGuidingVariants = false;
      if (_highlightedVariantTitle != null) {
        setState(() => _highlightedVariantTitle = null);
      }
      return;
    }

    // Wait for the selection's layout change to settle before scrolling.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _guideToVariant(next.title);
    });
  }

  /// Scrolls the given variant group into view and pulses a highlight on it.
  void _guideToVariant(String title) {
    final ctx = _variantKeys[title]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
    _highlightVariant(title);
  }

  void _highlightVariant(String title) {
    setState(() => _highlightedVariantTitle = title);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      if (_highlightedVariantTitle == title) {
        setState(() => _highlightedVariantTitle = null);
      }
    });
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
    if (widget.isDialog) return _buildDialogBody(context);

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        // Considered "fully expanded" when the drag extent reaches the top.
        final expanded = notification.extent >= (notification.maxExtent - 0.01);
        if (expanded != _isExpanded) {
          setState(() => _isExpanded = expanded);
        }
        return false;
      },
      child: DraggableScrollableSheet(
        controller: _sheetController,
        initialChildSize: _initialSheetSize,
        minChildSize: _minSheetSize,
        maxChildSize: _maxSheetSize,
        expand: false,
        builder: (BuildContext context, ScrollController scrollController) {
          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: context.cardBackground,
                  borderRadius: _sheetTopRadius,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Scrollable content
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(0),
                        child: _buildSheetContent(),
                      ),
                    ),

                    // Fixed bottom: Add to Cart button
                    KeyedSubtree(
                      key: _bottomBarKey,
                      child: _buildAddToCartButton(context),
                    ),
                  ],
                ),
              ),

              // App-bar style header — fades in once the sheet is expanded.
              _buildHeaderBar(),
            ],
          );
        },
      ),
    );
  }

  /// Scrollable detail content — shared verbatim by the mobile draggable
  /// sheet and the desktop-web dialog.
  Widget _buildSheetContent() {
    return Column(
      key: _sheetContentKey,
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

              // Reviews Section — only when the product has reviews.
              if (_hasReviews) ...[
                Divider(
                  color: context.textLight.withValues(alpha: 0.2),
                  thickness: 1,
                ),
                const SizedBox(height: 18),
                _buildReviewsSection(),
              ],
              const SizedBox(height: 10), // Space for button
            ],
          ),
        ),
      ],
    );
  }

  /// Desktop-web dialog body: close-button header + scrollable content +
  /// the same pinned add-to-cart bar. No drag affordances — dialogs don't
  /// expand; they scroll.
  Widget _buildDialogBody(BuildContext context) {
    return Container(
      color: context.cardBackground,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: product name + close.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 10, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.product.nameMap.trLanguage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeLarge,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: context.scaffoldBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: context.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              child: _buildSheetContent(),
            ),
          ),
          KeyedSubtree(
            key: _bottomBarKey,
            child: _buildAddToCartButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: !_isExpanded,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _isExpanded ? 1 : 0,
          child: Container(
            decoration: BoxDecoration(
              color: context.cardBackground,
              borderRadius: _sheetTopRadius,
              boxShadow: [
                BoxShadow(
                  color: ColorResource.shadowLight,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 10, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle — signals the sheet can be dragged.
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.textLight.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.product.nameMap.trLanguage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: poppinsBold.copyWith(
                          fontSize: Constants.fontSizeLarge,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: context.scaffoldBackground,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.textLight.withValues(
                              alpha: 0.15,
                            ),
                          ),
                        ),
                        child: Icon(
                          Icons.close,
                          color: context.textPrimary,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    bool hasDiscount = widget.product.hasDiscount;
    String? discountPercentage = hasDiscount ? (widget.product.discountType == 'percentage'
        ? '${widget.product.discountValue?.toInt()}% OFF'
        : '${PriceHelper.formatPrice(widget.product.discountValue?.toDouble()??0)} OFF') : null;

    return GestureDetector(
      onTap: () {
        context.pushNamed(
          RouteNames.imageViewer,
          extra: ImageViewerArgs(
            imageUrl: widget.product.imageId,
            heroTag: _imageHeroTag,
          ),
        );
      },
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: _sheetTopRadius,
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
              borderRadius: _sheetTopRadius,
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
                borderRadius: _sheetTopRadius,
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
                      label: '$discountPercentage',
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
        color: context.scaffoldBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.textLight.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          children: [
            Text(
              widget.product.nameMap.trLanguage,
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeLarge,
                height: 1.2,
                color: context.textPrimary,
              ),
            ),
            widget.product.isVeg ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: Constants.paddingSizeSmall),
              child: Image.asset(Images.veg, height: 20, width: 20,),
            ) : const SizedBox(),
          ],
        ),
        const SizedBox(height: Constants.paddingSizeSmall),

        RatingStars(
          rating: widget.product.avgRating,
          reviewCount: widget.product.ratingCount,
          size: 14,
          showRating: true,
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
                  color: context.textLight,
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
          _buildDescription(),
        ],
      ],
    ),
    );
  }

  Widget _buildDescription() {
    final style = poppinsRegular.copyWith(
      fontSize: Constants.fontSizeSmall,
      color: context.textSecondary,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Measure whether the text needs more than 2 lines at this width.
        final textPainter = TextPainter(
          text: TextSpan(text: _productDescription, style: style),
          maxLines: 2,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);

        final isOverflowing = textPainter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _productDescription,
              style: style,
              maxLines: _isDescriptionExpanded ? null : 2,
              overflow: _isDescriptionExpanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
            ),
            if (isOverflowing) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => setState(
                  () => _isDescriptionExpanded = !_isDescriptionExpanded,
                ),
                child: Text(
                  _isDescriptionExpanded ? 'see_less'.tr : 'see_more'.tr,
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeSmall,
                    color: ColorResource.primaryDark,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildVariantsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.textLight.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'customize_your_order'.tr,
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeLarge,
                  color: context.textPrimary,
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
                '${widget.product.variants.length} ${'groups'.tr}',
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
          'choose_your_preferred_options_to_build_the_perfect_order'.tr,
          style: poppinsRegular.copyWith(
            fontSize: Constants.fontSizeSmall,
            color: context.textSecondary,
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
    final isHighlighted = _highlightedVariantTitle == variant.title;

    return AnimatedContainer(
      key: _variantKeys.putIfAbsent(variant.title, () => GlobalKey()),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(Constants.paddingSizeSmall),
      decoration: BoxDecoration(
        color: isHighlighted
            ? ColorResource.primaryDark.withValues(alpha: 0.06)
            : context.scaffoldBackground.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isHighlighted
              ? ColorResource.primaryDark
              : Colors.transparent,
          width: isHighlighted ? 1.5 : 0,
        ),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: ColorResource.primaryDark.withValues(alpha: 0.22),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : const [],
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
                  color: context.textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: variant.required
                    ? ColorResource.error.withValues(alpha: 0.08)
                    : Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                variant.required ? 'Required' : 'Optional',
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeExtraSmall,
                  color: variant.required
                      ? ColorResource.error
                      : Theme.of(context).textTheme.bodyLarge!.color,
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
            color: context.textSecondary,
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
        _advanceGuidanceIfNeeded();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.green.withValues(alpha: 0.05)
              : context.scaffoldBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.green
                : context.textLight.withValues(alpha: 0.2),
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
                      : context.textLight,
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
                      color: context.textPrimary,
                    ),
                  ),
                  if (option.price <= 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Included at no extra cost',
                        style: poppinsRegular.copyWith(
                          fontSize: Constants.fontSizeExtraSmall,
                          color: context.textSecondary,
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
        _advanceGuidanceIfNeeded();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.green.withValues(alpha: 0.05)
              : context.scaffoldBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.green
                : context.textLight.withValues(alpha: 0.2),
            width: isSelected ? .7 : 0.5,
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
                      : context.textLight,
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
                      color: context.textPrimary,
                    ),
                  ),
                  if (option.price <= 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Included at no extra cost',
                        style: poppinsRegular.copyWith(
                          fontSize: Constants.fontSizeExtraSmall,
                          color: context.textSecondary,
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
              : context.textLight.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: enabled ? ColorResource.textWhite : context.textLight,
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
        color: context.cardBackground,
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
                color: context.scaffoldBackground,
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
                        color: context.textPrimary,
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
              onTap: (outOfStock || _isAddingToCart)
                  ? null
                  : () async {
                      // Adding to cart requires an account — prompt guests.
                      if (!isUserLoggedIn()) {
                        AuthFlow.openLogin(context);
                        return;
                      }
                      if (!_canAddToCart) {
                        // Required choices still missing — guide the user to
                        // the next required variant instead of adding.
                        _startVariantGuidance();
                        return;
                      }
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

                        if (_matchingCartItem == null &&
                            widget.cartItem == null &&
                            CartAnimationController.isSupported) {
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

                        Navigator.pop(this.context);

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
                                  this.context.pushNamed(RouteNames.cart);
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
                        Navigator.pop(this.context);
                        customToster('Failed to add to cart');
                      }
                    },
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
                      : ColorResource.primaryGradient,
                  borderRadius: BorderRadius.circular(Constants.radiusLarge),
                  boxShadow: !outOfStock
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
        color: context.cardBackground,
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
                      ? context.textLight
                      : context.textPrimary,
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
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.textLight.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customer reviews',
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeLarge,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'See what other customers are saying before you order.',
          style: poppinsRegular.copyWith(
            fontSize: Constants.fontSizeSmall,
            color: context.textSecondary,
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
        color: color ?? context.cardBackground,
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
              color: color != null ? Theme.of(context).cardColor : context.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
