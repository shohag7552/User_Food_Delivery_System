import 'package:appwrite_user_app/app/common/widgets/custom_clickable_widget.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/controllers/category_controller.dart';
import 'package:appwrite_user_app/app/helper/localization_extension_helper.dart';
import 'package:appwrite_user_app/app/modules/categories/screens/category_screen.dart';
import 'package:appwrite_user_app/app/modules/categories/screens/category_products_page.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/dashboard_shimmer.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CategorySectionWidget extends StatelessWidget {
  static const int _maxHomeCategorySlots = 10;

  const CategorySectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CategoryController>(
      builder: (categoryController) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'menu_categories'.tr,
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeExtraLarge,
                      color: ColorResource.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to all categories
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CategoryScreen(),
                        ),
                      );
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
            else if (categoryController.categories.isNotEmpty)
              _buildHomeCategories(context, categoryController)
            // Empty State
            else
              SizedBox(
                height: 50,
                child: Center(
                  child: Text(
                    'no_categories_available'.tr,
                    style: poppinsRegular.copyWith(
                      fontSize: Constants.fontSizeDefault,
                      color: ColorResource.textLight,
                    ),
                  ),
                ),
              )
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

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(left: 20, bottom: 10),
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
              Get.to(() => CategoryProductsPage(category: category));
            },
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
  }) {
    return CustomClickableWidget(
      onTap: onTap,
      isBackgroundTransparent: true,
      margin: const EdgeInsets.only(right: Constants.paddingSizeLarge),
      child: SizedBox(
        width: 70,
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
                    width: 2,
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
                          color: ColorResource.cardBackground,
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

  Widget _buildMoreCategoriesTile(BuildContext context, int totalCategories) {
    return CustomClickableWidget(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CategoryScreen(),
          ),
        );
      },
      isBackgroundTransparent: true,
      margin: const EdgeInsets.only(right: Constants.paddingSizeLarge),
      child: SizedBox(
        width: 70,
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
