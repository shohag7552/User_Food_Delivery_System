import 'package:appwrite_user_app/app/modules/dashboard/section_widget/category_section_widget.dart';
import 'package:appwrite_user_app/app/modules/dashboard/section_widget/todays_specials_widget.dart';
import 'package:appwrite_user_app/app/modules/dashboard/section_widget/popular_dishes_widget.dart';
import 'package:appwrite_user_app/app/modules/dashboard/section_widget/new_items_widget.dart';
import 'package:appwrite_user_app/app/modules/dashboard/section_widget/all_products_widget.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:flutter/material.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/promotional_banner.dart';
import 'package:appwrite_user_app/app/controllers/banner_controller.dart';
import 'package:appwrite_user_app/app/controllers/product_controller.dart';
import 'package:get/get.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more when near bottom
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
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Custom Sliver App Bar with gradient
        _buildSliverAppBar(context),

        // Main Content
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildPromotionalBanners(),
              ),

              const SizedBox(height: 28),

              // Categories
              CategorySectionWidget(),

              const SizedBox(height: 28),

              // Today's Specials
              const TodaysSpecialsWidget(),

              const SizedBox(height: 28),

              // Popular Dishes
              const PopularDishesWidget(),

              const SizedBox(height: 28),

              // New Items
              const NewItemsWidget(),

              const SizedBox(height: 20),
            ],
          ),
        ),

        SliverAppBar(
          automaticallyImplyLeading: false,
          pinned: true,
          backgroundColor: ColorResource.scaffoldBackground,
          elevation: 0,
          toolbarHeight: 0,
          flexibleSpace: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'All Products',
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeExtraLarge,
                    color: ColorResource.textPrimary,
                  ),
                ),
                IconButton(
                    onPressed: () {}, icon: const Icon(Icons.filter_list))
              ],
            ),
          ),
        ),

        AllProductsWidget(
            isTablet: isTablet, scrollController: _scrollController),
      ],
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: ColorResource.primaryDark,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: ColorResource.primaryGradient,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Greeting
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Good Evening! 👋',
                              style: poppinsRegular.copyWith(
                                fontSize: Constants.fontSizeDefault,
                                color:
                                    ColorResource.textWhite.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'What would you like to eat?',
                              style: poppinsBold.copyWith(
                                fontSize: Constants.fontSizeExtraLarge,
                                color: ColorResource.textWhite,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Notifications & Profile
                      Row(
                        children: [
                          Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: ColorResource.overlayMedium,
                                  borderRadius: BorderRadius.circular(
                                      Constants.radiusDefault),
                                ),
                                child: Icon(
                                  Icons.notifications_outlined,
                                  color: ColorResource.textWhite,
                                  size: 24,
                                ),
                              ),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: ColorResource.error,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: ColorResource.primaryDark,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: ColorResource.textWhite,
                            child: Icon(
                              Icons.person,
                              color: ColorResource.primaryDark,
                              size: 26,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Search Bar
                  _buildSearchBar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ColorResource.textWhite,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: ColorResource.textSecondary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Search for dishes...',
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: ColorResource.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionalBanners() {
    return GetBuilder<BannerController>(
      builder: (bannerController) {
        return PromotionalBanner(
          banners: bannerController.banners,
          isLoading: bannerController.isLoading,
          errorMessage: bannerController.errorMessage,
          onRetry: () => bannerController.getBanners(),
        );
      },
    );
  }
}
