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
import 'package:appwrite_user_app/app/modules/dashboard/widgets/category_chip.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/promotional_banner.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/order_tracking_widget.dart';



class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _chartAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _chartAnimation;

  int touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _chartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
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
    _chartAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _chartAnimationController,
        curve: Curves.easeInOutCubic,
      ),
    );
    _animationController.forward();
    // Delay chart animation to start after page fade in
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _chartAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _chartAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    
    return Scaffold(
      backgroundColor: ColorResource.scaffoldBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Custom Sliver App Bar with gradient
          _buildSliverAppBar(context),
          
          // Main Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // // Vendor Info Card
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(horizontal: 20),
                  //   child: Transform.translate(
                  //     offset: Offset(0, _slideAnimation.value),
                  //     child: _buildVendorInfoCard(),
                  //   ),
                  // ),
                  //
                  // const SizedBox(height: 24),
                  //
                  // // Active Order Tracking
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(horizontal: 20),
                  //   child: Transform.translate(
                  //     offset: Offset(0, _slideAnimation.value),
                  //     child: _buildActiveOrder(),
                  //   ),
                  // ),
                  //
                  // // Stats Cards
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(horizontal: 20),
                  //   child: Transform.translate(
                  //     offset: Offset(0, _slideAnimation.value),
                  //     child: _buildStatsSection(isTablet),
                  //   ),
                  // ),
                  //
                  // const SizedBox(height: 24),
                  //
                  // // Quick Actions
                  // Padding(
                  //   padding: const EdgeInsets.only(left: 20),
                  //   child: _buildQuickActions(),
                  // ),
                  //
                  // const SizedBox(height: 28),
                  
                  // Promotional Banners
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildPromotionalBanners(),
                  ),
                  
                  const SizedBox(height: 28),
                  
                  // Categories
                  _buildCategoriesSection(),
                  
                  const SizedBox(height: 28),
                  
                  // Today's Specials
                  _buildTodaysSpecials(),
                  
                  const SizedBox(height: 28),
                  
                  // Popular Dishes
                  _buildPopularDishes(),
                  
                  const SizedBox(height: 28),
                  
                  // New Items
                  _buildNewItems(isTablet),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
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

  Widget _buildVendorInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorResource.cardBackground,
            ColorResource.cardBackground.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: ColorResource.shadowMedium,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Vendor Logo
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: ColorResource.primaryGradient,
              borderRadius: BorderRadius.circular(Constants.radiusLarge),
              boxShadow: [
                BoxShadow(
                  color: ColorResource.primaryMedium.withOpacity(0.4),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.restaurant,
              size: 40,
              color: ColorResource.textWhite,
            ),
          ),
          const SizedBox(width: 16),
          // Vendor Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LokLagbe Kitchen',
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeLarge,
                    color: ColorResource.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 16,
                      color: ColorResource.ratingStarColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '4.8',
                      style: poppinsMedium.copyWith(
                        fontSize: Constants.fontSizeSmall,
                        color: ColorResource.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• ',
                      style: TextStyle(color: ColorResource.textLight),
                    ),
                    Text(
                      '500+ orders',
                      style: poppinsRegular.copyWith(
                        fontSize: Constants.fontSizeSmall,
                        color: ColorResource.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: ColorResource.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Open Now',
                      style: poppinsMedium.copyWith(
                        fontSize: Constants.fontSizeSmall,
                        color: ColorResource.success,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• ',
                      style: TextStyle(color: ColorResource.textLight),
                    ),
                    Text(
                      'Closes at 11:00 PM',
                      style: poppinsRegular.copyWith(
                        fontSize: Constants.fontSizeSmall,
                        color: ColorResource.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Info Button
          IconButton(
            onPressed: () {
              // TODO: Show vendor info
            },
            icon: Icon(
              Icons.info_outline,
              color: ColorResource.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOrder() {
    // Show active order if user has one
    final hasActiveOrder = true;
    
    if (!hasActiveOrder) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: OrderTrackingWidget(
        orderId: '12345',
        status: 'On the way',
        estimatedTime: '15-20 min',
        driverName: 'John Doe',
        driverPhone: '+1234567890',
        onTrackOrder: () {
          // TODO: Navigate to tracking page
        },
      ),
    );
  }

  Widget _buildStatsSection(bool isTablet) {
    final stats = [
      {'title': 'Active Orders', 'value': '2', 'icon': Icons.shopping_bag_outlined, 'color': ColorResource.primaryLight},
      {'title': 'Total Spent', 'value': '\$248', 'icon': Icons.account_balance_wallet_outlined, 'color': ColorResource.success},
      {'title': 'Loyalty Points', 'value': '1,240', 'icon': Icons.stars_outlined, 'color': ColorResource.warning},
    ];
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: isTablet ? 1.1 : 0.9,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return DashboardStatsCard(
          title: stat['title'] as String,
          value: stat['value'] as String,
          icon: stat['icon'] as IconData,
          iconColor: stat['color'] as Color,
          onTap: () {
            // TODO: Navigate to details
          },
        );
      },
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'icon': Icons.receipt_long, 'label': 'My Orders', 'color': ColorResource.info},
      {'icon': Icons.favorite, 'label': 'Favorites', 'color': ColorResource.favoriteColor},
      {'icon': Icons.local_offer, 'label': 'Offers', 'color': ColorResource.warning},
      {'icon': Icons.help_outline, 'label': 'Help', 'color': ColorResource.success},
    ];
    
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(right: 20),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          return QuickActionButton(
            icon: action['icon'] as IconData,
            label: action['label'] as String,
            backgroundColor: action['color'] as Color,
            onTap: () {
              // TODO: Handle action
            },
          );
        },
      ),
    );
  }

  Widget _buildPromotionalBanners() {
    final banners = [
      BannerData(
        imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836',
        title: '50% OFF',
        subtitle: 'On your first order',
        onTap: () {},
      ),
      BannerData(
        imageUrl: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1',
        title: 'Free Delivery',
        subtitle: 'Orders above \$30',
        onTap: () {},
      ),
      BannerData(
        imageUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38',
        title: 'Weekend Special',
        subtitle: 'Get extra 20% off',
        onTap: () {},
      ),
    ];
    
    return PromotionalBanner(banners: banners);
  }

  Widget _buildCategoriesSection() {
    final categories = [
      {'label': 'All', 'icon': Icons.apps},
      {'label': 'Pizza', 'icon': Icons.local_pizza},
      {'label': 'Burgers', 'icon': Icons.lunch_dining},
      {'label': 'Sushi', 'icon': Icons.set_meal},
      {'label': 'Desserts', 'icon': Icons.cake},
      {'label': 'Drinks', 'icon': Icons.local_cafe},
      {'label': 'Salads', 'icon': Icons.restaurant},
    ];
    
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
                  // TODO: See all categories
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
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return CategoryChip(
                label: category['label'] as String,
                icon: category['icon'] as IconData,
                isSelected: index == 0,
                onTap: () {
                  // TODO: Filter by category
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTodaysSpecials() {
    final specials = [
      {
        'name': 'Chef\'s Special Pizza',
        'imageUrl': 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002',
        'description': 'Handcrafted pizza with premium toppings',
        'price': 16.99,
        'oldPrice': 22.99,
      },
      {
        'name': 'Grilled Chicken Bowl',
        'imageUrl': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c',
        'description': 'Healthy bowl with grilled chicken & veggies',
        'price': 12.99,
        'oldPrice': 16.99,
      },
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: ColorResource.warning,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                'Today\'s Specials',
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeExtraLarge,
                  color: ColorResource.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: specials.length,
            itemBuilder: (context, index) {
              final dish = specials[index];
              return FoodItemCard(
                name: dish['name'] as String,
                imageUrl: dish['imageUrl'] as String,
                description: dish['description'] as String,
                price: dish['price'] as double,
                oldPrice: dish['oldPrice'] as double?,
                onTap: () {
                  // TODO: Navigate to dish details
                },
                onAddToCart: () {
                  // TODO: Add to cart
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPopularDishes() {
    final dishes = [
      {
        'name': 'Margherita Pizza',
        'imageUrl': 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002',
        'description': 'Classic Italian pizza with fresh mozzarella',
        'price': 12.99,
        'oldPrice': null,
      },
      {
        'name': 'Chicken Burger',
        'imageUrl': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd',
        'description': 'Juicy chicken patty with special sauce',
        'price': 8.99,
        'oldPrice': null,
      },
      {
        'name': 'California Roll',
        'imageUrl': 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351',
        'description': 'Fresh sushi roll with avocado and crab',
        'price': 14.99,
        'oldPrice': null,
      },
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(
                Icons.trending_up,
                color: ColorResource.success,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                'Popular Dishes',
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeExtraLarge,
                  color: ColorResource.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: dishes.length,
            itemBuilder: (context, index) {
              final dish = dishes[index];
              return FoodItemCard(
                name: dish['name'] as String,
                imageUrl: dish['imageUrl'] as String,
                description: dish['description'] as String,
                price: dish['price'] as double,
                oldPrice: dish['oldPrice'] as double?,
                onTap: () {
                  // TODO: Navigate to dish details
                },
                onAddToCart: () {
                  // TODO: Add to cart
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNewItems(bool isTablet) {
    final newItems = [
      {
        'name': 'Truffle Pasta',
        'imageUrl': 'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9',
        'description': 'Creamy pasta with truffle oil',
        'price': 18.99,
        'oldPrice': null,
      },
      {
        'name': 'Vegan Buddha Bowl',
        'imageUrl': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c',
        'description': 'Nutritious bowl with quinoa & veggies',
        'price': 14.99,
        'oldPrice': null,
      },
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ColorResource.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Constants.radiusSmall),
                ),
                child: Text(
                  'NEW',
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeSmall,
                    color: ColorResource.info,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'New Items',
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeExtraLarge,
                  color: ColorResource.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: newItems.length,
            itemBuilder: (context, index) {
              final dish = newItems[index];
              return FoodItemCard(
                name: dish['name'] as String,
                imageUrl: dish['imageUrl'] as String,
                description: dish['description'] as String,
                price: dish['price'] as double,
                oldPrice: dish['oldPrice'] as double?,
                onTap: () {
                  // TODO: Navigate to dish details
                },
                onAddToCart: () {
                  // TODO: Add to cart
                },
              );
            },
          ),
        ),
      ],
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
