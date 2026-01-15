import 'package:appwrite_user_app/app/common/widgets/sliver_deligate.dart';
import 'package:appwrite_user_app/app/modules/dashboard/section_widget/category_section_widget.dart';
import 'package:appwrite_user_app/app/modules/dashboard/section_widget/todays_specials_widget.dart';
import 'package:appwrite_user_app/app/modules/dashboard/section_widget/popular_dishes_widget.dart';
import 'package:appwrite_user_app/app/modules/dashboard/section_widget/new_items_widget.dart';
import 'package:appwrite_user_app/app/modules/dashboard/section_widget/all_products_widget.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:flutter/material.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:appwrite_user_app/app/modules/categories/screens/category_screen.dart';
import 'package:appwrite_user_app/app/modules/coupons/screens/coupons_screen.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/dashboard_stats_card.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/quick_action_button.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/restaurant_card.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/food_item_card.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/promotional_banner.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/order_tracking_widget.dart';
import 'package:appwrite_user_app/app/controllers/category_controller.dart';
import 'package:appwrite_user_app/app/controllers/product_controller.dart';
import 'package:appwrite_user_app/app/controllers/banner_controller.dart';
import 'package:get/get.dart';



class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  // late AnimationController _chartAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _chartAnimation;

  int touchedIndex = -1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    _animationController.forward();

    Get.find<CategoryController>().getCategories();
    Get.find<BannerController>().getBanners();
    Get.find<ProductController>().getSpecialProducts();
    Get.find<ProductController>().getPopularProducts();
    Get.find<ProductController>().getNewProducts();
    Get.find<ProductController>().getProducts();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      print('====> Near bottom, loading more products');
      // Load more when near bottom
      Get.find<ProductController>().loadMoreProducts();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    
    return Scaffold(
      backgroundColor: ColorResource.scaffoldBackground,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
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

                  // AllProductsWidget(isTablet: isTablet),
                  // AllProductsWidget(isTablet: isTablet, scrollController: _scrollController),

                  // const SizedBox(height: 20),
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

                    IconButton(onPressed: (){}, icon: Icon(Icons.filter_list) )
                  ],
                ),
              ),
            ),

            AllProductsWidget(isTablet: isTablet, scrollController: _scrollController),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: ColorResource.primaryDark,
      // title: Text(
      //   'Dashboard',
      //   style: poppinsBold.copyWith(
      //     fontSize: Constants.fontSizeLarge,
      //     color: ColorResource.textWhite,
      //   ),
      // ),
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
                                color: ColorResource.textWhite.withOpacity(0.9),
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
                                  borderRadius: BorderRadius.circular(Constants.radiusDefault),
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

  int _selectedIndex = 0;

  Widget _buildBottomNavBar() {
    return Container(
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', 0),
              _buildNavItem(Icons.restaurant_menu, 'Menu', 1),
              _buildNavItem(Icons.receipt_long, 'Orders', 2),
              _buildNavItem(Icons.person, 'Profile', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        // TODO: Navigate to respective page
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? ColorResource.primaryGradient : null,
          borderRadius: BorderRadius.circular(Constants.radiusLarge),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? ColorResource.textWhite
                  : ColorResource.textSecondary,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeSmall,
                  color: ColorResource.textWhite,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

}
