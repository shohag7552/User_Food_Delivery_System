import 'package:appwrite_user_app/app/common/widgets/custom_clickable_widget.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/common/widgets/hover_lift.dart';
import 'package:appwrite_user_app/app/common/widgets/web_top_nav.dart';
import 'package:appwrite_user_app/app/controllers/category_controller.dart';
import 'package:appwrite_user_app/app/helper/localization_extension_helper.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/models/category_model.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/dashboard_shimmer.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class CategorySectionWidget extends StatelessWidget {
  static const int _maxHomeCategorySlots = 10;

  /// Desktop web shows one row of tiles; at the full content width the grid
  /// fits exactly nine, so a tenth would wrap onto a lonely second row.
  static const int _maxWebCategorySlots = 9;

  const CategorySectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CategoryController>(
      builder: (categoryController) {
        // No categories: the section disappears instead of an empty shell.
        if (!categoryController.showHomeSection) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Own top spacing — the home column adds none, so nothing doubles
            // up when the section hides itself.
            const SizedBox(height: Constants.spaceSection),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'menu_categories'.tr,
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeExtraLarge,
                      color: context.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to all categories
                      context.pushNamed(RouteNames.categories);
                    },
                    child: Text(
                      'see_all'.tr,
                      style: poppinsMedium.copyWith(
                        fontSize: Constants.fontSizeDefault,
                        color: ColorResource.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Loading State
            if (categoryController.isLoading)
              const CategorySectionShimmer()
            // Error State
            else if (categoryController.errorMessage != null)
              SizedBox(
                height: 50,
                child: Center(
                  child: Text(
                    categoryController.errorMessage!,
                    style: poppinsRegular.copyWith(
                      fontSize: Constants.fontSizeSmall,
                      color: ColorResource.error,
                    ),
                  ),
                ),
              )
            // Categories List
            else
              _buildHomeCategories(context, categoryController)
          ],
        );
      },
    );
  }

  Widget _buildHomeCategories(
    BuildContext context,
    CategoryController categoryController,
  ) {
    final categories = categoryController.categories;
    final showMoreTile = categories.length > _maxHomeCategorySlots;
    final visibleCategories = showMoreTile
        ? categories.take(_maxHomeCategorySlots - 1).toList()
        : categories.take(_maxHomeCategorySlots).toList();
    final itemCount = visibleCategories.length + (showMoreTile ? 1 : 0);

    // Desktop web: an even, hover-lifted grid that fills the content cap
    // (a single row of larger tiles at full cap width). Mobile keeps its
    // horizontal strip untouched.
    //
    // No "more" tile on web: the section header's "See all" button already
    // leads to the full list, and a second one wrapping onto its own grid row
    // only repeats it. The grid just shows up to the slot cap.
    if (WebTopNav.isEnabled(context)) {
      final webCategories = categories.take(_maxWebCategorySlots).toList();
      return _buildWebCategoriesGrid(
        context,
        visibleCategories: webCategories,
        showMoreTile: false,
        totalCategories: categories.length,
        itemCount: webCategories.length,
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsetsDirectional.only(start: 20, bottom: 10),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (showMoreTile && index == itemCount - 1) {
            return _buildMoreCategoriesTile(context, categories.length);
          }

          final category = visibleCategories[index];
          return _buildCategoryTile(
            context,
            label: category.nameMap.trLanguage,
            imagePath: category.imagePath,
            onTap: () {
              context.pushNamed(
                RouteNames.category,
                pathParameters: {'id': category.id},
                extra: category,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildWebCategoriesGrid(
    BuildContext context, {
    // Typed (not dynamic): nameMap.trLanguage is an extension getter, and
    // extensions never resolve on dynamic receivers at runtime.
    required List<CategoryModel> visibleCategories,
    required bool showMoreTile,
    required int totalCategories,
    required int itemCount,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 118,
          mainAxisExtent: 132,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          final Widget tile;
          if (showMoreTile && index == itemCount - 1) {
            tile = _buildMoreCategoriesTile(
              context,
              totalCategories,
              width: double.infinity,
              margin: EdgeInsets.zero,
            );
          } else {
            final category = visibleCategories[index];
            tile = _buildCategoryTile(
              context,
              label: category.nameMap.trLanguage,
              imagePath: category.imagePath,
              onTap: () {
                context.pushNamed(
                  RouteNames.category,
                  pathParameters: {'id': category.id},
                  extra: category,
                );
              },
              width: double.infinity,
              margin: EdgeInsets.zero,
            );
          }
          return HoverLift(
            borderRadius: Constants.radiusExtraLarge,
            showShadow: false,
            child: tile,
          );
        },
      ),
    );
  }

  Widget _buildCategoryTile(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
    String? imagePath,
    // Mobile strip defaults; the web grid passes an expanding width and no
    // trailing margin so tiles fill their cells evenly.
    double width = 70,
    EdgeInsets? margin,
  }) {
    return CustomClickableWidget(
      onTap: onTap,
      isBackgroundTransparent: true,
      margin: margin ??
          const EdgeInsetsDirectional.only(end: Constants.paddingSizeLarge),
      child: SizedBox(
        width: width,
        child: Column(
          children: [
            Expanded(
              flex: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(
                    Constants.radiusExtraLarge,
                  ),
                  border: Border.all(
                    color: ColorResource.primaryLight,
                    width: 0.5,
                  ),
                ),
                padding: const EdgeInsets.all(1),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    Constants.radiusExtraLarge - 2,
                  ),
                  child: imagePath != null && imagePath.isNotEmpty
                      ? CustomNetworkImage(
                          image: imagePath,
                          width: 70,
                          height: double.infinity,
                        )
                      : Container(
                          color: context.cardBackground,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.restaurant_menu,
                            color: ColorResource.primaryDark,
                            size: 28,
                          ),
                        ),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Center(
                child: Text(
                  label,
                  style: poppinsMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreCategoriesTile(
    BuildContext context,
    int totalCategories, {
    double width = 70,
    EdgeInsets? margin,
  }) {
    return CustomClickableWidget(
      onTap: () {
        context.pushNamed(RouteNames.categories);
      },
      isBackgroundTransparent: true,
      margin: margin ??
          const EdgeInsetsDirectional.only(end: Constants.paddingSizeLarge),
      child: SizedBox(
        width: width,
        child: Column(
          children: [
            Expanded(
              flex: 8,
              child: Container(
                decoration: BoxDecoration(
                  gradient: ColorResource.primaryGradient,
                  borderRadius: BorderRadius.circular(
                    Constants.radiusExtraLarge,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ColorResource.primaryMedium.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  '$totalCategories+',
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeLarge,
                    color: ColorResource.textWhite,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Center(
                child: Text(
                  'see_all'.tr,
                  style: poppinsMedium.copyWith(
                    color: ColorResource.primaryDark,
                  ),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
