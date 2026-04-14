import 'package:appwrite_user_app/app/common/widgets/custom_clickable_widget.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/controllers/category_controller.dart';
import 'package:appwrite_user_app/app/helper/localization_extension_helper.dart';
import 'package:appwrite_user_app/app/models/category_model.dart';
import 'package:appwrite_user_app/app/modules/categories/screens/category_products_page.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/dashboard_shimmer.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  @override
  void initState() {
    super.initState();
    final controller = Get.find<CategoryController>();
    if (controller.categories.isEmpty && !controller.isLoading) {
      controller.getCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorResource.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          'categories'.tr,
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeLarge,
            color: ColorResource.textWhite,
          ),
        ),
        backgroundColor: ColorResource.primaryDark,
        foregroundColor: ColorResource.textWhite,
        elevation: 0,
      ),
      body: GetBuilder<CategoryController>(
        builder: (controller) {
          if (controller.isLoading && controller.categories.isEmpty) {
            return const Padding(
              padding: EdgeInsets.only(top: 12),
              child: CategorySectionShimmer(),
            );
          }

          if (controller.errorMessage != null && controller.categories.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: ColorResource.error,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      controller.errorMessage!,
                      textAlign: TextAlign.center,
                      style: poppinsRegular.copyWith(
                        fontSize: Constants.fontSizeDefault,
                        color: ColorResource.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => controller.getCategories(),
                      child: Text(
                        'try_again'.tr,
                        style: poppinsBold.copyWith(
                          color: ColorResource.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (controller.categories.isEmpty) {
            return Center(
              child: Text(
                'no_categories_available'.tr,
                style: poppinsRegular.copyWith(
                  fontSize: Constants.fontSizeDefault,
                  color: ColorResource.textLight,
                ),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 18,
              childAspectRatio: 0.7,
            ),
            itemCount: controller.categories.length,
            itemBuilder: (context, index) {
              final category = controller.categories[index];
              return _buildCategoryCard(context, category);
            },
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, CategoryModel category) {
    return CustomClickableWidget(
      onTap: () {
        Get.to(() => CategoryProductsPage(category: category));
      },
      isBackgroundTransparent: true,
      child: Column(
        children: [
          Expanded(
            flex: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(
                  Constants.radiusExtraLarge,
                ),
                border: Border.all(
                  color: ColorResource.primaryLight.withValues(alpha: 0.7),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  Constants.radiusExtraLarge - 2,
                ),
                child: category.imagePath != null && category.imagePath!.isNotEmpty
                    ? CustomNetworkImage(
                        image: category.imagePath!,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    : Container(
                        color: ColorResource.cardBackground,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.restaurant_menu,
                          size: 32,
                          color: ColorResource.primaryDark,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            flex: 3,
            child: Text(
              category.nameMap.trLanguage,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
}
