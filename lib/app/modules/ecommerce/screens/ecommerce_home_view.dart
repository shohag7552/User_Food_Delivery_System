import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/controllers/banner_controller.dart';
import 'package:appwrite_user_app/app/controllers/brand_controller.dart';
import 'package:appwrite_user_app/app/controllers/category_controller.dart';
import 'package:appwrite_user_app/app/controllers/product_controller.dart';
import 'package:appwrite_user_app/app/helper/localization_extension_helper.dart';
import 'package:appwrite_user_app/app/modules/categories/screens/category_products_page.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/promotional_banner.dart';
import 'package:appwrite_user_app/app/modules/ecommerce/widgets/ecommerce_product_card.dart';
import 'package:appwrite_user_app/app/modules/search/screens/search_page.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EcommerceHomeView extends StatefulWidget {
  const EcommerceHomeView({super.key});

  @override
  State<EcommerceHomeView> createState() => _EcommerceHomeViewState();
}

class _EcommerceHomeViewState extends State<EcommerceHomeView>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadData();
  }

  Future<void> _loadData({bool reload = false}) async {
    final categoryController = Get.find<CategoryController>();
    final bannerController = Get.find<BannerController>();
    final brandController = Get.find<BrandController>();
    final productController = Get.find<ProductController>();

    await Future.wait([
      bannerController.getBanners(reload: reload),
      categoryController.getCategories(reload: reload),
      brandController.getBrands(reload: reload),
      productController.getPopularProducts(reload: reload),
      productController.getProducts(reload: reload),
    ]);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      Get.find<ProductController>().loadMoreProducts();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final size = MediaQuery.of(context).size;
    final crossAxisCount = size.width > 600 ? 3 : 2;

    return RefreshIndicator(
      color: ColorResource.primaryDark,
      onRefresh: () => _loadData(reload: true),
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildBanners()),
          SliverToBoxAdapter(child: _buildCategories()),
          SliverToBoxAdapter(child: _buildBrands()),
          SliverToBoxAdapter(child: _buildPopular()),
          SliverToBoxAdapter(
            child: _sectionHeader('all_products'.tr),
          ),
          _buildAllProductsGrid(crossAxisCount),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(gradient: ColorResource.primaryGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'shop'.tr,
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeExtraLarge,
                  color: ColorResource.textWhite,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Get.to(() => const SearchPage()),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: ColorResource.cardBackground,
                    borderRadius: BorderRadius.circular(Constants.radiusLarge),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: ColorResource.textSecondary),
                      const SizedBox(width: 12),
                      Text(
                        'search_products'.tr,
                        style: poppinsRegular.copyWith(
                          fontSize: Constants.fontSizeDefault,
                          color: ColorResource.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBanners() {
    return GetBuilder<BannerController>(
      builder: (bannerController) {
        if (bannerController.banners.isEmpty && !bannerController.isLoading) {
          return const SizedBox(height: 16);
        }
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: PromotionalBanner(
            banners: bannerController.banners,
            isLoading: bannerController.isLoading,
            errorMessage: bannerController.errorMessage,
            onRetry: () => bannerController.getBanners(reload: true),
          ),
        );
      },
    );
  }

  Widget _buildCategories() {
    return GetBuilder<CategoryController>(
      builder: (controller) {
        if (controller.categories.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('categories'.tr),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: controller.categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final category = controller.categories[index];
                  return GestureDetector(
                    onTap: () => Get.to(
                      () => CategoryProductsPage(category: category),
                    ),
                    child: SizedBox(
                      width: 68,
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: ColorResource.primaryDark
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: (category.imagePath?.isNotEmpty ?? false)
                                ? CustomNetworkImage(
                                    image: category.imagePath!,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  )
                                : Icon(
                                    Icons.category_outlined,
                                    color: ColorResource.primaryDark,
                                  ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            category.nameMap.trLanguage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: poppinsMedium.copyWith(
                              fontSize: Constants.fontSizeExtraSmall,
                              color: ColorResource.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBrands() {
    return GetBuilder<BrandController>(
      builder: (controller) {
        if (controller.brands.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('brands'.tr),
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: controller.brands.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final brand = controller.brands[index];
                  return Container(
                    width: 110,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: ColorResource.cardBackground,
                      borderRadius: BorderRadius.circular(Constants.radiusLarge),
                      border: Border.all(
                        color: ColorResource.textLight.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        if ((brand.logoUrl ?? '').isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CustomNetworkImage(
                              image: brand.logoUrl!,
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            brand.nameMap.trLanguage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: poppinsMedium.copyWith(
                              fontSize: Constants.fontSizeSmall,
                              color: ColorResource.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPopular() {
    return GetBuilder<ProductController>(
      builder: (controller) {
        if (controller.popularProducts.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('popular'.tr),
            SizedBox(
              height: 280,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                itemCount: controller.popularProducts.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, index) => SizedBox(
                  width: 170,
                  child: EcommerceProductCard(
                    product: controller.popularProducts[index],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAllProductsGrid(int crossAxisCount) {
    return GetBuilder<ProductController>(
      builder: (controller) {
        if (controller.products.isEmpty && controller.isLoading) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (controller.products.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'no_products_available'.tr,
                  style: poppinsMedium.copyWith(
                    color: ColorResource.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 0.6,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => EcommerceProductCard(
                product: controller.products[index],
              ),
              childCount: controller.products.length,
            ),
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Text(
        title,
        style: poppinsBold.copyWith(
          fontSize: Constants.fontSizeExtraLarge,
          color: ColorResource.textPrimary,
        ),
      ),
    );
  }
}
