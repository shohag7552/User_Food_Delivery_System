import 'package:appwrite_user_app/app/controllers/product_controller.dart';
import 'package:appwrite_user_app/app/modules/ecommerce/widgets/product_filter_sheet.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Pinned "All Products" section header: the title plus a filter button that
/// carries the active-filter count. Everything else lives in the filter sheet.
///
/// Mounted through a pinned [SliverPersistentHeader], so it sticks to the top
/// of the viewport once the grid scrolls under it — the filter stays reachable
/// no matter how far down the catalogue the user is.
class AllProductsHeaderDelegate extends SliverPersistentHeaderDelegate {
  /// Side gutter, matching the surrounding storefront sections.
  final double horizontalPadding;

  const AllProductsHeaderDelegate({required this.horizontalPadding});

  /// Fixed height — one row plus vertical padding. Pinned headers need
  /// [minExtent] == [maxExtent] to sit still rather than collapse.
  static const double height = 56;

  static const double _rowHeight = 36;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  bool shouldRebuild(covariant AllProductsHeaderDelegate oldDelegate) =>
      oldDelegate.horizontalPadding != horizontalPadding;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return _AllProductsHeader(
      horizontalPadding: horizontalPadding,
      // Only separate from the content once something is actually passing
      // beneath — a resting header needs no divider.
      showDivider: overlapsContent,
    );
  }
}

class _AllProductsHeader extends StatelessWidget {
  final double horizontalPadding;
  final bool showDivider;

  const _AllProductsHeader({
    required this.horizontalPadding,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProductController>(
      builder: (productController) {
        return Container(
          height: AllProductsHeaderDelegate.height,
          // Opaque, so the grid scrolls underneath instead of showing through.
          color: context.scaffoldBackground,
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'all_products'.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: poppinsBold.copyWith(
                            fontSize: Constants.fontSizeExtraLarge,
                            color: context.textPrimary,
                          ),
                        ),
                      ),
                      _FilterButton(
                        activeCount:
                            productController.productFilter.activeCount,
                        onTap: () => ProductFilterFlow.open(context),
                      ),
                    ],
                  ),
                ),
              ),
              if (showDivider)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: context.textLight.withValues(alpha: 0.18),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Filter entry point, badged with how many filter groups are applied — the
/// only surface telling the user a filter is narrowing the grid, so it fills
/// in solid once anything is active.
class _FilterButton extends StatelessWidget {
  final int activeCount;
  final VoidCallback onTap;

  const _FilterButton({required this.activeCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = activeCount > 0;
    final foreground = isActive
        ? ColorResource.textWhite
        : ColorResource.primaryDark;

    return Material(
      color: isActive ? ColorResource.primaryDark : context.cardBackground,
      borderRadius: BorderRadius.circular(Constants.radiusDefault),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Constants.radiusDefault),
        child: Container(
          height: AllProductsHeaderDelegate._rowHeight,
          padding: const EdgeInsets.symmetric(
            horizontal: Constants.paddingSizeDefault,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Constants.radiusDefault),
            border: Border.all(
              color: isActive
                  ? ColorResource.primaryDark
                  : context.textLight.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune_rounded, size: 16, color: foreground),
              const SizedBox(width: Constants.paddingSizeExtraSmall),
              Text(
                isActive ? '${'filters'.tr} ($activeCount)' : 'filters'.tr,
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeSmall,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
