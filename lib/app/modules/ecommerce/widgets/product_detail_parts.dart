part of '../screens/ecommerce_product_detail_page.dart';

extension _ProductDetailParts on _EcommerceProductDetailPageState {
  /// Rebuilds [builder] against the header's collapse, handing it the shadow
  /// strength the floating buttons should currently paint with.
  Widget _collapseAware(Widget Function(double shadowOpacity) builder) {
    return ValueListenableBuilder<double>(
      valueListenable: _collapseProgress,
      builder: (context, progress, _) => builder(
        _EcommerceProductDetailPageState._headerButtonShadowOpacity(progress),
      ),
    );
  }

  /// [shadowOpacity] scales the drop shadow — 1 paints it in full, 0 drops it
  /// entirely. Defaults to 1, so the web gallery and dialog buttons that share
  /// this helper are unaffected.
  Widget _circleButton({
    IconData? icon,
    VoidCallback? onTap,
    Widget? child,
    double shadowOpacity = 1,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.cardBackground.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: shadowOpacity <= 0
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12 * shadowOpacity),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: child ?? Icon(icon, size: 20, color: context.textPrimary),
      ),
    );
  }

  /// Cart shortcut beside the favourite button: live item-count badge, opens
  /// the cart as a pushed page so back returns to this product. Mobile only —
  /// on web the top nav already carries the cart.
  Widget _cartButton({double shadowOpacity = 1}) {
    return GetBuilder<CartController>(
      builder: (cartController) {
        final itemCount = cartController.itemCount;
        return Tooltip(
          message: 'cart'.tr,
          child: _circleButton(
            shadowOpacity: shadowOpacity,
            onTap: () => context.pushNamed(RouteNames.cart),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 20,
                  color: context.textPrimary,
                ),
                if (itemCount > 0)
                  PositionedDirectional(
                    end: -9,
                    top: -9,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      decoration: BoxDecoration(
                        color: ColorResource.primaryDark,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.cardBackground,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          itemCount > 99 ? '99+' : '$itemCount',
                          style: poppinsBold.copyWith(
                            fontSize: 9,
                            color: ColorResource.textWhite,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Share control, styled as a twin of the favourite button beside it.
  ///
  /// [Builder] is not decoration: the share sheet needs the *button's* own
  /// context to anchor its popover on iPadOS, and the page's context would put
  /// that anchor in the wrong place.
  Widget _shareButton({double shadowOpacity = 1}) {
    return Builder(
      builder: (buttonContext) => Tooltip(
        message: 'share'.tr,
        child: _circleButton(
          icon: Icons.share_outlined,
          shadowOpacity: shadowOpacity,
          onTap: () => ShareHelper.shareProduct(buttonContext, product),
        ),
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
        outOfStock
            ? 'out_of_stock'.tr
            : 'stock_count_in_stock'.trParams({'count': '${product.stock}'}),
        style: poppinsMedium.copyWith(
          fontSize: Constants.fontSizeSmall,
          color: outOfStock ? ColorResource.error : ColorResource.success,
        ),
      ),
    );
  }

  /// Discount badge between the rating and the price — "10% OFF" /
  /// "৳100 OFF", or the flash-sale saving while a sale runs. Rebuilt with the
  /// flash controller so it follows a sale starting or ending on this page.
  Widget _buildDiscountBadge() {
    return GetBuilder<FlashSaleController>(
      builder: (_) {
        final label = _discountLabel;
        if (label == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: Constants.paddingSizeSmall),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Constants.paddingSizeSmall,
              vertical: Constants.paddingSizeExtraSmall - 1,
            ),
            decoration: BoxDecoration(
              color: ColorResource.primaryDark.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(Constants.radiusSmall),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_offer_outlined,
                  size: 14,
                  color: ColorResource.primaryDark,
                ),
                const SizedBox(width: Constants.paddingSizeExtraSmall),
                Text(
                  label,
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeSmall,
                    color: ColorResource.primaryDark,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpecs() {
    final rows = <Widget>[];
    if ((product.sku ?? '').isNotEmpty) {
      rows.add(_specRow('sku'.tr, product.sku!));
    }
    if (product.weight != null) {
      rows.add(
        _specRow('weight'.tr, '${product.weight}${product.weightUnit ?? ''}'),
      );
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows,
      ),
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
                color: context.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: poppinsMedium.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: context.textPrimary,
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
                    color: context.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
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
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ...product.variants.map(_buildVariantGroup),
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
              : context.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? ColorResource.primaryDark
                : context.textLight.withValues(alpha: 0.3),
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
                    : context.textPrimary,
              ),
            ),
            if (option.price > 0) ...[
              const SizedBox(width: 6),
              Text(
                // Shop variations are the price itself; food options add on.
                _variationIsPrice
                    ? PriceHelper.formatPrice(option.price)
                    : '+${PriceHelper.formatPrice(option.price)}',
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
            VariantSelection(
              optionName: option.name,
              optionPrice: option.price,
            ),
          );
        }
      } else {
        for (final option
            in (_selectedVariants[variant.title] as List<VariantOption>)) {
          selections.add(
            VariantSelection(
              optionName: option.name,
              optionPrice: option.price,
            ),
          );
        }
      }
      if (selections.isNotEmpty) {
        result.add(
          SelectedVariant(
            groupTitle: variant.title,
            groupType: variant.type,
            selections: selections,
          ),
        );
      }
    }
    return result;
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        Constants.paddingSizeDefault,
        Constants.paddingSizeSmall,
        Constants.paddingSizeDefault,
        Constants.paddingSizeSmall,
      ),
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
        child: product.isOutOfStock
            ? _disabledButton('out_of_stock'.tr)
            : _buildPurchaseBar(),
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      // Sized to the accessible minimum rather than grown by padding, so the
      // stepper — and with it the whole purchase bar — stays compact without
      // shrinking the hit area.
      child: SizedBox.square(
        dimension: Constants.minTapTarget,
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? context.textLight : ColorResource.primaryDark,
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
          disabledBackgroundColor: context.textLight.withValues(alpha: 0.4),
          // Matches the enabled add-to-cart button so the bar keeps the same
          // height when a product is out of stock.
          padding: const EdgeInsets.symmetric(
            vertical: Constants.paddingSizeSmall,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Constants.radiusLarge),
          ),
        ),
        child: Text(
          label,
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeDefault,
            color: ColorResource.textWhite,
          ),
        ),
      ),
    );
  }
}
