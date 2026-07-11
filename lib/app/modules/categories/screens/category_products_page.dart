import 'package:appwrite_user_app/app/common/widgets/custom_clickable_widget.dart';
import 'package:appwrite_user_app/app/common/widgets/favorite_button.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/common/widgets/hover_lift.dart';
import 'package:appwrite_user_app/app/common/widgets/rating_stars.dart';
import 'package:appwrite_user_app/app/common/widgets/web_top_nav.dart';
import 'package:appwrite_user_app/app/controllers/module_controller.dart';
import 'package:appwrite_user_app/app/controllers/product_controller.dart';
import 'package:appwrite_user_app/app/helper/cart_helper.dart';
import 'package:appwrite_user_app/app/helper/dashboard_tab_bus.dart';
import 'package:appwrite_user_app/app/helper/localization_extension_helper.dart';
import 'package:appwrite_user_app/app/models/category_model.dart';
import 'package:appwrite_user_app/app/models/product_model.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/product_detail_bottomsheet.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/web_profile_drawer.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class CategoryProductsPage extends StatefulWidget {
  final CategoryModel category;

  const CategoryProductsPage({super.key, required this.category}); 

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  static const int _pageSize = 10;
  static const double _maxContentWidth = 1100;

  final GlobalKey<ScaffoldState> _webScaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  List<ProductModel> _products = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadProducts();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        _isLoading ||
        _isLoadingMore ||
        !_hasMore) {
      return;
    }

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadProducts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _hasMore = true;
      _products = [];
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products = await Get.find<ProductController>().getProductsByCategory(
        widget.category.id,
        offset: _currentPage * _pageSize,
        limit: _pageSize,
      );
      setState(() {
        _products = products;
        _hasMore = products.length >= _pageSize;
        _currentPage = products.isEmpty ? 0 : 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load products: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMore) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final products = await Get.find<ProductController>().getProductsByCategory(
        widget.category.id,
        offset: _currentPage * _pageSize,
        limit: _pageSize,
      );

      setState(() {
        _products.addAll(products);
        _hasMore = products.length >= _pageSize;
        if (products.isNotEmpty) {
          _currentPage++;
        }
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });

      Get.snackbar(
        'Error',
        'Failed to load more products',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorResource.error.withValues(alpha: 0.9),
        colorText: ColorResource.textWhite,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Web shell (with the shared top-nav) only on desktop web — mobile,
    // tablets and narrow browser windows use the regular mobile scaffold.
    final useWebShell = WebTopNav.isEnabled(context);
    return useWebShell
        ? _buildWebScaffold(context)
        : _buildMobileScaffold(context);
  }

  // ---------------------------------------------------------------------------
  // Mobile (unchanged)
  // ---------------------------------------------------------------------------

  Widget _buildMobileScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorResource.scaffoldBackground,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // App Bar with Category Info
          _buildSliverAppBar(),

          // Products Grid
          if (_isLoading)
            SliverFillRemaining(
              child: _buildLoadingState(),
            )
          else if (_errorMessage != null)
            SliverFillRemaining(
              child: _buildErrorState(),
            )
          else if (_products.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(),
            )
          else
            SliverMainAxisGroup(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.7,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = _products[index];
                        return _buildProductCard(product);
                      },
                      childCount: _products.length,
                    ),
                  ),
                ),
                if (_isLoadingMore)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: ColorResource.primaryDark,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Web
  // ---------------------------------------------------------------------------

  Widget _buildWebScaffold(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 1400
        ? 5
        : width >= 1100
            ? 4
            : 3;

    late final Widget contentSliver;
    if (_isLoading) {
      contentSliver = SliverFillRemaining(
        hasScrollBody: false,
        child: _buildLoadingState(),
      );
    } else if (_errorMessage != null) {
      contentSliver = SliverFillRemaining(
        hasScrollBody: false,
        child: _buildErrorState(),
      );
    } else if (_products.isEmpty) {
      contentSliver = SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmptyState(),
      );
    } else {
      contentSliver = SliverMainAxisGroup(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 0.72,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    HoverLift(child: _buildProductCard(_products[index])),
                childCount: _products.length,
              ),
            ),
          ),
          if (_isLoadingMore)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Center(
                  child: CircularProgressIndicator(
                    color: ColorResource.primaryDark,
                  ),
                ),
              ),
            ),
        ],
      );
    }

    // Full-bleed scroll view (wheel and scrollbar work across the whole
    // screen, not just the middle column) — the content itself stays centered
    // within the cap via symmetric sliver gutters.
    final double gutter =
        width > _maxContentWidth ? (width - _maxContentWidth) / 2 : 0;

    return Scaffold(
      key: _webScaffoldKey,
      backgroundColor: ColorResource.scaffoldBackground,
      endDrawer: const WebProfileDrawer(),
      appBar: WebTopNav(
        selectedIndex: null,
        onDestinationSelected: (index) {
          DashboardTabs.open(context, index);
        },
        onMenuTap: () => _webScaffoldKey.currentState?.openEndDrawer(),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            sliver: SliverToBoxAdapter(child: _buildWebHeader()),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            sliver: contentSliver,
          ),
        ],
      ),
    );
  }

  Widget _buildWebHeader() {
    final description = widget.category.descriptionMap.trLanguage.trim();
    final hasImage = widget.category.imagePath?.isNotEmpty ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb: Home / <category>
          Row(
            children: [
              InkWell(
                onTap: () {
                  DashboardTabs.open(context, 0);
                },
                child: Text(
                  'home'.tr,
                  style: poppinsMedium.copyWith(
                    fontSize: Constants.fontSizeSmall,
                    color: ColorResource.primaryDark,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: ColorResource.textLight,
                ),
              ),
              Flexible(
                child: Text(
                  widget.category.nameMap.trLanguage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: poppinsMedium.copyWith(
                    fontSize: Constants.fontSizeSmall,
                    color: ColorResource.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Hero banner
          ClipRRect(
            borderRadius: BorderRadius.circular(Constants.radiusLarge),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    CustomNetworkImage(
                      image: widget.category.imagePath!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: ColorResource.primaryGradient,
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.category.nameMap.trLanguage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: poppinsBold.copyWith(
                            fontSize: Constants.fontSizeOverLarge,
                            color: ColorResource.textWhite,
                          ),
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: poppinsRegular.copyWith(
                              fontSize: Constants.fontSizeSmall,
                              color: ColorResource.textWhite
                                  .withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: ColorResource.primaryDark,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: ColorResource.textWhite),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.category.nameMap.trLanguage,
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeLarge,
            color: ColorResource.textWhite,
          ),
        ),
        background: widget.category.imagePath != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  CustomNetworkImage(
                    image: widget.category.imagePath!,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          ColorResource.primaryDark.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Container(
                decoration: BoxDecoration(
                  gradient: ColorResource.primaryGradient,
                ),
              ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: ColorResource.primaryDark,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading products...',
            style: poppinsMedium.copyWith(
              fontSize: Constants.fontSizeDefault,
              color: ColorResource.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: ColorResource.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Oops!',
              style: poppinsBold.copyWith(
                fontSize: 24,
                color: ColorResource.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: ColorResource.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _loadProducts(refresh: true),
              icon: const Icon(Icons.refresh),
              label: Text('try_again'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorResource.primaryDark,
                foregroundColor: ColorResource.textWhite,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Constants.radiusLarge),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: ColorResource.primaryDark.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.food_bank_outlined,
                size: 60,
                color: ColorResource.textLight,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Products Found',
              style: poppinsBold.copyWith(
                fontSize: 24,
                color: ColorResource.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We couldn\'t find any products in this category yet.\nCheck back soon!',
              textAlign: TextAlign.center,
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: ColorResource.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: Text('go_back'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorResource.primaryDark,
                foregroundColor: ColorResource.textWhite,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Constants.radiusLarge),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ecommerce items open their full detail page; food items keep the
  /// quick-view bottom sheet (dialog on desktop web).
  void _openProduct(ProductModel product) {
    if (product.moduleType == ModuleController.ecommerce) {
      context.pushNamed(
        RouteNames.productDetail,
        pathParameters: {'id': product.id},
        extra: product,
      );
    } else {
      ProductDetailBottomSheet.show(context, product);
    }
  }

  Widget _buildProductCard(ProductModel product) {
    final hasDiscount = product.discountValue != null && product.discountValue! > 0;
    final discountPercentage = hasDiscount ? product.discountValue!.toInt() : 0;

    return CustomClickableWidget(
      onTap: () => _openProduct(product),
      isBackgroundTransparent: true,
      child: Container(
        decoration: BoxDecoration(
          color: ColorResource.cardBackground,
          borderRadius: BorderRadius.circular(Constants.radiusLarge),
          boxShadow: ColorResource.customShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with badges and favorite button
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(Constants.radiusLarge),
                      topRight: Radius.circular(Constants.radiusLarge),
                    ),
                    child: CustomNetworkImage(
                      image: product.imageId,
                      height: 160,
                      width: double.infinity,
                    ),
                  ),

                  // Discount Badge
                  if (hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: ColorResource.error,
                          borderRadius: BorderRadius.circular(Constants.radiusSmall),
                        ),
                        child: Text(
                          '$discountPercentage% OFF',
                          style: poppinsBold.copyWith(
                            fontSize: Constants.fontSizeExtraSmall,
                            color: ColorResource.textWhite,
                          ),
                        ),
                      ),
                    ),

                  // Favorite Button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: FavoriteButton(
                      product: product,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),

            // Product Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    product.nameMap.trLanguage,
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeDefault,
                      color: ColorResource.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  RatingStars(
                    rating: product.avgRating,
                    reviewCount: product.ratingCount,
                    size: 13,
                  ),
                  const SizedBox(height: 8),

                  // Price and Add Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '\$${product.finalPrice.toStringAsFixed(2)}',
                              style: poppinsBold.copyWith(
                                fontSize: Constants.fontSizeLarge,
                                color: ColorResource.primaryDark,
                              ),
                            ),
                            if (hasDiscount)
                              Text(
                                '\$${product.price.toStringAsFixed(2)}',
                                style: poppinsRegular.copyWith(
                                  fontSize: Constants.fontSizeSmall,
                                  color: ColorResource.textLight,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Add Button — real add-to-cart (the old handler only
                      // showed a snackbar without adding anything). Ecommerce
                      // items with variants open the detail page to pick them.
                      GestureDetector(
                        onTap: () {
                          if (product.moduleType == ModuleController.ecommerce &&
                              product.variants.isNotEmpty) {
                            _openProduct(product);
                          } else {
                            CartHelper.handleAddToCart(product, context);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: ColorResource.primaryGradient,
                            borderRadius: BorderRadius.circular(
                              Constants.radiusDefault,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: ColorResource.primaryMedium.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.add_shopping_cart,
                            color: ColorResource.textWhite,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
