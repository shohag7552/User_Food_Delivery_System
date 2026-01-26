import 'package:appwrite_user_app/app/common/widgets/custom_clickable_widget.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/controllers/category_controller.dart';
import 'package:appwrite_user_app/app/modules/categories/screens/category_screen.dart';
import 'package:appwrite_user_app/app/modules/categories/screens/category_products_page.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CategorySectionWidget extends StatelessWidget {
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
                    'Menu Categories',
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
                      'See All',
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
              const SizedBox(
                height: 50,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )

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
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: categoryController.categories.length,
                    itemBuilder: (context, index) {
                      final category = categoryController.categories[index];
                      return CustomClickableWidget(
                        onTap: () {
                          Get.to(() => CategoryProductsPage(category: category));
                        },
                        margin: const EdgeInsets.only(right: Constants.paddingSizeLarge),
                        child: Container(
                          width: 70,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(Constants.radiusLarge),
                            boxShadow: [BoxShadow(color: Theme.of(context).disabledColor.withValues(alpha: 0.3), offset: const Offset(0, 5), blurRadius: 5)],
                          ),
                          child: Column(children: [
                            Expanded(
                              flex: 7,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(Constants.radiusLarge),
                                child: CustomNetworkImage(image: category.imagePath??'', width: 70, height: double.infinity,),
                              ),
                            ),

                            Expanded(
                              flex: 3,
                              child: Center(child: Text(category.name, style: poppinsMedium, maxLines: 2, overflow: TextOverflow.ellipsis)),
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
                )

              // Empty State
              else
                SizedBox(
                  height: 50,
                  child: Center(
                    child: Text(
                      'No categories available',
                      style: poppinsRegular.copyWith(
                        fontSize: Constants.fontSizeDefault,
                        color: ColorResource.textLight,
                      ),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}
