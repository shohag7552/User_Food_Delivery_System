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
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [

              SliverAppBar(
                floating: true,
                pinned: true,
                elevation: 0,
                automaticallyImplyLeading: false,
                surfaceTintColor: Theme.of(context).colorScheme.surface,
                backgroundColor: Theme.of(context).colorScheme.surface,
                title: _buildSearchBar(),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Quick Actions
                      Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: _buildQuickActions(),
                      ),
                      const SizedBox(height: 28),

                      // Promotional Banners
                      _buildPromotionalBanners(),
                      const SizedBox(height: 28),

                      // Categories
                      _buildCategoriesSection(),
                      const SizedBox(height: 28),

                      // Featured Restaurants
                      _buildFeaturedRestaurants(isTablet),
                      const SizedBox(height: 28),

                      // Popular Dishes
                      _buildPopularDishes(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ColorResource.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: ColorResource.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
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
              'Search for restaurants or dishes...',
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: ColorResource.textLight,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: ColorResource.primaryGradient,
              borderRadius: BorderRadius.circular(Constants.radiusDefault),
            ),
            child: Icon(
              Icons.tune,
              color: ColorResource.textWhite,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'icon': Icons.near_me, 'label': 'Nearby', 'color': ColorResource.info},
      {'icon': Icons.restaurant_menu, 'label': 'Menu', 'color': ColorResource.success},
      {'icon': Icons.favorite, 'label': 'Favorites', 'color': ColorResource.favoriteColor},
      {'icon': Icons.local_offer, 'label': 'Offers', 'color': ColorResource.warning},
    ];
    
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
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
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Categories',
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
        const SizedBox(height: 16),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
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

  Widget _buildFeaturedRestaurants(bool isTablet) {
    final restaurants = [
      {
        'name': 'Italian Paradise',
        'imageUrl': 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4',
        'cuisineType': 'Italian, Pizza, Pasta',
        'rating': 4.8,
        'deliveryTime': '25-30 min',
        'minimumOrder': 'Min \$15',
      },
      {
        'name': 'Burger House',
        'imageUrl': 'https://images.unsplash.com/photo-1550547660-d9450f859349',
        'cuisineType': 'American, Burgers, Fast Food',
        'rating': 4.6,
        'deliveryTime': '15-20 min',
        'minimumOrder': 'Min \$10',
      },
      {
        'name': 'Sushi Master',
        'imageUrl': 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351',
        'cuisineType': 'Japanese, Sushi, Asian',
        'rating': 4.9,
        'deliveryTime': '30-35 min',
        'minimumOrder': 'Min \$20',
      },
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Featured Restaurants',
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeExtraLarge,
                color: ColorResource.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: See all restaurants
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
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: restaurants.length,
          itemBuilder: (context, index) {
            final restaurant = restaurants[index];
            return RestaurantCard(
              name: restaurant['name'] as String,
              imageUrl: restaurant['imageUrl'] as String,
              cuisineType: restaurant['cuisineType'] as String,
              rating: restaurant['rating'] as double,
              deliveryTime: restaurant['deliveryTime'] as String,
              minimumOrder: restaurant['minimumOrder'] as String,
              isFavorite: index == 0,
              onTap: () {
                // TODO: Navigate to restaurant details
              },
              onFavoriteToggle: () {
                // TODO: Toggle favorite
              },
            );
          },
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
        'oldPrice': 15.99,
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
        'oldPrice': 18.99,
      },
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Popular Dishes',
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeExtraLarge,
                color: ColorResource.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: See all dishes
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
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
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
              _buildNavItem(Icons.search, 'Search', 1),
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
