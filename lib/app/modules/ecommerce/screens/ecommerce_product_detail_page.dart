import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:appwrite_user_app/app/common/widgets/favorite_button.dart';
import 'package:appwrite_user_app/app/common/widgets/rating_stars.dart';
import 'package:appwrite_user_app/app/controllers/auth_controller.dart';
import 'package:appwrite_user_app/app/controllers/brand_controller.dart';
import 'package:appwrite_user_app/app/controllers/cart_controller.dart';
import 'package:appwrite_user_app/app/helper/cart_helper.dart';
import 'package:appwrite_user_app/app/helper/localization_extension_helper.dart';
import 'package:appwrite_user_app/app/helper/price_helper.dart';
import 'package:appwrite_user_app/app/models/cart_item_model.dart';
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

  // Inline variant selection state. radio -> VariantOption, checkbox -> List.
  final Map<String, dynamic> _selectedVariants = {};
  final Map<String, GlobalKey> _variantKeys = {};
  String? _highlightedVariantTitle;
  int _qty = 1;
  bool _isAddingToCart = false;

  ProductModel get product => widget.product;

  bool get _hasVariants => product.variants.isNotEmpty;

  /// Per-unit price = discounted base price + the additions of every selected
  /// variant option (radio adds one, checkbox adds each chosen option).
  double get _unitPrice {
    double extra = 0;
    for (final variant in product.variants) {
      final selection = _selectedVariants[variant.title];
      if (selection == null) continue;
      if (variant.type == 'radio') {
        extra += (selection as VariantOption).price;
      } else {
        for (final option in (selection as List<VariantOption>)) {
          extra += option.price;
        }
      }
    }
    return product.finalPrice + extra;
  }

  double get _totalPrice => _unitPrice * _qty;

  /// The first required group still missing a choice, or null when satisfied.
  VariantGroup? _firstUnselectedRequiredVariant() {
    for (final variant in product.variants) {
      if (variant.required && !_selectedVariants.containsKey(variant.title)) {
        return variant;
      }
    }
    return null;
  }

  /// Flattens the in-memory selection map into the cart's variant model.
  List<SelectedVariant> _buildSelectedVariants() {
    final result = <SelectedVariant>[];
    for (final variant in product.variants) {
      if (!_selectedVariants.containsKey(variant.title)) continue;
      final selections = <VariantSelection>[];
      if (variant.type == 'radio') {
        final option = _selectedVariants[variant.title] as VariantOption?;
        if (option != null) {
          selections.add(
            VariantSelection(optionName: option.name, optionPrice: option.price),
          );
        }
      } else {
        for (final option
            in (_selectedVariants[variant.title] as List<VariantOption>)) {
          selections.add(
            VariantSelection(optionName: option.name, optionPrice: option.price),
          );
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
    return result;
  }

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
    return Scaffold(
      backgroundColor: ColorResource.scaffoldBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(child: _buildContent()),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  /// Collapsing image header. Expanded it shows the swipeable gallery; once
  /// scrolled past it pins to a compact bar carrying the product name.
  Widget _buildSliverAppBar(BuildContext context) {
    const double expandedHeight = 340;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      elevation: 0,
      backgroundColor: ColorResource.cardBackground,
      surfaceTintColor: ColorResource.cardBackground,
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: _circleButton(
          icon: Icons.arrow_back,
          onTap: () => Get.back(),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _circleButton(child: FavoriteButton(product: product, size: 22)),
        ),
      ],
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final double appBarHeight = constraints.maxHeight;
          final double statusBarHeight = MediaQuery.of(context).padding.top;
          final double minHeight = kToolbarHeight + statusBarHeight;
          final double collapseRatio =
              ((appBarHeight - minHeight) / (expandedHeight - minHeight))
                  .clamp(0.0, 1.0);
          final bool isCollapsed = collapseRatio < 0.1;

          return FlexibleSpaceBar(
            centerTitle: false,
            titlePadding: const EdgeInsetsDirectional.only(
              start: 56,
              end: 56,
              bottom: 16,
            ),
            title: isCollapsed
                ? Text(
                    product.nameMap.trLanguage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeLarge,
                      color: ColorResource.textPrimary,
                    ),
                  )
                : null,
            background: _buildGallery(),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    final hasDiscount = product.hasDiscount;
    final description = product.descriptionMap.trLanguage.trim();

    return Padding(
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
          if (_hasVariants) _buildVariantsSection(),
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
                onTap: () => setState(() => _descExpanded = !_descExpanded),
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
            Divider(color: ColorResource.textLight.withValues(alpha: 0.2)),
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
    );
  }

  Widget _circleButton({IconData? icon, VoidCallback? onTap, Widget? child}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ColorResource.cardBackground.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: child ??
            Icon(icon, size: 20, color: ColorResource.textPrimary),
      ),
    );
  }

  Widget _buildGallery() {
    final images = _images;
    return Stack(
      fit: StackFit.expand,
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
        // Subtle top scrim so the back/favorite buttons stay legible over
        // bright product images.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 110,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        if (images.length > 1)
          Positioned(
            bottom: 16,
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
                        : ColorResource.cardBackground.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
      ],
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

  Widget _buildVariantsSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
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
                    color: ColorResource.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: ColorResource.primaryDark.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${product.variants.length} ${'groups'.tr}',
                  style: poppinsMedium.copyWith(
                    fontSize: Constants.fontSizeExtraSmall,
                    color: ColorResource.primaryDark,
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
              color: ColorResource.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ...product.variants.map(_buildVariantGroup),
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
      margin: const EdgeInsets.only(bottom: 18),
      padding: EdgeInsets.all(isHighlighted ? 12 : 0),
      decoration: BoxDecoration(
        color: isHighlighted
            ? ColorResource.primaryDark.withValues(alpha: 0.04)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHighlighted
              ? ColorResource.primaryDark
              : Colors.transparent,
          width: isHighlighted ? 1.5 : 0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row: "Size" with a Required marker, helper text on the right.
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                variant.title,
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeDefault,
                  color: ColorResource.textPrimary,
                ),
              ),
              if (variant.required)
                Text(
                  ' *',
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeDefault,
                    color: ColorResource.error,
                  ),
                ),
              const Spacer(),
              Text(
                variant.required
                    ? 'select_one_option'.tr
                    : 'optional'.tr,
                style: poppinsRegular.copyWith(
                  fontSize: Constants.fontSizeExtraSmall,
                  color: ColorResource.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Options as selectable chips.
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: variant.options
                .map((option) => _buildOptionChip(variant, option))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionChip(VariantGroup variant, VariantOption option) {
    final isRadio = variant.type == 'radio';
    final bool isSelected;
    if (isRadio) {
      isSelected = _selectedVariants[variant.title] == option;
    } else {
      final selected =
          (_selectedVariants[variant.title] as List<VariantOption>?) ?? [];
      isSelected = selected.contains(option);
    }

    return GestureDetector(
      onTap: () => _onOptionTap(variant, option, isRadio: isRadio),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorResource.primaryDark
              : ColorResource.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? ColorResource.primaryDark
                : ColorResource.textLight.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              option.name,
              style: poppinsMedium.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: isSelected
                    ? ColorResource.textWhite
                    : ColorResource.textPrimary,
              ),
            ),
            if (option.price > 0) ...[
              const SizedBox(width: 6),
              Text(
                '+${PriceHelper.formatPrice(option.price)}',
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeSmall,
                  color: isSelected
                      ? ColorResource.textWhite.withValues(alpha: 0.9)
                      : ColorResource.primaryDark,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _onOptionTap(
    VariantGroup variant,
    VariantOption option, {
    required bool isRadio,
  }) {
    setState(() {
      if (isRadio) {
        _selectedVariants[variant.title] = option;
      } else {
        final selected =
            (_selectedVariants[variant.title] as List<VariantOption>?) ??
                <VariantOption>[];
        if (selected.contains(option)) {
          selected.remove(option);
          if (selected.isEmpty) {
            _selectedVariants.remove(variant.title);
          } else {
            _selectedVariants[variant.title] = selected;
          }
        } else {
          _selectedVariants[variant.title] = [...selected, option];
        }
      }
      // Clear the guidance highlight once the required choice is satisfied.
      if (_highlightedVariantTitle == variant.title &&
          _selectedVariants.containsKey(variant.title)) {
        _highlightedVariantTitle = null;
      }
    });
  }

  /// Scrolls to and pulses the given required group when the user tries to add
  /// without choosing it.
  void _guideToRequiredVariant(String title) {
    final ctx = _variantKeys[title]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
    setState(() => _highlightedVariantTitle = title);
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted && _highlightedVariantTitle == title) {
        setState(() => _highlightedVariantTitle = null);
      }
    });
  }

  Future<void> _addVariantProductToCart() async {
    final missing = _firstUnselectedRequiredVariant();
    if (missing != null) {
      _guideToRequiredVariant(missing.title);
      customToster('please_select_required_options'.tr, isSuccess: false);
      return;
    }

    setState(() => _isAddingToCart = true);
    try {
      final userId = await Get.find<AuthController>().getUserId();
      final cartItem = CartItemModel(
        id: '',
        userId: userId ?? '',
        productId: product.id,
        productName: product.nameMap.trLanguage,
        productImage: product.imageId,
        basePrice: product.price,
        discountType: product.discountType,
        discountValue: product.discountValue,
        finalPrice: product.finalPrice,
        selectedVariants: _buildSelectedVariants(),
        quantity: _qty,
        itemTotal: _totalPrice,
        moduleType: product.moduleType,
      );
      await Get.find<CartController>().addToCart(cartItem);
      if (!mounted) return;
      customToster('added_to_cart'.tr, isSuccess: true);
    } catch (_) {
      // addToCart surfaces its own stock/identical messages.
    } finally {
      if (mounted) setState(() => _isAddingToCart = false);
    }
  }

  /// Bottom bar for variant products: live total + quantity stepper + add.
  Widget _buildVariantBottomBar() {
    final maxQty = product.stock;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'total'.tr,
                    style: poppinsRegular.copyWith(
                      fontSize: Constants.fontSizeSmall,
                      color: ColorResource.textSecondary,
                    ),
                  ),
                  Text(
                    PriceHelper.formatPrice(_totalPrice),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeOverLarge,
                      color: ColorResource.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
            // Quantity stepper.
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
                    _qty > 1 ? () => setState(() => _qty--) : null,
                  ),
                  SizedBox(
                    width: 36,
                    child: Center(
                      child: Text(
                        '$_qty',
                        style: poppinsBold.copyWith(
                          fontSize: Constants.fontSizeLarge,
                          color: ColorResource.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  _qtyButton(
                    Icons.add,
                    _qty < maxQty ? () => setState(() => _qty++) : null,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isAddingToCart ? null : _addVariantProductToCart,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorResource.primaryDark,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Constants.radiusLarge),
              ),
            ),
            icon: _isAddingToCart
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: ColorResource.textWhite,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Icon(
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
        ),
      ],
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
            // Products with variants are configured inline above, so the bar
            // shows the live total, a quantity stepper, and a direct add.
            if (_hasVariants) {
              return _buildVariantBottomBar();
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

  Widget _qtyButton(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(
          icon,
          size: 18,
          color: onTap == null
              ? ColorResource.textLight
              : ColorResource.primaryDark,
        ),
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
